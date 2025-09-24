local Server = {
	RegisteredPlayers = {},
	RegisteredSpectators = {},
}
Server.__index = Server

local ServerStorage = game:GetService("ServerStorage")
local PhysicsService = game:GetService("PhysicsService")
local PlayerService = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SKR_Engine = ReplicatedStorage:WaitForChild("SKR_Engine")
local PlayerState = require(SKR_Engine.Types.Player)
local Maps = ServerStorage.Maps

local function UnloadContentsInFolder(folderToUnload: Folder)
	for _, child in pairs(folderToUnload:GetChildren()) do
		child:Destroy()
	end
end

local function LoadContentsIntoFolder(folderToUnload: Folder, folderToLoadOnto: Folder)
	for _, child: Object | Script in pairs(folderToUnload:GetChildren()) do
		if child:IsA("Script") then
			child.Enabled = true
		end
		
		child.Parent = folderToLoadOnto
	end
end

local function CreateFolder(name, parent)
	local newFolder = Instance.new("Folder")
	newFolder.Name = name
	newFolder.Parent = parent
	return newFolder
end

function Server:LoadMap(mapToLoad: Folder)
	local Map = mapToLoad.Map
	local Items = mapToLoad.Items
	local Interactables = mapToLoad.Interactables
	
	LoadContentsIntoFolder(Map.Visual, workspace.Map.Visual)
	LoadContentsIntoFolder(Map.StartingPoints, workspace.Map.StartingPoints)
	LoadContentsIntoFolder(Map.Checkpoints, workspace.Map.Checkpoints)
	LoadContentsIntoFolder(Map.Scripts, workspace.Map.Scripts)
	LoadContentsIntoFolder(Map.IntroCameraSequence, workspace.Map.IntroCameraSequence)
	LoadContentsIntoFolder(Items.Containers, workspace.Items.Containers)
	LoadContentsIntoFolder(Interactables.Atmosphere, workspace.Interactables.Atmosphere)
	LoadContentsIntoFolder(Interactables.Boost, workspace.Interactables.Boost)
	LoadContentsIntoFolder(Interactables.Velocity, workspace.Interactables.Velocity)
	LoadContentsIntoFolder(Interactables.Cannon, workspace.Interactables.Cannon)
	LoadContentsIntoFolder(Interactables.Catchnet, workspace.Interactables.Catchnet)
	LoadContentsIntoFolder(Interactables.Crash, workspace.Interactables.Crash)
	LoadContentsIntoFolder(Interactables.Generic, workspace.Interactables.Generic)
	LoadContentsIntoFolder(Interactables.Gravity, workspace.Interactables.Gravity)
	LoadContentsIntoFolder(Interactables.Bounce, workspace.Interactables.Bounce)
end

function Server:UnloadMap()
	UnloadContentsInFolder(workspace.Map.Visual)
	UnloadContentsInFolder(workspace.Map.StartingPoints)
	UnloadContentsInFolder(workspace.Map.Checkpoints)
	UnloadContentsInFolder(workspace.Map.Scripts)
	UnloadContentsInFolder(workspace.Map.IntroCameraSequence)
	UnloadContentsInFolder(workspace.Items.Containers)
	UnloadContentsInFolder(workspace.Interactables.Atmosphere)
	UnloadContentsInFolder(workspace.Interactables.Boost)
	UnloadContentsInFolder(workspace.Interactables.Velocity)
	UnloadContentsInFolder(workspace.Interactables.Cannon)
	UnloadContentsInFolder(workspace.Interactables.Catchnet)
	UnloadContentsInFolder(workspace.Interactables.Crash)
	UnloadContentsInFolder(workspace.Interactables.Generic)
	UnloadContentsInFolder(workspace.Interactables.Gravity)
	UnloadContentsInFolder(workspace.Interactables.Bounce)
end

function Server:ForceEndGame(savePlacements: boolean)
	self.GameCompleted = true
	
	if self.WaitingOnPlayers then else -- if EndGame was already called don't call again
		self:EndGame(savePlacements, false)
	end
end

function Server:EndGame(savePlacements: boolean?, awardPlayers: boolean?)
	local Placements = self.Checkpoint:GeneratePlacements(savePlacements)
	self.WaitingOnPlayers = true
	
	self.Network:Placements(Placements)
	
	if awardPlayers then
		self.Reward:RewardPlayers()
	end
	
	local timeout = 0
	
	repeat
		task.wait(1)
		timeout += 1
		
		if timeout > 15 then
			break
		end
	until self.GameCompleted == true
	
	self.Network:GameEnded()
	self.Checkpoint:ResetStates()
	self.Item:ResetStates()
	self.Kart:ResetStates()
	self:UnloadMap()
	
	self.GameCompleted = false
	self.GameOngoing = false
	self.WaitingOnPlayers = false
	self.CompletedPlayers = 0
end

function Server:StartGame(checkpointBased: boolean, mapName: string, customStartingPosition: {[Player]: number} | Vector3 | nil)
	if mapName ~= "None" then
		if Maps:FindFirstChild(mapName) then
			self:LoadMap(Maps[mapName])
		else
			debug.traceback(warn("Map to load wasn't found. Returning."))
			return
		end
	end
	
	self.GameOngoing = true
	self.Item:TrackItemBoxes()
	
	if type(customStartingPosition) == "table" then
		self:SpawnAllPlayers(customStartingPosition, nil)
	elseif type(customStartingPosition) == "vector" then
		self:SpawnAllPlayers(nil, customStartingPosition)
	else
		self:SpawnAllPlayers(nil, nil)
	end
 	
	if checkpointBased then
		self.Checkpoint:TrackCheckpoints(Maps[mapName]:GetAttribute("Laps"))
	end
	
	local waitForCountdown = checkpointBased or false
	self.Network:GameStarted(mapName, waitForCountdown)
end

function Server:RegisterPlayerAsPlayer(player: Player, vehicle: string, wheel: string, utility: string)
	local newPlayerState: PlayerState.Player = {}
	
	newPlayerState.ItemState = self.Item:NewState(player)
	newPlayerState.KartState = self.Kart:NewState(player, vehicle, wheel, utility)
	newPlayerState.CheckpointState = self.Checkpoint:NewState(player)
	 
	if self.RegisteredSpectators[player] then
		self.RegisteredSpectators[player] = nil
	end
	
	self.RegisteredPlayers[player] = newPlayerState
	self.Network:PlayerRegisteredAsPlayer(player)
end

function Server:RegisterPlayerAsSpectator(player: Player)
	local newSpectatorState: PlayerState.Spectator = {}

	if self.RegisteredPlayers[player] then
		self.Item:RemoveState(player)
		self.Kart:RemoveState(player)
		self.Checkpoint:RemoveState(player)
		self.RegisteredPlayers[player] = nil
	end
	
	self.RegisteredSpectators[player] = newSpectatorState
	self.Network:PlayerRegisteredAsSpectator(player)
end

function Server:UnregisterPlayer(player: Player)
	if self.RegisteredPlayers[player] then
		self.Item:RemoveState(player)
		self.Kart:RemoveState(player)
		self.Checkpoint:RemoveState(player)
		self.RegisteredPlayers[player] = nil
	end

	if self.RegisteredSpectators[player] then
		self.RegisteredSpectators[player] = nil
	end
end

function Server:SpawnAllPlayers(customStartingPositions: {[Player]: number} | nil, startingPosition: Vector3 | nil)
	for player, _ in pairs(self.RegisteredPlayers) do
		if customStartingPositions then
			self.Kart:SpawnPlayer(player, customStartingPositions[player])
		elseif startingPosition then
			self.Kart:SpawnPlayerOnPosition(player, startingPosition)
		else
			self.Kart:SpawnPlayer(player)
		end
	end
end

function Server:SpawnPlayer(player: Player, customStartingPosition: number | nil, startingPosition: Vector3 | nil)
	if startingPosition then
		self.Kart:SpawnPlayerOnPosition(player, startingPosition)
	else
		self.Kart:SpawnPlayer(player, customStartingPosition)
	end
end

function Server:SetAllKartsAnchor(anchor: boolean)
	for player, _ in pairs(self.RegisteredPlayers) do
		self.Kart:SetAnchor(player, anchor)
	end
end

function Server:SetKartAnchor(player: Player, anchor: boolean)
	self.Kart:SetAnchor(player, anchor)
end

function Server:SetCollide(canCollide: boolean)
	--TimeTrials or debugging
	PhysicsService:CollisionGroupSetCollidable("Kart", "Kart", canCollide)
	PhysicsService:CollisionGroupSetCollidable("BumpCheck", "Kart", canCollide)
end

function Server:PlayerFinished(player)
	if self.GameOngoing then
		if self.RegisteredPlayers[player] then
			self.CompletedPlayers += 1
			
			if self.CompletedPlayers == #self.RegisteredPlayers then
				self.GameCompleted = true
			end
		end
	end
end

function Server:Start()
	workspace.Gravity = 0
	
	self.GameCompleted = false
	self.GameOngoing = false
	self.WaitingOnPlayers = false
	self.CompletedPlayers = 0
	
	
	self.trackCheckpoints = true
	self.rewardPlayers = true
	self.rememberScoreboard = false
	
	if workspace:FindFirstChild("Interactables") then else
		local Directory = CreateFolder("Interactables", workspace)
		CreateFolder("Atmosphere",Directory)
		CreateFolder("Boost",Directory)
		CreateFolder("Velocity",Directory)
		CreateFolder("Cannon",Directory)
		CreateFolder("Catchnet",Directory)
		CreateFolder("Crash",Directory)
		CreateFolder("Generic",Directory)
		CreateFolder("Gravity",Directory)
		CreateFolder("Bounce",Directory)
	end
	
	if workspace:FindFirstChild("Map") then else
		local Directory = CreateFolder("Map", workspace)
		CreateFolder("Visual",Directory)
		CreateFolder("StartingPoints",Directory)
		CreateFolder("Checkpoints",Directory)
		CreateFolder("Scripts",Directory)
		CreateFolder("IntroCameraSequence",Directory)
	end
	
	if workspace:FindFirstChild("Items") then else
		local Directory = CreateFolder("Items", workspace)
		CreateFolder("Active",Directory)
		CreateFolder("Debris",Directory)
		CreateFolder("Containers",Directory)
		CreateFolder("Grounded",Directory)
	end
	
	if workspace:FindFirstChild("Karts") then else
		local Directory = CreateFolder("Karts", workspace)
		CreateFolder("Mover",Directory)
		CreateFolder("Body",Directory)
		CreateFolder("Rig",Directory)
	end
	
	self.Types = SKR_Engine.Types
	
	for _, module in pairs(script:GetChildren()) do
		self[module.Name] = require(module)
		self[module.Name]:Init(self)
	end
end

return setmetatable(Server, {})
