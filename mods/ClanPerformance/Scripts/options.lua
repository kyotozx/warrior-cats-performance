local M={}
M.groups={
 {'view','View distance','ViewDistance','Distant objects fade sooner at lower settings.'},
 {'aa','Anti-aliasing','AntiAliasing','Lower quality is cheaper but can shimmer in motion.'},
 {'shadow','Shadows','Shadow','Low removes most dynamic shadows.'},
 {'gi','Global illumination','GlobalIllumination','Low disables Lumen. Interiors may look darker.'},
 {'reflection','Reflections','Reflection','Lower quality reduces surface reflections.'},
 {'post','Post processing','PostProcessing','Reduces depth of field, bloom and other image effects.'},
 {'texture','Textures','Texture','Lower quality reduces texture detail and memory demand.'},
 {'effects','Effects','VisualEffect','Uses the engine effects budget, preserving game actors.'},
 {'foliage','Foliage','Foliage','Only assets that support density scaling are affected.'},
 {'shading','Shading','Shading','Uses simpler engine shading where supported.'},
}
M.quality={'Low','Medium','High','Epic','Cinematic'}
function M.copy(t)local o={};for k,v in pairs(t)do o[k]=type(v)=='table'and M.copy(v)or v end;return o end
local function number(n,lo,hi)return type(n)=='number'and n==n and n>=lo and n<=hi end
function M.valid(v)
 if type(v)~='table'or not number(v.scale,25,100)or not number(v.cap,0,1000)or type(v.smooth)~='boolean'then return false end
 for _,g in ipairs(M.groups)do if not number(v[g[1]],0,4)or v[g[1]]%1~=0 then return false end end
 return true
end
function M.equal(a,b)
 if not M.valid(a)or not M.valid(b)or math.abs(a.scale-b.scale)>.1 or math.abs(a.cap-b.cap)>.01 or a.smooth~=b.smooth then return false end
 for _,g in ipairs(M.groups)do if a[g[1]]~=b[g[1]]then return false end end;return true
end
M.presets={
 {id='balanced',name='Balanced',description='Preserves Lumen lighting. Reduced shadows and effects; 83% render scale.',
  values={scale=83,cap=60,smooth=false,view=1,aa=1,shadow=1,gi=1,reflection=0,post=0,texture=1,effects=1,foliage=1,shading=1}},
 {id='low',name='Low',description='Suggested starting point for integrated graphics. 67% scale, 30 FPS cap; Lumen off.',
  values={scale=67,cap=30,smooth=false,view=0,aa=1,shadow=0,gi=0,reflection=0,post=0,texture=1,effects=0,foliage=0,shading=0}},
 {id='ultra',name='Ultra Low',description='Prioritizes performance over detail. 50% scale, minimum quality, 30 FPS cap.',
  values={scale=50,cap=30,smooth=false,view=0,aa=0,shadow=0,gi=0,reflection=0,post=0,texture=0,effects=0,foliage=0,shading=0}},
}
return M
