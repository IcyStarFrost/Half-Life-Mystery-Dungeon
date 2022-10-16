AddCSLuaFile()

ENT.Base = "hlmd_item_base"
ENT.PickupRange = 100

local math_Clamp = math.Clamp
local random = math.random

function ENT:Initialize()

    self:SetModel( "models/items/item_item_crate.mdl" )
    
    self:HandlePosition()

end

function ENT:OnPickUp( by )

    local weapon = by:GetWeaponEntity()

    if SERVER and IsValid( weapon ) then
        if weapon.Clip == weapon.MaxClip then return false end

        self:EmitSound( "items/ammo_pickup.wav", 80 )

        local oldclip = weapon.Clip

        weapon.Clip = math_Clamp( weapon.Clip + random( 1, 4 ), 0, weapon.MaxClip )

        HLMD_DebugText( self, " Picked up a ammo box and increased their clip! ", oldclip, " to ", weapon.Clip)

        local maf = weapon.Clip - oldclip
        local plural = ( maf > 1 and " clips" or " clip")
        local pluralclip = ( weapon.Clip > 1 and " clips" or " clip")
        HLMD_LogEvent( by:GetNickname() .. " picked up " .. maf .. plural .. ". They now have " .. weapon.Clip .. pluralclip .. "." )

        return true
    end

end