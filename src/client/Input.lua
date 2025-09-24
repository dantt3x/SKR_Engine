local Input = {
	--{VARIABLES}
	Accelerate = 0,
	Steer = 0,
	DriftDirection = 0,
	Drifting = false,
	
	--{FLAGS}
	CanTrick = false,
	CanItem = true,
	CanBackpocket = true,
	CamInReverse = false,
	
	--{COOLDOWNS}
	DriftCD = 0,
	StickerCD = 0,
	
	--{SETTING}
	ThumbstickAccelerateDeadzone = .425,
	
	Connections = {}
}
Input.__index = Input

local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local InputType = "Keyboard"
local LocalPlayer = game.Players.LocalPlayer

local InputModules = {
	Keyboard = require(script.Keyboard),
	Controller = require(script.Controller),
	Mobile = require(script.Mobile)
}

local function getInputType()
	if UIS.TouchEnabled then
		return "Mobile"
	elseif UIS.GamepadEnabled then
		return "Controller"
	elseif UIS.KeyboardEnabled then
		return "Keyboard"
	end
end

function Input:Trick()
	local trickDirection = "Neutral"
	
	if self.Steer ~= 0 then
		if self.Steer > 0 then
			trickDirection = "Left"
		else
			trickDirection = "Right"
		end
	elseif self.Accelerate > 0 then
		trickDirection = "Forward"
	end
	
	self.Physics:Trick(trickDirection)
end

function Input:Drift()
	if (tick() - self.DriftCD) < 0 or self.Physics.falling or self.Drifting then else
		if self.Steer ~= 0 then
			self.Drifting = true
			self.DriftDirection = math.sign(self.Steer)
		end
	end
end

function Input:CancelDrift()
	if self.Drifting then
		self.DriftCD = tick()
		self.Drifting = false
		self.DriftDirection = 0
	end
end

function Input:SetAccelerate(Accelerate)
	self.Accelerate = Accelerate
end

function Input:Turn(Steer)
	self.Steer = Steer
end

function Input:UseItem()
	if self.CanItem then 
		self.Item:Use("Holding")
	end
end

function Input:BackpocketItem()
	if self.CanBackpocket then
		self.Item:Use("Backpocket")
	end
end

function Input:ReverseCamera()
	if self.CamInReverse then else
		self.CamInReverse = true
	end
end

function Input:NormalCamera()
	if self.CamInReverse then
		self.CamInReverse = false
	end
end

function Input:Sticker()
	if (tick() - self.StickerCD) > .25 then else
		self.StickerCD = tick()
		self.Kart:Sticker(LocalPlayer)
	end
end

function Input:RegisterKeybind(bind: string, input: Enum.KeyCode | Enum.UserInputType)
	InputModules.Keyboard:RegisterKeybind(bind, input)
end

function Input:RegisterControllerBind(bind: string, input: Enum.KeyCode)
	InputModules.Controller:RegisterControllerBind(bind, input)
end

function Input:SetGyro(bool: boolean)
	InputModules.Mobile:SetGyro(bool)
end


function Input:LoadInputSettings()
	
end

function Input:Init(Client)
	self.Kart = Client.Kart
	self.Item = Client.Item
	self.Camera = Client.Camera
	self.Physics = Client.Physics
	
	UIS.InputChanged:Connect(function()
		
		if getInputType() == InputType then else
			InputModules[InputType]:Unload()
			InputType = getInputType()
			InputModules[InputType]:Load()
		end
	end)
	
	InputModules[InputType]:Load()
	
	RunService.Heartbeat:Connect(function(dt)
		InputModules[InputType]:Update(self)
	end)
end

return setmetatable(Input, {})
