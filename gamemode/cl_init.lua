include( "shared.lua" )
include( "sh_files.lua" )
include( "cl_netmessages.lua" )
include( "cl_menu.lua" )

print("HLMD: Client-Side Initialized")

local trace = util.TraceLine
local ipairs = ipairs
local table_insert = table.insert
local table_Empty = table.Empty
local Clamp = math.Clamp
local table_remove = table.remove
local string_ToTable = string.ToTable

-- SKY VIEW --

HLMD_ClientViewoverridepos = nil
HLMD_ClientViewoverrideangs = nil
HLMD_ClientViewoverridefov = nil
local target
local farview = 500
local farviewlerp = 500
local viewtbl = {}
local tracetbl = {}

local lastpos 
local lastangle

function GM:CalcView( ply, origin, angles, fov, znear, zfar )
    if !IsValid( target ) then 
        
        viewtbl.origin = lastpos
        viewtbl.angles = lastangle
        viewtbl.fov = HLMD_ClientViewoverridefov or 60
        viewtbl.znear = znear
        viewtbl.zfar = zfar
    
        return viewtbl

    end
    farviewlerp = Lerp( 2 * FrameTime(), farviewlerp, farview )
    local skyviewpos = target:GetPos() + Vector( farviewlerp, 0, farviewlerp )

    local pos = HLMD_ClientViewoverridepos or skyviewpos or lastpos

    tracetbl.start = target:WorldSpaceCenter()
    tracetbl.endpos = pos
    tracetbl.filter = target

    local result = trace( tracetbl )

    viewtbl.origin = pos
    viewtbl.angles = HLMD_ClientViewoverrideangs or ( target:GetPos() - skyviewpos ):Angle() or lastangle
    viewtbl.fov = HLMD_ClientViewoverridefov or 60
    viewtbl.znear = result.Hit and result.HitPos:Distance( pos ) or 100
    viewtbl.zfar = zfar

    lastpos = viewtbl.origin
    lastangle = viewtbl.angles

    return viewtbl
end

net.Receive( "hlmd_setviewdistance", function() farview = net.ReadUInt( 16 ) end )
net.Receive( "hlmd_setviewtarget", function() target = net.ReadEntity() end )




-- EVENT LOG --

local trackedevents = {}


surface.CreateFont( "hlmd_eventlogfont", {
    font = "Agency FB",
	extended = false,
	size = 40,
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

local x = ScrW() - 50
local y = ScrH() - 300
local defaultcolor =  Color( 14, 165, 235)
local generic = Material( "hlmd/eventlog/generic.png" )
local combat = Material( "hlmd/target.png" )

local typemats = {
    [ "generic" ] = generic,
    [ "combat" ] = combat
}

hook.Add( "HUDPaint", "hlmd_eventlog", function()

    if #trackedevents > 0 then

        surface.SetFont( "hlmd_eventlogfont" )
        
        for k, event in ipairs( trackedevents ) do

            local tbl = trackedevents[ k ]
            local text = tbl.text
            local color = tbl.color or defaultcolor
            local time = tbl.time
            local type = tbl.type or "generic"

            local w, h = surface.GetTextSize( text )

            tbl.x = tbl.x or x + ( w + 100)

            if SysTime() > time then 
                
                tbl.x = Lerp( 5 * FrameTime(), tbl.x, ScrW() + ( w + 60 ) )

                if SysTime() > time + 1 then
                    trackedevents[ k ] = nil
                    continue
                end
            else

                tbl.x = Lerp( 5 * FrameTime(), tbl.x, ( ScrW() - 30 ) )

            end

            

            if k != 1 then
                tbl.y = Lerp( 2 * FrameTime(), tbl.y or y, ( y - ( k * 50 ) ) + h )
            end

            surface.SetDrawColor( 0, 0, 0, 200)
            surface.DrawRect( tbl.x - w, tbl.y or y, w, h )

            draw.DrawText( text, "hlmd_eventlogfont", tbl.x, tbl.y or y, color , TEXT_ALIGN_RIGHT )

            render.SetMaterial( typemats[ type ] )
            render.DrawScreenQuadEx( tbl.x - ( w + 35), ( tbl.y or y ) + 5, 32, 32 )

        end

    end

end )

net.Receive( "hlmd_logevent", function()
    local text = net.ReadString()
    local color = net.ReadColor( false )
    local type = net.ReadString()

    table_insert( trackedevents, 1, { text = text, color = color, type = type, time = SysTime() + 8 } )

end )



-- Health bars --

surface.CreateFont( "hlmd_statbar", {
    font = "Agency FB",
	extended = false,
	size = 20,
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

surface.CreateFont( "hlmd_HP", {
    font = "Agency FB",
	extended = false,
	size = 30,
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

surface.CreateFont( "hlmd_Nickname", {
    font = "Agency FB",
	extended = false,
	size = 25,
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

local teammembers = {}

local x = ScrW()
local y = ScrH() / 30
local green = Color( 0, 255, 106)
local hpcol = Color( 0, 225, 255 )
local fadedcolor = Color( 0, 0, 0, 70 )
local black = Color( 0, 0, 0 )
local characterbackground = Color( 9, 70, 56, 150)

hook.Add( "HUDPaint", "hlmd_teamstats", function()
    

    if #teammembers > 0 then
        
        for k, tbl in ipairs( teammembers ) do

            if IsValid( tbl.modelpanel ) then
                tbl.modelpanel:SetVisible( !HLMD_MAINMENUOPEN )
            end

            if HLMD_MAINMENUOPEN then continue end

            local masterx = x
            local mastery = y + ( 90 * k )
            
            local member = tbl[ 1 ]

            if !IsValid( member ) then teammembers[ k ] = nil return end

            local name = IsValid(  member ) and member:GetNickname() or tbl.name
            local level = IsValid( member ) and member:GetLevel() or tbl.level
            local hp = IsValid( member ) and member:GetNWInt( "hlmd_health", 0 ) or 0
            local color = IsValid( member ) and member:GetDisplayColor() or tbl.color
            local maxhp = IsValid( member ) and member:GetNWInt( "hlmd_maxhealth", 0 ) or tbl.maxhp

            tbl.name = name
            tbl.level = level
            tbl.hp = hp
            tbl.color = color
            tbl.maxhp = maxhp

            tbl.hplerp = tbl.hplerp or hp

            if !tbl.modelpanel then
                tbl.modelpanel = vgui.Create( "DModelPanel" )
                tbl.modelpanel:SetSize( 64, 64 )
                tbl.modelpanel:SetPos( masterx - 354, mastery - 60 )
                tbl.modelpanel:SetModel( member:GetModel() )
                tbl.modelpanel:SetFOV( 30 )
                local ent = tbl.modelpanel:GetEntity()
                local estimatedheadpos =  member:OBBCenter() * 1.9

                tbl.modelpanel:SetLookAt( estimatedheadpos )
                tbl.modelpanel:SetCamPos( estimatedheadpos + Vector( 30, -20, 0 ) ) 

                function tbl.modelpanel:LayoutEntity( ent )
                    if !IsValid( member ) then self:Remove() teammembers[ k ] = nil end
                    ent.GetPlayerColor = function() if IsValid( member ) and member.GetDisplayColor != nil then return member:GetDisplayColor() else return color end end

                end
            end

            draw.RoundedBox( 10, masterx - 354, mastery - 60 , 64, 64, characterbackground )

            surface.SetDrawColor( 255, 255, 255, 100)
            surface.DrawRect( masterx - 290, mastery, 290, 5)

            tbl.hplerp = Lerp( 5 * FrameTime(), tbl.hplerp, hp )

            draw.RoundedBox( 32, masterx - 250, mastery - 17 , 200, 15, fadedcolor )
            draw.RoundedBox( 32, masterx - 250, mastery - 17 , tbl.hplerp / maxhp * 200, 15, green )

            surface.SetFont( "hlmd_statbar" )

            surface.SetTextColor( 255, 255, 255 )
            surface.SetTextPos( masterx - 270, mastery - 20 )
            surface.DrawText( "HP" )

            draw.DrawText( "" .. hp .. "/" .. maxhp, "hlmd_HP", masterx - 60, mastery - 45, hpcol , TEXT_ALIGN_RIGHT )

            --draw.DrawText( name, "hlmd_Nickname", masterx - 270, mastery - 45, color_white , TEXT_ALIGN_LEFT )
            draw.SimpleTextOutlined( name, "hlmd_Nickname", masterx - 270, mastery - 45, color_white , TEXT_ALIGN_LEFT, nil, 1, black )

            draw.DrawText( "Lv. " .. level, "hlmd_Nickname", masterx - 275, mastery - 65, color_white , TEXT_ALIGN_LEFT )

        end

    end

end )

net.Receive( "hlmd_addteammember", function()
    local ent = net.ReadEntity()
    table_insert( teammembers, { ent } )
end )

net.Receive( "hlmd_removeteammember", function()
    local ent = net.ReadEntity()
    for k, tbl in ipairs( teammembers ) do
        
        if tbl[ 1 ] == ent then if IsValid( tbl.modelpanel ) then tbl.modelpanel:Remove() end teammembers[ k ] = nil break end
    end
end )

net.Receive( "hlmd_clearinvalidteammates", function()
    for k, v in ipairs( teammembers ) do
        if IsValid( v[ 1 ] ) then continue end
        if IsValid( v.modelpanel ) then v.modelpanel:Remove() end

        teammembers[ k ] = nil
    end
end )

net.Receive( "hlmd_clearteambars", function()
    for k, v in ipairs( teammembers ) do
        if IsValid( v.modelpanel ) then v.modelpanel:Remove() end

        teammembers[ k ] = nil
    end
end )

-- Text bars --
-- Main dialog option. 

local textx = ScrW() / 3
local texty = ScrH() / 1.2
local textbarcolor = Color( 20, 2, 2, 203)

local name
local mdl
local color
local time
local soundplaytime = 0
local text 
local buildtime = 0
local buildstring = ""
local modelpanel

surface.CreateFont( "hlmd_textbartext", {
    font = "Agency FB",
	extended = false,
	size = 30,
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

surface.CreateFont( "hlmd_textbarname", {
    font = "Agency FB",
	extended = false,
	size = 40,
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


hook.Add( "HUDPaint", "hlmd_textbarpaint", function()

    if name then

        if SysTime() > time then
            name = nil
            mdl = nil
            color = nil
            if IsValid( modelpanel ) then modelpanel:Remove() end
            return
        end

        if SysTime() > buildtime and #text > 0 then
            buildstring = buildstring .. text[ 1 ]
            table_remove( text, 1 )

            if #buildstring == 65 then
                buildstring = buildstring .. "\n"
            end

            local addtime = text[ 1 ] == "." and 0.5 or 0.02

            if SysTime() > soundplaytime then
                surface.PlaySound( "buttons/lightswitch2.wav" )
                soundplaytime = SysTime() + 0.1
            end

            buildtime = SysTime() + addtime
        end

        draw.RoundedBox( 10, textx, texty, 700, 90, textbarcolor )

        surface.SetFont( "hlmd_textbarname" )

        local x, y = surface.GetTextSize( name )

        draw.RoundedBox( 10, textx, texty - 42, x, y, textbarcolor )

        surface.SetTextColor( 255, 255, 255 )
        surface.SetTextPos( textx, texty - 42 )
        surface.DrawText( name )

        draw.DrawText( buildstring, "hlmd_textbartext", textx + 100, texty + 25, color_white , TEXT_ALIGN_LEFT )
        


        if !IsValid( modelpanel ) then
            modelpanel = vgui.Create( "DModelPanel" )
            modelpanel:SetSize( 90, 90 )
            modelpanel:SetPos( textx, texty )
            modelpanel:SetModel( mdl )
            modelpanel:SetFOV( 30 )
            local ent = modelpanel:GetEntity()
            local mins, maxs = ent:GetModelBounds()
            maxs[ 1 ] = 0
            maxs[ 2 ] = 0
            maxs[ 3 ] = maxs[ 3 ] / 1.15
            local estimatedheadpos = maxs

            modelpanel:SetLookAt( estimatedheadpos )
            modelpanel:SetCamPos( estimatedheadpos + Vector( 30, -20, 0 ) )

            function modelpanel:LayoutEntity( ent )
                if SysTime() > time then self:Remove() end
                ent.GetPlayerColor = function() return color end
            end
        end

    end


end )

net.Receive( "hlmd_addtextbar", function()

    buildstring = ""
    name = net.ReadString()
    mdl = net.ReadString()
    text = string_ToTable( net.ReadString() )
    color = net.ReadVector()
    time = SysTime() + ( 6 + #text / 20 ) 

end )



-- Text Bubbles -- 
-- Typically would be used for expressing pain or short sentences 

local activetext = {}

hook.Add( "HUDPaint", "hlmd_textbubblepaint", function()

    if #activetext > 0 then
        for k, tbl in ipairs( activetext ) do
            
            local ent = tbl[ 1 ]
            local text = tbl[ 2 ]
            local time = tbl[ 3 ]

            if !IsValid( ent ) then table_remove( activetext, k ) return end

            surface.SetFont( "hlmd_textbartext" )

            local textx, texty = surface.GetTextSize( text )

            tbl.sizex = tbl.sizex or 0
            tbl.sizey = tbl.sizey or 0
            local targetpos = ( ent:GetPos() + ent:OBBCenter() ):ToScreen()
            tbl.x = targetpos.x + 30
            tbl.y = targetpos.y

            surface.SetDrawColor( textbarcolor )

            surface.DrawRect( tbl.x, tbl.y, tbl.sizex, tbl.sizey )

            if SysTime() > time then

                tbl.sizex = Lerp( 30 * FrameTime(), tbl.sizex, 0 )
                tbl.sizey = Lerp( 30 * FrameTime(), tbl.sizey, 0 )

                if SysTime() > tbl.endtime then table_remove( activetext, k ) end 

            else

                tbl.endtime = SysTime() + 0.5

                tbl.sizex = Lerp( 30 * FrameTime(), tbl.sizex, textx )
                tbl.sizey = Lerp( 30 * FrameTime(), tbl.sizey, texty )



                if tbl.sizex > textx - 5 then
                    draw.DrawText( text, "hlmd_textbartext", tbl.x, tbl.y, color_white , TEXT_ALIGN_LEFT )
                end

            end

        end

    end

end )

net.Receive( "hlmd_addtextbubble", function()
    local ent = net.ReadEntity()
    local text = net.ReadString()


    table_insert( activetext, { ent, text, SysTime() + 2 } )
end )


-- Damage/miss Indicators --

local indicators = {}


hook.Add( "HUDPaint", "hlmd_hudindicator", function()

    if #indicators > 0 then
        
        for k, tbl in ipairs( indicators ) do

            local ent = tbl[ 1 ]
            local text = tbl[ 2 ]
            local time = tbl[ 3 ]
            local color = tbl[ 4 ]

            tbl[ 5 ] = tbl[ 5 ] or 255 -- Index 5 is the alpha
            tbl[ 6 ] = tbl[ 6 ] or SysTime() + 0.2
            local targetpos = ( ent:GetPos() + ent:OBBCenter() * 2.8 ):ToScreen()
            local x = targetpos.x
            local y = targetpos.y

            if SysTime() > time then

                tbl[ 5 ] = tbl[ 5 ] - 5

                if tbl[ 5 ] <= 0 then
                    table_remove( indicators, k )
                end

            end

            if SysTime() < tbl[ 6 ] then
                x = x + math.random( -3, 3 )
                y = y + math.random( -3, 3 )
            end
            
            color.a = tbl[ 5 ]

            draw.SimpleTextOutlined( text, "hlmd_textbartext", x, y, color , TEXT_ALIGN_CENTER, nil, 1, black )
            

        end

    end


end )

net.Receive( "hlmd_addhudindicator", function()
    local ent = net.ReadEntity()
    local text = net.ReadString()
    local col = net.ReadColor()

    table_insert( indicators, { ent, text, SysTime() + 2, col} )

end )

-- Misc --

local hide = {
    [ "CHudAmmo" ] = true,
    [ "CHudBattery" ]  = true,
    [ "CHudCrosshair" ] = true,
    [ "CHudDamageIndicator" ] = true,
    [ "CHudHealth" ] = true,
    [ "CHudZoom" ] = true,
    [ "CHudSuitPower" ] = true,
}

function GM:HUDShouldDraw( name ) return !hide[ name ] end