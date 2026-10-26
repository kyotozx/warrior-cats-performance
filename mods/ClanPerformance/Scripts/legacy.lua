-- Import only the old FPS preferences. Never write to Clan Tools or a game save.
local M={}
function M.read(path,json)
 local f=io.open(path,'rb');if not f then return nil end
 local raw=f:read(65537);f:close();if #raw>65536 then return nil end
 local ok,p=pcall(json.decode,raw)
 if not ok or type(p)~='table'or p.version~=1 or type(p.counter)~='boolean'or type(p.custom_limit)~='boolean'then return nil end
 local original=p.original
 if original~=nil and(type(original)~='table'or type(original.limit)~='number'or original.limit~=original.limit or original.limit<0 or original.limit>1000 or type(original.smooth)~='boolean')then return nil end
 return{counter=p.counter,custom_limit=p.custom_limit,original=original}
end
return M
