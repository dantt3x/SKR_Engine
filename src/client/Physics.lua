local Physics = {
	DriftMode = "Outside",
	Utility = "None",
	
	currentDriftPower = 0,
	currentBoost = 0,
	currentSpeed = 0,
	currentSteer = 0,
	currentGravity = 0,
	
	goalSpeed = 0,
	goalSteer = 0,
	goalGravity = 0,
	
	speedBoost = 1,
	driftLevel = 0,
	powerShift = 0,

	dt = 0.0001,
	lastCheckpoint = 1,
	lastTrickTick = tick(),
	crashedTick = tick(),
	fallingTick = tick(),

	--{STATES}
	drifting = false,
	boosting = false,
	tricked = false,
	crashing = false,
	outOfBounds = false,
	recovering = false,
	shocked = false,
	hacked = false,
	falling = false,
	invincible = false,
	in_cannon = false,
	
	Body = nil :: Part,
	Mover = nil :: Part,
	Character = nil :: Model,
}
Physics.__index = Physics
local RunService = game:GetService("RunService")
local Config = require(script.Config)
local Zones = require(script.Zones)

local LocalPlayer = game.Players.LocalPlayer

--{KART_STATS}
local RaceSpeed = 150 -- 150-200
local Speed = 10 -- 1-10
local Acceleration = 10 -- 1-10
local Weight = 10 -- 1-10
local Handling = 10 -- 1-10

--{POWERS}
local GravityP = 50
local DriftP = 3
local DBoostP = 100
local TrickP = 75

--{COEFFICIENTS}
local DriftingC = .7 -- 0-1
local GravityC = 1 -- 0-1
local FrictionC = .1 --0-1
local TurnC = .2 --0-1

--{FORCES}
local GravityF = 198.2

--{TIME}
local Time = 10

--{VECTORS}
local XZLock = Vector3.new(1,0,1)
local YLock = Vector3.new(0,1,0)

--{HELPER}
local Math = require(script.Parent.Parent.Library.Math)

--{PARAMS}
local gravityParams = RaycastParams.new()
gravityParams.FilterType = Enum.RaycastFilterType.Exclude
gravityParams.RespectCanCollide = true

local bumpParams = RaycastParams.new()
bumpParams.CollisionGroup = "BumpCheck"
bumpParams.RespectCanCollide = true
bumpParams.FilterType = Enum.RaycastFilterType.Exclude

local shockTimer = tick()
local hackTimer = tick()

local function isPlayerHurtable(self): boolean
	local canHurt = true
	
	if self.invincible or self.recovering or self.in_cannon then
		canHurt = false
	end
	
	return canHurt
end

local function Force(self)
	local BodyCF: CFrame = self.Body.CFrame
	local RightV: Vector3 = BodyCF.RightVector
	local LookV: Vector3 = BodyCF.LookVector
	
	local PushF: VectorForce = self.Mover.Push
	local DragF: VectorForce = self.Mover.Drag
	local FrictionF: LinearVelocity = self.Mover.FrictionF
	local TurnF: LinearVelocity = self.Mover.Turn
	
	local AssemblyVel: Vector3 = self.Mover.AssemblyLinearVelocity
	
	local function Push()
		local Direction: number = self.Input.Accelerate
		local Drifting: boolean = self.Input.Drifting
		local DriftDirection = self.Input.DriftDirection
		local DirectionMax: number = math.max(Direction, -0.85)
		
		if self.crashing then
			self.goalSpeed = 0
		else
			if self.falling == false then
				local boost = self.boosting == true and 1 or DirectionMax

				-- maximum should be 8 with speed boosts

				local speed = math.clamp(5.25 * (Speed/10) * (Time/10), 2.25, 5.25) * (self.invincible and 1.15 or 1) * (self.powerShift * 1.15 / 10) * self.speedBoost

				--		dt * math.clamp(1.25 * (Handling/10) * (Time/10), .75, (Time/10) + .25)
				local speed = (math.max(Time,8) + (Speed/10)) * (self.invincible and 1.15 or 1) * math.max(self.powerShift * 1.15 / 10, 1) * self.speedBoost
				local reduction = self.shocked and 3 or 0
				speed -= reduction
				self.goalSpeed = speed * boost		
			end
		end
				
		self.currentSpeed = Math.Lerp(
			self.currentSpeed,
			self.goalSpeed,
			Acceleration * self.dt * (Direction == 0 and .5 or 1)
		)
		
		--print(self.goalSpeed, self.currentSpeed, self.falling)
				
		local Vector = LookV
		if Drifting then
			if self.DriftMode == "Outside" then
				Vector = ((LookV + (RightV*DriftDirection)))
			elseif self.DriftMode == "Inside" then
				Vector = CFrame.Angles(0,math.rad(20 * DriftDirection),0):VectorToWorldSpace(LookV)
			end
		end

		PushF.Force = (
			Vector * 
				(self.currentSpeed * math.abs(self.currentSpeed) * RaceSpeed * 
					(Drifting and DriftingC or 1))	
		)
		
		if PushF.Force.Magnitude < 5 then
			PushF.Force = Vector3.zero
		end

		XZLock = LookV * Vector3.new(1,0,1)
	end
	
	local function Drag()
		if AssemblyVel.Magnitude > 1 then
			local dragForce: Vector3 = -AssemblyVel.Unit * (AssemblyVel.Magnitude^2)

			if dragForce ~= dragForce then -- NaN check
				return
			end

			DragF.Force = dragForce
		else
			DragF.Force = Vector3.zero
		end
	end
	
	local function Friction()
		if self.goalSpeed == 0 and self.grounded then
			if AssemblyVel.Magnitude < 5 then
				self.Mover.AssemblyLinearVelocity = Vector3.zero
				FrictionF.VectorVelocity = Vector3.zero
			else
				local frictionForce = -AssemblyVel.Unit * FrictionC

				if frictionForce ~= frictionForce then
					return
				end

				FrictionF.VectorVelocity = frictionForce
			end
		else
			FrictionF.VectorVelocity = Vector3.zero
		end
	end
	
	local function Turn()
		-- somehow works, the normalized dot product is the direction, multiplied by the magnitude against the right vector of the part gg
		local turnVelocity = -AssemblyVel.Unit:Dot(RightV.Unit) * AssemblyVel.Magnitude * TurnC * RightV
		if turnVelocity ~= turnVelocity then 
			TurnF.VectorVelocity = Vector3.zero
			return 
		end
		TurnF.VectorVelocity = turnVelocity
	end
	
	Drag()
	Friction()
	Push()
	Turn()
end

local function Gravity(self)
	gravityParams.FilterDescendantsInstances = {self.Mover, self.Character}

	local Mover: Part = self.Mover
	local Body: Part = self.Body
	local BodyCFrame: CFrame = Body.CFrame
	local UpVector = BodyCFrame.UpVector

	local Gravity: VectorForce = Mover.Gravity
	local Floor: LinearVelocity = Mover.Floor
	local Push: VectorForce = Mover.Push

	Gravity.Force = Vector3.zero
	Floor.VectorVelocity = Vector3.zero

	local raycastHit: RaycastResult = workspace:Raycast(
		Mover.Position, 
		-UpVector * 8, 
		gravityParams
	)

	local normal = YLock

	if raycastHit then
		if self.falling and (tick() - self.fallingTick > .25) then
			self.Kart:Landed(LocalPlayer)
		end
	
		self.falling = false
		self.tricked = false
		self.currentGravity = 0
		
		Gravity.Enabled = false
		Floor.Enabled = true
		normal = raycastHit.Normal
		Floor.VectorVelocity = DriftingC * GravityF^2 * -UpVector
	else
		if self.falling == false then
			self.fallingTick = tick()
		end
		
		self.falling = true
		Gravity.Enabled = true
		Floor.Enabled = false
		
		self.currentGravity = Math.Lerp(
			self.currentGravity, 
			GravityF * GravityP, 
			self.dt * Time * GravityC
		)
			
		Gravity.Force = -(YLock * Push.Force) + -(YLock * self.currentGravity)
	end

	local rotation = Math.getRotationBetween(UpVector, normal, Vector3.new(1,0,0))
	local goalCFrame = rotation * BodyCFrame
	self.Body.CFrame = goalCFrame
end

local function Steer(self)
	if self.falling then 
		return
	end

	local BodyCFrame: CFrame = self.Body.CFrame
	local DriftDirection: number = self.Input.DriftDirection
	local Accelerate: number = self.Input.Accelerate
	local SteerInput: number = self.Input.Steer
	local Steer: number = SteerInput * (Accelerate == 0 and 1 or Accelerate)

	if self.Input.Drifting then
		Steer = SteerInput + DriftDirection
		if Steer == 0 then
			Steer = 0.25 * DriftDirection
		end
	end

	self.Body.CFrame = BodyCFrame:Lerp(
		BodyCFrame * CFrame.fromEulerAnglesXYZ(
			0,
			BodyCFrame.Rotation.Y + Steer,
			0
		),

		self.dt * (Time / (10 - (Handling*.325)))
	)
end

local function DBoost(self)
	local change = self.dt * Time * DBoostP
	self.currentBoost = math.max(self.currentBoost - change, 0)

	if self.currentBoost == 0 then
		self.speedBoost = 1
		self.boosting = false
	end
end

local function DBuff(self)
	if self.shocked then
		if tick() - shockTimer > 4 then
			self.shocked = false
			self.Atmosphere:ShockEnded()
		end
	end
	
	if self.hacked then
		if tick() - hackTimer > 3 then
			self.hacked = false
			self.Atmosphere:HackEnded()
		end
	end
end

local function Drift(self)
	local Steer: number = self.Input.Steer
	local DriftDirection: number = self.Input.DriftDirection
	local isDrifting: boolean = self.Input.Drifting
	local powerChange = self.dt * Time * DriftP * math.max(math.abs(Steer + DriftDirection), 1)

	if isDrifting and self.falling == false and (self.spinningOut or self.outOfBounds) == false then
		if self.drifting == false then
			self.drifting = true
			self.Kart:Drift(LocalPlayer)
		end
		
		self.currentDriftPower = math.min(self.currentDriftPower + powerChange, 100)

		if self.currentDriftPower >= 33 and self.driftLevel == 0 then
			self.driftLevel = 1
			self.Kart:DriftLevel(LocalPlayer, 1)
		elseif self.currentDriftPower >= 66 and self.driftLevel == 1 then
			self.driftLevel = 2
			self.Kart:DriftLevel(LocalPlayer, 2)
		elseif self.currentDriftPower >= 99 and self.driftLevel == 2 then
			self.driftLevel = 3
			self.Kart:DriftLevel(LocalPlayer, 3)
		end
		
	elseif isDrifting == false then
		if self.driftLevel ~= 0 then
			local boostPower = 1.15
			local boostDuration = 50
			boostPower += self.driftLevel == 2 and .1 or (self.driftLevel == 3 and .35 or 0)
			boostDuration += self.driftLevel == 2 and 10 or (self.driftLevel == 3 and 25 or 0)
			self:Boost(boostPower, boostDuration)
		end

		self.driftLevel = 0
		self.drifting = false
		self.currentDriftPower = 0
	end
end

local function Bump(self)
	bumpParams.FilterDescendantsInstances = {self.Mover, self.Body}
	
	local Mover: Part = self.Mover
	local Velocity: number = Mover.AssemblyLinearVelocity.Magnitude
	local BodyCFrame: CFrame = self.Body.CFrame
	local marginOfDis = .01 -- how much farther outside the model should the raycast go
	local power = (Velocity * (Velocity * (1/Weight)))

	local function Cast(Direction)		
		local posCast = workspace:Raycast(
			BodyCFrame.Position,
			((Direction + (Direction * marginOfDis))) * (Mover.Size.X/2),
			bumpParams
		)

		local negCast = workspace:Raycast(
			BodyCFrame.Position,
			((-Direction + (-Direction * marginOfDis))) * (Mover.Size.X/2),
			bumpParams
		)

		if posCast and negCast then else
			
			if self.Utility == "PlayingItSmooth" then
				if (tick()-self.lastTrickTick) > .3 then else	
					local collidePos: BasePart = posCast.Instance
					local collideNeg: BasePart = negCast.Instance
					
					if collidePos.CollisionGroup == "Kart" or collideNeg.CollisionGroup == "Kart" then
						self:Boost(1.15, 50)
						self.Kart:Tricked(LocalPlayer, "Neutral")
						return
					end
				end
			end
			
			if posCast or negCast then
				self:Crash(0)
				self.Input:CancelDrift()
				self.currentSpeed /= 2
				self.currentDriftPower = 0
			end
			
			if posCast then
				Mover:ApplyImpulse(-Direction * power)
			
			elseif negCast then
				Mover:ApplyImpulse(Direction * power)
			end
		end
	end

	if Velocity > 25 then
		local LookVector = BodyCFrame.LookVector
		local RightVector = BodyCFrame.RightVector
		Cast(LookVector)
		Cast(RightVector)
	end
end

function Physics:ResetForces()
	if self.Mover == nil then
		return
	end
	
	local Push: VectorForce = self.Mover.Push
	local Drag: VectorForce = self.Mover.Drag
	local Friction: LinearVelocity = self.Mover.FrictionF
	local Turn: LinearVelocity = self.Mover.Turn	
	local Gravity: VectorForce = self.Mover.Gravity
	local Floor: LinearVelocity = self.Mover.Floor

	self.Mover.AssemblyLinearVelocity = Vector3.zero
	Push.Force = Vector3.zero
	Drag.Force = Vector3.zero
	Friction.VectorVelocity = Vector3.zero
	Turn.VectorVelocity = Vector3.zero
	Gravity.Force = Vector3.zero
	Floor.VectorVelocity = Vector3.zero
end

function Physics:Crash(duration)
	if isPlayerHurtable(self) and self.crashing == false then
		if tick() - self.crashedTick < .05 then
			return
		end
		
		
		self.crashedTick = tick()
		self.crashing = true
		self.crashDuration = duration
		
		if duration > .25 then
			self:RemoveCoin(3)
		end
		
		self.Input:CancelDrift()
		self.Kart:Crashed(LocalPlayer, duration)
		
		task.delay(duration, function()
			self.crashing = false
		end)
	end
end

function Physics:Boost(boostPower: number, boostDuration: number)
	self.currentSpeed = self.goalSpeed
	
	if self.boosting then
		if self.speedBoost > boostPower then
			self.currentBoost += boostDuration * .325
			boostPower = self.speedBoost
			boostDuration = self.currentBoost
		else
			self.speedBoost = boostPower
			self.currentBoost = math.max(boostDuration, self.currentBoost)
			boostDuration = self.currentBoost
		end
	else
		self.boosting = true
		self.speedBoost = boostPower
		self.currentBoost = boostDuration
	end
	
	self.Camera:AddBoost(boostPower, boostDuration)
	self.Kart:Boost(LocalPlayer, boostPower, boostDuration)
end

function Physics:Trick(direction: string)
	local BodyCFrame = self.Body.CFrame 
	
	local Directions = {
		Neutral = BodyCFrame.LookVector,
		Forward = BodyCFrame.LookVector,
		Left = -BodyCFrame.RightVector,
		Right = BodyCFrame.RightVector,
	}
	
	if self.Utility == "PlayingItSmooth" then
		self.lastTrickTick = tick()
	end

	if Directions[direction] and self.tricked == false and self.falling then
		self.Mover:ApplyImpulse(Directions[direction] * TrickP)	
		self:Boost(1.15, 50)
		self.Kart:Tricked(LocalPlayer, direction)
		self.tricked = true
	end
end

function Physics:AddCoin(count: number)
	self.powerShift = math.min(self.powerShift + count, 10)
	self.Gui:SetPowerShift(self.powerShift)
end

function Physics:RemoveCoin(count: number)
	if self.Utility == "StrongRecovery" then
		count = math.floor(count / 2)
	end
	
	self.powerShift = math.min(self.powerShift - count, 0)
	--self.Gui:SetPowerShift(self.powerShift)
end

function Physics:ResetToLastCheckpoint()
	self.recovering = true
	
	task.delay(3, function()
		self.recovering = false
	end)
end

function Physics:SetKartAnchor(anchor: boolean)
	self.Mover.Anchored = anchor
end

function Physics:SetGravity(direction: Vector3)
	YLock = direction
end

function Physics:SetInvincibility(invincBool: boolean)
	self.invincible = invincBool
end

function Physics:Shock()
	if isPlayerHurtable(self) then
		self:Crash(2)
		self.Atmosphere:Shock()
		self.shocked = true
		shockTimer = tick()
	end
end

function Physics:Hack()
	if isPlayerHurtable(self) then
		self.Atmosphere:Hack()
		self.hacked = true
		hackTimer = tick()
	end
end

function Physics:AtmosphereChanged(...)
	self.Atmosphere:Changed(...)
end

function Physics:ConfigUpdate(config: string, newValue: number)
	local case = {
		Speed= 			function() Speed=        newValue 		end,
		Handling=  		function() Handling=     newValue  		end,
		Weight= 		function() Weight=       newValue 		end,
		Acceleration=   function() Acceleration= newValue  		end,
		GravityP= 		function() GravityP=     newValue 		end,
		DriftP= 		function() DriftP=       newValue 		end,
		DBoostP= 		function() DBoostP=      newValue 		end,
		TrickP= 		function() TrickP=       newValue 		end,
		DriftingC= 		function() DriftingC=    newValue 		end,
		GravityC= 		function() GravityC=     newValue 		end,
		FrictionC= 		function() FrictionC=    newValue 		end,
		TurnC= 			function() TurnC=        newValue 		end,
		Time= 			function() Time=         newValue 		end,
	}
	
	if RunService:IsStudio() then 
		if case[config] then
			case[config](newValue)
		end
	end
end

function Physics:RunKart(Body: Part, Mover: Part, Character: Model)
	self.isRunning = true
	self.Camera:FollowKart()
	
	local kartJanitor = self.Janitor.new()
	kartJanitor:LinkToInstances(Body, Mover, Character)
	Mover.AssemblyLinearVelocity = Vector3.zero
	
	Config.Listen(self, kartJanitor)
	
	kartJanitor:Add(
		RunService.PreSimulation:Connect(function(dt)
			if self.recovering or self.in_cannon then else
				Gravity(self)
				Force(self)
				Bump(self)
			end
		end)
	)
	
	kartJanitor:Add(
		RunService.PostSimulation:Connect(function(dt)
			self.dt = dt
			DBoost(self)
			DBuff(self)

			if self.recovering or self.crashing or self.in_cannon or self.Mover.Anchored then else
				Drift(self)
				Steer(self)
			end	

			Body.Position = Mover.Position	 

			Zones.Update(self)
		end)
	)
	
	kartJanitor:Add(function()
		self.Body = nil
		self.Mover = nil
		self.Character = nil
		self.isRunning = false
	end)
end

function Physics:LoadVehicleData(vehicle: string, wheel: string, utility: string)
	self.utility = utility
end

function Physics:Init(Client)
	self.Camera = Client.Camera
	self.Input = Client.Input
	self.Kart = Client.Kart
	self.Gui = Client.Gui
	self.Atmosphere = Client.Atmosphere
	self.Janitor = require(script.Parent.Parent:FindFirstChild("Janitor", true))
	
	local Karts: Folder = workspace:WaitForChild("Karts")
	local Body: Folder = Karts.Body
	local Mover: Folder = Karts.Mover	
	
	self.Body = nil
	self.Mover = nil
	self.Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()	
	self.isRunning = false	
	
	local function checkIfKartCanRun()
		if self.isRunning then else
			if self.Body and self.Mover and self.Character then
				print("RUNNING KART")
				self:RunKart(self.Body, self.Mover, self.Character)
			end
		end
	end

	Body.ChildAdded:Connect(function(newChild)
		if newChild.Name == LocalPlayer.Name then
			self.Body = newChild
			checkIfKartCanRun()
		end
	end)
	
	Mover.ChildAdded:Connect(function(newChild)
		print("NewMoverAdded")
		if newChild.Name == LocalPlayer.Name then
			self.Mover = newChild
			checkIfKartCanRun()
		end
	end)
	
end

return setmetatable(Physics, {})
