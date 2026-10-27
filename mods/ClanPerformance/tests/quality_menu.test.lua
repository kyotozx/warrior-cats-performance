local base='mods/ClanPerformance/Scripts/'
local O=dofile(base..'options.lua');local Menu=dofile(base..'menu.lua')

local function fixture(scale)
 local current=O.copy(O.presets[1].values);current.scale=scale
 local selected
 local controller={status=function()return{ready=true,label='Custom',current=current,counter=false,presets={}}end,
  preview=function(value)selected=O.copy(value);return true end}
 local menu=Menu.new({},controller,{});local buttons={};local scaleButtons={}
 local p={text=function()end,close=function()end,focusContent=function()end,notify=function(message)error(message)end}
 p.button=function(label,x,y,width,fn)
  buttons[label]=fn
  if y==306 and(label=='-'or label=='+')then scaleButtons[label]=fn end
 end
 p.refresh=function()buttons={};scaleButtons={};menu.render(p)end
 p.refresh();assert(buttons['Image quality'])()
 return function(direction)
  assert(scaleButtons[direction])();assert(buttons['Preview custom settings'])()
  return selected,current
 end
end

local adjust=fixture(40)
local changed,original=adjust('-')
assert(changed.scale==35,'Reducing a supported sub-50% render scale must not increase it')
original.scale=35;assert(O.equal(changed,original),'Render scale adjustment changed unrelated settings')
assert(adjust('+').scale==40)
for _,case in ipairs({{25,'-',25},{25,'+',30},{45,'-',40},{100,'+',100},{100,'-',95}})do
 local change=fixture(case[1]);local value=change(case[2])
 assert(value.scale==case[3]and O.valid(value),'Render scale must follow the supported 25–100% range')
end
print('PASS render scale direction, lower and upper bounds, and preservation of unrelated settings')
