local RedWheel = {}

local RunService = game:GetService("RunService")

local lifetime = 7
local speed = 275
local stun = 1.75
local projectileType = "Hover"

local totalAngle = 70
local maxSideAngle = math.rad(totalAngle) / 2

local pitchRNG = Random.new()

function RedWheel.CreateVisual(self, Hitbox: Part)
	if Hitbox == nil then
		return
	end

	local hitboxCF = Hitbox.CFrame
	local wheelModel = script.RedWheel:Clone()
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
				10*dt
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

function RedWheel.Call(self, Hitbox: Part)
	local startingCF = self.Kart.Physics.Body.CFrame
	local projectile = self.Projectile.new(
		Hitbox, 
		startingCF,
		projectileType, 
		speed, 
		lifetime
	)
	
	local canHit = true
	local kartMovers = game.Workspace.Karts.Mover:GetChildren()
	
	local currentTarget: Part = nil
	local raycastParams = RaycastParams.new()
	raycastParams.CollisionGroup = "NoCollide"
	raycastParams.RespectCanCollide = true
	
	local janitor = self.Janitor.new()
	janitor:LinkToInstance(Hitbox)

	local function FindAngle(directionV): number
		local lookV = Hitbox.CFrame.LookVector
		return math.acos(math.clamp(lookV:Dot(directionV), -1, 1))
	end

	local function FindNearestPlayer(): Part | void
		local target = nil
		
		for _, kartBody: Part in pairs(kartMovers) do
			if kartBody.Name == game.Players.LocalPlayer.Name then
				continue
			end
			
			local distanceBetween = (kartBody.Position - Hitbox.Position).Magnitude
			
			if distanceBetween > 150 then
				continue
			end
			
			local direction = (kartBody.Position - Hitbox.Position).Unit
			local kartVisionBlocked = workspace:Raycast(Hitbox.Position, direction * distanceBetween, raycastParams)
			
			if kartVisionBlocked then 
				continue
			end
			
			local angleBetween = FindAngle(direction)
			
			if math.abs(angleBetween) < maxSideAngle then
				target = kartBody
				break
			end 
			
		end
		
		return target
	end
	
	janitor:AddObject(
		projectile, "Clean"
	)

	janitor:Add(
		RunService.Stepped:Connect(function(t,dt)
			currentTarget = FindNearestPlayer()
			
			if currentTarget then
				projectile:SetLookVector(currentTarget.Position)
			end
			
			projectile:Update(dt)
		end)
	)
	
	janitor:Add(
		projectile.Hit.Event:Connect(function(victim: string, isPlr: boolean? | void, selfHit: boolean? | void)
			if canHit and selfHit == false then
				canHit = false
				self.ValidateAction:FireServer("Hit", Hitbox.Name, victim, stun)
			end
		end)
	)
	
	janitor:Add(
		projectile.HitWall.Event:Connect(function(_)
			self:RequestValidation("Delete", Hitbox.Name)
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

return RedWheel
