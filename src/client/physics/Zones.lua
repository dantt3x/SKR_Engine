local Zones = {}
local Interactables = workspace:WaitForChild("Interactables")

local _Catchnet = Interactables.Catchnet
local _Bounce = Interactables.Bounce
local _Boost = Interactables.Boost
local _Velocity = Interactables.Velocity
local _Cannon = Interactables.Cannon
local _Generic = Interactables.Generic
local _Atmosphere = Interactables.Atmosphere
local _Gravity = Interactables.Gravity
local _Crash = Interactables.Crash

local ZoneParams = OverlapParams.new()
ZoneParams.CollisionGroup = "Interactables"
ZoneParams.MaxParts = 16
ZoneParams.RespectCanCollide = false

local insideGravityZone = false
local insideAtmosphereZone = false
local lastBounce: Part = nil
local lastBoost: Part = nil
local lastCrash: Part = nil
local lastGrav: Part = nil
local lastAtmosphere: Part = nil
local cannonPoint = nil

local active_gen = {}
local active_vel = {}
local vel_obj = {}

local function Catchnet(self, catchZone: Part)
	if self.recovering == false then
		self:ResetToLastCheckpoint()
	end
end

local function Boost(self, boostZone: Part)
	if lastBoost == boostZone then else
		lastBoost = boostZone
		local Multiplier = boostZone:GetAttribute("Multiplier")
		local Duration = boostZone:GetAttribute("Duration")
		self:Boost(Multiplier,Duration)
		
		task.delay(2, function()
			if lastBoost == boostZone then
				lastBoost = nil
			end
		end)
	end
end

local function Crash(self, crashZone: Part)
	if crashZone == lastCrash then else
		lastCrash = crashZone
		local Duration = crashZone:GetAttribute("Duration")
		self:Crash(Duration)
		
		task.delay(2, function()
			if lastCrash == crashZone then
				lastCrash = nil
			end
		end)
	end
end

local function Gravity(self, gravityZone: Part)
	insideGravityZone = true
	if gravityZone == lastGrav then else
		lastGrav = gravityZone
		local Direction: Attachment = gravityZone.Direction
		local newY: Vector3 = Direction.CFrame.UpVector
		self:SetGravity(newY)
	end
end

local function Velocity(self, velocityZone: Part)
	if active_vel[velocityZone] then
		active_vel[velocityZone] = true
	else
		active_vel[velocityZone] = true
		local direction: Attachment = velocityZone:FindFirstChild("Direction")
		
		if direction == nil then 
			debug.traceback(warn(
				"VELOCITY ZONE WITH NO DIRECTION -> Returning.. If you see this please report it!"	
			))
			active_vel[velocityZone] = false
			return
		end
		
		local velocityDirection = direction.CFrame.UpVector
		local power = direction:GetAttribute("Power") or 10000
		local newVelObj = Instance.new("LinearVelocity")
		
		newVelObj.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
		newVelObj.RelativeTo = Enum.ActuatorRelativeTo.World
		newVelObj.LineDirection = velocityDirection
		newVelObj.LineVelocity = power
		
		newVelObj.Attachment0 = self.Mover.Center
		newVelObj.Parent = self.Mover
		
		vel_obj[velocityZone] = newVelObj
	end
end

local function Cannon(self, cannonZone: Part)
	local cannonMoverPos: AlignPosition = self.Mover.CannonPosition
	local cannonMoverOri: AlignOrientation = self.Mover.CannonOrientation
	
	if self.in_cannon == false then
		self.in_cannon = true
		self:ResetForces()
		local firstPoint: Part = cannonZone:FindFirstChild("1")
		
		if firstPoint == nil then
			debug.traceback(warn(
				"CANNON WITH NO FIRST POINT -> Returing.. If you see this please report it!"	
			))
		end
		
		cannonMoverPos.Position = firstPoint.CFrame.Position
		cannonMoverOri.CFrame = firstPoint.CFrame
		cannonPoint = firstPoint
	else
		if (self.Mover.Position - cannonPoint.Position).Magnitude < 1 then
			local index = tonumber(cannonPoint.Name)
			local nextIndex = index+1
			
			if cannonPoint.Parent:FindFirstChild(nextIndex) then
				cannonPoint = cannonPoint.Parent[nextIndex]
				cannonMoverPos.Position = cannonPoint.CFrame.Position
				cannonMoverOri.CFrame = cannonPoint.CFrame
			else
				self.in_cannon = false
				self.currentSpeed = 10
			end
		end
	end
end

local function Bounce(self, bounceZone: Part)
	if lastBounce == bounceZone then else
		lastBounce = bounceZone
		
		local direction: Attachment = bounceZone:FindFirstChild("Direction")
		
		if direction == nil then 
			debug.traceback(warn(
				"BOUNCE ZONE WITH NO DIRECTION -> Returning.. If you see this please report it!"	
				))
			return
		end
		
		local velocityDirection = direction.CFrame.UpVector
		local bouncePower = bounceZone:GetAttribute("Power") or 100000
		local bounceDuration = bounceZone:GetAttribute("Duration")
		local velocity = Instance.new("VectorForce")
		
		velocity.ApplyAtCenterOfMass = true
		velocity.RelativeTo = Enum.ActuatorRelativeTo.World
		velocity.Attachment0 = self.Mover.Center
		velocity.Force = velocityDirection * bouncePower
		
		task.delay(bounceDuration, function()
			if velocity then
				velocity:Destroy()
			end
		end)
		
		task.delay(2, function()
			if lastBounce == bounceZone then
				lastBounce = nil
			end
		end)
	end
end

local function Atmosphere(self, atmosphereZone: Part)
	insideAtmosphereZone = true
	if atmosphereZone == lastAtmosphere then else
		if lastAtmosphere ~= nil then
			self:AtmosphereChanged("Leave", atmosphereZone.Name, atmosphereZone)
		end
		
		self:AtmosphereChanged("Enter", atmosphereZone.Name, atmosphereZone)
	end
end

local function Generic(self, genericZone: Part)
	if active_gen[genericZone] then
		active_gen[genericZone] = true
	else
		active_gen[genericZone] = true
		if genericZone:FindFirstChild("PlayerEntered") then
			genericZone.PlayerEntered:Fire()
		end
	end
end

local case = {
	_Boost = Boost;
	_Cannon = Cannon;
	_Catchnet = Catchnet;
	_Velocity = Velocity;
	_Generic = Generic;
	_Atmosphere = Atmosphere;
	_Gravity = Gravity;
	_Crash = Crash;
	_Bounce = Bounce;
}

function Zones.Update(self)
	insideGravityZone = false
	insideAtmosphereZone = false
	
	for i, _ in pairs(active_vel) do
		active_vel[i] = false
	end
	
	for generic: Part, _ in pairs(active_gen) do
		active_gen[generic] = false
	end
	
	local query = workspace:GetPartBoundsInBox(
		self.Mover.CFrame, 
		self.Mover.Size, 
		ZoneParams
	)
	
	for _, zone: Part in query do
		if case[zone.Parent] then
			case[zone.Parent](self, zone)
		end
	end
	
	if insideGravityZone == false then
		self:SetGravity(Vector3.new(0,1,0))	
	end
	
	if insideAtmosphereZone == false then
		--self.Sound:AtmosphereChanged("Default")
		--self.AtmosphereChanged:Fire("Default")
	end
	
	for i, bool in pairs(active_vel) do
		if bool then else
			vel_obj[i]:Destroy()
			vel_obj[i] = nil
			active_vel[i] = nil
		end
	end
	
	for generic: Part, bool: boolean in pairs(active_gen) do
		if bool then else
			if generic:FindFirstChild("PlayerLeft") then
				generic.PlayerLeft:Fire()
				active_gen[generic] = nil	
			end	
		end
	end
end

return Zones
