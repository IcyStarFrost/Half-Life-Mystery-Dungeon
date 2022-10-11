AddCSLuaFile()

ENT.Base = "base_anim"
ENT.PickupRange = 100


local trace = util.TraceLine
local tracetbl = {}
local math_sin = math.sin
local math_abs = math.abs
local HLMD_FindInSphere = HLMD_FindInSphere

function ENT:OnPickUp( by )
end

function ENT:HandlePosition()
    
    tracetbl.start = self:WorldSpaceCenter()
    tracetbl.endpos = self:WorldSpaceCenter() - Vector( 0, 0, 10000 )
    tracetbl.filter = self

    local result = trace( tracetbl )

    self:SetPos( result.HitPos + Vector( 0, 0, 20 ) )
end

-- Gmod example but it works so let's use it
local function draw_Circle( x, y, radius, seg )
	local cir = {}

	table_insert( cir, { x = x, y = y, u = 0.5, v = 0.5 } )
	for i = 0, seg do
		local a = math_rad( ( i / seg ) * -360 )
		table_insert( cir, { x = x + math_sin( a ) * radius, y = y + math_cos( a ) * radius, u = math_sin( a ) / 2 + 0.5, v = math_cos( a ) / 2 + 0.5 } )
	end

	local a = math_rad( 0 )
	table_insert( cir, { x = x + math_sin( a ) * radius, y = y + math_cos( a ) * radius, u = math_sin( a ) / 2 + 0.5, v = math_cos( a ) / 2 + 0.5 } )

	surface.DrawPoly( cir )
end

function ENT:Draw()

    tracetbl.start = self:WorldSpaceCenter()
    tracetbl.endpos = self:WorldSpaceCenter() - Vector( 0, 0, 10000 )
    tracetbl.filter = self

    local result = trace( tracetbl )

    cam.Start3D2D( result.HitPos, Angle(), 1 )
        surface.SetDrawColor( 0, 255, 0, math_abs( math_sin( SysTime() * 2 ) * 50 ) )
        draw.NoTexture()
        draw_Circle( 0, 0, self:GetModelRadius() / 2, 16 )
    cam.End3D2D()

    self:SetAngles( 0, SysTime(), 0 )

    self:DrawModel()

end

function ENT:Think()

    local nearby = HLMD_FindInSphere( self:GetPos(), self.PickupRange, function( ent ) if ent.IsHLMDNPC then return true end end )

    if #nearby > 0 then
        for k, v in ipairs( nearby ) do
            self:OnPickUp( v )
            self:Remove()
            break
        end
    end

    self:NextThink( CurTime() + 0.5 )
    return true
end