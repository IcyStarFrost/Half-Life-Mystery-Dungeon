GM.Name = "Half Life: Mystery Dungeon"
GM.Author = "StarFrost"

local findinsphere = ents.FindInSphere
local IsValid = IsValid

local debugconvar = CreateConVar( "hlmd_debug", 0, FCVAR_NONE, "debug", 0, 1 )

function GM:Initialize()
    

end


function HLMD_DebugText( ... )
	if !debugconvar:GetBool() then return end
    print( "HLMD: ", ... )
end

function HLMD_InitializeCoroutineThread( func )
	local thread = coroutine.create(func)
	local id = math.random(1000000)
	hook.Add("Think","zetacoroutineengine"..id,function()
		if coroutine.status(thread) != "dead" then
			local ok, msg = coroutine.resume(thread)

            if !ok then
                ErrorNoHalt( msg )    
            end

		else
			hook.Remove("Think","zetacoroutineengine"..id)
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