local M={}
M.defaults={blur=false,fov=0,smoothing=0,shake=false,sprint=false,horizontal=1,vertical=1}
M.reduced={blur=true,fov=90,smoothing=2,shake=true,sprint=true,horizontal=.75,vertical=.75}
local function number(n,lo,hi)return type(n)=='number'and n==n and n>=lo and n<=hi end
function M.valid(v)
 if v==nil then return true end -- preferences from earlier versions
 if type(v)~='table'then return false end
 for _,k in ipairs({'blur','shake','sprint'})do if type(v[k])~='boolean'then return false end end
 return (v.fov==0 or number(v.fov,60,110))and number(v.smoothing,0,2)and v.smoothing%1==0
  and number(v.horizontal,.25,2)and number(v.vertical,.25,2)
end
function M.copy(v)local out={};for k,value in pairs(v or M.defaults)do out[k]=value end;return out end
function M.equal(a,b)
 if not M.valid(a)or not M.valid(b)then return false end
 a=a or M.defaults;b=b or M.defaults
 for k,value in pairs(M.defaults)do if a[k]~=b[k]then return false end end;return true
end
function M.camera(v)return v.fov~=0 or v.smoothing~=0 or v.sprint or v.horizontal~=1 or v.vertical~=1 end
return M
