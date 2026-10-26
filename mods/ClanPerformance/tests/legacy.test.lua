local base='mods/ClanPerformance/Scripts/'
local L=dofile(base..'legacy.lua');local J=dofile(base..'json.lua');local C=dofile(base..'controller.lua');local O=dofile(base..'options.lua')
local path=os.tmpname()
local function write(s)local f=assert(io.open(path,'wb'));f:write(s);f:close()end
write('{broken');assert(L.read(path,J)==nil)
write(J.encode({version=1,counter=true,custom_limit=true,original={limit=60,smooth=true}}))
local legacy=assert(L.read(path,J));os.remove(path)
local function fixture(existing,fail)
 local live=O.copy(O.presets[1].values);live.cap=144;live.scale=100;live.smooth=true
 local saved=existing;local writes=0
 local api=C.new({read=function()return O.copy(live)end,apply=function(v)live=O.copy(v)end,save=function()end},
  {load=function()return saved end,save=function(v)writes=writes+1;if fail then error('Disk full')end;saved=O.copy(v)end},os.time,legacy)
 return api,function()return live,saved,writes end
end
local a,read=fixture();assert(a.start());local live,saved,writes=read()
assert(live.cap==144 and not live.smooth and saved.counter and saved.original.cap==60 and saved.original.smooth and live.scale==100)
assert(writes==1);assert(a.start());assert(select(3,read())==1)
assert(a.restore());assert(a.confirm());assert(read().cap==60 and read().smooth)
local existing={schema=1,label='Original',counter=false,presets={}}
a,read=fixture(existing);assert(a.start());live,saved,writes=read();assert(live.smooth and not a.status().counter and writes==0)
a,read=fixture(nil,true);assert(not a.start());assert(read().smooth,'Failed import must not mutate graphics')
print('PASS legacy import preserves cap and baseline, respects existing preferences, is idempotent and fails before native mutation')
