AddCSLuaFile()

local random = math.random

ENT.Base = "hlmd_weapon_base"
ENT.WeaponType = HLMD_WEAPONTYPE_RANGED
ENT.DamageType = DMG_BULLET
ENT.Clip = 18
ENT.MaxClip = 18
ENT.WeaponPower = 15
ENT.Accuracy = 70
ENT.Range = 600
ENT.WeaponName = "SMG1"

local bullettbl = {}

function ENT:Initialize()

    self:SetModel( "models/weapons/w_smg1.mdl" )

end

function ENT:FireWeapon( finishcallback )
    if self.Clip == 0 then return end

    local endtime = CurTime() + 2
    local donedamage = false

    self.Clip = self.Clip - 1

    HLMD_DebugText( self:GetOwner(), "'s clip dropped to ", self.Clip)

    HLMD_InitializeCoroutineThread( function()
    
        while true do
            if CurTime() > endtime - 1 and !donedamage then donedamage = true self:AttemptDamage() end
            if CurTime() > endtime or !IsValid( self:GetOwner():GetEnemy() ) then break end
            
            local waitdur = random( 1, 6 ) == 1 and 0.6 or 0.08

            self:HandleMuzzleFlash( 1 )
            self:HandleShellEjects( 1, Angle( 0, 90, 0 ) )

            bullettbl.Attacker = self:GetOwner()
            bullettbl.Damage = 0
            bullettbl.TracerName = "Tracer"
            bullettbl.Dir = ( self:GetOwner():GetEnemy():GetPos() - self:GetPos() ):GetNormalized()
            bullettbl.Spread = Vector( 0.08, 0.08, 0)
            bullettbl.Src = self:GetPos()
            bullettbl.IgnoreEntity = self:GetOwner()

            self:FireBullets( bullettbl )
            self:GetOwner():RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_SMG1 )
            self:GetOwner():AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_SMG1, true )

            self:EmitSound( "^weapons/smg1/npc_smg1_fire1.wav", 90)

            coroutine.wait( waitdur )
        end

        coroutine.wait( 1 )

        self:DoReload()

        finishcallback()
    
    end )

end

function ENT:DoReload()
    self:GetOwner():AddGesture( ACT_HL2MP_GESTURE_RELOAD_SMG1, true )
    self:EmitSound( "weapons/smg1/smg1_reload.wav", 80 )
end