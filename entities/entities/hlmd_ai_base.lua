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
local math_abs = math.abs
local developermode = GetConVar( "developer" )
local IsValid = IsValid

local targetsprite = Material( "hlmd/target.png" )

ENT.FootStepTrace = {}
ENT.NextFootstepSnd = 0
ENT.IsHLMDNPC = true
ENT.InputAllowed = true
ENT.PastEnemies = {}
ENT.PauseMovement = nil
ENT.GoalPosition = nil
ENT.FaceTarget = nil
ENT.IsAttacking = false

function ENT:SetupDataTables()

    self:NetworkVar( "Int", 0, "HLMDTeam" )
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

        col.a = math_abs( math_sin( SysTime() * 2 ) * 50 )


        surface.SetDrawColor( col.r, col.g, col.b, col.a )
        draw.NoTexture()

        draw_Circle( 0, 0, self:GetModelRadius() / 2, 32 )

        if self:GetPlayerControlled() and IsValid( self:GetWeaponEntity() ) then 

          local r = 0
          local g = 255

          local find = HLMD_FindInSphere( self:GetPos(), self:GetWeaponEntity().Range, function( ent ) if ent.IsHLMDNPC and ent != self and ent:GetHLMDTeam() != self:GetHLMDTeam() then return true end end )

          if #find > 0 then
            r = 255
            g = 0
          end

          surface.DrawCircle( 0, 0, self:GetWeaponEntity().Range, r, g, 0, 200 ) 

          surface.DrawCircle( 0, 0, self:GetWeaponEntity().Range - 1, 0, 0, 0, 200 ) 
          surface.DrawCircle( 0, 0, self:GetWeaponEntity().Range + 1, 0, 0, 0, 200 ) 

        end

        render.DepthRange( 0, 1 )

    cam.End3D2D()

    if self:GetPlayerControlled() and IsValid( self:GetEnemy() ) then
      render.SetMaterial( targetsprite )
      local maxz = self:GetEnemy():OBBMaxs()
      maxz[ 1 ] = 0
      maxz[ 2 ] = 0
      maxz[ 3 ] = maxz[ 3 ] + 100
      render.DrawSprite( ( self:GetEnemy():GetPos() + maxz ), 32, 32, color_white ) 
    end 

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

        local idle = IsValid( self:GetWeaponEntity() ) and self:GetWeaponEntity().Animations.idle or ACT_HL2MP_IDLE
        local run = IsValid( self:GetWeaponEntity() ) and self:GetWeaponEntity().Animations.run or ACT_HL2MP_RUN
        local jump = IsValid( self:GetWeaponEntity() ) and self:GetWeaponEntity().Animations.jump or ACT_HL2MP_JUMP_FIST

        if !self.loco:GetVelocity():IsZero() and self.loco:IsOnGround() and self:GetActivity() != run then
            self:StartActivity( run )
        elseif self.loco:GetVelocity():IsZero() and self.loco:IsOnGround() and self:GetActivity() != idle then
            self:StartActivity( idle )
        elseif !self.loco:IsOnGround() and self:GetActivity() != jump then
            self:StartActivity( jump )
        end


        if IsValid( self.FaceTarget ) then
          self.loco:FaceTowards( ( isentity( self.FaceTarget ) and self.FaceTarget:GetPos() or self.FaceTarget ) )
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


function ENT:ChangeEnemy()
  if !IsValid( self:GetWeaponEntity() ) then return end
  local find = HLMD_FindInSphere( self:GetPos(), self:GetWeaponEntity().Range, function( ent ) if ent.IsHLMDNPC and ent != self and ent:GetHLMDTeam() != self:GetHLMDTeam() then return true end end )
  
  for k, v in ipairs( find ) do
    if !self.PastEnemies[ v ] and v != self:GetEnemy() then
      self:SetEnemy( v )
      HLMD_DebugText( self, " Has chosen a new target! ", v)
      self.PastEnemies[ v ] = v
      return
    end
  end

  self.PastEnemies = {}
  self:SetEnemy( NULL )
  HLMD_DebugText( self, " Doesn't have anyone near them or their enemies are in the past! Cleaning PastEnemies Table..")

end

function ENT:AttackEnemy()
  if !IsValid( self:GetWeaponEntity() ) then HLMD_DebugText( self, " Tried to attack a target with no weapon! ", debug.traceback() ) return end
  if !IsValid( self:GetEnemy() ) then HLMD_DebugText( self, " Tried to attack a non existent enemy! ", debug.traceback() ) return end
  if self:GetRangeSquaredTo( self:GetEnemy() ) > ( self:GetWeaponEntity().Range * self:GetWeaponEntity().Range ) then HLMD_DebugText( self, " Tried to attack from a range their weapon can't reach!") return end

  self.InputAllowed = false
  self.FaceTarget = self:GetEnemy()
  self.IsAttacking = true

  timer.Simple( math.Rand( 0.3, 1 ), function() 
    self:GetWeaponEntity():FireWeapon( function() self.FaceTarget = nil self.InputAllowed = true self.IsAttacking = false end )
  end )

end

function ENT:SwitchWeapon( classname )
  if IsValid( self:GetWeaponEntity() ) and self:GetWeaponEntity():GetClass() == classname then return end

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

  if IsValid( self:GetOwner() ) then
    local dist = weapon.Range > 500 and weapon.Range or 500

    net.Start( "hlmd_setviewdistance" )
    net.WriteUInt( dist + 200 , 16 )
    net.Send( self:GetOwner() )
  end

end