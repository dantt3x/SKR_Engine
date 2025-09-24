local Bomb = {}

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local lifetime = 5
local speed = 400
local stun = .8
local projectileType = "Throw"

local rotationData = {
	xRot = 35,
	xRotAdd = -1,
	xRotMax = math.rad(-35),
	xRotSpeed = 90,

	yRot = 0,
	yRotAdd = 0,
	yRotMax = 0,
	yRotSpeed = 0
}

-- Different hitbox from projectile, ground debris
function Bomb.CreateDebris(self, Hitbox: Part)
	if Hitbox == nil then
		return
	end
	
	local bombModel: Model = script.Bomb:Clone()
	local hitboxCFrame = Hitbox.CFrame
	bombModel.Parent = Hitbox
	bombModel:PivotTo(hitboxCFrame)
	bombModel.PrimaryPart.Anchored = true
	bombModel.PrimaryPart.Fuse:Play()
	
	local janitor = self.Janitor.new()
	janitor:LinkToInstance(Hitbox)


	local colorTween = TweenService:Create(
		bombModel.PrimaryPart.SurfaceAppearance,
		TweenInfo.new(1.5, Enum.EasingStyle.Quart),
		{["Color"] = Color3.fromRGB(255,0,0)}
	)
	
	janitor:Add(colorTween:Play(), 'Cancel')
	janitor:Add(function()
		local explosionEffect = script.Explosion:Clone()
		explosionEffect.Parent = workspace
		explosionEffect.CFrame = hitboxCFrame + Vector3.new(0,2,0)
		explosionEffect.Sound:Play()
		explosionEffect.Attachment.ParticleExplosion1:Emit(300)
		explosionEffect.Attachment.ParticleExplosion2:Emit(200)
		explosionEffect.Attachment.ParticleExplosion3:Emit(50)
		task.wait(1.2)
		explosionEffect:Destroy()
	end)
end

function Bomb.CreateVisual(self, Hitbox: Part)
	if Hitbox == nil then
		return
	end
	
	local bombModel = script.Bomb:Clone()
	bombModel.Parent = Hitbox
	bombModel:PivotTo(Hitbox.CFrame)
	
	local janitor = self.Janitor.new()
	janitor:LinkToInstance(Hitbox)
	
	janitor:Add(
		RunService.Heartbeat:Connect(function()
			bombModel:PivotTo(Hitbox.CFrame)
		end)
	)
end

function Bomb.Call(self, Hitbox)
	local canHit = true
	local startCF = self.Kart.Physics.Body.CFrame
	
	local projectile = self.Projectile.new(
		Hitbox, 
		startCF, 
		projectileType, 
		speed, 
		lifetime, 
		rotationData
	)
	
	local janitor = self.Janitor.new()
	janitor:LinkToInstance(Hitbox)
	
	janitor:AddObject(
		projectile, "Clean"
	)
	
	janitor:Add(
		RunService.Stepped:Connect(function(t,dt)
			projectile:Update(dt)
		end)
	)
	
	janitor:Add(
		projectile.Landed.Event:Connect(function(raycastPos: Vector3, raycastNor: Vector3)
			self:RequestValidation("Land", Hitbox.Name, raycastPos, raycastNor)
		end)
	)

	janitor:Add(
		projectile.Hit.Event:Connect(function(victim: string, isPlr: boolean? | nil, selfHit: boolean)
			if canHit and selfHit == false then
				canHit = false
				self:RequestValidation("Hit", Hitbox.Name, victim, stun)
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


return Bomb
