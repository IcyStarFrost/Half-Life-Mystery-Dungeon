AddCSLuaFile()

ENT.Base = "hlmd_ai_base"

local trace = util.TraceLine

function ENT:Initialize()

    self:SetModel( "models/player/group02/male_04.mdl" )

    self:SetDisplayColor( Vector( 1, 1, 1 ) )
    self:SetShouldServerRagdoll( true )

    if SERVER then
        self.loco:SetStepHeight( 30 )
        self.loco:SetAcceleration( 800 )
        self.loco:SetDeceleration( 800 )
        self:SetMaxHealth( 30 )
        self:SetHealth( 30 )
    elseif CLIENT then
        self.GetPlayerColor = function() return self:GetDisplayColor() end
     end

end




function ENT:BodyUpdate()
    self:BodyMoveXY()
end

