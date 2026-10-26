local base='mods/ClanPerformance/Scripts/'
local C=dofile(base..'comfort.lua');local O=dofile(base..'comfort_options.lua')
local function copy(v)return O.copy(v)end
local serial=0
local function object(fields)
 serial=serial+1;fields.id=serial
 fields.GetAddress=function(self)return self.id end
 fields.GetFullName=function(self)return'Object_'..self.id end
 return fields
end
local camera=object({Performance_fov=75,Performance_sprintBlur=.7,Performance_sprintArm=65,Performance_sprintArmHandheld=45,Performance_sprintFov=12,Performance_yaw=80,Performance_pitch=65})
local arm=object({bEnableCameraLag=true,bEnableCameraRotationLag=true,CameraLagSpeed=8,CameraRotationLagSpeed=10,Performance_horizontalLag=6})
local shake=object({disabled=false,IsDisabled=function(self)return self.disabled end,DisableModifier=function(self)self.disabled=true end,EnableModifier=function(self)self.disabled=false end})
local manager=object({FindCameraModifierByClass=function()return shake end})
local session={camera=camera,arm=arm,manager=manager,key='world-A'}
local world=object({});local engine=object({GameViewport=object({World=world})})
local cvar=3;local commands=0;local registration=0
StaticFindObject=function()return object({GetConsoleVariableIntValue=function()return cvar end,
 ExecuteConsoleCommand=function(_,w,command)assert(w==world);cvar=tonumber(command:match('(%d+)$'));commands=commands+1 end})end
FindFirstOf=function()return engine end
PropertyTypes={FloatProperty='float'}
RegisterCustomProperty=function(spec)assert(spec.Type=='float');registration=registration+1 end
local ctx={root='unused/',valid=function(o)return type(o)=='table'and not o.dead end,verify=function()return true end,snapshot=function()return session end}
local api=C.new(ctx)
assert(api.tick()and registration==0 and commands==0,'Defaults must do no native camera or CVar work')
api.configure(O.reduced);assert(registration==8 and cvar==0);assert(api.tick())
assert(camera.Performance_fov==90 and camera.Performance_sprintArm==0 and camera.Performance_sprintFov==0 and camera.Performance_sprintBlur==0)
assert(camera.Performance_yaw==60 and camera.Performance_pitch==48.75)
assert(not arm.bEnableCameraLag and not arm.bEnableCameraRotationLag and shake.disabled)
for i=1,50 do assert(api.tick())end
assert(camera.Performance_yaw==60,'Sensitivity must never compound')
session=nil;assert(api.tick());assert(camera.Performance_yaw==80 and camera.Performance_fov==75 and arm.bEnableCameraLag and not shake.disabled)
assert(cvar==0,'Global blur is independent of camera transitions')
session={camera=camera,arm=arm,manager=manager,key='world-B'};assert(api.tick());assert(camera.Performance_fov==90)
api.reset();assert(camera.Performance_fov==75 and cvar==3 and arm.bEnableCameraRotationLag)
local reduced=copy();reduced.smoothing=1;api.configure(reduced);assert(api.tick())
assert(arm.CameraLagSpeed==24 and arm.CameraRotationLagSpeed==30 and arm.Performance_horizontalLag==18)
api.reset();assert(arm.CameraLagSpeed==8 and arm.Performance_horizontalLag==6)
local v=copy();v.horizontal=.5;api.configure(v);assert(api.tick());camera.Performance_yaw=120
api.reset();assert(camera.Performance_yaw==120,'Do not overwrite another owner during restore')
camera.Performance_yaw=80;api.configure(v);assert(api.tick());camera.dead=true;api.reset();camera.dead=nil
assert(camera.Performance_yaw==40,'Destroyed objects must not be dereferenced during restore')
camera.Performance_yaw=80
shake.disabled=true;v=copy();v.shake=true;api.configure(v);assert(api.tick());api.reset();assert(shake.disabled,'Already disabled shake modifiers stay disabled')
assert(not O.valid({}));v=copy();v.fov=0/0;assert(not O.valid(v));v=copy();v.horizontal=3;assert(not O.valid(v))
assert(O.equal(nil,O.defaults)and not O.equal(nil,O.reduced))
local rejected=C.new(setmetatable({verify=function()error('Unsupported build')end},{__index=ctx}))
assert(not pcall(rejected.configure,O.reduced));assert(O.equal(rejected.get(),O.defaults))
print('PASS camera preset, independent axes, no compounding, lag modes, sprint effects, blur, transition restoration and build refusal')
