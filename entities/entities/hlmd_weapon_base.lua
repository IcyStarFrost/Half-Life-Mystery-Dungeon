AddCSLuaFile()

local random = math.random
local Round = math.Round
local PlayEffect = util.Effect
--HLMD_WEAPONTYPE_RANGED
--HLMD_WEAPONTYPE_MELEE

ENT.Base = "base_anim"
ENT.WeaponType = HLMD_WEAPONTYPE_RANGED
ENT.DamageType = DMG_BULLET
ENT.Clip = 0
ENT.MaxClip = 0
ENT.WeaponPower = 0
ENT.Accuracy = 0
ENT.WeaponName = ""
ENT.Range = 0
ENT.Animations = {
    idle = ACT_HL2MP_IDLE_SMG1,
    run = ACT_HL2MP_RUN_SMG1,
    jump = ACT_HL2MP_JUMP_SMG1
}


function ENT:FireWeapon( finishcallback )
end


-- 1 = Regular muzzle
-- 5 = AR2 muzzle
-- 7 bigger regular
function ENT:HandleMuzzleFlash( type )
    local lookup = self:LookupAttachment( "muzzle" )
    local attach = self:GetAttachment( lookup )

    local effect = EffectData()
    effect:SetOrigin( attach.Pos )
    effect:SetAngles( attach.Ang )
    effect:SetEntity( self )
    effect:SetFlags( type )

    PlayEffect( "MuzzleFlash", effect )
end

local typetranslation = {
    [ 1 ] = "ShellEject",
    [ 2 ] = "RifleShellEject",
    [ 3 ] = "ShotgunShellEject"
}

function ENT:HandleShellEjects( type, offang, offpos )
    offpos = offpos or Vector( 0, 0, 0 )
    local effect = EffectData()

    effect:SetOrigin( self:GetPos() + offpos )
    effect:SetAngles( self:GetAngles() + offang )
    effect:SetEntity( self )

    PlayEffect( typetranslation[ type ], effect )
end

function ENT:HandleClipTakeaway()
    if self:GetOwner():GetHLMDTeam() != HLMD_PLAYERTEAM then return end
    self.Clip = self.Clip - 1

    if self.Clip == ( Round( self.MaxClip * 0.3, 0 ) ) then
        HLMD_LogEvent( self:GetOwner():GetNickname() .. " is running low on clips! " .. self.Clip .. " left", Color( 255, 0, 0 ) )
    elseif self.Clip == 0 then
        HLMD_LogEvent( self:GetOwner():GetNickname() .. " ran out of clips! ", Color( 255, 0, 0 ) )
    end

    HLMD_DebugText( self:GetOwner(), "'s clip dropped to ", self.Clip)
end

function ENT:AttemptDamage( pos )
    local owner = self:GetOwner()
    local enemy = owner:GetEnemy()

    if !IsValid( enemy ) then HLMD_DebugText( owner, " Tried to deal damage to a non existent entity!" ) return "failed" end

    if random( 1, 100 ) < self.Accuracy then
        local ownerattackpower = owner:GetAttack()
        local enemydefense = enemy:GetDefense()
        local enemyevade = enemy:GetEvade()

        HLMD_DebugText( enemy, " Evade = ", enemyevade )

        if random( 1, 100 ) < enemyevade then HLMD_DebugText( enemy, " Dodged ", owner, "'s Attack!" ) return "dodged" end

        HLMD_DebugText( owner, " Attack Power = ", ownerattackpower )
        HLMD_DebugText( owner, " Weapon Power = ", self.WeaponPower )
        HLMD_DebugText( enemy, " Defense = ", enemydefense )

        local dmg = self.WeaponPower + ( ownerattackpower / 2 )

        HLMD_DebugText( owner, " Pre Defense Damage = ", dmg )

        dmg = dmg - ( enemydefense / 2 )

        HLMD_DebugText( owner, " Post Defense Damage = ", dmg )

        local force = ( enemy:WorldSpaceCenter() - pos ):GetNormalized()

        local info = DamageInfo()

        info:SetDamage( dmg )
        info:SetDamageType( self.DamageType  )
        info:SetAttacker( owner )
        info:SetInflictor( self )
        info:SetDamageForce( force * ( dmg * 500 ) )
        info:SetDamagePosition( pos )

        if random( 0, 100 ) < self.CritChance then
            dmg = dmg * 2
            info:SetDamage( dmg )
            HLMD_DebugText( owner, " Had a critical hit on ", enemy, "!" )
        end
        
        HLMD_DebugText( enemy, " Took ", dmg, " damage from ", owner, "!" )
        
        enemy:TakeDamageInfo( info )

        return dmg
    else
        HLMD_DebugText( owner, " Missed their shot on ", enemy, "!" )
        return "missed"
    end

end

function ENT:DoReload()
end