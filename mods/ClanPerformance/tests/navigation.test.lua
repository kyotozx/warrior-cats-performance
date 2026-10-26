local base='mods/ClanPerformance/Scripts/'
local Nav=dofile(base..'navigation.lua')
local Menu=dofile(base..'menu.lua')
local O=dofile(base..'options.lua')
local count=0
local function test(name,fn)fn();count=count+1;print('PASS '..name)end
local function fixture()
 local status={ready=true,label='Original',current=O.copy(O.presets[1].values),counter=false}
 status.current.scale=100
 local menu=Menu.new({valid=function(o)return o~=nil end},{status=function()return status end},{})
 local buttons,texts,index={}, {},1
 local p={}
 function p.text(t)texts[#texts+1]=t end
 function p.button(label,x,y,w,fn,enabled,zone)
  buttons[#buttons+1]={label=label,x=x,y=y,fn=fn,enabled=enabled~=false,zone=zone or'content',active=zone=='tabs'and label:sub(1,1)=='>'}
 end
 function p.refresh()buttons={};texts={};menu.render(p)end
 function p.focusContent()index=Nav.firstContent(buttons)or index end
 p.close=function()end
 p.refresh()
 return menu,p,function()return buttons,texts,index end,status
end
test('display name and selecting a tab enters its settings',function()
 local m,p,get=fixture();local b,t=get();assert(t[1]=='PERFORMANCE')
 b[2].fn();local b,t,index=get();assert(b[index].label=='-'and b[index].y==306)
end)
test('right enters content instead of moving down the sidebar',function()
 local m,p,get=fixture();local b=get();b[2].fn();b=get()
 local i=Nav.move(b,2,3);assert(b[i].label=='-'and b[i].y==306)
 assert(Nav.move(b,2,2)==3);assert(Nav.move(b,2,1)==1)
end)
test('settings navigate by rows and columns with a route back to tabs',function()
 local m,p,get=fixture();local b=get();b[2].fn();b=get()
 local minus=Nav.firstContent(b);local plus=Nav.move(b,minus,3)
 assert(b[plus].label=='+'and b[plus].y==306)
 local nextPlus=Nav.move(b,plus,2);assert(b[nextPlus].label=='+'and b[nextPlus].y==394)
 assert(Nav.move(b,nextPlus,1)==plus)
 assert(Nav.move(b,plus,4)==minus)
 assert(b[Nav.move(b,minus,4)].zone=='tabs')
 assert(Nav.move(b,plus,3)==plus)
end)
test('changing values preserves the page and affects only the selected draft field',function()
 local m,p,get,status=fixture();status.current.scale=100;p.refresh()
 local b=get();b[2].fn();b=get();b[Nav.firstContent(b)].fn()
 local _,t=get();local found=false;for _,v in ipairs(t)do if v=='95%'then found=true end end
 assert(found and status.current.scale==100)
end)
test('all tab pages and both footer actions remain reachable',function()
 local m,p,get=fixture()
 for page=1,6 do
  local b=get();b[page].fn();b=get()
  local start=Nav.firstContent(b);assert(start)
  local seen={[start]=true};local queue={start};local n=1
  while queue[n]do
   for dir=1,4 do local j=Nav.move(b,queue[n],dir);if not seen[j]then seen[j]=true;queue[#queue+1]=j end end
   n=n+1
  end
  for i,v in ipairs(b)do assert(not v.enabled or seen[i],page..': unreachable '..v.label)end
 end
end)
test('pending confirmation cannot switch tabs and disabled controls are skipped',function()
 local m,p,get,status=fixture();status.pending=true;status.seconds=20;p.refresh()
 assert(m.navigate(1)==false)
 local b=get();local i=Nav.firstContent(b);assert(b[i].label=='Keep changes')
 assert(b[Nav.move(b,i,3)].label=='Revert');assert(Nav.move(b,i,4)==i)
end)
print(count..' navigation tests passed')
