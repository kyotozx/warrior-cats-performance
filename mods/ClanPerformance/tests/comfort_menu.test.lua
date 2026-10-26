local base='mods/ClanPerformance/Scripts/'
local O=dofile(base..'options.lua');local Menu=dofile(base..'menu.lua')
local current=O.copy(O.presets[1].values);current.comfort=O.comfort.copy()
local captured;local status={ready=true,label='Original',current=current,counter=false,presets={}}
local controller={status=function()return status end,preview=function(value)captured=O.copy(value);return true end}
local menu=Menu.new({},controller,{});local buttons={};local rows={}
local p={text=function()end,close=function()end,focusContent=function()end,notify=function(e)error(e)end}
p.button=function(label,x,y,w,fn,enabled,group)
 assert(y>=0 and y+66<=1080)
 buttons[label]=fn;if label=='+'then rows[#rows+1]={y=y,fn=fn}end
end
p.refresh=function()buttons={};rows={};menu.render(p)end
local function click(label)assert(buttons[label],label)()end
p.refresh();click('Camera & Comfort');click('Reduced Camera Motion')
assert(O.comfort.equal(captured.comfort,O.comfort.reduced)and captured.scale==current.scale)
click('Restore camera defaults');assert(O.comfort.equal(captured.comfort,O.comfort.defaults))
click('Camera controls');rows[2].fn();click('Preview camera settings')
assert(captured.comfort.horizontal==1.05 and captured.comfort.vertical==1 and captured.cap==current.cap)
click('View & motion');rows[2].fn();click('Preview camera settings');assert(captured.comfort.fov==60)
-- Graphics presets keep comfort preferences, while saved presets include them.
current.comfort=O.comfort.copy(O.comfort.reduced)
click('Presets');click('Low');assert(O.comfort.equal(captured.comfort,current.comfort))
print('PASS native Camera & Comfort page, preset/defaults, separate axes/FOV and graphics preset isolation')
