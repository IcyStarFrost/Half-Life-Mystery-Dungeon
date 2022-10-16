AddCSLuaFile()

local random = math.random
local Round = math.Round
ENT.Base = "hlmd_weapon_base"
ENT.WeaponType = HLMD_WEAPONTYPE_RANGED
ENT.DamageType = DMG_BULLET
ENT.Clip = 25
ENT.MaxClip = 25
ENT.WeaponPower = 15
ENT.Accuracy = 85
ENT.Range = 500
ENT.CritChance = 20
ENT.WeaponName = "Pistol"
ENT.Animations = {
    idle = ACT_HL2MP_IDLE_PISTOL,
    run = ACT_HL2MP_RUN_PISTOL,
    jump = ACT_HL2MP_JUMP_PISTOL
}

local bullettbl = {}

function ENT:Initialize()

    self:SetModel( "models/weapons/w_pistol.mdl" )

end

function ENT:FireWeapon( finishcallback )
    if self.Clip == 0 then return end
    

    local endtime = CurTime() + 2
    local donedamage = false

    self:HandleClipTakeaway()

    HLMD_InitializeCoroutineThread( function()
    
        while true do
            if CurTime() > endtime - 1 and !donedamage then donedamage = true self:AttemptDamage( self:WorldSpaceCenter() ) end
            if CurTime() > endtime or !IsValid( self:GetOwner():GetEnemy() ) then break end
            
            local waitdur = random( 1, 6 ) == 1 and 0.6 or 0.3

            self:HandleMuzzleFlash( 1 )
            self:HandleShellEjects( 1, Angle( 0, -90, 0 ) )

            bullettbl.Attacker = self:GetOwner()
            bullettbl.Damage = 0
            bullettbl.TracerName = "Tracer"
            bullettbl.Dir = ( self:GetOwner():GetEnemy():WorldSpaceCenter() - self:GetPos() ):GetNormalized()
            bullettbl.Spread = Vector( 0.05, 0.05, 0)
            bullettbl.Src = self:GetPos()
            bullettbl.IgnoreEntity = self:GetOwner()

            self:FireBullets( bullettbl )
            self:GetOwner():RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL )
            self:GetOwner():AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL, true )

            self:EmitSound( "^weapons/pistol/pistol_fire3.wav", 90)

            coroutine.wait( waitdur )
        end

        coroutine.wait( 0.3 )

        self:DoReload()

        finishcallback()
    
    end )

end

function ENT:DoReload()
    self:GetOwner():AddGesture( ACT_HL2MP_GESTURE_RELOAD_PISTOL, true )
    self:EmitSound( "weapons/pistol/pistol_reload1.wav", 80 )


end