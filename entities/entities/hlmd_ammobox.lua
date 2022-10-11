AddCSLuaFile()

ENT.Base = "hlmd_item_base"

ENT.PickupRange = 100

function ENT:Initialize()

    self:SetModel( "models/items/item_item_crate.mdl" )
    
    self:HandlePosition()

end

function ENT:OnPickUp( by )

end