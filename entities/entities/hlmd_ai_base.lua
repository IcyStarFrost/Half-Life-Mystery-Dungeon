AddCSLuaFile()

ENT.Base = "base_nextbot"


-- Optimize by localizing these so we don't have to go through a global table AND/OR go through the table holding these functions
local trace = util.TraceLine
local table_insert = table.insert
local table_Count = table.Count
local tracetbl = {}
local math_rad = math.rad
local math_sin = math.sin
local math_cos = math.cos
local math_clamp = math.Clamp
local math_abs = math.abs
local random = math.random
local developermode = GetConVar( "developer" )
local IsValid = IsValid
local expcolor = Color( 0,126,148)
local lvlupcol = Color( 0, 255, 157)

local targetsprite = Material( "hlmd/target.png" )

local ValidWeapons = {

	[ "Human" ] = {
		"hlmd_weapon_smg1",
	},

	[ "Combine" ] = {
		"hlmd_weapon_smg1",
	},

}

ENT.FootStepTrace = {}
ENT.NextFootstepSnd = 0
ENT.IsHLMDNPC = true
ENT.InputAllowed = true
ENT.PastEnemies = {}
ENT.PastWeapons = {}
ENT.Ammo = {}
ENT.HLMDType = ""
ENT.PauseMovement = nil
ENT.GoalPosition = nil
ENT.FaceTarget = nil
ENT.IsAttacking = false
ENT.AddedLevelhealth = 0
ENT.CanPassiveHeal = true
ENT.AllowAI = true

ENT.PreventAction = false


function ENT:SetupDataTables()

    self:NetworkVar( "Int", 0, "HLMDTeam" )
    self:NetworkVar( "Vector", 0, "DisplayColor" )
    self:NetworkVar( "Bool", 0, "PlayerControlled" )
    self:NetworkVar( "Bool", 1, "Alive")
    self:NetworkVar( "Entity", 0, "WeaponEntity" )
    self:NetworkVar( "Entity", 1, "Enemy" )
    self:NetworkVar( "String", 0, "Nickname" )
    self:NetworkVar( "String", 1, "State" )
    self:NetworkVar( "String", 2, "Weapon" )
    self:NetworkVar( "String", 3, "Personality" )

    -- Stats
    self:NetworkVar( "Int", 1, "Attack" )
    self:NetworkVar( "Int", 2, "Defense" )
    self:NetworkVar( "Int", 3, "Speed" )
    self:NetworkVar( "Int", 4, "Level" )
    self:NetworkVar( "Int", 5, "Evade" )
    self:NetworkVar( "Int", 6, "XP" )

    self:SetAlive( true )
    self:SetState( "wander" )

	if SERVER then
		self:NetworkVarNotify( "XP", function( ent, name, old, new ) self:OnGainXP( new ) end )
	end
end

-- Technically we aren't "gaining" as in increasing the number but it is what it is
function ENT:OnGainXP( CurrentXP )
	local leftover = 0

	if CurrentXP <= 0 then
		leftover = math_abs( CurrentXP )
		if self:InPlayerTeam() then
			HLMD_LogEvent( self:GetNickname() .. " leveled up! Lvl " .. self:GetLevel() .. " to " .. " Lvl" .. self:GetLevel() + 1, lvlupcol, "buff" )
		end
		self:SetUpHLMDStats( self:GetLevel() + 1, leftover )

		if self:InPlayerTeam() and ( !HLMD_NEXTLEVELUPSOUND or ( CurTime() > HLMD_NEXTLEVELUPSOUND ) ) then
			BroadcastLua( "sound.PlayFile( 'sound/hlmd/misc/levelup.mp3', '', function( sndchan, id, name ) end )" )
			HLMD_NEXTLEVELUPSOUND = CurTime() + 6
		end
	end
	
end

-- Settings stats based on level. xpminus is used as any leftovers from any level ups
function ENT:SetUpHLMDStats( level, xpminus )

  self:SetLevel( level )

  self.BaseAttack = self.BaseAttack + 2 * ( level )
  self.BaseDefense = self.BaseDefense + 2 * ( level )
  self.BaseSpeed = self.BaseSpeed + 2 * ( level )

  self:SetAttack( self.BaseAttack )
  self:SetDefense( self.BaseDefense )
  self:SetSpeed( self.BaseSpeed )
  self:SetEvade( self.BaseEvade )

  self:SetXP( ( 100 * ( 2 * level) ) - ( xpminus or 0 ) )

  if SERVER then
    self:SetMaxHealth( self.BaseHealth + self.AddedLevelhealth + 2 * ( level ) )
  end

end

-- Pretty much just randomizing stats through this
function ENT:RandomizeStats( level )

  self:SetLevel( level )

  self.BaseAttack = ( self.BaseAttack + 2 * ( level ) ) + random( -10, 10 )
  self.BaseDefense = ( self.BaseDefense + 2 * ( level ) ) + random( -10, 10 )
  self.BaseSpeed = ( self.BaseSpeed + 2 * ( level ) ) + random( -10, 10 )

  self.AddedLevelhealth = ( self:GetMaxHealth() + 2 * ( level ) ) + random( -10, 10 )

  self:SetXP( 100 * ( 2 * level) + random( -100, 0 ) )

  if SERVER then
    self:SetMaxHealth( self.AddedLevelhealth )
  end

  local limit = 2
  local i = 0

  for k, v in RandomPairs( ValidWeapons[ self.HLMDType ] ) do
	if i == limit then break end

	self.Weapons[ #self.Weapons + 1 ] = v

	i = i + 1
  end

  self:SetAttack( self.BaseAttack )
  self:SetDefense( self.BaseDefense )
  self:SetSpeed( self.BaseSpeed )
  self:SetEvade( self.BaseEvade )

end

-- For override

function ENT:AddonThink()
end

function ENT:AddonThread()
end

function ENT:OnRevive()
end

--


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
  if !self:GetAlive() then return end

    tracetbl.start = self:WorldSpaceCenter()
    tracetbl.endpos = self:WorldSpaceCenter() - Vector( 0, 0, 10000 )
    tracetbl.filter = self
	tracetbl.mask = MASK_NPCSOLID

    local result = trace( tracetbl )

	-- Inside this cam handles the little circle under the nextbot and the weapon range circle
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

          local find = HLMD_FindInSphere( self:GetPos(), self:GetWeaponEntity().Range, function( ent ) if ent.IsHLMDNPC and ent:GetAlive() and self:HasLOS( ent ) and ent != self and ent:GetHLMDTeam() != self:GetHLMDTeam() then return true end end )

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

    if self:GetPlayerControlled() and IsValid( self:GetEnemy() ) then -- Draws the target sprite above our target
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
    if !self:GetAlive() then return end

    self:SetAlive( false )
	self:DrawShadow( false )

	self:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )

    info:GetAttacker():OnEnemyKilled()

    HLMD_OnHLMDNPCKilled( self, info:GetAttacker(), info:GetInflictor() )

	if IsValid( self:GetWeaponEntity() ) then self:GetWeaponEntity():SetNoDraw( true ) self:GetWeaponEntity():DrawShadow( false ) end

	net.Start( "hlmd_ragdollhlmdnpc" )
	net.WriteEntity( self )
	net.WriteVector( self:GetDisplayColor() )
	net.WriteVector( info:GetDamageForce() )
	net.Broadcast()

end

function ENT:OnAttacked( attacker )

	if !IsValid( self:GetEnemy() ) or self:GetEnemy() != attacker then
		self:StopMovement()
		self:SetEnemy( attacker )
		self:SetState( "attackenemy" )
	end

end


function ENT:Revive()

	self:SetHealth( self:GetMaxHealth() )
	self:SetCollisionGroup( COLLISION_GROUP_NONE )
	self:DrawShadow( true )
	self:SetNoDraw( false )
	self:SetAlive( true )

	if IsValid( self:GetWeaponEntity() ) then self:GetWeaponEntity():SetNoDraw( false ) self:GetWeaponEntity():DrawShadow( true ) end

	net.Start( "hlmd_removedeathragdoll" )
	net.WriteEntity( self )
	net.Broadcast()

	self:OnRevive()

end


function ENT:Think()


    -- It is important that we have this up here so the health is still networked even when dead
    if SERVER then
      if !self.NextHealthNetwork or CurTime() > self.NextHealthNetwork then
        self:SetNWInt( "hlmd_health", math_clamp( self:Health(), 0, self:GetMaxHealth() ) )
        self:SetNWInt( "hlmd_maxhealth", self:GetMaxHealth() )
        self.NextHealthNetwork  = CurTime() + 0.1
      end
    end

    if !self:GetAlive() then return end

    self:AddonThink()

    if SERVER then

		if self.PreventAction and HLMD_PLAYERMOVING then
			HLMD_ResetPreventActions()
		end

		-- The AI should pull out a weapon
		if !self:GetPlayerControlled() and !IsValid( self:GetWeaponEntity() ) then self:ScrollWeapon() end

		local dist = self:InPlayerTeam() and 150 or 1000
		if !self:GetPlayerControlled() then

			local nearby  = HLMD_FindInSphere( self:GetPos(), dist, function( ent ) if ent.IsHLMDNPC and ent:GetAlive() and ent != self and ent:GetHLMDTeam() != self:GetHLMDTeam() then return true end end )

			local closest = self:GetClosestEntity( nearby )

			if IsValid( closest ) and self:GetEnemy() != closest then
				self:StopMovement()
				self:SetEnemy( closest )
				self:SetState( "attackenemy" )
			end
		end

		local speed = self.loco:GetVelocity():Length()

		-- Passive healing
		if self.CanPassiveHeal and self:Health() < self:GetMaxHealth() and speed > 0 and ( !self.NextPassiveHeal or CurTime() > self.NextPassiveHeal ) and self:GetHLMDTeam() == HLMD_PLAYERTEAM then
			
			self:SetHealth( self:Health() + 1 )

			self.NextPassiveHeal = CurTime() + 0.5
		end

        -- Footstep sounds
        if CurTime() > self.NextFootstepSnd and speed > 0 and self.loco:IsOnGround() then

            self.FootStepTrace.start = self:WorldSpaceCenter()
            self.FootStepTrace.endpos = self:WorldSpaceCenter() - Vector( 0, 0, 400 )
            self.FootStepTrace.filter = self
            local result = trace( self.FootStepTrace )

            if result.Hit then

                local loudness = ( self:GetPlayerControlled() and 0 or 70)
                self:EmitSound( HLMD_FootstepsTranslations[ result.MatType ], loudness )

                local nextSnd = math_clamp(0.25 * (self.loco:GetDesiredSpeed() / speed), 0.25, 0.35)
                self.NextFootstepSnd = CurTime() + nextSnd
            end
        end


		-- Animations are handled here
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
		--


		-- Facing a target or Vector
        if IsValid( self.FaceTarget ) then
          self.loco:FaceTowards( ( isentity( self.FaceTarget ) and self.FaceTarget:GetPos() or self.FaceTarget ) )
        end

    end

end


-- Gets the closest entity in a sequential table of entities
function ENT:GetClosestEntity( tbl )

	local entities = HLMD_FindInSphere( self:GetPos(), 1000, function( ent ) if ent.IsHLMDNPC and ent:GetAlive() and ent != self and ent:GetHLMDTeam() != self:GetHLMDTeam() then return true end end )

	local closest 
	local dist
	for k, v in ipairs( entities ) do
		if !closest and !dist then closest = v dist = self:GetRangeSquaredTo( v ) continue end

		local newdist = self:GetRangeSquaredTo( v )
		if newdist < dist then
			closest = v
			dist = newdist
		end
	end

	return closest
end

-- Say something in a text dialog box
function ENT:SayInTextBox( text )
	net.Start( "hlmd_addtextbar" )
		net.WriteString( self:GetNickname() )
		net.WriteString( self:GetModel() )
		net.WriteString( text )
		net.WriteVector( self:GetDisplayColor() )
	net.Broadcast()
end

-- Say something in a small box. This was a iffy recreation of small expressions in PMD DX when a pokemon attacks or gets hurt
function ENT:SayInBubble( text )
	net.Start( "hlmd_addtextbubble" )
		net.WriteEntity( self )
		net.WriteString( text )
	net.Broadcast()
end

-- In a sphere, simulates a use on everything found
function ENT:SimulateUse()

	local front = HLMD_FindInSphere( self:WorldSpaceCenter() + self:GetForward() * 50, 50 )

	for k, v in ipairs( front ) do
		if IsValid( v ) then v:Use( self, self, USE_TOGGLE ) end
	end
end


-- Find a random position and walk to it
function ENT:Wander()

	local navareas = {}

	for k, area in ipairs( navmesh.GetAllNavAreas() ) do
		if IsValid( area ) and area:GetSizeX() > 50 and area:GetSizeY() > 50 and !area:IsUnderwater() then
			navareas[ #navareas + 1 ] = area
		end
	end

	local targetspot = navareas[ random( #navareas ) ]:GetRandomPoint()

	if !targetspot then HLMD_DebugText( "ENT:Wander() had experienced a NIL targetspot! This should never happen! ..But it did" ) return end 

	HLMD_DebugText( self, " Moving to position ", targetspot )

	self.GoalPosition = targetspot
	self:ControlMovement()

end

function ENT:FollowPlayer()
	if self:GetRangeSquaredTo( Entity( 1 ).Nextbot ) < ( 100 * 100 ) then return end

	self.GoalPosition = Entity( 1 ).Nextbot
	self:ControlMovement( true, 100 )

end

function ENT:StopMovement()
	self.StopMoving = self.IsMoving
end

function ENT:InPlayerTeam()
	return self:GetHLMDTeam() == HLMD_PLAYERTEAM
end

function ENT:GetWeaponRange()
	return self:GetWeaponEntity().Range
end

function ENT:AttackState()
	if !IsValid( self:GetEnemy() ) or !self:GetEnemy():GetAlive() then self:SetState( "wander" ) return end

	if self:GetRangeSquaredTo( self:GetEnemy() ) > ( self:GetWeaponRange() * self:GetWeaponRange() ) or !self:HasLOS( self:GetEnemy() ) then

		self.GoalPosition = self:GetEnemy()
		self:ControlMovement( true, self:HasLOS( self:GetEnemy() ) and self:GetWeaponRange() - 50 or 30 )

	end

	if self:GetRangeSquaredTo( self:GetEnemy() ) < ( self:GetWeaponRange() * self:GetWeaponRange() ) then
		self:AttackEnemy()
	end

end

local statefunctions = {
	[ "wander" ] = ENT.Wander,
	[ "followplayer" ] = ENT.FollowPlayer,
	[ "attackenemy" ] = ENT.AttackState
}


-- Where the AI is handled.
-- These (if then return end) functions are mainly part of the Turn based combat stuff.
-- This was the best way I could come up with
function ENT:AIFunc()
	if self:GetPlayerControlled() or !self:GetAlive() then return end
	if HLMD_AttackActive then return end
	if self:GetHLMDTeam() == HLMD_PLAYERTEAM and HLMD_ENEMYTURN then return end
	if self:GetHLMDTeam() == HLMD_PLAYERTEAM and ( !HLMD_PLAYERMOVING and !HLMD_PLAYERTEAMTURN ) then return end
	if self:GetHLMDTeam() != HLMD_PLAYERTEAM and HLMD_PLAYERTEAMTURN then return end
	if self:GetHLMDTeam() != HLMD_PLAYERTEAM and ( !HLMD_PLAYERMOVING and !HLMD_ENEMYTURN ) then return end
	if self.PreventAction then return end
  
  

	if self.AllowAI then

		if self:InPlayerTeam() then
			if !IsValid( self:GetEnemy() ) or !self:GetEnemy():GetAlive() then self:SetState( "followplayer" ) end
			
			statefunctions[ self:GetState() ]( self )
		else
			statefunctions[ self:GetState() ]( self )
		end

	end

end

function ENT:RunBehaviour()

	while true do

		self:AIFunc()

		self:AddonThread()

		coroutine.wait( 0.1 )
	end

end

-- It took me a while to figure out how to get a turn based system down. It might not be perfect but that's alright if there's a better way I'm sure someone would tell me
function ENT:UpdateOnPath( path )
  if HLMD_AttackActive then return end
  if self:GetHLMDTeam() == HLMD_PLAYERTEAM and HLMD_ENEMYTURN then return end
  if self:GetHLMDTeam() == HLMD_PLAYERTEAM and ( !HLMD_PLAYERMOVING and !HLMD_PLAYERTEAMTURN ) then return end
  if self:GetHLMDTeam() != HLMD_PLAYERTEAM and HLMD_PLAYERTEAMTURN then return end
  if self:GetHLMDTeam() != HLMD_PLAYERTEAM and ( !HLMD_ENEMYTURN and !HLMD_PLAYERMOVING ) then return end
  if self.PreventAction then return end

	path:Update( self )
end

-- Main movement with pathfinding
function ENT:ControlMovement( update, stopdist )
	if stopdist then stopdist = stopdist + self:GetModelRadius()/2 end
	if stopdist and self:GetRangeSquaredTo( self.GoalPosition ) < ( stopdist * stopdist ) then return end 
	local path = Path( "Follow" )

	path:SetMinLookAheadDistance( 100 )
	path:SetGoalTolerance( 10 )
	path:Compute( self, ( isentity( self.GoalPosition ) and self.GoalPosition:GetPos() or self.GoalPosition) )

	if ( !path:IsValid() ) then HLMD_DebugText( self, " Path was invalid " ) return "failed" end

	self.IsMoving = true


	while ( path:IsValid() and self:GetAlive() and !self:GetPlayerControlled()  ) do
		if self.StopMoving then self.StopMoving = false break end
		if stopdist and self:GetRangeSquaredTo( self.GoalPosition ) < ( stopdist * stopdist ) then break end

		self:UpdateOnPath( path )

		if developermode:GetBool() then
			path:Draw()
		end

		if ( self.loco:IsStuck() ) then

            HLMD_DebugText( self, " Got stuck at position ", self:GetPos() )

			self:HandleStuck()
			self.IsMoving = false

			return "stuck"

		end

		if update then
			if path:GetAge() > 0.1 then path:Compute( self, ( isentity( self.GoalPosition ) and self.GoalPosition:GetPos() or self.GoalPosition) ) end
		end

		coroutine.yield()

	end

	self.IsMoving = false

    self.GoalPosition = nil

	return "ok"

end

-- Attachments stuff
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

-- Cycle through enemies
function ENT:ChangeEnemy()
  if !IsValid( self:GetWeaponEntity() ) then return end
  local find = HLMD_FindInSphere( self:GetPos(), self:GetWeaponEntity().Range, function( ent ) if ent.IsHLMDNPC and ent:GetAlive() and self:HasLOS( ent ) and ent != self and ent:GetHLMDTeam() != self:GetHLMDTeam() then return true end end )
  
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

-- Not sure what to say for this
function ENT:OnAction()
	self.PreventAction = true
end

function ENT:OnEnemyKilled()
	local enemylevel = self:GetEnemy():GetLevel()
	local addxp = ( ( 5 * enemylevel ) + random( 0, 10) ) * HLMD_EXPMULT
	self:SetEnemy( NULL )
	self.PastEnemies = {}

	if self:InPlayerTeam() then
		timer.Simple( 1, function()
			for k, v in ipairs( HLMD_GetPlayerTeamMembers() ) do
				HLMD_AddHudIndicator( v, "+" .. addxp .. " XP", expcolor )
				HLMD_DebugText( v, " Gained " .. addxp .. " XP")
				v:SetXP( v:GetXP() - addxp )
			end
		end )
	else
		HLMD_DebugText( self, " Gained " .. addxp .. " XP")
		self:SetXP( self:GetXP() - addxp )
	end
end

local lostbl = {}

function ENT:HasLOS( ent )
	lostbl.start = self:WorldSpaceCenter()
	lostbl.endpos = ent:WorldSpaceCenter()
	lostbl.filter = self

	local result = trace( lostbl )

	return result.Entity == ent
end

function ENT:AttackEnemy()
	if !IsValid( self:GetWeaponEntity() ) then HLMD_DebugText( self, " Tried to attack a target with no weapon! ", debug.traceback() ) return end
	if !IsValid( self:GetEnemy() ) then HLMD_DebugText( self, " Tried to attack a non existent enemy! ", debug.traceback() ) return end
	if self:GetRangeSquaredTo( self:GetEnemy() ) > ( self:GetWeaponEntity().Range * self:GetWeaponEntity().Range ) then HLMD_DebugText( self, " Tried to attack from a range their weapon can't reach!") return end
	if !self:HasLOS( self:GetEnemy() ) then HLMD_DebugText( self, " Tried to attack a target that is out of sight!" ) return end
	if self.IsAttacking or HLMD_AttackActive then return end
	if self.PreventAction then return end

	-- Parts of this code is how I got the turn based stuff down

	self.FaceTarget = self:GetEnemy()
	self.IsAttacking = true
 	HLMD_AttackActive = true

	if !self:GetPlayerControlled() then
		self:OnAction()
	else
		HLMD_ResetPreventActions()
	end
	
	local enemy = self:GetEnemy()

	timer.Simple( math.Rand( 0.3, 1 ), function() 

		self:GetWeaponEntity():FireWeapon( function()
		
			self.FaceTarget = nil 
			self.IsAttacking = false 
			HLMD_AttackActive = false

			if enemy:GetAlive() then
				enemy:OnAttacked( self )
			end
			
			if self:InPlayerTeam() then
				HLMD_EnemyTurn( 0.8 )
			else
				HLMD_PlayerTeamTurn( 0.8 )
			end
		
    	end )
	end )

end

function ENT:ScrollWeapon()

	if table_Count( self.PastWeapons ) == #self.Weapons then self.PastWeapons = {} end

	for k, v in RandomPairs( self.Weapons ) do
		if !self.PastWeapons[ v ] and ( IsValid( self:GetWeaponEntity() ) and self:GetWeaponEntity():GetClass() != v or !IsValid( self:GetWeaponEntity() ) ) then
			
			self:SwitchWeapon( v )
			self.PastWeapons[ v ] = v
		end
	end

end

function ENT:SwitchWeapon( classname )
	if IsValid( self:GetWeaponEntity() ) and self:GetWeaponEntity():GetClass() == classname then return elseif IsValid( self:GetWeaponEntity() ) and classname != self:GetWeaponEntity():GetClass() then self.Ammo[ self:GetWeaponEntity():GetClass() ] = self:GetWeaponEntity().Clip self:GetWeaponEntity():Remove() end
	
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

	timer.Simple( 0, function()
		weapon.Clip = self.Ammo[ classname ] or weapon.Clip
	end )

	if IsValid( self:GetOwner() ) then
		local dist = weapon.Range > 500 and weapon.Range or 500

		net.Start( "hlmd_setviewdistance" )
		net.WriteUInt( dist + 200 , 16 )
		net.Send( self:GetOwner() )
	end

end