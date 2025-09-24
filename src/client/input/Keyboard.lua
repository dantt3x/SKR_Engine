local Keyboard = {}
Keyboard.__index = Keyboard

local UIS = game:GetService("UserInputService")

local Keybinds = {
	Drift = Enum.KeyCode.Space,
	Trick = Enum.KeyCode.K,
	Forward = Enum.KeyCode.W,
	Backwards = Enum.KeyCode.S,
	Left = Enum.KeyCode.A,
	Right = Enum.KeyCode.D,
	ReverseCamera = Enum.KeyCode.LeftShift,
	UseItem = Enum.KeyCode.E,
	BackpocketItem = Enum.KeyCode.Q,
	Sticker = Enum.KeyCode.C,
}

local IsKey = {}

local function GetInputState(bind: string): boolean
	if IsKey[bind] == true then
		return UIS:IsKeyDown(Keybinds[bind])
	else
		return UIS:IsMouseButtonPressed(Keybinds[bind])
	end
end

local function SetKey(index: string, input: InputObject) 
	IsKey[index] = input:IsA("KeyCode")
end

function Keyboard:Update(Input)
	local forwardDown: 		boolean = GetInputState("Forward")
	local backwardsDown: 	boolean = GetInputState("Backwards")
	local steerLeft: 		boolean = GetInputState("Left")
	local steerRight: 		boolean = GetInputState("Right")
	local drift: 			boolean = GetInputState("Drift")
	local trick: 			boolean = GetInputState("Trick")
	local reverseCam: 		boolean = GetInputState("ReverseCamera")
	local useItem: 			boolean = GetInputState("UseItem")
	local backpocketItem: 	boolean = GetInputState("BackpocketItem")
	local sticker: 			boolean = GetInputState("Sticker")

	if forwardDown == true and backwardsDown == false then
		Input:SetAccelerate(1)
	elseif forwardDown == false and backwardsDown == true then
		Input:SetAccelerate(-1)
	else
		Input:SetAccelerate(0)
	end

	if steerLeft == true and steerRight == false then
		Input:Turn(1)
	elseif steerLeft == false and steerRight == true then
		Input:Turn(-1)
	else
		Input:Turn(0)
	end

	if drift then
		Input:Drift()
	else
		Input:CancelDrift()
	end
	
	if trick then
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

function Keyboard:RegisterKeybind(bind: string, key: Enum.UserInputType | Enum.KeyCode)
	Keybinds[bind] = key
	SetKey(bind, key)
end

function Keyboard:Load()
	for index, key in pairs(Keybinds) do
		SetKey(index, key)
	end
end

function Keyboard:Unload()

end

return setmetatable(Keyboard, {})
