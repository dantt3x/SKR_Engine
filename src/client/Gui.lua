local Gui = {}
Gui.__index = Gui

function Gui:DisplayPlacements(...)
	self.Finish:DisplayPlacements(... , function()
		self.Network:PlayerCompleted()
	end)
end

function Gui:Finish(playerStats: {}?, rewards: {}?)
	self.Finish:Play(playerStats :: {}? | nil, rewards :: {}? | nil)
end

function Gui:SetPowerShift(powerShift: number)
	self.FlagCoin:SetPowerShift(powerShift)
end

function Gui:SetMinimapEnable(bool: boolean)
	self.Minimap:SetEnable(bool)
end

function Gui:SetFlagCoinEnable(bool: boolean)
	self.FlagCoin:SetEnable(bool)
end

function Gui:SetItemEnable(bool: boolean)
	self.Item:SetEnable(bool)
end

function Gui:SetPlacementEnable(bool: boolean)
	self.Placement:SetEnable(bool)
end

function Gui:ItemStateChanged(...)
	self.Item:ItemStateChanged(...)
end

function Gui:CheckpointStateChanged(changes: {string: any})	
	-- given the lap changed, then maxlaps must already be set
	local lapChanged = false
	
	local case = {
		Lap = function()
			lapChanged = true
		end,
		
		Placement = function()
			self.Placement:SetPlacement(self.CheckpointState.Placement)
		end,
	}
	
	for index, newValue in pairs(changes) do
		if self.CheckpointState[index] ~= nil then
			self.CheckpointState[index] = newValue
			
			if case[index] then
				case[index]()
			end
		end
	end
	
	if lapChanged then
		self.FlagCoin:SetLap(self.CheckpointState.Lap, self.CheckpointState.MaxLaps)
	end
end

function Gui:GameStarted(mapName: string)
	self.Minimap:LoadMinimap(mapName)
	self:SetCoreGuiEnable(true)
end

function Gui:GameEnded(...)
	self:DisplayPlacements(...)
	self:SetCoreGuiEnable(false)
end

-- FlagCoin,Item,Placement
function Gui:SetCoreGuiEnable(bool)
	self.FlagCoin:SetEnable(bool)
	self.Item:SetEnable(bool)
	self.Placement:SetEnable(bool)
	self.Minimap:SetEnable(bool)
end

function Gui:Init(Client)
	self.CheckpointState = {
		Checkpoint = 0,
		Lap = 0,
		MaxLaps = 0,
		Placement = 0,
		Finished = false
	}
	
	for index, module in pairs(script:GetChildren()) do
		if module:IsA("ModuleScript") then
			self[module.Name] = require(module)
		end
	end
end

return setmetatable(Gui, {})
