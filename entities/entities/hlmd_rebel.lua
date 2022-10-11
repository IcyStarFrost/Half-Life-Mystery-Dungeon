AddCSLuaFile()

ENT.Base = "base_nextbot"

local trace = util.TraceLine

function ENT:Initialize()

    self:SetModel( "models/player/group02/male_04.mdl" )

    self.NextFootstepSnd = 0
    self.FootStepTrace = {}

    if SERVER then
        self.loco:SetStepHeight( 30 )


    end

end


function ENT:Think()

    if SERVER then

        local speed = self.loco:GetVelocity():Length()
        if CurTime() > self.NextFootstepSnd and speed > 0 and self.loco:IsOnGround() then

            self.FootStepTrace.start = self:WorldSpaceCenter()
            self.FootStepTrace.endpos = self:WorldSpaceCenter() - Vector( 0, 0, 400 )
            self.FootStepTrace.filter = self
            local result = trace( self.FootStepTrace )

            if result.Hit then
                self:EmitSound( HLMD_FootstepsTranslations[ result.MatType ], 80 )

                local nextSnd = math.Clamp(0.25 * (400 / speed), 0.25, 0.35)
                self.NextFootstepSnd = CurTime() + nextSnd
            end
        end

        if !self.loco:GetVelocity():IsZero() and self.loco:IsOnGround() and self:GetActivity() != ACT_HL2MP_RUN then
            self:StartActivity( ACT_HL2MP_RUN )
        elseif self.loco:GetVelocity():IsZero() and self.loco:IsOnGround() and self:GetActivity() != ACT_HL2MP_IDLE then
            self:StartActivity( ACT_HL2MP_IDLE )
        elseif !self.loco:IsOnGround() and self:GetActivity() != ACT_HL2MP_JUMP then
            self:StartActivity( ACT_HL2MP_JUMP_FIST )
        end

    end

end

function ENT:BodyUpdate()
    self:BodyMoveXY()
end

