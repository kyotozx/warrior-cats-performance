-- Exercise the production scheduler and meter together, including the first
-- measurement when the overlay has never been enabled.
local base='mods/ClanPerformance/Scripts/'
local realDofile=dofile
local meter=realDofile(base..'meter.lua').new()
local callback
local world={GetAddress=function()return 100 end}
local gs={}
local frames,seconds,paused=0,0,false
local counter=false
local contextCalls=0
local backend={
 tickComfort=function()return true end,
 monitorContext=function()contextCalls=contextCalls+1;return world,gs,nil end,
 sample=function(s)assert(s==gs);return frames,seconds,paused end,
}
dofile=function(path)
 if path:match('runtime_valid.lua$')then return{valid=function(o)return type(o)=='table'end}end
 if path:match('backend.lua$')then return{new=function()return backend end}end
 if path:match('legacy.lua$')then return{read=function()end}end
 if path:match('controller.lua$')then return{new=function()return{
  counterEnabled=function()return counter end,start=function()return true end,tick=function()end,
 }end}end
 if path:match('store.lua$')then return{new=function()return{}end}end
 if path:match('meter.lua$')then return{new=function()return meter end}end
 if path:match('native_panel.lua$')then return{new=function()return{tick=function()end,active=function()return false end}end}end
 if path:match('menu.lua$')then return{new=function()return{}end}end
 return realDofile(path)
end
Key={F8=8,F9=9}
RegisterKeyBind=function()end
RegisterHook=function()end
LoopInGameThreadWithDelay=function(_,fn)callback=fn end
FindFirstOf=function()error('The monitor must not scan for arbitrary gameplay objects')end
FindAllOf=function()return{}end
realDofile(base..'main.lua')
local function sample()
 frames=frames+60;seconds=seconds+.5
 for _=1,5 do callback()end
end
sample();assert(contextCalls==0,'An idle disabled monitor must do no world lookup')
meter.begin();sample()
assert(meter.status().remaining==30 and not meter.status().result,'First world binding must preserve the measurement')
for _=1,60 do sample()end
local result=meter.status()
assert(not result.remaining and result.result.average==120 and result.result.seconds==30)
sample() -- disabled monitor releases its old world binding
world={GetAddress=function()return 200 end}
meter.begin();sample();sample()
assert(meter.status().remaining==29.5,'A fresh measurement in another campaign must also start normally')
world={GetAddress=function()return 300 end};sample()
assert(meter.status().result.error=='Measurement cancelled: world changed')
sample();meter.begin();sample();world=nil;sample()
assert(meter.status().result.error=='Measurement cancelled: world changed','Losing an active world must cancel the test')
world={GetAddress=function()return 400 end};sample();meter.begin();sample()
paused=true;sample();assert(meter.status().remaining==30,'Pause must not consume measurement time')
paused=false;sample();sample();assert(meter.status().remaining==29.5)
dofile=realDofile
print('PASS production monitor: first run, complete measurement, inactive campaigns, transitions, pause and no object scans')
