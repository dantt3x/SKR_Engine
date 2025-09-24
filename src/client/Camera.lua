local Camera = {}
Camera.__index = Camera

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local CameraShaker = require(script.Parent.Parent.Library.CameraShaker)

local function lerp(a,b,t)
	return a + (b - a) * t
end

function Camera:AddShake(shake: number)
	self.Shake:ShakeOnce(
		shake,
		10,
		0,
		2,
		Vector3.new(2,2,.15),
		Vector3.new(0,0,0)
	)
end

function Camera:AddShakeBasedOnDistance(position: Vector3, maximumDistance: number, shake: number)
	local distance = math.min((self.Camera.CFrame.Position - position).Magnitude, maximumDistance)
	local factor = 1 - (distance/maximumDistance)
	self:AddShake(shake*factor)
end

function Camera:AddBoost(power, duration)
	TweenService:Create(
		self.Camera,
		TweenInfo.new((duration/100), Enum.EasingStyle.Quart, Enum.EasingDirection.InOut, 0, true),
		{["FieldOfView"] = self.DefaultFOV + (5 * power)}
	):Play()
end

function Camera:UpdateCamera()
	self.Camera.CameraType = Enum.CameraType.Scriptable
	
	local modes = {
		FollowKart = function()
			local KartBody: Part = self.Physics.Body
			
			if KartBody then
				self.Camera.CameraSubject = KartBody
				
				
				local reverseCFrame = CFrame.fromEulerAnglesXYZ(
					0, 
					math.rad(self.Input.CamInReverse == true and -180 or 0), 
					0
				)
				
				
			
				local bodyPos = KartBody.CFrame.Position
				local newCFrame = CFrame.new(bodyPos)
					* 
					self.Camera.CFrame.Rotation:Lerp(
						KartBody.CFrame.Rotation * reverseCFrame, 
						self.FrameDT * 3
					) 
					* 
					self.CameraOffset
				self.Camera.Focus = newCFrame
				self.Camera.CFrame = newCFrame
			end
		end,
		
		Finish = function()
			local KartBody: Part = self.Physics.Body
			
			if KartBody then
				self.Camera.CameraSubject = KartBody
				local newCFrame = KartBody.CFrame * CFrame.new(-10, 4, -25) * CFrame.fromEulerAnglesXYZ(math.rad(10), math.rad(-150), 0)
				
				self.Camera.CFrame = self.Camera.CFrame:Lerp(newCFrame, self.FrameDT * 2)
				self.Camera.FieldOfView = lerp(self.Camera.FieldOfView, 25, self.FrameDT * 2)
				
				self.Camera.Focus = newCFrame
			end
		end,
		
		Spectate = function()			
			if self.PlayerToSpectate then
				local Character = self.PlayerToSpectate.Character
				if Character then
					self.Camera.CameraSubject = Character
					self.Camera.CameraType = Enum.CameraType.Custom
				end
			else
				self:Limbo()
			end
		end,
		
		Limbo = function()
			self.Camera.CameraSubject = nil
			self.Camera.CFrame = CFrame.new()
		end,
	}
	
	if self.Mode ~= "None" or self.Mode ~= "PlayingIntroSequence" then
		if modes[self.Mode] then
			modes[self.Mode]()
		end
	end
end

function Camera:FollowKart()
	self.Mode = "FollowKart"
end

function Camera:Finish()
	self.Mode = "Finish"
end

function Camera:Spectate(player: Player)
	if player == nil then
		debug.traceback(warn("Player camera is set to spectate mode, but no player to spectate was given."))
	end
	
	self.PlayerToSpectate = player
	self.Mode = "Spectate"
end

function Camera:Limbo()
	self.Mode = "Limbo"
end

function Camera:PlayIntroSequence(callback: () -> void)
	local completed = false
	local Camera: Camera = self.Camera
	Camera.CameraType = Enum.CameraType.Scriptable	
	
	task.spawn(function()
		local timeout = tick()
		
		repeat 
			task.wait(.05) 
			self.Mode = "PlayingIntroSequence"	
			
			if tick() - timeout > 30 then
				break
			end
		until completed
		
		callback()
	end)
	
	local IntroCameraSequence: Folder = workspace.Map.IntroCameraSequence
	local Sequence = IntroCameraSequence:GetChildren()
	
	if #Sequence == 0 then
		debug.traceback(warn("PlayIntroSequence called, but no intro sequence was found.. Returning -> Callback()"))
		completed = true
		return
	end
	
	for i = 1, #Sequence, 1 do
		local Next: Part = IntroCameraSequence[tostring(i)]
		local NextType = Next:GetAttribute("Type")
		
		if NextType == "Teleport" then
			local TeleportDelay = Next:GetAttribute("Delay") or 0
			self.Camera.CFrame = Next.CFrame
			task.wait(TeleportDelay)
		elseif NextType == "Pan" then
			local PanSpeed = Next:GetAttribute("PanSpeed") or 1
			TweenService:Create(
				self.Camera,
				TweenInfo.new(PanSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{["CFrame"] = Next.CFrame}
			):Play()
			task.wait(PanSpeed+.1)
		else
			debug.traceback(warn("Part was found in IntroCameraSequence, but doesn't have a valid Type: "..NextType))
		end
	end
	
	task.wait(2)
	completed = true
end

function Camera:SetReverse(bool: boolean)
	self.Reverse = bool
end

function Camera:Init(Client)
	self.Input = Client.Input
	self.Physics =  Client.Physics
	self.Camera = workspace.CurrentCamera :: Camera
	self.CameraOffset = CFrame.new(0, 6, 24)
	self.DefaultFOV = 70
	self.CameraMode = "None"
	self.BoostTween = nil
	
	self.Update = RunService.PreRender:Connect(function(dtS)
		self:UpdateCamera()
	end)
	
	self.Frame = RunService.Heartbeat:Connect(function(dt)
		self.FrameDT = dt
	end)
	
	self.Shake = CameraShaker.new(Enum.RenderPriority.Camera.Value + 10, function(shakeCF: CFrame)
		self.Camera.CFrame = self.Camera.CFrame * shakeCF
	end)
	
	self.Shake:Start()
	
	print("Camera Loaded")
end

return setmetatable(Camera, {})
