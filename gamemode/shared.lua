GM.Name = "Half Life: Mystery Dungeon"
GM.Author = "StarFrost"

local findinsphere = ents.FindInSphere
local IsValid = IsValid
local ents_GetAll = ents.GetAll

print("HLMD: Shared Initialized")

HLMD_PLAYERMOVING = false 
HLMD_PLAYERTEAMTURN = false
HLMD_ENEMYTURN = false
HLMD_AllowInput = true
HLMD_AttackActive = false

local debugconvar = CreateConVar( "hlmd_debug", 0, FCVAR_NONE, "debug", 0, 1 )

function GM:Initialize()
    

end

hook.Add( "Think", "hlmd_betterstartthinking", function()

	if SERVER then
		local player = Entity( 1 ).Nextbot
		
		if IsValid( player ) and !player.loco:GetVelocity():IsZero() then
			HLMD_PLAYERMOVING = true 
		else
			HLMD_PLAYERMOVING = false 
		end


	elseif CLIENT then



	end

end )


function HLMD_DebugText( ... )
	if !debugconvar:GetBool() then return end
    print( "HLMD: ", ... )
end


function HLMD_EnemyTurn( time )
	HLMD_ENEMYTURN = true
	HLMD_AllowInput = false
	timer.Simple( time, function()
		HLMD_ENEMYTURN = false
		HLMD_AllowInput = true
	end )
end

function HLMD_PlayerTeamTurn( time )
	HLMD_PLAYERTEAMTURN = true
	HLMD_AllowInput = false
	timer.Simple( time, function()
		HLMD_PLAYERTEAMTURN = false
		HLMD_AllowInput = true
	end )
end

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

function HLMD_FindInSphere( pos, radius, filter )
	local entities = {}

	for k, v in ipairs( findinsphere( pos, radius ) ) do
		if IsValid( v ) and ( filter == nil or filter( v ) ) then
			entities[ #entities + 1 ] = v
		end
	end

	return entities
end

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