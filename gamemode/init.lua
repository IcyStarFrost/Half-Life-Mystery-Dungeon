AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "sounds.lua" )
AddCSLuaFile( "cl_netmessages.lua" )
AddCSLuaFile( "enums.lua" )
AddCSLuaFile( "sh_files.lua" )

print("HALF LIFE: Mystery Dungeon Initialized\n")

include( "shared.lua" )
include( "networkstrings.lua" )
include( "hooks.lua" )
include( "sounds.lua" )
include( "enums.lua" )
include( "sv_netmessages.lua" )
include( "sh_files.lua" )



local whitevec = Vector( 1, 1, 1 )
local zeroangle = Angle()
local zerovec = Vector()
local ipairs = ipairs
local ents_GetAll = ents.GetAll
local defaultcolor =  Color( 14, 165, 235)

-- Easily Create a NPC 
function HLMD_CreateNPC( Classname, pos, angles, ply, colvec, HLMDteam )
    colvec = colvec or whitevec
    angles = angles or zeroangle
    pos = pos or zerovec

    local Nextbot = ents.Create( "hlmd_rebel" )
    Nextbot:SetPos( pos )
    Nextbot:SetAngles( angles )
    Nextbot:Spawn()

    timer.Simple( 0, function()
        Nextbot:SetPlayerControlled( IsValid( ply ) )
        Nextbot:SetDisplayColor( colvec )
        Nextbot:SetHLMDTeam( HLMDteam or 0)
    end )

    HLMD_DebugText( "New HLMD NPC has spawned! ", Nextbot )
    return Nextbot
end

function HLMD_LogEvent( text, color, type)

    net.Start( "hlmd_logevent" )
    net.WriteString( text )
    net.WriteColor( color or defaultcolor, false )
    net.WriteString( type or "generic" )
    net.Broadcast()

end

function HLMD_AddHLMDNPCTobar( ent )

    net.Start( "hlmd_addteammember" )
    net.WriteEntity( ent )
    net.Broadcast()

end

function HLMD_AddHudIndicator( ent, text, color )
    net.Start( "hlmd_addhudindicator" )
    net.WriteEntity( ent )
    net.WriteString( text )
    net.WriteColor( color )
    net.Broadcast()
end

function HLMD_ClearTeamBar()

    net.Start( "hlmd_clearteambars" )
    net.Broadcast()

end

function HLMD_RemoveHLMDNPCFrombar( ent )

    net.Start( "hlmd_removeteammember" )
    net.WriteEntity( ent )
    net.Broadcast()

end

function HLMD_CleanDeadHLMDNPCS()
    local count = 0
    
    for k, v in ipairs( ents_GetAll() ) do
        if IsValid( v ) and v.IsHLMDNPC and !v:GetAlive() then HLMD_RemoveHLMDNPCFrombar( v ) v:Remove() count = count + 1 end
    end

    HLMD_DebugText( "Removing dead HLMD NPCs.. (" .. count .. ") Entities were removed" )
end

function HLMD_DisplayMainMenu( intro )
    net.Start( "hlmd_displaymainmenu" )
    net.WriteEntity( Entity( 1 ).Nextbot )
    net.WriteBool( intro )
    net.Broadcast()
    HLMD_AllowInput = false
end

function HLMD_CleanClientRagdolls()

    net.Start( "hlmd_ragdollclean" )
    net.Broadcast()

end


function HLMD_OnHLMDNPCKilled( npc, attacker, inflictor )

    if npc:GetHLMDTeam() == HLMD_PLAYERTEAM then
        
        HLMD_LogEvent( npc:GetNickname() .. " was killed!", Color( 255, 0, 0 ) )

    end

end