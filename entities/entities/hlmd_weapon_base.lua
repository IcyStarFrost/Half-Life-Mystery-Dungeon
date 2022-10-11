AddCSLuaFile()

local random = math.random
local PlayEffect = util.Effect
--HLMD_WEAPONTYPE_RANGED
--HLMD_WEAPONTYPE_MELEE

ENT.Base = "base_anim"
ENT.WeaponType = HLMD_WEAPONTYPE_RANGED
ENT.DamageType = DMG_BULLET
ENT.Clip = 0
ENT.WeaponPower = 0
ENT.Accuracy = 0
ENT.WeaponName = ""


function ENT:FireWeapon()
end


-- 1 = Regular muzzle
-- 5 = AR2 muzzle
-- 7 bigger regular
function ENT:HandleMuzzleFlash( type )
    local lookup = self:LookupAttachment( "muzzle" )
    local attach = self:GetAttachment( lookup )

    local effect = EffectData()
    effect:SetPos( attach.Pos )
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

function ENT:HandleShellEjects( type, ang, offpos )
    offpos = offpos or Vector( 0, 0, 0 )
    local effect = EffectData()

    effect:SetPos( self:GetPos() + offpos )
    effect:SetAngles( ang )
    effect:SetEntity( self )

    PlayEffect( typetranslation[ type ], effect )
end

function ENT:AttemptDamage()
    local owner = self:GetOwner()
    local enemy = owner:GetEnemy()

    if !IsValid( enemy ) then return "failed" end

    if random( 1, 100 ) < self.Accuracy then
        local ownerattackpower = owner:GetAttack()
        local enemydefense = enemy:GetDefense()
        local enemyevade = enemy:GetEvade()

        if random( 1, 100 ) < enemyevade then return "dodged" end

        local dmg = self.WeaponPower + ( ownerattackpower / 2 )
        dmg = dmg - ( enemydefense / 2 )

        local info = DamageInfo()

        info:SetDamage( dmg )
        info:SetDamageType( self.DamageType  )
        info:SetAttacker( owner )
        info:SetInflictor( self )
        
        
        enemy:TakeDamageInfo( dmg )

        return dmg
    else
        return "missed"
    end

end

function ENT:DoReload()
end