local dir=debug.getinfo(1,'S').source:gsub('^@',''):match('^(.*[/\\])')
local O=dofile(dir..'options.lua');local M={}
function M.new(adapter,store,clock,legacy)
 local state={schema=1,label='Original',counter=false};local pendingDeadline;local lastError;local started=false
 local ok,loaded=pcall(store.load)
 local function presetName(value)
  if type(value)~='string'then return nil,'Enter a preset name.'end
  value=value:match('^%s*(.-)%s*$')
  local length=utf8.len(value)
  if not length or length<1 or length>32 or value:find('[%z\1-\31\127<>]')then return nil,'Use 1 to 32 characters without control characters.'end
  return value
 end
 local function validPresets(presets)
  if presets==nil then return true end
  if type(presets)~='table'or #presets>24 then return false end
  local names,count={},0
  for i,p in pairs(presets)do
   if type(i)~='number'or i%1~=0 or i<1 or i>#presets or type(p)~='table'or not O.valid(p.values)then return false end
   local name=presetName(p.name);if not name or name~=p.name or names[name:lower()]then return false end
   names[name:lower()]=true;count=count+1
  end
  return count==#presets
 end
 local function validState(s)
  return type(s)=='table'and s.schema==1 and type(s.label)=='string'and #s.label<=128 and type(s.counter)=='boolean'and validPresets(s.presets)
   and(s.original==nil or O.valid(s.original))and(s.desired==nil or O.valid(s.desired))
   and(s.pending==nil or(type(s.pending)=='table'and O.valid(s.pending.before)and O.valid(s.pending.desired)
       and type(s.pending.label)=='string'and #s.pending.label<=128 and type(s.pending.restore)=='boolean'))
 end
 local loadError
 if not ok or(loaded~=nil and not validState(loaded))then loadError='Preferences are unreadable. Restore preferences.json.previous or move the damaged file aside.'
 elseif loaded then state=O.copy(loaded)end
 local function persist(s)assert(store.save(O.copy(s))~=false,'Cannot save performance preferences');state=O.copy(s)end
 local function read()local v=adapter.read();assert(O.valid(v),'Graphics settings are unavailable or outside supported bounds');return v end
 local function apply(v)adapter.apply(v);assert(O.equal(read(),v),'Engine did not accept every setting; changes were reverted')end
 local function guarded(fn)
  local success,a=pcall(function()assert(not loadError,loadError);return fn()end)
  if success then lastError=nil else lastError=tostring(a)end
  return success,success and a or lastError
 end
 local function rollback(v,previous)
  local good,why=pcall(function()apply(v);adapter.save();persist(previous)end)
  if not good then error('Recovery failed: '..tostring(why)..'. Keep this mod enabled and use Restore original.')end
 end
 local api={}
 function api.start()
  return guarded(function()
   if started then return end
   local before=read()
   if loaded==nil and legacy and not state.migrated then
    local nextState=O.copy(state);nextState.migrated=true;nextState.counter=legacy.counter
    if legacy.custom_limit then
     nextState.desired=O.copy(before);nextState.desired.smooth=false;nextState.label='Imported FPS'
     if legacy.original then
      nextState.original=O.copy(before);nextState.original.cap=legacy.original.limit;nextState.original.smooth=legacy.original.smooth
     end
    end
    persist(nextState)
   end
   if state.pending then
    local nextState=O.copy(state);local before=nextState.pending.before;nextState.pending=nil
    apply(before);adapter.save();persist(nextState)
   elseif state.desired then
    local good,why=pcall(function()apply(state.desired)end)
    if not good then apply(before);error(why)end
   end
   started=true
  end)
 end
 function api.preview(value,label,restore)
  return guarded(function()
   assert(started,'Graphics settings are not ready');assert(not state.pending,'Keep or revert the current preview first')
   assert(O.valid(value)and type(label)=='string'and #label<=128,'Invalid graphics selection')
   local before=read();local previous=O.copy(state);local nextState=O.copy(state)
   nextState.original=nextState.original or O.copy(before)
   nextState.pending={before=before,desired=O.copy(value),label=label,restore=restore==true}
   -- Recovery baseline is durable BEFORE any native mutation.
   persist(nextState)
   local good,why=pcall(function()apply(value)end)
   if not good then rollback(before,previous);error(why)end
   pendingDeadline=clock()+20
  end)
 end
 function api.confirm()
  return guarded(function()
   local p=assert(state.pending,'No preview to keep');local previous=O.copy(state);previous.pending=nil
   local nextState=O.copy(previous)
   if p.restore then nextState.original=nil;nextState.desired=nil;nextState.label='Original'
   else nextState.desired=O.copy(p.desired);nextState.label=p.label end
   local good,why=pcall(function()assert(O.equal(read(),p.desired),'Settings changed during preview');adapter.save();persist(nextState)end)
   if not good then rollback(p.before,previous);pendingDeadline=nil;error(why)end
   pendingDeadline=nil
  end)
 end
 function api.cancel()
  return guarded(function()
   local p=assert(state.pending,'No preview to revert');local nextState=O.copy(state);nextState.pending=nil
   apply(p.before);adapter.save();persist(nextState);pendingDeadline=nil
  end)
 end
 function api.restore()
  if not state.original then return false,'No original settings have been captured yet' end
  return api.preview(O.copy(state.original),'Original',true)
 end
 function api.counter(value)
  return guarded(function()assert(type(value)=='boolean');local s=O.copy(state);s.counter=value;persist(s)end)
 end
 function api.savePreset(name)
  return guarded(function()
   assert(started,'Graphics settings are not ready');assert(not state.pending,'Keep or revert the current preview first')
   local checked,why=presetName(name);assert(checked,why)
   local s=O.copy(state);s.presets=s.presets or{}
   assert(#s.presets<24,'You can save up to 24 presets. Delete one to make room.')
   for _,p in ipairs(s.presets)do assert(p.name:lower()~=checked:lower(),'A preset already uses that name. Choose another name.')end
   s.presets[#s.presets+1]={name=checked,values=O.copy(read())};persist(s)
  end)
 end
 function api.deletePreset(name)
  return guarded(function()
   assert(not state.pending,'Keep or revert the current preview first')
   local s=O.copy(state);local found
   for i,p in ipairs(s.presets or{})do if p.name==name then table.remove(s.presets,i);found=true;break end end
   assert(found,'Preset no longer exists');persist(s)
  end)
 end
 function api.previewPreset(name)
  for _,p in ipairs(state.presets or{})do if p.name==name then return api.preview(O.copy(p.values),p.name)end end
  return false,'Preset no longer exists'
 end
 function api.tick()
  if state.pending and pendingDeadline and clock()>=pendingDeadline then return api.cancel()end
  return true
 end
 function api.counterEnabled()return state.counter end
 function api.status()
  local good,current=pcall(read)
  return{ready=started,current=good and current or nil,label=state.label,counter=state.counter,
   desired=state.desired and O.copy(state.desired),presets=O.copy(state.presets or{}),canRestore=state.original~=nil,pending=state.pending~=nil,
   seconds=pendingDeadline and math.max(0,math.ceil(pendingDeadline-clock()))or nil,
   error=loadError or lastError or(not good and tostring(current)or nil),
   changed=good and state.desired~=nil and not state.pending and not O.equal(current,state.desired)}
 end
 return api
end
return M
