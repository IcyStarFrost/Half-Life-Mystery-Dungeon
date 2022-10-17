
file.CreateDir( "hlmd" )

-- Localize some vars

local JSONToTable = util.JSONToTable
local TableToJSON = util.TableToJSON

-- We use our own version of Write and Read since they are open source and any addon can screw stuff up

function HLMDFileWrite( filename, contents )

	local f = file.Open( filename, "w", "DATA" )
	if ( !f ) then return end

	f:Write( contents )
	f:Close()

end

function HLMDFileRead( filename, path )

	if ( path == true ) then path = "GAME" end
	if ( path == nil || path == false ) then path = "DATA" end

	local f = file.Open( filename, "r", path )
	if ( !f ) then return end

	local str = f:Read( f:Size() )

	f:Close()

	if ( !str ) then str = "" end
	return str

end

function HLMDReadSettings()

	local f = file.Open( "hlmd/settings.dat", "r", "DATA" )
	if ( !f ) then return end

	local str = f:Read( f:Size() )

	f:Close()

	if ( !str ) then str = "" end
	return str

end

function HLMDGetSettingValue( name )
    local settings = HLMDReadSettings()
    settings = JSONToTable( settings )
    return settings[ name ]
end

--


-- Originally I was gonna use ConVars but I was afraid of the rare instance of a game crash and everything gets reset
function HLMDUpdateSetting( name, value, override )

    if !file.Exists( "hlmd/settings.dat", "DATA" ) then HLMDFileWrite( "hlmd/settings.dat", "[]" ) end

    if !override then

        local settings = HLMDReadSettings()
        local data = JSONToTable( settings )

        if !data[ name ] then data[ name ] = value elseif data[ name ] then return end

        data = TableToJSON( data, true )

        HLMDFileWrite( "hlmd/settings.dat", data )

    else

        local settings = HLMDReadSettings()
        local data = JSONToTable( settings )

        data[ name ] = value

        data = TableToJSON( data, true )

        HLMDFileWrite( "hlmd/settings.dat", data )

    end

end


-- Set up the settings. This will only create them if they don't exist already.
HLMDUpdateSetting( "MenuTheme", "Brink.mp3" )