GM.Name = "Half Life: Mystery Dungeon"
GM.Author = "StarFrost"

local findinsphere = ents.FindInSphere
local IsValid = IsValid
local ents_GetAll = ents.GetAll
local ipairs = ipairs
local string_Explode = string.Explode
local string_Left = string.Left
local string_Right = string.Right
local string_upper = string.upper

print("HLMD: Shared Initialized")


-- Debug Convar 
local debugconvar = CreateConVar( "hlmd_debug", 0, FCVAR_NONE, "debug", 0, 1 )


-- These variables here are pretty important for the turn based combat
-- I'll be honest, I just threw stuff at the wall to see what would stick and evidently this did.
-- It is not perfect and I understand that but honestly it works fine
HLMD_PLAYERMOVING = false 
HLMD_PLAYERTEAMTURN = false
HLMD_ENEMYTURN = false
HLMD_AllowInput = true -- Except this one is pretty much used universally. Like for the main menu
HLMD_AttackActive = false
HLMD_PlayerNearEnemy = false

-- This will be used for any thing that would reward a multiply.
-- Probably will just be used for a form of "dojos" that Pokemon Mystery Dungeon DX had that gave you a massive boost when you went through it
HLMD_EXPMULT = 1


-- The chance when a enemy calls their OnKilled() hook, they will ask to join the player's team instead of dying 
HLMD_JOINPLAYERTEAMCHANCE = 5

-- If the player is currently in Free cam
HLMD_FREECAM = false


-- Get a part of the map name to fake the "Location"
local mapname = game.GetMap()

local mapnamesplit = string_Explode( "_", mapname )

local largeststring

for k, v in ipairs( mapnamesplit ) do
	if !largeststring then largeststring = v end 

	if #v > #largeststring then
		largeststring = v
	end
end

-- This is getting the first character so we can capitalize it 
local firstcharacter = string_Left( largeststring, 1 )
local restofstring = string_Right( largeststring, #largeststring - 1 )
local firstcharacter = string_upper( firstcharacter )

HLMD_LOCATIONNAME = firstcharacter .. restofstring
--


-- A extremely garbage way of trying to get map size
if SERVER then

	timer.Simple( 0.1, function()
		HLMD_MAPSIZE = "small"
		local mapradius = Entity( 0 ):GetModelRadius()

		if mapradius < 30000 then
			HLMD_MAPSIZE = "small"
		end

		if mapradius < 15000 then
			HLMD_MAPSIZE = "extrasmall"
		end
	end )

end

-- Haven't found a use for this to be honest
function GM:Initialize()

end

-- Instead of a scoreboard, open the main menu with the scoreboard key
function GM:ScoreboardShow()
	HLMD_OpenMainMenuPanel( Entity( 1 ):GetNWEntity( "hlmd_nextbot", NULL ) )

	net.Start( "hlmd_mainmenuopened" )
	net.SendToServer()
end

hook.Add( "Think", "hlmd_betterstartthinking", function()

	if SERVER then
		local player = Entity( 1 ).Nextbot
		
		if IsValid( player ) and !player.loco:GetVelocity():IsZero() then
			HLMD_PLAYERMOVING = true 
		else
			HLMD_PLAYERMOVING = false 
		end

--[[ 		if IsValid( player ) and isfunction( player.GetWeaponEntity ) and IsValid( player:GetWeaponEntity() ) then
			local find = HLMD_FindInSphere( player:GetPos(), player:GetWeaponEntity().Range, function( ent ) if ent.IsHLMDNPC and ent:GetAlive() and player:HasLOS( ent ) and ent != player and ent:GetHLMDTeam() != player:GetHLMDTeam() then return true end end )

			HLMD_PlayerNearEnemy = #find > 0

		end ]]

		if IsValid( player ) then Entity( 1 ):SetPos( player:GetPos() ) end

	elseif CLIENT then



	end

end )


-- Debugging
function HLMD_DebugText( ... )
	if !debugconvar:GetBool() then return end
    print( "HLMD: ", ... )
end


-- All HLMD NPCS not in the player's team is allowed to move during the time
function HLMD_EnemyTurn( time )
	HLMD_ENEMYTURN = true
	HLMD_AllowInput = false
	timer.Simple( time, function()
		HLMD_ENEMYTURN = false
		HLMD_AllowInput = true
	end )
end

-- Same as above for applies to the player's teammates but not the player
function HLMD_PlayerTeamTurn( time )
	HLMD_PLAYERTEAMTURN = true
	HLMD_AllowInput = false
	timer.Simple( time, function()
		HLMD_PLAYERTEAMTURN = false
		HLMD_AllowInput = true
	end )
end

-- Self explanatory. Allows all HLMD NPCs to execute a action
function HLMD_ResetPreventActions()

	for k, v in ipairs( ents_GetAll() ) do
		if IsValid( v ) and v.IsHLMDNPC then
			v.PreventAction = false
		end
	end

end

-- Simple Coroutine
function HLMD_InitializeCoroutineThread( func )
	local thread = coroutine.create(func)
	local id = math.random(1000000)
	hook.Add("Think","HLMDcoroutineengine"..id,function()
		if coroutine.status(thread) != "dead" then
			local ok, msg = coroutine.resume(thread)

            if !ok then
                ErrorNoHalt( msg )    
            end

		else
			hook.Remove("Think","HLMDcoroutineengine"..id)
		end
	end)
end

-- FindInSphere but with a filter arg
function HLMD_FindInSphere( pos, radius, filter )
	local entities = {}

	for k, v in ipairs( findinsphere( pos, radius ) ) do
		if IsValid( v ) and ( filter == nil or filter( v ) ) then
			entities[ #entities + 1 ] = v
		end
	end

	return entities
end

-- These two functions are just for getting these easier
function HLMD_GetPlayerTeamMembers()
	local mem = {}
	for k, v in ipairs( ents_GetAll() ) do
		if IsValid( v ) and v.IsHLMDNPC and v:GetHLMDTeam() == HLMD_PLAYERTEAM then
			mem[ #mem + 1 ] = v
		end
	end
	return mem
end

function HLMD_GetEnemyMembers()
	local mem = {}
	for k, v in ipairs( ents_GetAll() ) do
		if IsValid( v ) and v.IsHLMDNPC and v:GetHLMDTeam() != HLMD_PLAYERTEAM then
			mem[ #mem + 1 ] = v
		end
	end
	return mem
end
--