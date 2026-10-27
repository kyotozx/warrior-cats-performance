-- Exploration-only camera adjustments. No actor scans, input remaps or save edits.
local dir=debug.getinfo(1,'S').source:gsub('^@',''):match('^(.*[/\\])')
local O=dofile(dir..'comfort_options.lua');local layout=dofile(dir..'comfort_layout.lua')
local M={}
M.fields={fov=0x3f8,sprintBlur=0x3fc,sprintArm=0x41c,sprintArmHandheld=0x420,sprintFov=0x424,yaw=0x448,pitch=0x44c}
function M.verify(path)
 local f=assert(io.open(path,'rb'),'Camera controls require the supported game executable.')
 local ok,why=pcall(function()
  assert(f:seek('end')==layout.size,'Camera controls require Steam build 26184573.')
  for _,p in ipairs(layout.probes)do
   f:seek('set',p.offset);local bytes=assert(f:read(#p.hex/2))
   local hex=bytes:gsub('.',function(c)return string.format('%02x',string.byte(c))end)
   assert(hex==p.hex,'Camera layout differs from the supported game build.')
  end
 end);f:close();assert(ok,why);return true
end
function M.new(ctx)
 local settings=O.copy();local engine;local classes={};local registered=false
 local records={};local blurOriginal;local errorMessage;local active=false
 local api={}
 local valid=ctx.valid
 local function class(path)
  if not valid(classes[path])then classes[path]=StaticFindObject(path)end;return classes[path]
 end
 local function ensureLayout()
  if registered then return end
  assert((ctx.verify or M.verify)(ctx.root..'../../../Wrc-Win64-ShippingDRM.exe'))
  for name,offset in pairs(M.fields)do RegisterCustomProperty({Name='Performance_'..name,Type=PropertyTypes.FloatProperty,
   BelongsToClass='/Script/SwtAdventure.SwtAdventureCameraActor',OffsetInternal=offset})end
  RegisterCustomProperty({Name='Performance_horizontalLag',Type=PropertyTypes.FloatProperty,
   BelongsToClass='/Script/SwtAdventure.SwtAdventureCameraSpringArm',OffsetInternal=0x350})
  registered=true
 end
 local function finite(n,lo,hi)return type(n)=='number'and n==n and n>=lo and n<=hi end
 local function restore()
  local keep={};local last
  for key,r in pairs(records)do
   local ok,why=pcall(function()
    if valid(r.object)and r.object:GetAddress()==r.address and r.object:GetFullName()==r.name then
     -- Another owner changed this property: its newer value wins.
     if r.shake then
      if r.wasEnabled and r.object:IsDisabled()then r.object:EnableModifier()end
     elseif r.object[r.field]==r.written then r.object[r.field]=r.original end
    end
   end)
   if not ok then keep[key]=r;last=why end
  end
  records=keep;active=false;assert(next(keep)==nil,last)
 end
 local function write(object,field,change,lo,hi)
  local key=tostring(object:GetAddress())..':'..field;local r=records[key]
  local value=object[field]
  assert(type(value)=='boolean'or finite(value,lo or -10000,hi or 10000),'Camera property unavailable: '..field)
  if not r then r={object=object,address=object:GetAddress(),name=object:GetFullName(),field=field,original=value};records[key]=r
  elseif value~=r.written then r.original=value end
  local desired=change(r.original)
  if value~=desired then object[field]=desired end;r.written=desired
 end
 local function snapshot()
  if ctx.snapshot then return ctx.snapshot()end
  if not valid(engine)then engine=FindFirstOf('GameEngine')end
  if not valid(engine)or not valid(engine.GameViewport)then return end
  local w=engine.GameViewport.World;if not valid(w)then return end
  local s=w.GameState
  if not valid(s)or not s:IsA(class('/Script/Wrc.WrcGameplayGameState'))then return end
  local p=s.MainCharacter;if not valid(p)then return end
  local pc=p.Controller;local camera=s.CameraActor
  if not valid(pc)or not valid(camera)or s.CurrentPhase~=4 or valid(s.Director)then return end
  if not camera:IsA(class('/Script/SwtAdventure.SwtAdventureCameraActor'))then return end
  local target=pc:GetViewTarget()
  if not valid(target)or target:GetAddress()~=camera:GetAddress()or pc:IsLookInputIgnored()then return end
  if valid(camera.SplineActor)or valid(p.ActiveCameraSpline)then return end
  if not valid(camera.TargetActor)or camera.TargetActor:GetAddress()~=p:GetAddress()then return end
  if camera:GetWorld():GetAddress()~=w:GetAddress()then return end
  if class('/Script/Engine.Default__GameplayStatics'):IsGamePaused(w)then return end
  local arm,lens,manager=camera.AdventureArmComponent,camera.CameraComponent,pc.PlayerCameraManager
  if not valid(arm)or not valid(lens)or not valid(manager)then return end
  return{camera=camera,arm=arm,lens=lens,manager=manager,key=tostring(w:GetAddress())..':'..camera:GetAddress()..':'..p:GetAddress()}
 end
 local key
 local function tick()
  if not O.camera(settings)and not settings.shake then if next(records)then restore()end;key=nil;return end
  local s=snapshot()
  if not s then if next(records)then restore()end;key=nil;return end
  if key~=s.key then restore();key=s.key end
  if O.camera(settings)then
   ensureLayout();local camera=s.camera
   if settings.fov~=0 then write(camera,'Performance_fov',function()return settings.fov end,5,170)end
   if settings.sprint then
    for _,field in ipairs({'sprintArm','sprintArmHandheld','sprintFov','sprintBlur'})do write(camera,'Performance_'..field,function()return 0 end)end
   end
   if settings.horizontal~=1 then write(camera,'Performance_yaw',function(v)return v*settings.horizontal end,0,1000)end
   if settings.vertical~=1 then write(camera,'Performance_pitch',function(v)return v*settings.vertical end,0,1000)end
   if settings.smoothing==2 then
    write(s.arm,'bEnableCameraLag',function()return false end)
    write(s.arm,'bEnableCameraRotationLag',function()return false end)
   elseif settings.smoothing==1 then
    -- These native lag values are interpolation speeds: larger means less lag.
    for _,field in ipairs({'CameraLagSpeed','CameraRotationLagSpeed','Performance_horizontalLag'})do
     write(s.arm,field,function(v)return v==0 and 0 or math.min(1000,v*3)end,0,1000)
    end
   end
  end
  if settings.shake then
   -- Disable only the local shake modifier. Other camera modifiers keep running.
   local modifier=s.manager:FindCameraModifierByClass(class('/Script/Engine.CameraModifier_CameraShake'))
   if valid(modifier)then
    local id='shake:'..modifier:GetAddress()
    if not records[id]then records[id]={object=modifier,address=modifier:GetAddress(),name=modifier:GetFullName(),shake=true,wasEnabled=not modifier:IsDisabled()}end
    if not modifier:IsDisabled()then modifier:DisableModifier(true)end
   end
  end
  active=true
 end
 -- Blur is a global render option, separate from exploration camera ownership.
 local function blur(off)
  local k=class('/Script/Engine.Default__KismetSystemLibrary')
  if not valid(engine)then engine=FindFirstOf('GameEngine')end
  local world=valid(engine)and valid(engine.GameViewport)and engine.GameViewport.World
  assert(valid(world),'Open the game menu before changing motion blur.')
  if off then
   local now=k:GetConsoleVariableIntValue('r.MotionBlurQuality')
   assert(finite(now,0,4),'Motion blur setting unavailable.')
   if blurOriginal==nil then blurOriginal=now end
   k:ExecuteConsoleCommand(world,'r.MotionBlurQuality 0',nil)
   assert(k:GetConsoleVariableIntValue('r.MotionBlurQuality')==0,'Motion blur setting was not accepted.')
  elseif blurOriginal~=nil then
   if k:GetConsoleVariableIntValue('r.MotionBlurQuality')==0 then
    k:ExecuteConsoleCommand(world,'r.MotionBlurQuality '..blurOriginal,nil)
    assert(k:GetConsoleVariableIntValue('r.MotionBlurQuality')==blurOriginal,'Motion blur could not be restored.')
   end
   blurOriginal=nil
  end
 end
 function api.get()return O.copy(settings)end
 function api.configure(value)
  assert(O.valid(value),'Invalid camera settings.');value=O.copy(value)
  if O.camera(value)then ensureLayout()end
  restore();key=nil
  if value.blur or blurOriginal~=nil then blur(value.blur)end
  settings=value;errorMessage=nil
 end
 function api.tick()
  local ok,why=pcall(tick)
  if not ok then errorMessage=tostring(why);pcall(restore);return false,errorMessage end
  errorMessage=nil;return true
 end
 function api.status()return{active=active,error=errorMessage}end
 function api.reset()api.configure(O.defaults)end
 return api
end
return M
