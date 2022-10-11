


hook.Add( "PlayerInitialSpawn", "hlmd_setupplayernextbot", function( ply )

    ply:SetNoDraw( true )
    ply:SetMoveType( MOVETYPE_NOCLIP )

    ply.Nextbot = ents.Create( "hlmd_rebel" )
    ply.Nextbot:SetPos( ply:GetPos() )
    ply.Nextbot:SetAngles( ply:GetAngles() )
    ply.Nextbot:Spawn()
    ply.Nextbot:SetPlayerControlled( true )

    ply.Nextbot.loco:SetDesiredSpeed( 200 )

    net.Start( "hlmd_setviewtarget" )
    net.WriteEntity( ply.Nextbot )
    net.Send( ply )

end )

hook.Add("SetupPlayerVisibility", "hlmd_vis", function( ply, view )
    if !IsValid( ply.Nextbot ) then return end

    AddOriginToPVS( ply.Nextbot:GetPos() )

end )

hook.Add( "StartCommand", "hlmd_command", function( ply, cmd )
    if IsValid( ply.Nextbot ) then

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
        Entity( 1 ).Nextbot:Spawn()
        Entity( 1 ).Nextbot:SetPlayerControlled( true )
        
        Entity( 1 ).Nextbot.loco:SetDesiredSpeed( 200 )

        net.Start( "hlmd_setviewtarget" )
        net.WriteEntity( Entity( 1 ).Nextbot )
        net.Send( Entity( 1 ) )

    end )

end )