AddCSLuaFile()

ENT.Base = "hlmd_ai_base"

local trace = util.TraceLine

ENT.BaseAttack =  10
ENT.BaseDefense = 10
ENT.BaseSpeed = 10
ENT.BaseEvade = 10
ENT.BaseHealth = 40
ENT.HLMDType = "Human"
ENT.Weapons = { "hlmd_weapon_smg1", "hlmd_weapon_pistol" }

function ENT:Initialize()

    self:SetUpHLMDStats( 5 )

    self:SetModel( "models/player/group02/male_04.mdl" )

    self:SetNickname( "Rebel" )
    self:SetShouldServerRagdoll( true )

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

