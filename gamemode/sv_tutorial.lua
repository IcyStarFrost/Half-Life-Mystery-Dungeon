
function HLMD_StartTutorial()

    local player = Entity( 1 ).Nextbot

    HLMD_InitializeCoroutineThread( function()
    
        --HLMD_ClearTeamBar()
        coroutine.wait( 0.5 )

        --HLMD_ControlMusic( 2, "discussions.mp3", 0.3, true )

        coroutine.wait( 2 )
    
        player:SayInTextBox( "Where.. Where am I? How did I get here?" )

        coroutine.wait( 5 )

        player:SayInTextBox( ".. I can't remember anything before now." )

        coroutine.wait( 4 )

        player:SayInTextBox( "I think I recognize this place however.. This looks like " .. HLMD_LOCATIONNAME .. "." )

        coroutine.wait( 6 )

        player:SayInTextBox( "Though, it's real quiet out here.." )
    
    
    
    end )


end