local Cone = {}

local RunService = game:GetService("RunService")

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

function Cone.CreateDebris(self, Hitbox: Part)
	if Hitbox == nil then
		return
	end
	
	local coneModel: Model = script.Cone:Clone()
	coneModel.Parent = Hitbox
	coneModel:PivotTo(Hitbox.CFrame)
	coneModel.PrimaryPart.Land:Play()
	coneModel.PrimaryPart.Anchored = true
end

function Cone.CreateVisual(self, Hitbox: Part)
	if Hitbox == nil then
		return
	end

	local coneModel: Model = script.Cone:Clone()
	coneModel.Parent = Hitbox
	coneModel:PivotTo(Hitbox.CFrame)
	
	local janitor = self.Janitor.new()
	janitor:LinkToInstance(Hitbox)
	
	janitor:Add(
		RunService.Heartbeat:Connect(function(dt)
			coneModel:PivotTo(Hitbox.CFrame)
		end)
	)
end

function Cone.Call(self, Hitbox: Part)
	local startingCF = self.Kart.Physics.Body.CFrame
	local newProjectile = self.Projectile.new(
		Hitbox, 
		startingCF, 
		projectileType, 
		speed, 
		lifetime, 
		rotationData
	)
	local canHit = true
	
	local janitor = self.Janitor.new()
	janitor:LinkToInstance(Hitbox)
	
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

return Cone
