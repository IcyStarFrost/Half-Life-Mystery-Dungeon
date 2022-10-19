
-- Client Side Net Messages

local cl_ragdolls = {}
local ipairs = ipairs
local table_insert = table.insert

print("HLMD: Client-Side Net Messages Initialized")

net.Receive( "hlmd_setmodelcolor", function()
    local ent = net.ReadEntity()
    local vec = net.ReadVector()

    if !IsValid( ent ) then return end

    ent.GetPlayerColor = function() return vec end
end )

net.Receive( "hlmd_ragdollhlmdnpc", function()
    local ent = net.ReadEntity()
    local col = net.ReadVector()
    local force = net.ReadVector()

    if !IsValid( ent ) then return end

    ent.Deathragdoll = ent:BecomeRagdollOnClient()
    ent.Deathragdoll.GetPlayerColor = function() return col end

    table_insert( cl_ragdolls, ent.Deathragdoll )

    for i=1, 2 do
        local phys = ent.Deathragdoll:GetPhysicsObjectNum( i )

        if IsValid( phys ) then
            phys:ApplyForceCenter( force )
        end

    end
    ent:SetNoDraw( false )
end )

net.Receive( "hlmd_removedeathragdoll", function()
    local ent = net.ReadEntity()

    if !IsValid( ent ) then return end

    ent.Deathragdoll:Remove()
end )

net.Receive( "hlmd_ragdollclean", function()
    for k, v in ipairs( cl_ragdolls ) do
        if IsValid( v ) then v:Remove() end
    end
end )


local currentmusictrack

net.Receive( "hlmd_controlmusic", function()
    local control = net.ReadUInt( 3 )
    local track = net.ReadString()
    local musicvolume = net.ReadFloat()
    local loop = net.ReadBool()

    if control == 0 then
        if IsValid( currentmusictrack ) then currentmusictrack:Stop() end
    elseif control == 1 then
        if !IsValid( currentmusictrack ) then return end

        local volume = currentmusictrack:GetVolume()
        hook.Add( "Think", "hlmd_musicfadeout", function()
            if !IsValid( currentmusictrack ) then hook.Remove( "Think", "hlmd_musicfadeout" ) return end

            volume = volume - 0.01
            currentmusictrack:SetVolume( volume )

            if volume <= 0 then
                currentmusictrack:Stop()
                hook.Remove( "Think", "hlmd_musicfadeout" )
            end
        end )

    elseif control == 2 then

        sound.PlayFile( "sound/hlmd/music/" .. track, "", function( sndchan, id, name )
            if id and name then print( "HLMD MUSIC CONTROL ERROR: ", id, name ) end
        
            currentmusictrack = sndchan

            sndchan:EnableLooping( loop )
            sndchan:SetVolume( musicvolume )
        
        end )

    end



end )