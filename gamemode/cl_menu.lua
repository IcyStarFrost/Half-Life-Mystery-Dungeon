
local math_sin = math.sin
local math_cos = math.cos
local table_remove = table.remove
local string_ToTable = string.ToTable
local logo = Material( "hlmd/logo.png" )
local FFTColor = Color( 0, 195, 255 )
local JSONToTable = util.JSONToTable
local TableToJSON = util.TableToJSON
local ipairs = ipairs
print( "HLMD: Main Menu Loaded" )


surface.CreateFont( "hlmd_intro", {
    font = "Agency FB",
	extended = false,
	size = 50,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,

})

local optionsmain

local function CreateSettingsComboBox( pnl, settingname, optiontbl, selectcallback )

    local combo = vgui.Create( "DComboBox", pnl )
    combo:Dock( TOP )
    combo:SetSize( 100, 30 )

    local settings = HLMDReadSettings()
    settings = JSONToTable( settings )

    for k, v in ipairs( optiontbl ) do
        combo:AddChoice( v, nil, v == settings[ settingname ] )
    end

    function combo:OnSelect( id, val, data )
        if isfunction( selectcallback ) then selectcallback( val ) end
        HLMDUpdateSetting( settingname, val, true )
    end

    return combo
end
local musicchannel


function HLMD_OpenOptionsPanel( parent )
    if IsValid( optionsmain ) then return end

    optionsmain = vgui.Create( "DFrame", parent )
    optionsmain:SetSize( 400, 400 )
    optionsmain:Center()
    optionsmain:MakePopup()
    optionsmain:SetSizable( true )
    optionsmain:SetTitle( "HLMD Settings" )
    optionsmain:SetIcon( "hlmd/eventlog/generic.png" )

    local misctab = vgui.Create( "EditablePanel", optionsmain)

    local scroll = vgui.Create( "DScrollPanel", misctab )
    scroll:Dock( FILL )

    local tabs = vgui.Create( "DPropertySheet", optionsmain )
    tabs:Dock( FILL )

    tabs:AddSheet( "Misc", misctab )

    local sndfiles = file.Find( "sound/hlmd/mainmenu/music/*", "GAME", "namedesc")

    local lbl = vgui.Create( "DLabel", scroll )
    lbl:SetText( "Main Menu Theme" )
    lbl:Dock( TOP )
    local combo = CreateSettingsComboBox( scroll, "MenuTheme", sndfiles, function( val )
        if IsValid( musicchannel ) then musicchannel:Stop() end
        sound.PlayFile( "sound/hlmd/mainmenu/music/" .. val, "", function( sndchan, id, name ) musicchannel = sndchan  end )
    end )


    function optionsmain:Paint( w, h )

        surface.SetDrawColor( 0, 0, 0, 200 )
        surface.DrawRect( 0, 0, ScrW(), ScrH() )

    end


end

function HLMD_OpenMainMenuPanel( ent, showintro  )

    HLMD_MAINMENUOPEN = true
    gui.EnableScreenClicker( true )

    local time = showintro and 8 or 0



    if showintro then
        local alpha = 255
        local startlogo = CurTime() + 2
        local startonce = true
        local endonce = true
        local endlogo = CurTime() + 8
        local buildtime = 0
        local presents = string_ToTable( "StarFrost presents.. A Pokemon inspired gamemode.." )
        local buildstring = ""
        local soundplaytime = 0
        local introcolor = Color( 0, 195, 255, 0)

        sound.PlayFile( "sound/hlmd/mainmenu/debris02.wav", "", function( sndchan, id, name )  end )

        hook.Add( "HUDPaint", "hlmd_mainintro", function()
        
            surface.SetDrawColor( 0, 0, 0, alpha )
            surface.DrawRect( 0, 0, ScrW(), ScrH() )



            if CurTime() > endlogo then

                if endonce then
                    endonce = false
                    local theme = HLMDGetSettingValue( "MenuTheme" )
                    sound.PlayFile( "sound/hlmd/mainmenu/music/" .. theme, "", function( sndchan, id, name ) musicchannel = sndchan  end )

                    sound.PlayFile( "sound/hlmd/mainmenu/fadein.mp3", "", function( sndchan, id, name )  end )
                end
                introcolor.a = introcolor.a - 1
                alpha = alpha - 1
    
                if alpha <= 0 and introcolor.a <= 0 then
                    hook.Remove( "HUDPaint", "hlmd_mainintro" )
                end
    
                return
            end
    
            if CurTime() > startlogo then
                if introcolor.a < 255 then
                    introcolor.a = introcolor.a + 1
                end

                if SysTime() > buildtime and #presents > 0 then
                    buildstring = buildstring .. presents[ 1 ]
                    table_remove( presents, 1 )
        
                    if #buildstring == 21 then
                        buildstring = buildstring .. "\n"
                    end
        
                    local addtime = presents[ 1 ] == "." and 0.4 or 0.02
        
                    if SysTime() > soundplaytime then
                        surface.PlaySound( "buttons/combine_button7.wav" )
                        soundplaytime = SysTime() + 0.1
                    end
        
                    buildtime = SysTime() + addtime
                end

                draw.DrawText( buildstring, "hlmd_intro", ScrW() / 2, ScrH() / 2, introcolor , TEXT_ALIGN_CENTER )
    
                if startonce then
                    startonce = false
                    sound.PlayFile( "sound/hlmd/mainmenu/logopan.wav", "", function( sndchan, id, name )  end )
                end
    
            end


        end)



    end


    timer.Simple( time, function()


        local imagepnl = vgui.Create( "DImage" )
        imagepnl:SetPos( 50, 130 )
        imagepnl:SetSize( ScrW() / 2, 128 )
        imagepnl:SetMaterial( logo )

        local resumebutton = vgui.Create( "DButton" )
        resumebutton:SetPos( ( ScrW() / 2 ) - 75, ScrH() - 100 )
        resumebutton:SetSize( 150, 30)
        resumebutton:SetText( "Resume Game" )

        local Optionsbutton = vgui.Create( "DButton" )
        Optionsbutton:SetPos( ( ScrW() / 1.5 ) - 75, ScrH() - 100 )
        Optionsbutton:SetSize( 150, 30 )
        Optionsbutton:SetText( "Options" )

        function Optionsbutton:DoClick() HLMD_OpenOptionsPanel() end

        hook.Add( "RenderScreenspaceEffects", "hlmd_blur", function()
            DrawBokehDOF( 7, 0, 1 )
        end )

        hook.Add( "NeedsDepthPass", "NeedsDepthPass_Bokeh", function()

            return true
        
        end )

        local startx = 50
        local starty = 130 + 128
        local Fft = {}

        hook.Add( "HUDPaint", "hlmd_mainmenuhud", function()

            surface.SetDrawColor( 0, 0, 0, 100 )
            surface.DrawRect( 0, 0, ScrW(), ScrH() )
            if IsValid( musicchannel ) then

                musicchannel:FFT( Fft, FFT_8192 )
                
                for i=1, 150 do
                    
                    local x = startx + ( 5 * i )

                    surface.SetDrawColor( FFTColor )
                    surface.DrawRect( x, starty, 5, 5 + Fft[ i ] * 300 )

                end

            end
        
        end )

        hook.Add( "Think", "hlmd_menuthink", function()
            
            local time = SysTime() / 30
            local pos = ( ent:GetPos() + ent:OBBCenter() ) + Vector( math_sin( time ), math_cos( time ), 0 ) * 200
            HLMD_ClientViewoverridepos = pos
            HLMD_ClientViewoverrideangs = ( ( ent:GetPos() + ent:OBBCenter() ) - pos ):Angle()
            HLMD_ClientViewoverridefov = 30
        
        end )

        function resumebutton:Paint( w, h )
            surface.SetDrawColor( 0, 0, 0, 200 )
            surface.DrawRect( 0, 0, w, h )
        end

        function Optionsbutton:Paint( w, h )
            surface.SetDrawColor( 0, 0, 0, 200 )
            surface.DrawRect( 0, 0, w, h )
        end

        function resumebutton:DoClick()
            HLMD_ClientViewoverridepos = nil
            HLMD_MAINMENUOPEN = false
            HLMD_ClientViewoverrideangs = nil
            HLMD_ClientViewoverridefov = nil
            gui.EnableScreenClicker( false )
            hook.Remove( "NeedsDepthPass", "NeedsDepthPass_Bokeh" )
            hook.Remove( "RenderScreenspaceEffects", "hlmd_blur" )
            hook.Remove( "HUDPaint", "hlmd_mainintro" )
            hook.Remove( "Think", "hlmd_menuthink" )
            hook.Remove( "HUDPaint", "hlmd_mainmenuhud" )

            imagepnl:Remove()
            resumebutton:Remove()
            Optionsbutton:Remove()

            net.Start( "hlmd_mainmenuexit" )
            net.SendToServer()

            if IsValid( musicchannel ) then

                local volume = 1
                
                hook.Add( "Think", "hlmd_fademusic", function()
                    if !IsValid( musicchannel ) then hook.Remove( "Think", "hlmd_fademusic" ) return end
                    volume = volume - 0.005
                    musicchannel:SetVolume( volume )

                    if volume <= 0 and IsValid( musicchannel ) then
                        musicchannel:Stop()
                        hook.Remove( "Think", "hlmd_fademusic" )
                    end
                end )

            end
        end 

    end )
end

net.Receive( "hlmd_displaymainmenu", function() HLMD_OpenMainMenuPanel( net.ReadEntity(), net.ReadBool() or false ) end )