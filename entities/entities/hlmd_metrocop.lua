AddCSLuaFile()

ENT.Base = "hlmd_ai_base"

local trace = util.TraceLine

ENT.BaseAttack =  5
ENT.BaseDefense = 20
ENT.BaseSpeed = 10
ENT.BaseEvade = 10
ENT.BaseHealth = 45
ENT.HLMDType = "Combine"
ENT.Weapons = { "hlmd_weapon_smg1", "hlmd_weapon_pistol" }

function ENT:Initialize()

    self:SetUpHLMDStats( 5 )

    self:SetModel( "models/player/police.mdl" )

    self:SetNickname( "Metro Cop" )
    self:SetShouldServerRagdoll( true )

    self:AddFlags( FL_NPC )

    if SERVER then
        self.loco:SetStepHeight( 30 )
        self.loco:SetAcceleration( 1200 )
        self.loco:SetDeceleration( 1200 )
        self.loco:SetDesiredSpeed( 200 )
        self:SetHealth( self:GetMaxHealth() )
    elseif CLIENT then
        self.GetPlayerColor = function() return self:GetDisplayColor() end

        self:NetworkVarNotify( "DisplayColor", function( ent, name, old, new )
            self.GetPlayerColor = function() return new end
        end )

     end

end




function ENT:BodyUpdate()
    self:BodyMoveXY()
end

