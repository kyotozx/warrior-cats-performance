local M={}
function M.firstContent(buttons)
 for i,b in ipairs(buttons)do if b.enabled and b.zone=='content'then return i end end
end
function M.move(buttons,index,command)
 local current=buttons[index];if not current then return index end
 if current.zone=='tabs'and command==3 then return M.firstContent(buttons)or index end
 local horizontal=command==3 or command==4
 local sign=(command==1 or command==4)and -1 or 1
 local best,score
 for i,b in ipairs(buttons)do
  if i~=index and b.enabled then
   local dx,dy=b.x-current.x,b.y-current.y
   local forward=(horizontal and dx or dy)*sign
   local across=math.abs(horizontal and dy or dx)
   -- Keep up/down within the sidebar or the settings area. Left/right
   -- crosses between areas, and pairs the minus/plus buttons on one row.
   local sameArea=(current.zone=='tabs')==(b.zone=='tabs')
   local eligible=horizontal and (b.zone=='tabs'or math.abs(dy)<1)or(not horizontal and sameArea)
   if eligible and forward>0 then
    local cost=across*10000+forward
    if not score or cost<score then best,score=i,cost end
   end
  end
 end
 if best and command==4 and current.zone~='tabs'and buttons[best].zone=='tabs'then
  for i,b in ipairs(buttons)do if b.zone=='tabs'and b.active and b.enabled then return i end end
 end
 return best or index
end
return M
