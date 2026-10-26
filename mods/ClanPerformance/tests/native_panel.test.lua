local base='mods/ClanPerformance/Scripts/'
local realDofile=dofile
local hooks,queue,buttons={}, {},{}
local serial=0
local function object()
 serial=serial+1
 local o={id=serial,visible=0,live=true}
 function o:GetAddress()return self.id end
 function o:RemoveFromParent()self.live=false end
 function o:GetVisibility()return self.visible end
 function o:SetVisibility(v)self.visible=v end
 function o:IsInViewport()return true end
 function o:AddChild()return object()end
 return setmetatable(o,{__index=function()return function()end end})
end
local pc=object();local owner=object();function owner:GetOwningPlayer()return pc end
local lib={Create=function()local o=object();o.WidgetTree={RootWidget=object()};return o end,SetFocusToGameViewport=function()end}
local layout={GetViewportSize=function()return{X=1920,Y=1080}end,GetViewportScale=function()return 1 end}
function StaticFindObject(path)if path:find('WidgetBlueprintLibrary')then return lib elseif path:find('WidgetLayoutLibrary')then return layout else return{}end end
function LoadAsset()return{}end
function StaticConstructObject()return object()end
function FText(s)return s end
function FName(s)return s end
function ExecuteInGameThreadAfterFrames(_,fn)queue[#queue+1]=fn end
function RegisterHook(path,fn)hooks[path]=fn;return 1,2 end
function UnregisterHook()end
dofile=function(path)
 if path:match('native_skin.lua$')then return{createButton=function(_,_,_,_,label)
  local b=object();b.label=label;buttons[#buttons+1]=b
  return b,{setEnabled=function(_,v)b.enabled=v end,setSelected=function(_,v)b.selected=v end,tick=function()end}
 end}end
 return realDofile(path)
end
local Panel=dofile(base..'native_panel.lua');dofile=realDofile
local O=dofile(base..'options.lua');local Menu=dofile(base..'menu.lua')
local state={ready=true,label='Original',current=O.copy(O.presets[1].values)}
local ctx={valid=function(o)return o and o.live==true end}
local savedName
local menu=Menu.new(ctx,{status=function()return state end,savePreset=function(name)savedName=name;state.presets={};return true end},{})
ctx.navigate=menu.navigate
local panel=Panel.new(ctx);assert(panel.open(owner,menu.render))
local function flush()local q=queue;queue={};for _,fn in ipairs(q)do fn()end end
local function param(v)return{get=function()return v end,set=function(_,n)v=n end}end
local function command(c,phase)local value=param(c);hooks['/Script/SwtEngine.SwtScreen:OnListenCommand'](param(owner),value,param(phase or 0));assert(value:get()==0)end
local function key(k)hooks['/Script/SwtEngine.SwtScreen:OnKeyPressed'](param(owner),param({KeyName={ToString=function()return k end}}))end
local function selected()for _,b in ipairs(buttons)do if b.live and b.selected then return b.label end end end
assert(selected()=='>  Presets')
command(10);key('Two');flush()
assert(selected()=='-','Native and raw tab events must cycle only once and focus settings')
command(3);flush();assert(selected()=='+')
command(2,2);flush();assert(selected()=='+','Held navigation must keep the same column')
key('Left');command(4);flush();assert(selected()=='-','A raw key and command must not produce two moves')
command(4);flush();assert(selected():find('Image quality',1,true))
command(26);flush();assert(selected()=='-','Selecting a tab must enter settings')
command(9);flush();assert(selected()=='Balanced')
command(9);flush();assert(selected()=='Save current settings')
command(26);flush();assert(selected()=='Q')
key('T');flush();key('E');flush();key('S');flush();key('T');flush();key('Two');flush()
command(26);key('Enter');flush();flush()
assert(savedName=='test2','Naming must consume digits and suppress the duplicate native confirm')
assert(selected()=='Save current settings')
command(26);flush();key('Escape');flush();assert(panel.active()and selected()=='Save current settings')
command(25,1);flush();assert(panel.active(),'Key release must not close panel')
command(25);flush();assert(not panel.active()and owner.visible==0)
print('PASS native tab commands, duplicate event suppression, held navigation, tab entry and close restoration')
