
-- Where most of the hooks will be handled

print("HLMD: Hooks Initialized")

hook.Add( "PlayerInitialSpawn", "hlmd_setupplayernextbot", function( ply )

    timer.Simple( 0, function()
    ply:SetNoDraw( true )
    ply:SetMoveType( MOVETYPE_NOCLIP )
    ply:SetCollisionGroup( COLLISION_GROUP_DEBRIS )

    ply.Nextbot = ents.Create( "hlmd_rebel" )
    ply.Nextbot:SetPos( ply:GetPos() )
    ply.Nextbot:SetAngles( ply:GetAngles() )
    ply.Nextbot:SetOwner( ply )
    ply.Nextbot:Spawn()
    ply.Nextbot:SetPlayerControlled( true )
    ply.Nextbot:SetDisplayColor( Vector( 1, 1, 1 ) )
    ply:SetNWEntity( "hlmd_nextbot", ply.Nextbot )

    net.Start( "hlmd_setviewtarget" )
    net.WriteEntity( ply.Nextbot )
    net.Send( ply )

    net.Start( "hlmd_addteammember" )
    net.WriteEntity( ply.Nextbot )
    net.Send( ply )

        timer.Simple( 0, function() HLMD_DisplayMainMenu( true ) end )

    end )

end )

hook.Add("SetupPlayerVisibility", "hlmd_vis", function( ply, view )
    if !IsValid( Entity( 1 ).Nextbot ) then return end

    AddOriginToPVS( Entity( 1 ).Nextbot:GetPos() )

end )


-- Player nextbot control
hook.Add( "StartCommand", "hlmd_command", function( ply, cmd )
    if IsValid( ply.Nextbot ) and HLMD_AllowInput and ply.Nextbot:GetAlive() and !HLMD_ENEMYTURN and !HLMD_AttackActive then

        local vec = ply.Nextbot:GetPos()
        local ismoving = false

        if cmd:KeyDown( IN_FORWARD ) then
            vec.x = vec.x - 100
            ismoving = true
        end

        if cmd:KeyDown( IN_BACK ) then
            vec.x = vec.x + 100
            ismoving = true
        end

        if cmd:KeyDown( IN_MOVERIGHT ) then
            vec.y = vec.y + 100
            ismoving = true
        end

        if cmd:KeyDown( IN_MOVELEFT ) then
            vec.y = vec.y - 100
            ismoving = true
        end

        if cmd:KeyDown(IN_USE) and ( !ply.Nextbot.WeaponswitchCooldown or CurTime() > ply.Nextbot.WeaponswitchCooldown )  then
            ply.Nextbot:ScrollWeapon()
            ply.Nextbot.WeaponswitchCooldown = CurTime() + 1
        end

        if cmd:KeyDown( IN_JUMP ) and ( !ply.Nextbot.ChangeEnemyCooldown or CurTime() > ply.Nextbot.ChangeEnemyCooldown ) then
            ply.Nextbot:ChangeEnemy()
            ply.Nextbot.ChangeEnemyCooldown = CurTime() + 0.5
        end

        if cmd:KeyDown( IN_ATTACK ) and !ply.Nextbot.IsAttacking then ply.Nextbot:AttackEnemy() end



        if ismoving then
            ply.Nextbot.loco:Approach( vec, 1 )
            ply.Nextbot.loco:FaceTowards( vec )
        end

    end

    cmd:ClearButtons()
    cmd:ClearMovement()

    

end )

hook.Add( "EntityTakeDamage", "hlmd_nodamage", function( ent )
    if IsValid( ent ) and ent:IsPlayer() then return true end
end )

hook.Add( "CanPlayerSuicide", "hlmd_nokillbind", function( ply )
    return false
end )


hook.Add( "PostCleanupMap", "hlmd_reset", function()

    timer.Simple( 0.1, function()

        Entity( 1 ):Spawn()
        Entity( 1 ):SetNoDraw( true )
        Entity( 1 ):SetMoveType( MOVETYPE_NOCLIP )
        Entity( 1 ):SetCollisionGroup( COLLISION_GROUP_DEBRIS )

        Entity( 1 ).Nextbot = ents.Create( "hlmd_rebel" )
        Entity( 1 ).Nextbot:SetPos( Entity( 1 ):GetPos() )
        Entity( 1 ).Nextbot:SetAngles( Entity( 1 ):GetAngles() )
        Entity( 1 ).Nextbot:SetOwner( Entity( 1 ) )
        Entity( 1 ).Nextbot:Spawn()
        Entity( 1 ).Nextbot:SetPlayerControlled( true )
        Entity( 1 ).Nextbot:SetDisplayColor( Vector( 1, 1, 1 ) )
        Entity( 1 ):SetNWEntity( "hlmd_nextbot", Entity( 1 ).Nextbot )

        net.Start( "hlmd_setviewtarget" )
        net.WriteEntity( Entity( 1 ).Nextbot )
        net.Send( Entity( 1 ) )

        net.Start( "hlmd_setviewdistance" )
        net.WriteUInt( 500 , 16 )
        net.Send( Entity( 1 ) )

        net.Start( "hlmd_addteammember" )
        net.WriteEntity( Entity( 1 ).Nextbot )
        net.Send( Entity( 1 ) )

    end )

end )