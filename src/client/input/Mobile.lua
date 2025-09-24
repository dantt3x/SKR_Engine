local Mobile = {}
Mobile.__index = Mobile

local UIS = game:GetService("UserInputService")

local GyroEnabled = UIS.GyroscopeEnabled
local ThumbstickAccelerateDeadzone = .425
local GyroDeadzone = .05

task.wait(5)
local PlayerGui = game.Players.LocalPlayer.PlayerGui
local MobileGyro = PlayerGui.MobileGyro
local MobileThumbstick = PlayerGui.MobileThumbstick

local GyroRelativeCF = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)
local Connections = {}

local function TouchChanged(self, Input, inputObject: InputObject)
	local stickSize = MobileThumbstick.Thumbstick.Stick.AbsoluteSize
	local thumbstickSize = MobileThumbstick.Thumbstick.AbsoluteSize
	local thumbstickPosition = MobileThumbstick.Thumbstick.AbsolutePosition
	
	local centerPos = Vector2.new(
		thumbstickPosition.X + thumbstickSize.X/2, 
		thumbstickPosition.Y + thumbstickSize.Y/2
	)
	
	local relativePos = Vector2.new(
		inputObject.Position.X - centerPos.X, 
		inputObject.Position.Y - centerPos.Y
	)
	
	local length = relativePos.Magnitude
	local maximumLength = thumbstickSize.X/2
	local finalLength = math.min(length, maximumLength)
	
	relativePos = relativePos.Unit * length
	MobileThumbstick.Thumbstick.Stick.Position = UDim2.new(
		0, 
		relativePos.X + stickSize.X/2,
		0,
		relativePos.Y + stickSize.Y/2
	)
	
	local direction = Vector2.new(
		inputObject.Position.X - centerPos.X, 
		inputObject.Position.Y - centerPos.Y
	)
	
	local moveVector = direction / (thumbstickSize/2)
	
	local inputAxisMagnitude = moveVector.magnitude
	if inputAxisMagnitude < .05 then
		Input:Steer(0)
		Input:Accelerate(0)
	else
		moveVector = moveVector.unit * math.min(1, (inputAxisMagnitude - .05) / (1 - .05))
		local steer = moveVector.X
		local accelerate = math.sign(moveVector.Y)
		Input:Steer(steer)
		Input:Accelerate(accelerate)
	end
end

local function Drift(self, Input, inputObj: InputObject)
	if inputObj.UserInputState == Enum.UserInputState.Begin then
		Input:Drift()
	elseif inputObj.UserInputState == Enum.UserInputState.End then
		Input:cancelDrift()
	end
end

local function Camera(self, Input, inputObj: InputObject)
	if inputObj.UserInputState == Enum.UserInputState.Begin then
		Input:ReverseCamera()
	elseif inputObj.UserInputState == Enum.UserInputState.End then
		Input:NormalCamera()
	end
end

local function Sticker(self, Input, inputObj: InputObject)
	if inputObj.UserInputState == Enum.UserInputState.Begin then
		Input:Sticker()
	end
end

local function Item(self, Input, inputObj: InputObject)
	if inputObj.UserInputState == Enum.UserInputState.Begin then
		Input:UseItem()
	elseif inputObj.UserInputState == Enum.UserInputState.End then
		Input.CanItem = true
	end
end

local function Pocket(self, Input, inputObj: InputObject)
	if inputObj.UserInputState == Enum.UserInputState.Begin then
		Input:BackpocketItem()
	elseif inputObj.UserInputState == Enum.UserInputState.End then
		Input.CanBackpocket = true
	end
end

function LoadMobileButtonsWithGyro(self, Input)
	local Left = MobileGyro.Left
	local Accelerate = Left.Accelerate
	local Sticker = Left.Sticker
	local Reverse = Left.Reverse
	local Right = MobileGyro.Right
	local Drift = Right.Drift
	local Camera = Right.Camera
	local Item = Right.Item
	local Pocket = Right.Pocket
	
	table.insert(Connections, UIS.DeviceRotationChanged:Connect(function(input: InputObject, gyro: CFrame)
		local x,y,z = GyroRelativeCF:ToObjectSpace(gyro.Rotation):ToEulerAnglesXYZ()
		local yaw = math.clamp((y*45), -45, 45)
		local steer = (yaw / 45)
		
		if steer > GyroDeadzone then
			Input:Steer(steer)
		else
			Input:Steer(0)
		end
	end))
	table.insert(Connections, Accelerate.InputChanged:Connect(function(input: InputObject)
		if input.UserInputState == Enum.UserInputState.Begin then
			Input:Accelerate(1)
		else
			Input:Accelerate(0)
		end
	end))
	table.insert(Connections, Reverse.InputChanged:Connect(function(input: InputObject)
		if input.UserInputState == Enum.UserInputState.Begin then
			Input:Accelerate(-1)
		else
			Input:Accelerate(0)
		end
	end))
	table.insert(Connections, Sticker.InputChanged:Connect(function(input: InputObject)
		Sticker(self, Input, input)
	end))
	table.insert(Connections, Drift.InputChanged:Connect(function(input: InputObject)
		Drift(self, Input, input)
	end))
	
	table.insert(Connections, Camera.InputChanged:Connect(function(input: InputObject)
		Camera(self, Input, input)
	end))
	table.insert(Connections, Item.InputChanged:Connect(function(input: InputObject)
		Item(self, Input, input)
	end))
	table.insert(Connections, Pocket.InputChanged:Connect(function(input: InputObject)
		Pocket(self, Input, input)
	end))
end

function LoadMobileButtonsWithoutGyro(self, Input)
	local Thumbstick = MobileThumbstick.Thumbstick
	local Right = MobileThumbstick.Right
	local Drift = Right.Drift
	local Camera = Right.Camera
	local Item = Right.Item
	local Pocket = Right.Pocket
	local Sticker = Right.Sticker
	
	local currentTouch = nil
	
	table.insert(Connections, Thumbstick.InputBegan:Connect(function(input: InputObject, gPE: boolean)
		if currentTouch or input.UserInputType ~= Enum.UserInputType.Touch
			or input.UserInputState ~= Enum.UserInputState.Begin then
			return
		end
		
		currentTouch = input
	end))
	
	table.insert(Connections, UIS.TouchMoved:Connect(function(input: InputObject, gPE: boolean)
		if input == currentTouch then
			TouchChanged(self, Input, input)
		end
	end))
	
	table.insert(Connections, UIS.TouchEnded:Connect(function(input: InputObject, gPE: boolean)
		if input == currentTouch then
			currentTouch = nil
			MobileThumbstick.Thumbstick.Stick.Position = UDim2.new(.5,0,.5,0)
			Input:Accelerate(0)
			Input:Steer(0)
		end
	end))
	
	table.insert(Connections, Sticker.InputChanged:Connect(function(input: InputObject)
		Sticker(self, Input, input)
	end))
	table.insert(Connections, Drift.InputChanged:Connect(function(input: InputObject)
		Drift(self, Input, input)
	end))

	table.insert(Connections, Camera.InputChanged:Connect(function(input: InputObject)
		Camera(self, Input, input)
	end))
	table.insert(Connections, Item.InputChanged:Connect(function(input: InputObject)
		Item(self, Input, input)
	end))
	table.insert(Connections, Pocket.InputChanged:Connect(function(input: InputObject)
		Pocket(self, Input, input)
	end))
end

function Mobile:Update(Input)

end

function Mobile:Load(Input)
	if GyroEnabled then
		LoadMobileButtonsWithGyro(self, Input)
	else
		LoadMobileButtonsWithoutGyro(self, Input)
	end
end

function Mobile:Unload()
	for _, buttonConnection: RBXScriptConnection in Connections do
		buttonConnection:Disconnect()
	end
end

return setmetatable(Mobile, {})
