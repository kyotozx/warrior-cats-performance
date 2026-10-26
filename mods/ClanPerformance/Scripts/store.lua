local dir=debug.getinfo(1,'S').source:gsub('^@',''):match('^(.*[/\\])')
local json=dofile(dir..'json.lua');local M={}
function M.new(path)
 local function raw(p)local f=io.open(p,'rb');if not f then return end;local s=f:read(65537);f:close();assert(#s<=65536,'Preferences file is too large');return s end
 return{
  load=function()local s=raw(path)or raw(path..'.previous');return s and json.decode(s)end,
  save=function(value)
   local bytes=json.encode(value);assert(#bytes<=65536,'Preferences file is too large')
   local tmp=path..'.tmp';local f=assert(io.open(tmp,'wb'),'Cannot create preferences');assert(f:write(bytes));assert(f:close())
   assert(raw(tmp)==bytes,'Preferences readback failed')
   local old=raw(path)
   if old then
    local backup=io.open(path..'.previous','rb');if backup then backup:close();assert(os.remove(path..'.previous'))end
    assert(os.rename(path,path..'.previous'),'Cannot back up preferences')
   end
   local ok,why=os.rename(tmp,path)
   if not ok then if old then os.rename(path..'.previous',path)end;error(why or'Cannot replace preferences')end
   return true
  end,
 }
end
return M
