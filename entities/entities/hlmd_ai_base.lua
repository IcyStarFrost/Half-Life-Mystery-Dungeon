AddCSLuaFile()

ENT.Base = "base_nextbot"


-- Optimize by localizing these so we don't have to go through a global table AND go through the table holding these functions
local trace = util.TraceLine
local table_insert = table.insert
local tracetbl = {}
local math_rad = math.rad
local math_sin = math.sin
local math_cos = math.cos
local math_clamp = math.Clamp
local developermode = GetConVar( "developer" )

ENT.FootStepTrace = {}
ENT.NextFootstepSnd = 0

function ENT:SetupDataTables()

    self:NetworkVar( "Int", 0, "Team" )
    self:NetworkVar( "Vector", 0, "DisplayColor" )
    self:NetworkVar( "Bool", 0, "PlayerControlled" )
    self:NetworkVar( "Entity", 0, "WeaponEntity" )
    self:NetworkVar( "Entity", 1, "Enemy" )
    self:NetworkVar( "String", 0, "Nickname" )
    self:NetworkVar( "String", 1, "State" )
    self:NetworkVar( "String", 2, "Weapon" )

    -- Stats
    self:NetworkVar( "Int", 1, "Attack" )
    self:NetworkVar( "Int", 2, "Defense" )
    self:NetworkVar( "Int", 3, "Speed" )
    self:NetworkVar( "Int", 4, "Level" )
    self:NetworkVar( "Int", 5, "Evade" )
    
    
end

-- For override
function ENT:AddonThink()
end


-- Gmod example but it works so let's use it
local function draw_Circle( x, y, radius, seg )
	local cir = {}

	table_insert( cir, { x = x, y = y, u = 0.5, v = 0.5 } )
	for i = 0, seg do
		local a = math_rad( ( i / seg ) * -360 )
		table_insert( cir, { x = x + math_sin( a ) * radius, y = y + math_cos( a ) * radius, u = math_sin( a ) / 2 + 0.5, v = math_cos( a ) / 2 + 0.5 } )
	end

	local a = math_rad( 0 )
	table_insert( cir, { x = x + math_sin( a ) * radius, y = y + math_cos( a ) * radius, u = math_sin( a ) / 2 + 0.5, v = math_cos( a ) / 2 + 0.5 } )

	surface.DrawPoly( cir )
end

function ENT:Draw()

    tracetbl.start = self:WorldSpaceCenter()
    tracetbl.endpos = self:WorldSpaceCenter() - Vector( 0, 0, 10000 )
    tracetbl.filter = self

    local result = trace( tracetbl )
    cam.Start3D2D( result.HitPos + Vector( 0, 0, 2), Angle( 0, 0, 0 ), 1 )

        render.DepthRange( 0, 0 )

        local col = self:GetDisplayColor():ToColor()

        col.a = math.abs( math_sin( SysTime() * 2 ) * 50 )


        surface.SetDrawColor( col.r, col.g, col.b, col.a )
        draw.NoTexture()

        draw_Circle( 0, 0, self:GetModelRadius() / 2, 32 )

        render.DepthRange( 0, 1 )

    cam.End3D2D()

    self:DrawModel()

end

function ENT:OnKilled( info )
    local ragdoll = self:BecomeRagdoll( info )

    net.Start( "hlmd_setmodelcolor" )
    net.WriteEntity( ragdoll )
    net.WriteVector( self:GetDisplayColor() )
    net.Broadcast()

    timer.Simple( 15, function()
        if IsValid( ragdoll ) then ragdoll:Remove() end
    end )
end

local weaponanimations = {
    ["SMG1"] = {
        idle = ACT_HL2MP_IDLE_SMG1,
        run = ACT_HL2MP_RUN_SMG1,
        jump = ACT_HL2MP_JUMP_SMG1
    }
}

function ENT:Think()

    self:AddonThink()

    if SERVER then

        local speed = self.loco:GetVelocity():Length()
        if CurTime() > self.NextFootstepSnd and speed > 0 and self.loco:IsOnGround() then

            self.FootStepTrace.start = self:WorldSpaceCenter()
            self.FootStepTrace.endpos = self:WorldSpaceCenter() - Vector( 0, 0, 400 )
            self.FootStepTrace.filter = self
            local result = trace( self.FootStepTrace )

            if result.Hit then

                local loudness = ( self:GetPlayerControlled() and 0 or 70)
                self:EmitSound( HLMD_FootstepsTranslations[ result.MatType ], loudness )

                local nextSnd = math_clamp(0.25 * (400 / speed), 0.25, 0.35)
                self.NextFootstepSnd = CurTime() + nextSnd
            end
        end

        local idle = weaponanimations[ self:GetWeapon() ] and weaponanimations[ self:GetWeapon() ].idle or ACT_HL2MP_IDLE
        local run = weaponanimations[ self:GetWeapon() ] and weaponanimations[ self:GetWeapon() ].run or ACT_HL2MP_RUN
        local jump = weaponanimations[ self:GetWeapon() ] and weaponanimations[ self:GetWeapon() ].jump or ACT_HL2MP_JUMP_FIST

        if !self.loco:GetVelocity():IsZero() and self.loco:IsOnGround() and self:GetActivity() != run then
            self:StartActivity( run )
        elseif self.loco:GetVelocity():IsZero() and self.loco:IsOnGround() and self:GetActivity() != idle then
            self:StartActivity( idle )
        elseif !self.loco:IsOnGround() and self:GetActivity() != jump then
            self:StartActivity( jump )
        end

    end

end


function ENT:ControlMovement( update )
	local path = Path( "Follow" )

	path:SetMinLookAheadDistance( 100 )
	path:SetGoalTolerance( 10 )
	path:Compute( self, self.GoalPosition )

	if ( !path:IsValid() ) then return "failed" end

	while ( path:IsValid() ) do

        if self.PauseMovement then coroutine.yield() end

		path:Update( self )

		if developermode:GetBool() then
			path:Draw()
		end

		if ( self.loco:IsStuck() ) then

            HLMD_DebugText( self, " Got stuck at position ", self:GetPos() )

			self:HandleStuck()

			return "stuck"

		end

		if update then
			if path:GetAge() > 0.1 then path:Compute( self, self.GoalPosition ) end
		end

		coroutine.yield()

	end

    self.GoalPosition = nil

	return "ok"

end

function ENT:GetBonePosAngs(index)
    local pos,angle = self:GetBonePosition(index)
    if pos and pos == self:GetPos() then
      local matrix = self:GetBoneMatrix(index)
      if ismatrix(matrix) and matrix != nil then
        pos = matrix:GetTranslation()
      else
        return {Pos = (self:GetPos()+self:OBBCenter()),Ang = self:GetForward():Angle()}
      end
    elseif !pos then
      pos = self:GetPos()+self:OBBCenter()
    end
    return {Pos = pos,Ang = angle}
  end
  
  function ENT:GetAttachmentPoint(pointtype)
  
    if pointtype == "hand" then
  
      local lookup = self:LookupAttachment('anim_attachment_RH')
  
      if lookup == 0 then
          local bone = self:LookupBone("ValveBiped.Bip01_R_Hand")
        
          if !bone then
            return {Pos = (self:GetPos()+self:OBBCenter()),Ang = self:GetForward():Angle()}
          else
            if isnumber(bone) then
              return self:GetBonePosAngs(bone)
            else
              return {Pos = (self:GetPos()+self:OBBCenter()),Ang = self:GetForward():Angle()}
            end
          end
          
      else
  
        return self:GetAttachment(lookup)
      end
  
    elseif pointtype == "eyes" then
      
      local lookup = self:LookupAttachment('eyes')
  
      if lookup == 0 then
          return {Pos = self:GetPos()+self:OBBCenter()+Vector(0,0,5),Ang = self:GetForward():Angle()+Angle(20,0,0)}
      else
        return self:GetAttachment(lookup)
      end
  
    end
  
  end

function ENT:SwitchWeapon( classname )

    local attach = self:GetAttachmentPoint( "hand" )
    local id = self:LookupAttachment( "anim_attachment_RH" )

    local weapon = ents.Create( classname )
    weapon:SetPos( attach.Pos )
    weapon:SetAngles( attach.Ang )
    weapon:AddEffects( EF_BONEMERGE )
    weapon:SetParent( self, id )
    weapon:SetOwner( self )
    weapon:Spawn()

    self:SetWeapon( weapon.WeaponName )
    self:SetWeaponEntity( weapon )

end