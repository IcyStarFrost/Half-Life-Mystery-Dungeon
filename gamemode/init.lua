AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "sounds.lua" )
AddCSLuaFile( "cl_netmessages.lua" )
AddCSLuaFile( "enums.lua" )

include( "shared.lua" )
include( "networkstrings.lua" )
include( "hooks.lua" )
include( "sounds.lua" )

local whitevec = Vector( 1, 1, 1 )
local zeroangle = Angle()
local zerovec = Vector()

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
end