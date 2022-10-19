AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "sh_shared.lua" )
AddCSLuaFile( "sh_sounds.lua" )
AddCSLuaFile( "cl_netmessages.lua" )
AddCSLuaFile( "sh_enums.lua" )
AddCSLuaFile( "sh_files.lua" )
AddCSLuaFile( "sh_adventurehandling.lua" )

print("HALF LIFE: Mystery Dungeon Initialized\n")

include( "sh_shared.lua" )
include( "sv_networkstrings.lua" )
include( "sv_hooks.lua" )
include( "sh_sounds.lua" )
include( "sh_enums.lua" )
include( "sv_netmessages.lua" )
include( "sh_files.lua" )
include( "sv_tutorial.lua" )
include( "sh_adventurehandling.lua" )


-- Localize variables.
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

    local Nextbot = ents.Create( Classname )
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

-- Shows a gmod notifcation style log at the right of the screen
-- Valid types below --
--generic
--combat
--buff
function HLMD_LogEvent( text, color, type )

    net.Start( "hlmd_logevent" )
    net.WriteString( text )
    net.WriteColor( color or defaultcolor, false )
    net.WriteString( type or "generic" )
    net.Broadcast()

end

-- Adds a HLMD NPC to the Health bars at the top right of the screen
function HLMD_AddHLMDNPCTobar( ent )

    net.Start( "hlmd_addteammember" )
    net.WriteEntity( ent )
    net.Broadcast()

end

-- Indicators such as Damage, Misses, and ect use this
function HLMD_AddHudIndicator( ent, text, color )
    net.Start( "hlmd_addhudindicator" )
    net.WriteEntity( ent )
    net.WriteString( text )
    net.WriteColor( color )
    net.Broadcast()
end

-- Does as named. Clears the Health Bar of any HLMD NPC listed on it
function HLMD_ClearTeamBar()

    net.Start( "hlmd_clearteambars" )
    net.Broadcast()

end

-- Remove a specific HLMD NPC from the health bars
function HLMD_RemoveHLMDNPCFrombar( ent )

    net.Start( "hlmd_removeteammember" )
    net.WriteEntity( ent )
    net.Broadcast()

end

-- In HLMD, NPCs do not get removed and instead wait in a shutdown state until they are either Revived or Removed
-- This function pretty much removes all dead NPCs
function HLMD_CleanDeadHLMDNPCS()
    local count = 0
    
    for k, v in ipairs( ents_GetAll() ) do
        if IsValid( v ) and v.IsHLMDNPC and !v:GetAlive() then HLMD_RemoveHLMDNPCFrombar( v ) v:Remove() count = count + 1 end
    end

    HLMD_DebugText( "Removing dead HLMD NPCs.. (" .. count .. ") Entities were removed" )
end

-- Shows the main menu either with the intro or not
function HLMD_DisplayMainMenu( intro )
    net.Start( "hlmd_displaymainmenu" )
    net.WriteEntity( Entity( 1 ).Nextbot )
    net.WriteBool( intro )
    net.Broadcast()
    HLMD_AllowInput = false
end

-- Removes all HLMD Clientside ragdolls spawned by HLMD NPCs
function HLMD_CleanClientRagdolls()

    net.Start( "hlmd_ragdollclean" )
    net.Broadcast()

end


-- This function controls the background music during gameplay --
-- These are the control types 
--HLMD_MUSICCONTROL_STOP = 0
--HLMD_MUSICCONTROL_FADEDSTOP = 1
--HLMD_MUSICCONTROL_PLAY = 2
function HLMD_ControlMusic( controltype, track, volume, loop )
    net.Start( "hlmd_controlmusic" )
    net.WriteUInt( controltype, 3 )
    net.WriteString( track or "" )
    net.WriteUInt( volume or 1, 4 )
    net.WriteBool( loop or false )
    net.Broadcast()
end


-- A form of "noclip"
-- Due to how this works and PVS, moving out of bounds or out of sight of the Player's PVS will make the free cam not move.
-- That's alright because the free cam is meant for taking screenshots and such. Doesn't need to be perfect
function HLMD_EnterFreecam()
    local cam = ents.Create( "base_anim" )
    cam:SetPos( Entity( 1 ).Nextbot:GetPos() )
    cam:SetMaterial( "null" )
    cam:DrawShadow( false )
    cam:Spawn()

    net.Start( "hlmd_sendfreecam" )
    net.WriteEntity( cam )
    net.Broadcast()

    Entity( 1 ).Freecam = cam

    HLMD_FREECAM = true
    
end


-- Obviously a on killed hook when a HLMD NPC "dies"
function HLMD_OnHLMDNPCKilled( npc, attacker, inflictor )

    if npc:GetHLMDTeam() == HLMD_PLAYERTEAM then
        
        HLMD_LogEvent( npc:GetNickname() .. " was killed!", Color( 255, 0, 0 ) )

        -- When the player dies, cue the epic cinematic dramatic on edge slowmotion!
        if npc:GetPlayerControlled() then
            game.SetTimeScale( 0.2 )

            timer.Simple( 1, function()
                game.SetTimeScale( 1 )
            end )

            BroadcastLua( "sound.PlayFile( 'sound/hlmd/misc/playerdied.mp3', '', function( sndchan, id, name ) end )" )
        else
            BroadcastLua( "sound.PlayFile( 'sound/hlmd/misc/teammatedied.mp3', '', function( sndchan, id, name ) end )" )
        end

    end

end