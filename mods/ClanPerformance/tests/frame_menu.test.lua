local base='mods/ClanPerformance/Scripts/'
local O=dofile(base..'options.lua');local Menu=dofile(base..'menu.lua')
local current=O.copy(O.presets[1].values);current.cap=144;current.scale=100
local captured,counter;local status={ready=true,label='Original',current=current,counter=false,presets={}}
local controller={status=function()return status end,preview=function(v,label)captured=O.copy(v);return true end,counter=function(v)counter=v;status.counter=v;return true end}
local menu=Menu.new({},controller,{});local buttons={};local p={text=function()end,close=function()end,focusContent=function()end,notify=function(e)error(e)end}
p.button=function(label,x,y,w,fn)buttons[label]=fn end
p.refresh=function()buttons={};menu.render(p)end
local function click(label)assert(buttons[label],label)()end
p.refresh();click('Frame rate');click('Unlimited');click('Preview frame limit')
assert(captured.cap==0 and captured.scale==100 and not captured.smooth)
click('360 FPS');click('+ 10');click('Preview frame limit');assert(captured.cap==370)
for i=1,100 do click('+ 10')end;click('Preview frame limit');assert(captured.cap==1000)
for i=1,110 do click('- 10')end;click('Preview frame limit');assert(captured.cap==15)
click('FPS counter: Off');assert(counter and current.cap==144)
-- Draft quality edits must not leak into a frame-limit-only preview.
click('Image quality');click('-');click('Frame rate');click('Preview frame limit');assert(captured.scale==100)
print('PASS FPS presets, custom bounds, counter and frame-only previews preserve other quality settings')
