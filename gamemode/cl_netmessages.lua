


net.Receive( "hlmd_setmodelcolor", function()
    local ent = net.ReadEntity()
    local vec = net.ReadVector()

    if !IsValid( ent ) then return end

    ent.GetPlayerColor = function() return vec end
end )