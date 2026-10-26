local M=dofile('mods/ClanPerformance/Scripts/meter.lua');local m=M.new()
m.begin();m.sample(0,0,false);for i=1,60 do m.sample(i*30,i*.5,false)end
local r=m.status().result;assert(r and r.average==60 and r.low==60 and r.high==60 and r.seconds==30)
m.begin();m.sample(0,0,false);m.sample(30,.5,false);m.sample(90,5,true);assert(m.status().remaining==29.5)
m.sample(100,10,false);m.sample(130,10.5,false);assert(m.status().remaining==29)
m.sample(500,20,false);assert(m.status().remaining==29 and m.status().fps==nil)
m.reset();assert(m.status().result.error and not m.status().remaining)
print('PASS 30-second frame delta average, pauses, loading gaps and world transitions')
