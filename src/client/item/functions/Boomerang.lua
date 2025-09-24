local Boomerang = {}

local RunService = game:GetService("RunService")

local lifetime = 99
local speed = 400
local stun = .7
local projectileType = "Hover"

local speedMult = 300

function Boomerang.CreateVisual(self, Hitbox: Part)
	if Hitbox == nil then
		return
	end

	local boomerangModel: Model = script.Boomerang:Clone()
	local root: Weld = boomerangModel.PrimaryPart.Root
	boomerangModel.Parent = Hitbox
	boomerangModel:PivotTo(Hitbox.CFrame)
	boomerangModel.PrimaryPart.Spin:Play()

	local janitor = self.Janitor.new()
	janitor:LinkToInstance(Hitbox)

	janitor:Add(
		RunService.Heartbeat:Connect(function(dt)
			boomerangModel:PivotTo(Hitbox.CFrame)
			root.C1 = root.C1.Rotation:Lerp(
				root.C1 * CFrame.fromEulerAnglesXYZ(0,0,math.rad(45)),
				12*dt
			)
		end)
	)
end

function Boomerang.Call(self, Hitbox: Part)
	local startingCF = self.Kart.Physics.Body.CFrame
	local projectile = self.Projectile.new(Hitbox, startingCF, projectileType, speed, lifetime)
	projectile:SetGravityEnabled(false)
	
	local janitor = self.Janitor.new()
	janitor:LinkToInstance(Hitbox)
	
	janitor:AddObject(
		projectile, "Clean"
	)

	local alreadyRotated = false
	local currentSpeed = speed
	local speedAdd = -1

	local function Rotate()
		if alreadyRotated then else
			alreadyRotated = true
			currentSpeed = 0
			speedAdd = 0
			projectile:SetSpeed(0)
			projectile:AddRotation(0, 180)
			
			task.delay(.2, function()
				speedAdd = 1
			end)
		end
	end
	
	janitor:Add(
		RunService.Stepped:Connect(function(t,dt)
			projectile:Update(dt)
			currentSpeed += speedAdd * dt * speedMult
			projectile:SetSpeed(currentSpeed)

			if currentSpeed <= 0 then
				Rotate()
			elseif currentSpeed > speed then
				self:RequestValidation("Delete", Hitbox.Name)
			end
		end)
	)

	janitor:Add(
		projectile.Hit.Event:Connect(function(victim: string, isPlr: boolean? | nil, selfHit: boolean)
			if selfHit == false then
				self:RequestValidation("Hit", Hitbox.Name, victim, stun)
			end
		end)
	)
	
	janitor:Add(
		projectile.HitWall.Event:Connect(function(_)
			Rotate()
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

return Boomerang
