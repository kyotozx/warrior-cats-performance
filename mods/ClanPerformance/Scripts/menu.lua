local dir=debug.getinfo(1,'S').source:gsub('^@',''):match('^(.*[/\\])')
local O=dofile(dir..'options.lua');local M={}
function M.new(ctx,controller,meter)
 local page='presets';local draft;local pendingText,meterText;local api={};local lastSeconds;local savedPage=1
 local comfortPage='view'
 local function invoke(p,fn)local ok,why=fn();if not ok then p.notify(why)else p.refresh()end end
 function api.open()draft=nil;page='presets'end
 function api.navigate(delta)
  if controller.status().pending then return false end
  local pages={'presets','image','world','comfort','frames','measure','saved'}
  for i,v in ipairs(pages)do if v==page then page=pages[(i-1+delta)%#pages+1];return end end
 end
 function api.render(p)
  pendingText=nil;meterText=nil
  local s=controller.status();draft=draft or(s.current and O.copy(s.current))
  if draft then draft.comfort=draft.comfort or O.comfort.copy()end
  if p.icon then p.icon('performance',90,70,64)end
  p.text('PERFORMANCE',176,65,1570,48,true)
  p.text('Graphics, camera comfort and performance controls',94,143,1500,22)
  local tabs={{'presets','Presets'},{'image','Image quality'},{'world','World & effects'},{'comfort','Camera & Comfort'},{'frames','Frame rate'},{'measure','Performance monitor'},{'saved','Saved presets'}}
  for i,t in ipairs(tabs)do p.button((page==t[1]and'>  'or'')..t[2],90,245+(i-1)*73,365,function()page=t[1];p.refresh();p.focusContent()end,not s.pending,'tabs')end
  p.text('Active: '..s.label,94,760,350,23,true)
  p.text('F9 / L3: open from game menus',94,875,345,19)
  p.text('Credits: kyotozx',94,925,340,16)
  p.button('Back to game menu',1370,915,440,p.close,not s.pending,'footer')
  if s.pending then
   p.text('Keep these settings?',525,250,1250,38,true)
   pendingText=p.text('Reverting in '..(s.seconds or 20)..' seconds',529,335,1200,26)
   p.text('Changes are temporary until confirmed. Original settings remain recoverable.',529,405,1230,23)
   p.button('Keep changes',525,560,600,function()draft=nil;invoke(p,controller.confirm)end)
   p.button('Revert',1160,560,600,function()draft=nil;invoke(p,controller.cancel)end)
   return
  end
  if not s.ready or not draft then p.text(s.error or'Waiting for game video settings...',525,300,1240,25);return end
  if page=='presets'then
   p.text('Choose a starting point',525,232,1250,36,true)
   for i,preset in ipairs(O.presets)do
    local y=320+(i-1)*150
    p.button(preset.name,525,y,365,function()draft=O.copy(preset.values);draft.comfort=O.comfort.copy(s.current.comfort);invoke(p,function()return controller.preview(draft,preset.name)end)end)
    p.text(preset.description,935,y+6,820,23)
   end
   p.text('Low and Ultra Low disable Lumen. Use Balanced if interiors become too dark.',529,790,1250,21)
   p.button('Restore original settings',525,915,770,function()invoke(p,controller.restore);draft=nil end,s.canRestore,'footer')
  elseif page=='image'or page=='world'then
   p.text(page=='image'and'Image quality'or'World & effects',525,225,1230,36,true)
   local keys=page=='image'and{'scale','aa','gi','reflection','texture','post'}or{'view','shadow','effects','foliage','shading'}
   for i,key in ipairs(keys)do
    local y=306+(i-1)*88;local g
    for _,row in ipairs(O.groups)do if row[1]==key then g=row end end
    local label=g and g[2]or(key=='scale'and'Render scale'or'Frame limit')
    local value=g and O.quality[draft[key]+1]or(key=='scale'and(string.format('%.0f%%',draft.scale))or(draft.cap==0 and'Unlimited'or draft.cap..' FPS'))
    p.text(label,529,y+2,380,24,true)
    p.text(g and g[4]or(key=='scale'and'Internal 3D resolution. Interface stays sharp.'or'Use one mod to manage the frame limit.'),529,y+35,755,16)
    local function adjust(delta)
     if g then draft[key]=math.max(0,math.min(4,draft[key]+delta))
     elseif key=='scale'then draft.scale=math.max(25,math.min(100,math.floor(draft.scale+delta*5+.5)))
     else
      local caps={0,30,40,45,60,75,90,120,144,165,240};local idx=1
      for j,n in ipairs(caps)do if n<=draft.cap then idx=j end end
      draft.cap=caps[math.max(1,math.min(#caps,idx+delta))];draft.smooth=false
     end
     p.refresh()
    end
    p.button('-',1300,y,100,function()adjust(-1)end)
    p.text(value,1430,y+15,225,24,true)
    p.button('+',1680,y,100,function()adjust(1)end)
   end
   p.button('Preview custom settings',525,915,770,function()invoke(p,function()return controller.preview(draft,'Custom')end)end,true,'footer')
  elseif page=='comfort'then
   p.text('Camera & Comfort',525,232,1250,36,true)
   p.button((comfortPage=='view'and'>  'or'')..'View & motion',525,305,600,function()comfortPage='view';p.refresh()end)
   p.button((comfortPage=='controls'and'>  'or'')..'Camera controls',1160,305,615,function()comfortPage='controls';p.refresh()end)
   local c=draft.comfort
   local rows=comfortPage=='view'and{
    {'blur','Motion blur','Disable motion blur without changing other effects.',c.blur and'Off'or'Game default'},
    {'fov','Exploration FOV','Horizontal field of view. Default follows the game.',c.fov==0 and'Game default'or c.fov..' degrees'},
    {'shake','Camera shake','Turn off exploration shakes. Scenes keep their own camera.',c.shake and'Off'or'Game default'},
    {'sprint','Sprint camera effects','Disable sprint zoom, pullback and added blur.',c.sprint and'Off'or'Game default'},
   }or{
    {'smoothing','Camera smoothing','Reduced follows more closely. Off removes positional and rotational lag.',({'Game default','Reduced','Off'})[c.smoothing+1]},
    {'horizontal','Horizontal sensitivity','Native camera turn speed for keyboard and controller.',string.format('%.0f%%',c.horizontal*100)},
    {'vertical','Vertical sensitivity','Native vertical speed. Your invert-axis setting is preserved.',string.format('%.0f%%',c.vertical*100)},
   }
   for i,row in ipairs(rows)do
    local key,label,hint,value=table.unpack(row);local y=397+(i-1)*88
    p.text(label,529,y,690,25,true);p.text(hint,529,y+36,755,16)
    local function change(delta)
     if key=='fov'then
      local values={0,60,65,70,75,80,85,90,95,100,105,110};local index=1
      for j,n in ipairs(values)do if n<=c.fov then index=j end end
      c.fov=values[math.max(1,math.min(#values,index+delta))]
     elseif key=='smoothing'then c.smoothing=math.max(0,math.min(2,c.smoothing+delta))
     elseif key=='horizontal'or key=='vertical'then c[key]=math.max(.25,math.min(2,math.floor(c[key]*100+delta*5+.5)/100))
     else c[key]=not c[key]end
     p.refresh()
    end
    p.button('-',1300,y,100,function()change(-1)end);p.text(value,1410,y+16,260,22,true)
    p.button('+',1680,y,100,function()change(1)end)
   end
   local function previewComfort(value,label)
    local values=O.copy(s.current);values.comfort=O.comfort.copy(value);draft=nil
    invoke(p,function()return controller.preview(values,label)end)
   end
   p.button('Reduced Camera Motion',525,790,620,function()previewComfort(O.comfort.reduced,'Reduced Camera Motion')end)
   p.button('Restore camera defaults',1180,790,600,function()previewComfort(O.comfort.defaults,'Camera defaults')end)
   local cs=ctx.comfortStatus and ctx.comfortStatus()or{}
   p.text(cs.error or'Camera controls apply during free exploration. Motion blur is a global setting.',529,860,1230,17)
   p.button('Preview camera settings',525,915,770,function()previewComfort(c,'Custom camera')end,true,'footer')
  elseif page=='frames'then
   p.text('Frame rate',525,232,1250,36,true)
   p.text('Selected: '..(draft.cap==0 and'Unlimited'or string.format('%.0f FPS',draft.cap)),529,303,1200,25,true)
   local caps={30,40,45,60,75,90,120,144,165,240,360,0}
   for i,cap in ipairs(caps)do
    p.button(cap==0 and'Unlimited'or cap..' FPS',525+((i-1)%4)*315,365+math.floor((i-1)/4)*82,295,function()draft.cap=cap;draft.smooth=false;p.refresh()end)
   end
   p.text('Custom limit (15 to 1000 FPS)',529,625,1200,23,true)
   local function change(delta)return function()draft.cap=math.max(15,math.min(1000,math.floor(draft.cap+delta)));draft.smooth=false;p.refresh()end end
   p.button('- 10',525,680,240,change(-10));p.button('- 1',785,680,240,change(-1))
   p.button('+ 1',1045,680,240,change(1));p.button('+ 10',1305,680,240,change(10))
   p.button('FPS counter: '..(s.counter and'On'or'Off'),525,772,590,function()invoke(p,function()return controller.counter(not s.counter)end)end)
   p.text('VSync is controlled in the game options and may limit FPS.',1135,783,640,19)
   p.button('Preview frame limit',525,915,770,function()
    local values=O.copy(s.current);values.cap=draft.cap;values.smooth=false
    invoke(p,function()return controller.preview(values,'Custom FPS')end)
   end,true,'footer')
  elseif page=='saved'then
   p.text('Your saved presets',525,232,1250,36,true)
   p.button('Save current settings',525,315,700,function()
    p.prompt('Name your preset',function(name)
     local ok,why=controller.savePreset(name)
     if ok then savedPage=math.max(1,math.ceil(#controller.status().presets/3))end
     return ok,why
    end)
   end,#(s.presets or{})<24)
   p.text('Saves graphics, frame limits and Camera & Comfort settings currently in use.',529,385,1250,19)
   local saved=s.presets or{};local pages=math.max(1,math.ceil(#saved/3));savedPage=math.min(savedPage,pages)
   if #saved==0 then p.text('No saved presets yet. Save your current setup to switch back to it later.',529,490,1200,24)end
   for i=(savedPage-1)*3+1,math.min(savedPage*3,#saved)do
    local preset=saved[i];local y=440+((i-1)%3)*115
    p.button(preset.name,525,y,820,function()draft=nil;invoke(p,function()return controller.previewPreset(preset.name)end)end)
    p.button('Delete',1460,y,310,function()
     p.confirm('Delete preset?',preset.name..' will be removed from your saved presets. Your current graphics settings will stay as they are.',function()invoke(p,function()return controller.deletePreset(preset.name)end)end)
    end)
    p.text(string.format('%.0f%% render scale  |  %s',preset.values.scale,preset.values.cap==0 and'Unlimited FPS'or tostring(preset.values.cap)..' FPS'),550,y+67,1200,18)
   end
   if pages>1 then
    p.button('Previous',525,800,350,function()savedPage=savedPage-1;p.refresh()end,savedPage>1)
    p.text(savedPage..' / '..pages,1030,815,250,23,true)
    p.button('Next',1390,800,380,function()savedPage=savedPage+1;p.refresh()end,savedPage<pages)
   end
  else
   p.text('Measure, then compare',525,240,1200,36,true)
   meterText=p.text('',529,325,1200,28,true)
   p.text('Use the same place, camera and route for each preset. Close menus while measuring.',529,404,1250,22)
   p.text('The test counts 30 seconds of active samples. Pauses and loading gaps are excluded.',529,475,1250,22)
   p.text('Sampled FPS range is not a per-frame 1% low. A frame cap can hide rendering gains.',529,546,1250,22)
   p.button('Start 30-second measurement',525,665,1250,function()meter.begin();p.close()end)
   p.button('FPS overlay: '..(s.counter and'On'or'Off'),525,765,600,function()invoke(p,function()return controller.counter(not s.counter)end)end)
   p.button('Reload current values',1160,765,615,function()draft=O.copy(s.current);p.refresh()end)
  end
  if s.error then p.text(s.error:sub(1,135),529,860,1230,18)
  elseif s.changed then p.text('Another setting changed these values. Preview again to reapply your selection.',529,860,1230,18)end
 end
 function api.tick(panel)
  local s=controller.status()
  if pendingText and ctx.valid(pendingText)then
   if not s.pending then draft=nil;panel.refresh();pendingText=nil
   elseif lastSeconds~=s.seconds then lastSeconds=s.seconds;pendingText:SetText(FText('Reverting in '..s.seconds..' seconds'))end
  end
  if meterText and ctx.valid(meterText)then
   local m=meter.status();local label=m.fps and string.format('Live: %.0f FPS',m.fps)or'Live: --'
   if m.remaining then label=label..string.format('   |   Test: %.0f s remaining',m.remaining)
   elseif m.result then
    if m.result.error then label=m.result.error
    else label=string.format('Mean: %.1f FPS   |   Sample range: %.0f - %.0f',m.result.average,m.result.low,m.result.high)end
   end
   meterText:SetText(FText(label))
  end
 end
 return api
end
return M
