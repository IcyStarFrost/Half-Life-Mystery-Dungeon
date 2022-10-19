
-- Server side netmessages

-- Received when the player exits the main menu
net.Receive( "hlmd_mainmenuexit", function( len, ply )

--[[     local firsttimeplaying = HLMDGetSettingValue( "FirstTime" )
 ]]
    HLMD_AllowInput = true
--[[ 
    if firsttimeplaying then
        HLMD_StartTutorial()
    end ]]

end )

-- Received when the player opens the main menu
net.Receive( "hlmd_mainmenuopened", function()
    HLMD_AllowInput = false
end )

-- Received from the main menu when Enter Free Cam is pressed
net.Receive( "hlmd_startfreecam", function()
    HLMD_EnterFreecam()
end )