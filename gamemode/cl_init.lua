include( "shared.lua" )
include( "cl_netmessages.lua" )

local trace = util.TraceLine

local overridepos
local overrideangs
local overridefov 
local target

local viewtbl = {}
local tracetbl = {}

function GM:CalcView( ply, origin, angles, fov, znear, zfar )
    if !IsValid( target ) then return end
    local skyviewpos = target:GetPos() + Vector( 500, 0, 500 )

    tracetbl.start = target:WorldSpaceCenter()
    tracetbl.endpos = skyviewpos
    tracetbl.filter = target

    local result = trace( tracetbl )

    viewtbl.origin = overridepos or skyviewpos
    viewtbl.angles = overrideangs or ( target:GetPos() - skyviewpos ):Angle()
    viewtbl.fov = overridefov or 60
    viewtbl.znear = result.Hit and result.HitPos:Distance( skyviewpos ) or 100
    viewtbl.zfar = zfar

    return viewtbl
end

net.Receive( "hlmd_setviewtarget", function() target = net.ReadEntity() end )
