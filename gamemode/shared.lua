GM.Name = "Half Life: Mystery Dungeon"
GM.Author = "StarFrost"

function GM:Initialize()
    

end


function HLMD_DebugText( ... )
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