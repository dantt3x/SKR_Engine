local Item = {
	Enabled = {
		Boost = true,
		TripleBoost = true,
		UltraBoost = true,
		RedWheel = true,
		TripleRed = true,
		GreenWheel = true,
		TripleGreen = true,
		Cone = true,
		TripleCone = true,
		Hammer = true,
		Forcefield = true,
		Bomb = true,
		Boomerang = true,
		Hack = true,
		SuperStrike = true,
		PrecisionStrike = true,	
		PowerShift = true,
	},
	
	RespawnTime = 3
}
Item.__index = Item


local PlayerService = game:GetService("Players")
local RunService = game:GetService("RunService")

local SKR_Engine = game.ReplicatedStorage.SKR_Engine
local Types = SKR_Engine.Types
local ItemType = require(Types.Item)
local ItemData = require(script.Data)
local ItemPlacements = require(script.Placements)
local Janitor = require(SKR_Engine.Library.Janitor)

local takenUniques = {
	PrecisionStrike = false,
	SuperStrike = false,
	Hack = false,
	Hammer = false,
}


local ActiveHitboxes = {}
local LoadedContainers = {}
local LoadedBoxes = {}

local ItemRNG = Random.new()
local IdRNG = Random.new()

local function Hitbox(player: Player, functionName: string, itemName: string): Part
	local newHitbox = Instance.new("Part")
	newHitbox.Name = tostring(IdRNG:NextInteger(10000,99999)) .. "_" .. player.UserId
	newHitbox.Size = Vector3.new(3,3,3)
	--newHitbox.Color = Color3.new(colorRNG:NextNumber(), colorRNG:NextNumber(),colorRNG:NextNumber())
	newHitbox.Material = Enum.Material.Neon	
	newHitbox.Transparency = 1
	newHitbox.CollisionGroup = "Active"

	newHitbox.Anchored = false
	newHitbox.CanCollide = false
	newHitbox.Parent = workspace.Items.Active

	newHitbox:SetAttribute("Function", functionName)
	newHitbox:SetAttribute("Name", itemName)
	newHitbox:SetNetworkOwner(player)

	return newHitbox
end

local function CreateItem(self, player: Player, pocket: string)
	local itemState = self.States[pocket]
	
	if itemState.IsProjectile then
		local newHitbox = Hitbox(player, itemState.Function, itemState.Name)
		ActiveHitboxes[newHitbox.Name] = newHitbox
		
		local hitboxJanitor = Janitor.new()
		hitboxJanitor:LinkToInstance(newHitbox)
		hitboxJanitor:Add(function()
			ActiveHitboxes[newHitbox.Name] = nil
		end)
		
		self.Network:RequestValidated(
			player,
			"Use",
			newHitbox
		)
		
	elseif itemState.Unique then
		self.Functions:Unique(self, itemState.Function, player)
	else
		Item.RequestValidated:Fire(player, nil, pocket)
	end

	itemState.Charges -= 1

	if itemState.Charges <= 0 then
		itemState = {
			Name = "None",
			Function = "None",
			Charges = 0
		}
		self.Network:PocketChanged(player, pocket, itemState)
	else
		self.Network:PocketChanged(player, pocket, {Charges = itemState.Charges})
	end
end

local function AwardItem(self, player: Player, placement: number)
	local possibleItems = {}

	for itemName, data: ItemType.ItemData in pairs(ItemData) do
		local allowedPlacements = ItemPlacements[data.Name]

		if allowedPlacements then
			if type(allowedPlacements) == "string" then
				table.insert(possibleItems, data)
				continue
			else
				for _, allowed in pairs(allowedPlacements) do
					if placement == allowed then
						table.insert(possibleItems, data)
						break
					end
				end
			end
		end
	end
	
	local tail = #possibleItems

	if tail ~= 0 then
		local selected = ItemRNG:NextInteger(1, tail)
		local newItemData = possibleItems[selected]

		self.States[player].Holding = table.clone(newItemData)
		local arg: string = "New"
		local pocket: string = "Holding"
		self.Network:PocketChanged(player, pocket, newItemData)
	else
		debug.traceback(warn("no items for player.. ?"))
	end
end

local function CheckBoxes(self, player: Player, placement: number, position: Vector3)
	local containerFlag = self.States[player].Container
	
	if containerFlag ~= 0 then
		for _, itemBox: Part in pairs(LoadedBoxes[containerFlag]) do
			if itemBox:GetAttribute("Taken") then
				if tick() - itemBox:GetAttribute("Tick") > self.RespawnTime then
					itemBox:SetAttribute("Taken", false)
				else
					continue
				end				
			end
			
			local distance = (itemBox.Position - position).Magnitude
			local radius = itemBox.Size.Magnitude

			if distance <= radius then
				itemBox:SetAttribute("Taken", true)
				itemBox:SetAttribute("Tick", tick())
				
				if self.States[player].Holding.Name == "None" then
					AwardItem(self, player, placement)
				end
			end
		end
	end
end

local function CheckContainers(self, player: Player, position: Vector3)
	self.States[player].Container = 0
	
	for flag: number, container: Part in pairs(LoadedContainers) do
		local radius = (container.Size.X + container.Size.Y + container.Size.Z)/3
		
		if (container.Position - position).Magnitude <= radius then
			self.States[player].Container = flag
		end
	end
end

function Item:ValidationRequested(player: Player, arg: string, ...)	
	local itemState = self.States[player]
	
	if itemState == nil then
		return
	end
	
	if itemState.Validating then
		return
	end
	
	itemState.Validating = true
	
	local case = {
		Use = function(pocket: string)
			if pocket == "Backpocket" then
				if itemState.Backpocket.Name == "None" and itemState.Holding.Name ~= "None" then
					
					if itemState.Holding.Charges <= 0 or itemState.Holding.Charges == 2 then
						return
					end
					
					local temp = itemState.Holding
					itemState.Backpocket = temp
					itemState.Holding = {
						Name = "None",
						Function = "None",
						Charges = 0,
					}
					
					self.Network:PocketChanged(player, "Holding", itemState.Holding)
					self.Network:PocketChanged(player, "Backpocket", itemState.Backpocket)
					
				elseif itemState.Backpocket.Name ~= "None" then
					
					CreateItem(self, player, pocket)
					
				end
			else
				if itemState.Holding.Name ~= "None" then
					
					CreateItem(self, player, pocket)

				end
			end
		end,
		
		Hit = function(hitboxName: string, victim: string, stun: number, isPlr: boolean)
			local activeHitbox: Part = ActiveHitboxes[hitboxName]
			
			if activeHitbox then
				if isPlr then
					if victim == player.Name then
						self.Network:RequestValidated(player, "Hit", stun)
					else
						
						local playerVictim = PlayerService:FindFirstChild(victim)
						if playerVictim then
							local victimItemState: ItemType.ItemState = self.States[playerVictim]
							
							if victimItemState then
								if victimItemState.Backpocket.Charges > 0 then
									victimItemState.Backpocket.Charges -= 1
									self.Network:PocketChanged(playerVictim, "Backpocket", {Changes = victimItemState.Backpocket.Charges})
								else
									self.Network:RequestValidated(playerVictim, "Hit", stun)
									self.Network:RequestValidated(player, "HitConfirmed")
								end
							end
						end
						
					end
				else
					if ActiveHitboxes[victim] then
						ActiveHitboxes[victim]:Destroy()
						ActiveHitboxes[victim] = nil
					end
				end
			end
			
			activeHitbox:Destroy()
			ActiveHitboxes[hitboxName] = nil
		end,
		
		Land = function(hitboxName: string, raycastPos: Vector3, raycastNor: Vector3)
			local activeHitbox: Part = ActiveHitboxes[hitboxName]
			
			if activeHitbox then
				local itemFunction: string = activeHitbox:GetAttribute("Function")
				
				if itemFunction then
					ActiveHitboxes[hitboxName] = nil
					self.Functions:Land(self, itemFunction, raycastPos, raycastNor)
				end
			end
		end,
		
		Delete = function(hitboxName: string)
			if ActiveHitboxes[hitboxName] then
				ActiveHitboxes[hitboxName]:Destroy()
				ActiveHitboxes[hitboxName] = nil
			end
		end,
	}
	
	if case[arg] then
		case[arg](...)
	end
	
	itemState.Validating = false
end

function Item:CheckItemBoxes(containers: Folder)
	RunService:BindToRenderStep("ItemBoxUpdate", Enum.RenderPriority.Character, function(dt)
		for player: Player, itemState: ItemType.ItemState in pairs(self.States) do
			local kartState = self.Kart.States[player]
			local checkpointState = self.Checkpoint.States[player]
			local placement: number = checkpointState.Placement
			local kartBodyPos: Vector3 = kartState.Mover.Position
			CheckContainers(self, player, kartBodyPos)
			CheckBoxes(self, player, placement, kartBodyPos)
		end
	end)
end

function Item:ResetStates()
	for player: Player, state: ItemType.ItemState in pairs(self.States) do
		state = {
			Holding = {
				Name = "",
				Function = "",
				Charges = 0,
			},

			Backpocket = {
				Name = "",
				Function = "",
				Charges = 0,
			},

			Container = 0,
			Validating = false
		}
		
		self.Network:PocketChanged(player, state.Holding)
		self.Network:PocketChanged(player, state.Backpocket)
	end
end

function Item:NewState(player): ItemType.ItemState
	local newState: ItemType.ItemState = {
		Holding = {
			Name = "",
			Function = "",
			Charges = 0,
		},
		
		Backpocket = {
			Name = "",
			Function = "",
			Charges = 0,
		},
		
		Container = 0,
		Validating = false
	}
	
	self.States[player] = newState
	return self.States[player]
end

function Item:DeleteState(player)
	self.States[player] = nil
end

function Item:Init(Server)
	local States: {Player: ItemState} = {}
	self.States = States
	self.Checkpoint = Server.Checkpoint
	self.Kart = Server.Kart
	self.Network = Server.Network
	self.Janitor = Janitor
	
	local containers: Folder = workspace.Items.Containers

	local function loadBox(containerFlag: number, container: Part, itemBox: Part)
		table.insert(LoadedBoxes[containerFlag], itemBox)

		local boxJanitor = Janitor.new()
		boxJanitor:LinkToInstances(itemBox, container)

		boxJanitor:Add(function()
			local box = table.find(LoadedBoxes[containerFlag], itemBox)
			LoadedBoxes[containerFlag][box] = nil
		end)
	end
	
	local function loadContainer(container: Part)
		local containerFlag: number = container:GetAttribute("Flag")
		LoadedContainers[containerFlag] = table.create(1)

		local containerJanitor = Janitor.new()
		containerJanitor:LinkToInstance(container)

		containerJanitor:Add(container.ChildAdded:Connect(function(newBox: Part)
			loadBox(containerFlag, container, newBox)
		end))

		containerJanitor:Add(function()
			LoadedContainers[containerFlag] = nil
			LoadedBoxes[containerFlag] = nil
		end)

		for _, itemBox: Part in container:GetChildren() do
			loadBox(containerFlag,container,itemBox)
		end
	end

	for _, container: Part in pairs(containers:GetChildren()) do
		loadContainer(container)
	end
	
	containers.ChildAdded:Connect(function(newContainer: Part)
		loadContainer(newContainer)
	end)
end

return setmetatable(Item, {})
