local dir=debug.getinfo(1,'S').source:gsub('^@',''):match('^(.*[/\\])')
local ctx={root=dir..'../',valid=dofile(dir..'runtime_valid.lua').valid}
local backend=dofile(dir..'backend.lua').new(ctx.valid,ctx)
ctx.comfortStatus=backend.comfortStatus
local legacy=dofile(dir..'legacy.lua').read(ctx.root..'../ClanTools/settings-extensions.json',dofile(dir..'json.lua'))
local controller=dofile(dir..'controller.lua').new(backend,dofile(dir..'store.lua').new(ctx.root..'preferences.json'),os.time,legacy)
local meter=dofile(dir..'meter.lua').new()
local panel,menu,owner,button,visual;local requested=false;local ticks=0;local lastError;local started=false
local overlay,overlayText,worldAddress
local comfortError
local function cleanupOverlay()if ctx.valid(overlay)then overlay:RemoveFromParent()end;overlay=nil;overlayText=nil end
RegisterKeyBind(Key.F9,function()requested=true end)
RegisterKeyBind(Key.F8,function()requested=true end)
RegisterHook('/Script/SwtEngine.SwtScreen:OnKeyPressed',function(o,key)
 if ctx.valid(owner)and ctx.valid(o:get())and o:get():GetAddress()==owner:GetAddress()and key:get().KeyName:ToString()=='Gamepad_LeftThumbstick'then requested=true end
end)
RegisterHook('/Script/SwtEngine.GuiControl:OnControlClick',function(o)
 if ctx.valid(button)and ctx.valid(o:get())and o:get():GetAddress()==button:GetAddress()then requested=true end
end)
local function monitor()
 if not controller.counterEnabled()and not meter.status().remaining then cleanupOverlay();return end
 local gs=FindFirstOf('WrcGameplayGameState')
 if not ctx.valid(gs)then cleanupOverlay();if worldAddress then meter.reset();worldAddress=nil end;return end
 local world=gs:GetWorld();if not ctx.valid(world)then cleanupOverlay();return end
 local addr=world:GetAddress();if addr~=worldAddress then cleanupOverlay();meter.reset();worldAddress=addr end
 local frames,seconds,paused=backend.sample(gs)
 meter.sample(frames,seconds,paused)
 if paused then cleanupOverlay();return end
 local m=meter.status()
 if not controller.counterEnabled()and not m.remaining then cleanupOverlay();return end
 if not ctx.valid(overlay)then
  local pc=FindFirstOf('WrcGameplayPlayerController');if not ctx.valid(pc)then return end
  local lib=StaticFindObject('/Script/UMG.Default__WidgetBlueprintLibrary')
  local layout=StaticFindObject('/Script/UMG.Default__WidgetLayoutLibrary')
  local class=LoadAsset('/Game/Art/UXD/Blueprints/Controls/gui_common/WBP_GuiClanScreenBackground.WBP_GuiClanScreenBackground_C')
  overlay=lib:Create(gs,class,pc);local root=overlay.WidgetTree.RootWidget
  root:GetChildAt(0):SetVisibility(2)
  overlayText=StaticConstructObject(StaticFindObject('/Script/UMG.TextBlock'),overlay.WidgetTree)
  local dpi=layout:GetViewportScale(gs);local slot=root:AddChild(overlayText)
  slot:SetAnchors({Minimum={X=1,Y=0},Maximum={X=1,Y=0}});slot:SetPosition({X=-390/dpi,Y=16/dpi});slot:SetSize({X=375/dpi,Y=90/dpi})
  overlayText:SetFont({FontObject=LoadAsset('/Game/Art/UXD/Fonts/Catamaran/Catamaran.Catamaran'),Size=20/dpi,TypefaceFontName=FName('Catamaran-Medium')})
  overlayText:SetColorAndOpacity({SpecifiedColor={R=.91,G=.94,B=.86,A=1},ColorUseRule=0});overlay:SetVisibility(3);overlay:AddToViewport(1000003)
 end
 local label=m.fps and string.format('FPS: %.0f',m.fps)or'FPS: --'
 if m.remaining then label=label..string.format('   Test: %.0f s',m.remaining)end
 if m.result and m.result.average then label=label..string.format('\nLast mean: %.1f FPS',m.result.average)end
 overlayText:SetText(FText(label))
end
LoopInGameThreadWithDelay(100,function()
 local ok,why=pcall(function()
  ticks=ticks+1
  if not started and ticks%10==0 then local good=controller.start();started=good end
  controller.tick()
  local cameraOK,cameraError=backend.tickComfort()
  if not cameraOK and cameraError~=comfortError then print('[ClanPerformance] Camera & Comfort: '..tostring(cameraError)..'\n')end
  comfortError=cameraOK and nil or cameraError
  if not panel then panel=dofile(dir..'native_panel.lua').new(ctx);menu=dofile(dir..'menu.lua').new(ctx,controller,meter);ctx.navigate=menu.navigate end
  panel.tick()
  if ticks%5==0 then
   monitor();if panel.active()then menu.tick(panel)end
   if not panel.active()then
    local found
    for _,class in ipairs({'GuiPopupGameSettings','GuiPopupSettings','GuiScreenPause','GuiScreenMainMenu'})do
     for _,s in ipairs(FindAllOf(class)or{})do if ctx.valid(s)and s:IsInViewport()and s:GetVisibility()~=2 then found=s;break end end
     if found then break end
    end
    if not found or not ctx.valid(owner)or found:GetAddress()~=owner:GetAddress()then
     if ctx.valid(button)then button:RemoveFromParent()end;button=nil;visual=nil;owner=found
    end
   end
   if owner and ctx.valid(owner)and not button then
    local pc=owner:GetOwningPlayer();local layout=StaticFindObject('/Script/UMG.Default__WidgetLayoutLibrary');local size=layout:GetViewportSize(owner)
    local scale=layout:GetViewportScale(owner)/math.min(size.X/1920,size.Y/1080)
    local context=setmetatable({snapshot=function()return{gameState=owner,pc=pc}end,nativeButtonClass=LoadAsset('/Game/Art/UXD/Blueprints/Buttons/WBP_GuiButtonCommon1.WBP_GuiButtonCommon1_C')},{__index=ctx})
    local x=owner:IsA(StaticFindObject('/Script/Wrc.GuiScreenMainMenu'))and 900 or 500
    button,visual=dofile(dir..'native_skin.lua').createButton(context,owner.WidgetTree.RootWidget,owner,nil,'Performance [F9 / L3]',x,25,490,66,scale,false);button.Slot:SetZOrder(999)
   end
  end
  if visual then visual:tick()end
  if requested then
   requested=false
   if panel.active()then panel.close()
   elseif ctx.valid(owner)then menu.open();assert(panel.open(owner,menu.render,function()if controller.status().pending then controller.cancel()end end))
   else print('[ClanPerformance] Open the original pause, settings or main menu, then press F9 / L3.\n')end
  end
 end)
 if not ok and tostring(why)~=lastError then lastError=tostring(why);print('[ClanPerformance] '..lastError..'\n')elseif ok then lastError=nil end
end)
print('[ClanPerformance] Ready. Performance [F9 / L3] in original game menus. No preset is applied until selected.\n')
