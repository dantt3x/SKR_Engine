local Controller = {}
Controller.__index = Controller

local UIS = game:GetService("UserInputService")

local ControllerBinds = {
	Drift = Enum.KeyCode.ButtonB,
	Trick = Enum.KeyCode.ButtonL1,
	ReverseCamera = Enum.KeyCode.ButtonL2,
	UseItem = Enum.KeyCode.ButtonA,
	BackpocketItem = Enum.KeyCode.ButtonX,
	Sticker = Enum.KeyCode.ButtonY
}

--UIS:IsGamepadButtonDown(Enum.KeyCode.Thumbstick1.)

function Controller:Update(Input)
	local gamepadInputs = UIS:GetGamepadState(Enum.UserInputType.Gamepad1)
	print("trolleruodate")
	for _, input: InputObject in pairs(gamepadInputs) do
		if input.KeyCode == Enum.KeyCode.Thumbstick1 then
			local Accelerate = 0
			local Steer = 0
			
			if math.abs(input.Position.Y) > Input.ThumbstickAccelerateDeadzone then
				Accelerate = math.sign(input.Position.Y)
			end
			
			-- Gamepad left is 0 <-> -1, but CFrame for left is 0 <-> 1.
			Steer = input.Position.X * -1
			
			if Accelerate < 0 then
				Steer *= -1
			end
			
			Input:SetAccelerate(Accelerate)
			Input:Turn(Steer)
		else
			continue
		end
	end
	
	local drift: 			boolean = UIS:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, ControllerBinds.Drift)
	local trick: 			boolean = UIS:IsGamepadButtonDown(Enum.UserInputType.Gamepad1,ControllerBinds.Trick)
	local reverseCam: 		boolean = UIS:IsGamepadButtonDown(Enum.UserInputType.Gamepad1,ControllerBinds.ReverseCamera)
	local useItem: 			boolean = UIS:IsGamepadButtonDown(Enum.UserInputType.Gamepad1,ControllerBinds.UseItem)
	local backpocketItem: 	boolean = UIS:IsGamepadButtonDown(Enum.UserInputType.Gamepad1,ControllerBinds.BackpocketItem)
	local sticker: 			boolean = UIS:IsGamepadButtonDown(Enum.UserInputType.Gamepad1,ControllerBinds.Sticker)
	
	if drift then
		Input:Drift()
	else
		Input:CancelDrift()
	end

	if trick and Input.CanTrick then
		Input:Trick()
	end

	if reverseCam then
		Input:ReverseCamera()
	else
		Input:NormalCamera()
	end

	if useItem then
		Input:UseItem()
	else
		Input.CanItem = true
	end

	if backpocketItem then
		Input:BackpocketItem()
	else
		Input.CanBackpocket = true
	end

	if sticker then
		Input:Sticker()
	end
end

function Controller:Load()
	print("Controller loaded")
end

function Controller:Unload()
	
end

return setmetatable(Controller, {})
