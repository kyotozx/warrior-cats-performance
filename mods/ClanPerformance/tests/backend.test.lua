local B=dofile('mods/ClanPerformance/Scripts/backend.lua');local O=dofile('mods/ClanPerformance/Scripts/options.lua')
local values=O.copy(O.presets[1].values);local native={};local engine={GameUserSettings=native,bSmoothFrameRate=false,bUseFixedFrameRate=false}
FindFirstOf=function()return engine end
for _,g in ipairs(O.groups)do
 native['Get'..g[3]..'Quality']=function()return values[g[1]]end
 native['Set'..g[3]..'Quality']=function(_,v)values[g[1]]=v end
end
native.GetResolutionScaleInformationEx=function(_,n,v,lo,hi)n.CurrentScaleNormalized=.5;v.CurrentScaleValue=values.scale;lo.MinScaleValue=25;hi.MaxScaleValue=100 end
native.GetFrameRateLimit=function()return values.cap end
native.SetFrameRateLimit=function(_,v)values.cap=v end
native.SetResolutionScaleValueEx=function(_,v)values.scale=v end
local applied,saved=0,0
native.ApplyNonResolutionSettings=function()applied=applied+1 end;native.SaveSettings=function()saved=saved+1 end
local b=B.new(function(v)return v~=nil end)
assert(O.equal(b.read(),values));b.apply(O.presets[2].values);assert(O.equal(b.read(),O.presets[2].values)and applied==1 and saved==0)
b.save();assert(saved==1)
local gameplayClass={}
StaticFindObject=function(path)assert(path=='/Script/Wrc.WrcGameplayGameState');return gameplayClass end
local activeController={};local activeState={MainCharacter={Controller=activeController},IsA=function(_,class)return class==gameplayClass end}
local activeWorld={GameState=activeState};engine.GameViewport={World=activeWorld}
local w,g,p=b.monitorContext();assert(w==activeWorld and g==activeState and p==activeController)
local nextState={IsA=function()return true end};local nextWorld={GameState=nextState};engine.GameViewport.World=nextWorld
w,g,p=b.monitorContext();assert(w==nextWorld and g==nextState and p==nil,'Read the active viewport after switching saves')
engine.GameViewport.World={GameState={IsA=function()return false end}}
assert(b.monitorContext()==nil,'Main menu and non-gameplay worlds are not campaign samples')
for _,preset in ipairs(O.presets)do b.apply(preset.values);assert(O.equal(b.read(),preset.values),preset.name..' failed adapter readback')end
engine.bUseFixedFrameRate=true;local old=O.copy(values);assert(not pcall(b.apply,O.presets[1].values));assert(O.equal(b.read(),old))
print('PASS reflected native adapter, output tables, all quality groups and fixed timestep guard')
