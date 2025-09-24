local Visual = {}

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local itemBoxesToBeUpdated = {}
local coinsToBeUpdated = {}

local RNG = Random.new()

local tweenInfo = TweenInfo.new(
	100,
	Enum.EasingStyle.Linear,
	Enum.EasingDirection.Out,
	-1,
	false,
	0
)

function updateCoins(dt)
	local coins = {}
	local coinCFrames = {}
	
	for _, coin: MeshPart in pairs(coinsToBeUpdated) do
		if coin.Parent:GetAttribute("Taken") then
			continue
		end
		
		table.insert(coins, coin)
		table.insert(coinCFrames, coin.CFrame * CFrame.fromEulerAnglesXYZ(0, math.rad(5) * dt, 0))
	end
	
	workspace:BulkMoveTo(coins, coinCFrames, Enum.BulkMoveMode.FireCFrameChanged)
end

function updateItemBoxes(dt)
	local itemBoxes = {}
	local boxCFrames = {}
	
	for _, box: MeshPart in pairs(itemBoxesToBeUpdated) do
		if box.Parent:GetAttribute("Taken") then
			continue
		end

		local hue, sat, val = box.Color:ToHSV()
		local newColor = RNG:NextNumber()

		local newHue = ((hue*255) + newColor > 255) and 1 or ((hue*255) + newColor)
		newHue /= 255
		box.Color = Color3.fromHSV(newHue, sat, val)

		table.insert(itemBoxes, box)
		table.insert(boxCFrames, box.CFrame * CFrame.fromEulerAnglesXYZ(
			RNG:NextNumber()  * dt,
			RNG:NextNumber()  * dt,
			RNG:NextNumber()  * dt
		))
	end
	
	workspace:BulkMoveTo(itemBoxes, boxCFrames, Enum.BulkMoveMode.FireCFrameChanged)
end

function removeVisual(self, interactable: Part)
	local case = {
		ItemBox = function()
			local index = table.find(itemBoxesToBeUpdated, interactable)
			
			if index then
				table.remove(itemBoxesToBeUpdated, index)
			end
		end,
		
		Coin = function()
			local index = table.find(coinsToBeUpdated, interactable)

			if index then
				table.remove(coinsToBeUpdated, index)
			end
		end,
	}
	
	if case[interactable.Name] then
		case[interactable.Name]()
	end
end

function createVisual(self, interactable: Part)
	local case = {
		ItemBox = function()
			local newItemBox = script.ItemBox:Clone()
			newItemBox.Parent = interactable
			table.insert(itemBoxesToBeUpdated, newItemBox)
		end,

		Coin = function()
			local newCoin = script.Coin:Clone()
			newCoin.Parent = interactable
			table.insert(coinsToBeUpdated, newCoin)
		end,
	}

	if case[interactable.Name] then
		case[interactable.Name]()
		
		local janitor = self.Janitor.new()
		janitor:LinkToInstance(interactable)
		
		local popIn1 = janitor:Add(
			TweenService:Create(
				interactable,
				TweenInfo.new(.2, Enum.EasingStyle.Back),
				{["Size"] = script.ItemBox.Size}
			),
			'Cancel'
		)
		
		local popIn2 = janitor:Add(
			TweenService:Create(
				interactable.QuestionMark.Gui,
				TweenInfo.new(.2, Enum.EasingStyle.Back),
				{["Size"] = script.ItemBox.QuestionMark.Gui.Size}
			),
			'Cancel'
		)
		
		local popOut1 = janitor:Add(
			TweenService:Create(
				interactable,
				TweenInfo.new(.2, Enum.EasingStyle.Quart),
				{["Size"] = Vector3.zero}
			),
			'Cancel'
		)
		
		local popOut2 = janitor:Add(
			TweenService:Create(
				interactable.QuestionMark.Gui,
				TweenInfo.new(.2, Enum.EasingStyle.Quart),
				{["Size"] = UDim2.new(0,0,0,0)}
			),
			'Cancel'
		)
		
		janitor:Add(
			interactable.Parent.AttributeChanged:Connect(function()
				local taken = interactable.Parent:GetAttribute("Taken")
				
				if taken then
					popIn1:Play()
					popIn2:Play()
				else
					interactable.Despawn.PitchEffect.Octave = RNG:NextNumber() + .5
					interactable.Despawn:Play()
					popOut1:Play()
					popOut2:Play()
				end
			end)
		)
		
		task.wait(RNG:NextNumber())	
		
		local hover = janitor:Add(
			TweenService:Create(
				interactable,
				TweenInfo.new(2, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut, -1, true),
				{["Position"] = interactable.Position - Vector3.new(0,.25,0)}	
			),
			'Cancel'
		)
		
		hover:Play()

		if interactable.Name == "ItemBox" then
			for _, texture: Texture | any in pairs(interactable:GetChildren()) do
				if texture:IsA("Texture") then
					local textureTween = janitor:Add(TweenService:Create(texture, tweenInfo, {OffsetStudsU = 50}), 'Cancel')
					local textureTween2 = janitor:Add(TweenService:Create(texture, tweenInfo, {OffsetStudsV  = 50}), 'Cancel')	
					textureTween:Play()
					textureTween2:Play()
				end
			end
		end
	end
end

function listenContainer(self, container: Part)
	for _, interactable: Part in pairs(container:GetChildren()) do
		createVisual(interactable)
	end

	local janitor = self.Janitor.new()
	janitor:LinkToInstance(container)

	janitor:Add(
		container.ChildAdded:Connect(function(newChild)
			createVisual(newChild)
		end)
	)

	janitor:Add(
		container.ChildRemoved:Connect(function(oldChild)
			removeVisual(oldChild)
		end)
	)
end

function Visual:Init(Item)
	self.Functions = Item.Functions
	self.Janitor = Item.Janitor
	
	local Items: Folder = workspace:WaitForChild("Items")
	local Active: Folder = Items.Active
	local Debris: Folder = Items.Debris
	local Grounded: Folder = Items.Grounded
	local Containers:Folder = Items.Containers
	
	local visualJanitor = self.Janitor.new()
	visualJanitor:LinkToInstances(Active,Debris,Grounded)
	
	for _, active: Part in pairs(Active:GetChildren()) do
		local itemFunction = active:GetAttribute("Function")
		self.Functions:CreateVisual(itemFunction, active)
	end
	
	for _, debris: Part in pairs(Debris:GetChildren()) do
		local itemFunction = debris:GetAttribute("Function")
		self.Functions:CreateDebris(itemFunction, debris)
	end
	
	for _, grounded: Part in pairs(Grounded:GetChildren()) do
		local itemFunction = grounded:GetAttribute("Function")
		self.Functions:CreateGrounded(itemFunction, grounded)
	end
	
	visualJanitor:Add(
		Active.ChildAdded:Connect(function(newChild)
			local itemFunction = newChild:GetAttribute("Function")
			self.Functions:CreateVisual(itemFunction, newChild)
		end)
	)
	
	visualJanitor:Add(
		Debris.ChildAdded:Connect(function(newChild)
			local itemFunction = newChild:GetAttribute("Function")
			self.Functions:CreateDebris(itemFunction, newChild)
		end)
	)
	
	visualJanitor:Add(
		Grounded.ChildAdded:Connect(function(newChild)
			local itemFunction = newChild:GetAttribute("Function")
			self.Functions:CreateGrounded(itemFunction, newChild)
		end)
	)
	
	for _, container: Part in pairs(Containers:GetChildren()) do
		listenContainer(self, container)
	end
	
	Containers.ChildAdded:Connect(function(newChild)
		listenContainer(newChild)
	end)
	
	RunService.Heartbeat:Connect(function(dt)
		updateCoins(dt)
		updateItemBoxes(dt)
	end)
end

return setmetatable(Visual, {})
