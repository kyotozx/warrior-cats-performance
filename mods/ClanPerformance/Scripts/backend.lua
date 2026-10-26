local dir=debug.getinfo(1,'S').source:gsub('^@',''):match('^(.*[/\\])')
local O=dofile(dir..'options.lua');local M={}
function M.new(valid,ctx)
 local cachedEngine
 local comfort=ctx and dofile(dir..'comfort.lua').new(ctx)
 local function native()
  if not valid(cachedEngine)then cachedEngine=FindFirstOf('GameEngine')end
  local e=cachedEngine;assert(valid(e),'Game engine unavailable')
  local s=e.GameUserSettings;assert(valid(s),'Game video settings unavailable');return e,s
 end
 local api={}
 function api.read()
  local e,s=native();local n,v,lo,hi={},{},{},{}
  s:GetResolutionScaleInformationEx(n,v,lo,hi)
  local out={scale=v.CurrentScaleValue,cap=s:GetFrameRateLimit(),smooth=e.bSmoothFrameRate,comfort=comfort and comfort.get()or nil}
  for _,g in ipairs(O.groups)do out[g[1]]=s['Get'..g[3]..'Quality'](s)end
  assert(O.valid(out),'Unsupported graphics settings');return out
 end
 function api.apply(v)
  assert(O.valid(v),'Invalid graphics values');local e,s=native()
  local old=api.read()
  assert(not e.bUseFixedFrameRate or(v.cap==old.cap and v.smooth==old.smooth),'A fixed engine timestep is active')
  if comfort then comfort.configure(v.comfort)end
  for _,g in ipairs(O.groups)do s['Set'..g[3]..'Quality'](s,v[g[1]])end
  s:SetResolutionScaleValueEx(v.scale);s:SetFrameRateLimit(v.cap);e.bSmoothFrameRate=v.smooth
  s:ApplyNonResolutionSettings()
 end
 function api.save()local _,s=native();s:SaveSettings()end
 function api.tickComfort()if comfort then return comfort.tick()end;return true end
 function api.comfortStatus()return comfort and comfort.status()or{}end
 function api.sample(world)
  assert(valid(world),'World unavailable')
  local k=StaticFindObject('/Script/Engine.Default__KismetSystemLibrary')
  local g=StaticFindObject('/Script/Engine.Default__GameplayStatics')
  return k:GetFrameCount(),g:GetRealTimeSeconds(world),g:IsGamePaused(world)
 end
 return api
end
return M
