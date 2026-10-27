-- Standalone native menu, usable before a campaign exists (creator / mod hub).
local dir=debug.getinfo(1,'S').source:gsub('^@',''):match('^(.*[/\\])')
local skin=dofile(dir..'native_skin.lua')
local navigation=dofile(dir..'navigation.lua')
local textEntry=dofile(dir..'text_entry.lua')
local M={}
function M.new(ctx)
 local iconTexture=dofile(dir..'menu_icons.lua').new(ctx.valid)
 local api={};local h;local lib=StaticFindObject('/Script/UMG.Default__WidgetBlueprintLibrary')
 local layout=StaticFindObject('/Script/UMG.Default__WidgetLayoutLibrary')
 local function later(fn)ExecuteInGameThreadAfterFrames(1,fn)end
 function api.active()return h~=nil end
 local function dismissDialog()
  if not h then return end
  h.prompt=nil;h.confirm=nil;h.index=h.returnIndex or 1;h.returnIndex=nil;api.refresh()
 end
 function api.close()
  if not h then return end
  local old=h;h=nil;if old then if ctx.valid(old.widget)then old.widget:RemoveFromParent()end;if ctx.valid(old.owner)then old.owner:SetVisibility(old.visibility)end;if old.closed then old.closed()end end
  lib:SetFocusToGameViewport()
 end
 function api.open(owner,render,closed)
  if h then return false,'Close the current mod panel first.'end
  assert(ctx.valid(owner),'Native screen unavailable.');local pc=owner:GetOwningPlayer();assert(ctx.valid(pc),'Menu controller unavailable.')
  h={owner=owner,visibility=owner:GetVisibility(),pc=pc,render=render,closed=closed,index=1,buttons={},widgets={},seen={}}
  local ok,why=pcall(function()
   local class=LoadAsset('/Game/Art/UXD/Blueprints/Controls/gui_common/WBP_GuiClanScreenBackground.WBP_GuiClanScreenBackground_C')
   h.widget=lib:Create(owner,class,pc);assert(ctx.valid(h.widget),'Could not create native menu.');h.root=h.widget.WidgetTree.RootWidget
   local backdrop=StaticConstructObject(StaticFindObject('/Script/UMG.Image'),h.widget.WidgetTree)
   backdrop:SetColorAndOpacity({R=.012,G=.026,B=.035,A=1});backdrop:SetVisibility(3)
   local bs=h.root:AddChild(backdrop);bs:SetAnchors({Minimum={X=0,Y=0},Maximum={X=1,Y=1}});bs:SetOffsets({Left=0,Top=0,Right=0,Bottom=0});bs:SetZOrder(-100)
   local v=layout:GetViewportSize(owner);h.scale=layout:GetViewportScale(owner)/math.min(v.X/1920,v.Y/1080)
   h.context=setmetatable({snapshot=function()return{gameState=owner,pc=pc}end,nativeButtonClass=LoadAsset('/Game/Art/UXD/Blueprints/Buttons/WBP_GuiButtonCommon1.WBP_GuiButtonCommon1_C'),nativeFocusable=false},{__index=ctx})
   h.widget:AddToViewport(1000030);owner:SetVisibility(2);api.refresh();lib:SetFocusToGameViewport()
  end)
  if not ok then api.close();return false,tostring(why)end;return true
 end
 function api.refresh()
  if not h then return end;local current=h
  for _,w in ipairs(h.widgets)do if ctx.valid(w)then w:RemoveFromParent()end end;h.widgets={};h.buttons={}
  local p={}
  function p.text(value,x,y,width,size,heading)
   local t=StaticConstructObject(StaticFindObject('/Script/UMG.TextBlock'),h.widget.WidgetTree)
   t:SetText(FText(tostring(value)));t:SetAutoWrapText(true);t:SetFont({FontObject=LoadAsset(heading and'/Game/Art/UXD/Fonts/Amarante/Amarante.Amarante'or'/Game/Art/UXD/Fonts/Catamaran/Catamaran.Catamaran'),Size=size/h.scale,TypefaceFontName=FName(heading and'Regular'or'Catamaran-Medium')})
   t:SetColorAndOpacity({SpecifiedColor={R=.91,G=.94,B=.86,A=1},ColorUseRule=0});t:SetVisibility(3)
   local slot=h.root:AddChild(t);slot:SetPosition({X=x/h.scale,Y=y/h.scale});slot:SetSize({X=width/h.scale,Y=size*2.2/h.scale});slot:SetZOrder(20);h.widgets[#h.widgets+1]=t;return t
  end
  function p.icon(name,x,y,size)
   local texture=iconTexture(name,h.widget);if not texture then return end
   local icon=StaticConstructObject(StaticFindObject('/Script/UMG.Image'),h.widget.WidgetTree)
   icon:SetBrushFromTexture(texture,false);icon:SetVisibility(3)
   local slot=h.root:AddChild(icon);slot:SetPosition({X=x/h.scale,Y=y/h.scale});slot:SetSize({X=size/h.scale,Y=size/h.scale});slot:SetZOrder(20)
   h.widgets[#h.widgets+1]=icon
  end
  function p.button(label,x,y,width,fn,enabled,zone)
   local b,s=skin.createButton(h.context,h.root,h.owner,nil,label,x,y,width,66,h.scale,false);s:setEnabled(enabled~=false)
   h.widgets[#h.widgets+1]=b;h.buttons[#h.buttons+1]={object=b,skin=s,fn=fn,enabled=enabled~=false,x=x,y=y,zone=zone or'content',active=zone=='tabs'and label:sub(1,1)=='>'}
  end
  p.focusContent=function()if h then h.index=navigation.firstContent(h.buttons)or h.index;api.tick()end end
  p.refresh=api.refresh;p.close=api.close
  p.notify=function(message)if h then h.message=tostring(message):gsub('^.-:%d+: ','');api.refresh()end end
  p.prompt=function(title,accept)
   local old=h;old.returnIndex=old.index;old.index=1;old.promptTitle=title;old.message=nil
   old.prompt=textEntry.new({maxLength=32,accept=function(value)
    local ok,why=accept(value);if ok==false then return false,why end
    later(function()if h==old then dismissDialog()end end);return true
   end,cancel=function()later(function()if h==old then dismissDialog()end end)end})
   api.refresh()
  end
  p.confirm=function(title,message,fn)
   h.returnIndex=h.index;h.index=1;h.confirm={title=title,message=message,accept=fn};h.message=nil;api.refresh()
  end
  if h.prompt then
   p.text(h.promptTitle,335,120,1250,40,true)
   h.promptValue=p.text('',335,220,1250,30,true)
   h.promptStatus=p.text('',335,290,1250,20)
   for i,key in ipairs(h.prompt.keys)do
    local col,row=(i-1)%10,math.floor((i-1)/10)
    p.button(key,335+col*125,385+row*90,118,function()if h and h.prompt then h.prompt.activate(i);api.tick()end end)
   end
   p.text('Type a name and press Enter, or use the on-screen keyboard with your controller.',335,890,1300,20)
   p.text('D-pad / arrows: choose a key   A: select   B / Esc: cancel   Backspace: delete',335,945,1300,18)
   api.tick();return
  elseif h.confirm then
   p.text(h.confirm.title,400,260,1150,40,true)
   p.text(h.confirm.message,400,370,1150,24)
   p.button('Cancel',400,570,500,dismissDialog)
   p.button('Delete preset',1000,570,500,function()local fn=h.confirm.accept;dismissDialog();fn()end)
   api.tick();return
  end
  h.render(p);if h~=current then return end
  p.text(h.message or'Right: enter settings   Left: return to tabs   Up / Down: choose   Enter / A: select',110,990,1700,18)
  p.text('D-pad / left stick: navigate   1 / 2 or LB / RB (L1 / R1): tabs   Backspace / B: back',110,1025,1700,18)
  h.index=math.max(1,math.min(h.index,#h.buttons))
  if h.buttons[h.index]and not h.buttons[h.index].enabled then h.index=navigation.firstContent(h.buttons)or h.index end
  api.tick()
 end
 local function action(fn)
  local old=h;if not old or old.busy then return end;old.busy=true
  later(function()if h~=old then return end;old.busy=false;local ok,r=pcall(fn);if not ok and h==old then old.message=tostring(r):gsub('^.-:%d+: ','');api.refresh()end end)
 end
 local function route(command)
  if not h then return end;local old=h
  if old.seen[command]then return end;old.seen[command]=true;later(function()old.seen[command]=nil end)
  if h.prompt then
   local prompt=h.prompt
   later(function()
    if h~=old or old.prompt~=prompt or old.rawHandled or prompt.closed then return end
    local direction=({[1]='up',[2]='down',[3]='right',[4]='left'})[command]
    if direction then prompt.navigate(direction)elseif command==26 then prompt.activate()elseif command==25 then prompt.cancel()end
    api.tick()
   end);return
  end
  if command==25 then action(h.confirm and dismissDialog or api.close)
  elseif command==26 then local b=h.buttons[h.index];if b and b.enabled then action(b.fn)end
  elseif command==9 or command==10 then
   if h.confirm then return end
   if ctx.navigate then action(function()
    if ctx.navigate(command==9 and -1 or 1)==false then return end
    api.refresh();if h then h.index=navigation.firstContent(h.buttons)or h.index;api.tick()end
   end)end
  elseif command>=1 and command<=4 then
   h.index=navigation.move(h.buttons,h.index,command)
   api.tick()
  end
 end
 local path='/Script/SwtEngine.SwtScreen:OnListenCommand'
 local pre,post=RegisterHook(path,function(o,c,e)
  if h and ctx.valid(o:get())and o:get():GetAddress()==h.owner:GetAddress()then
   local command=c:get();c:set(0);command=({[15]=1,[16]=2,[17]=3,[18]=4})[command]or command
   if e:get()==0 or(e:get()==2 and command>=1 and command<=4)then route(command)end
  end
 end)
 local keyPath='/Script/SwtEngine.SwtScreen:OnKeyPressed'
 local kp,kq=RegisterHook(keyPath,function(o,key)
  if h and ctx.valid(o:get())and o:get():GetAddress()==h.owner:GetAddress()then
   local name=key:get().KeyName:ToString()
   if h.prompt then
    local old=h;local shift=h.pc:IsInputKeyDown({KeyName=FName('LeftShift')})or h.pc:IsInputKeyDown({KeyName=FName('RightShift')})
    if h.prompt.key(name,shift)then old.rawHandled=true;later(function()old.rawHandled=false end);api.tick()end
    return
   end
   -- Movement and confirm use the game's commands exclusively. Handling both
   -- raw keys and commands could move focus twice for one press.
   local tab=({One=9,Two=10,Gamepad_LeftShoulder=9,Gamepad_RightShoulder=10})[name]
   if tab then route(tab)end
  end
 end)
 local clickPath='/Script/SwtEngine.GuiControl:OnControlClick'
 local cp,cq=RegisterHook(clickPath,function(o)if h then for _,b in ipairs(h.buttons)do if ctx.valid(o:get())and o:get():GetAddress()==b.object:GetAddress()and b.enabled then action(b.fn);return end end end end)
 function api.tick()
  if not h then return end
  if not ctx.valid(h.owner)or not h.owner:IsInViewport()then api.close();return end
  if h.prompt then
   h.index=h.prompt.index
   if ctx.valid(h.promptValue)then h.promptValue:SetText(FText(h.prompt.text..'|'))end
   if ctx.valid(h.promptStatus)then h.promptStatus:SetText(FText(h.prompt.error or'Save the graphics settings currently in use. Choose Done to save.'))end
  end
  for i,b in ipairs(h.buttons)do b.skin:setSelected(i==h.index);b.skin:tick()end
 end
 function api.shutdown()api.close();UnregisterHook(path,pre,post);UnregisterHook(keyPath,kp,kq);UnregisterHook(clickPath,cp,cq)end
 return api
end
return M
