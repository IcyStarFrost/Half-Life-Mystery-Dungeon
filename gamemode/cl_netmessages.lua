
local cl_ragdolls = {}
local ipairs = ipairs
local table_insert = table.insert

print("HLMD: Client-Side Net Messages Initialized")

net.Receive( "hlmd_setmodelcolor", function()
    local ent = net.ReadEntity()
    local vec = net.ReadVector()

    if !IsValid( ent ) then return end

    ent.GetPlayerColor = function() return vec end
end )

net.Receive( "hlmd_ragdollhlmdnpc", function()
    local ent = net.ReadEntity()
    local col = net.ReadVector()
    local force = net.ReadVector()

    if !IsValid( ent ) then return end

    ent.Deathragdoll = ent:BecomeRagdollOnClient()
    ent.Deathragdoll.GetPlayerColor = function() return col end

    table_insert( cl_ragdolls, ent.Deathragdoll )

    for i=1, 2 do
        local phys = ent.Deathragdoll:GetPhysicsObjectNum( i )

        if IsValid( phys ) then
            phys:ApplyForceCenter( force )
        end

    end
    ent:SetNoDraw( false )
end )

net.Receive( "hlmd_removedeathragdoll", function()
    local ent = net.ReadEntity()

    if !IsValid( ent ) then return end

    ent.Deathragdoll:Remove()
end )

net.Receive( "hlmd_ragdollclean", function()
    for k, v in ipairs( cl_ragdolls ) do
        if IsValid( v ) then v:Remove() end
    end
end )