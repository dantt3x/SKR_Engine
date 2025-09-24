local GreenWheel = {}

local RunService = game:GetService("RunService")

local lifetime = 3
local speed = 250
local stun = 1.6
local projectileType = "Hover"

local bounceRNG = Random.new()
local pitchRNG = Random.new()

function GreenWheel.CreateVisual(self, Hitbox: Part)
	if Hitbox == nil then
		return
	end
	
	local hitboxCF = Hitbox.CFrame
	local wheelModel = script.GreenWheel:Clone()
	local root: Weld = wheelModel.PrimaryPart.Root
	local alert: Sound = wheelModel.PrimaryPart.Alert
	
	local janitor = self.Janitor.new()
	janitor:LinkToInstance(Hitbox)
	
	wheelModel.Parent = Hitbox
	wheelModel:PivotTo(hitboxCF)
	
	alert.Shift.Octave += pitchRNG:NextNumber()
	alert:Play()
	
	janitor:Add(
		RunService.Heartbeat:Connect(function(dt)
			hitboxCF = Hitbox.CFrame
			wheelModel:PivotTo(hitboxCF)
			root.C1 = root.C1.Rotation:Lerp(
				root.C1 * CFrame.fromEulerAnglesXYZ(0,0,math.rad(45)),
				12*dt
			)
		end)
	)

	janitor:Add(
		function()
			local breakPart = script.Break:Clone()
			breakPart.Parent = workspace
			breakPart.CFrame = hitboxCF
			breakPart.Sound:Play()
			breakPart.Attachment.Particle:Emit(5)
			task.wait(.25)
			breakPart:Destroy()
		end
	)
	
end

function GreenWheel.Call(self, Hitbox: Part)
	local startingCF = self.Kart.Physics.Body.CFrame
	local projectile = self.Projectile.new(
		Hitbox, 
		startingCF, 
		projectileType,
		speed,
		lifetime
	)
	
	local bouncesLeft = 3
	local canHit = false
	local canHitSelf = false
	
	local janitor = self.Janitor.new()
	janitor:LinkToInstance(Hitbox)
	
	
	janitor:AddObject(
		projectile, "Clean"
	)
	
	janitor:Add(
		task.delay(.3, function()
			canHitSelf = true
		end)
	)
	
	janitor:Add(
		RunService.Stepped:Connect(function(t,dt)
			projectile:Update(dt)
		end)
	)
	
	janitor:Add(
		projectile.HitWall.Event:Connect(function(wallNormal: Vector3)
			if bouncesLeft > 0 then
				bouncesLeft -= 1
				local yRot = 180 
				projectile:AddRotation(0, yRot)
			else
				self:RequestValidation("Delete", Hitbox.Name)
			end
		end)
	)
	
	janitor:Add(
		projectile.Hit.Event:Connect(function(victim: string, isPlr: boolean? | void, selfHit: boolean? | void)
			if canHit then
				if selfHit and canHitSelf then
					canHit = false
					self:RequestValidation("Hit", Hitbox.Name, victim, stun)
				end
				
				if selfHit == false then
					canHit = false
					self:RequestValidation("Hit", Hitbox.Name, victim, stun)
				end
			end
		end)
	)

	janitor:Add(
		projectile.Ended.Event:Connect(function()
			self:RequestValidation("Delete", Hitbox.Name)
		end)
	)

	janitor:Add(
		self.ForceCleanAllItems.Event:Connect(function()
			self:RequestValidation("Delete", Hitbox.Name)
		end)
	)
end

return GreenWheel
