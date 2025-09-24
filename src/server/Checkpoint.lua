local Checkpoint = {}
Checkpoint.__index = Checkpoint

local PlayerService = game:GetService("Players")
local RunService = game:GetService("RunService")

local SKR_Engine = game.ReplicatedStorage.SKR_Engine
local Types = SKR_Engine.Types
local CheckpointType = require(Types.Checkpoint)
local Janitor = require(SKR_Engine.Library.Janitor)

local placementAddPoints = {12,11,10,9,8,7,6,5,4,3,2,1}
local startingTick = tick()

local LoadedCheckpoints = {}

local function SortPlayers(self)
	for player: Player, checkpointState: CheckpointType.CheckpointState in pairs(self.States) do
		local kartState = self.Kart.States[player]
		if kartState == nil then
			continue
		end
		
		local kartMover: Part = kartState.Mover
		local nextC: number = checkpointState.Checkpoint + 1
		
		if nextC > #LoadedCheckpoints then
			nextC = 1
		end
		
		local currCheckpoint: Part = LoadedCheckpoints[checkpointState.Checkpoint]
		local nextCheckpoint: Part = LoadedCheckpoints[nextC]
		
		checkpointState.NextDistance = (currCheckpoint.Position - nextCheckpoint.Position).Magnitude
	end
	
	table.sort(self.ActiveStates, function(a, b)
		if a == nil or b == nil then
			return
		end
		
		local stateA: CheckpointType.CheckpointState = self.States[a]
		local stateB: CheckpointType.CheckpointState = self.States[b]
	
		if stateA.Lap > b.Lap then
			return a.Lap > b.Lap
		elseif a.Lap == b.Lap then
			if a.Checkpoint == b.Checkpoint then
				return a.NextDistance < b.NextDistance
			else
				return a.Checkpoint > b.Checkpoint
			end
		end
	end)
end

function Checkpoint:GeneratePlacements(savePlacements: boolean?): {[number]: CheckpointType.Placement}
	local placements: {[number]: CheckpointType.Placement} = {}
	
	for player: Player, checkpointState: CheckpointType.CheckpointState in pairs(self.States) do
		local newPlacement: CheckpointType.Placement = {}
		newPlacement.Name = player.Name
		
		local totalTime = startingTick - checkpointState.FinishedTick
		local minutes = (math.floor(totalTime) / 60) % 60
		local seconds = math.floor(totalTime) % 60
		local milliseconds = (totalTime % 1) * 1000
	
		newPlacement.Time = string.format("%d:%.02d:%.02d", minutes, seconds, milliseconds)
		
		if self.Placements and savePlacements then
			local currentPoints = nil
			
			for _, placement: CheckpointType.Placement in pairs(self.Placements) do
				if placement.Name ==  player.Name then
					currentPoints = placement.CurrentPoints
					break
				end
			end
			
			if currentPoints then
				newPlacement.CurrentPoints = currentPoints + placementAddPoints[checkpointState.Placement]
				newPlacement.AddPoints = placementAddPoints[checkpointState.Placement]
			else
				newPlacement.CurrentPoints = placementAddPoints[checkpointState.Placement]
				newPlacement.AddPoints = newPlacement.CurrentPoints
			end
			
		elseif savePlacements then
			newPlacement.CurrentPoints = placementAddPoints[checkpointState.Placement]
			newPlacement.AddPoints = newPlacement.CurrentPoints
		end
	end
		
	if savePlacements then
		self.Placements = placements
	else
		self.Placements = nil
	end
	
	return placements
end

function Checkpoint:TrackCheckpoints(maximumLaps: number)
	local Checkpoints = workspace.Map.Checkpoints:GetChildren()
	if #Checkpoints == 0 then
		debug.traceback(warn("Checkpoints cannot be tracked if none exist: "..Checkpoints))
		return
	end
	
	for _, checkpoint: Part in pairs(Checkpoints) do
		local flag = tonumber(checkpoint.Name)
		LoadedCheckpoints[flag] = checkpoint
		
		local checkpointJanitor = Janitor.new()
		checkpointJanitor:LinkToInstance(checkpoint)
		
		checkpointJanitor:Add(checkpoint.Touched:Connect(function(otherPart: Part)
			if otherPart.CollisionGroup ~= "Kart" then
				return
			end
			
			local player: Player = PlayerService:FindFirstChild(otherPart.Name)
			
			if player then
				local checkpointState = self.States[player]
				
				if checkpointState then
					local currentCheckpoint = checkpointState.Checkpoint
					local nextCheckpoint = currentCheckpoint + 1
					local maximumCheckpoints = #Checkpoints
					
					if nextCheckpoint == flag then
						if currentCheckpoint == maximumCheckpoints then
							checkpointState.Lap += 1
							checkpointState.Checkpoint = nextCheckpoint
							
							if checkpointState.Lap >= checkpointState.MaxLaps then
								self.Network:CheckpointStateChanged(player, {
									Lap = checkpointState.Lap,
									Checkpoint = checkpointState.Checkpoint,
									Finished = true
								})
							else
								self.Network:CheckpointStateChanged(player, {
									Lap = checkpointState.Lap,
									Checkpoint = checkpointState.Checkpoint,
								})
							end
						else
							checkpointState.Checkpoint = nextCheckpoint
							self.Network:CheckpointStateChanged(player, {
								Checkpoint = checkpointState.Checkpoint
							})
						end
					end
				end
			end
		end))
		
		checkpointJanitor:Add(function()
			LoadedCheckpoints[flag] = nil
		end)
	end
	
	startingTick = tick()
	maximumLaps = maximumLaps or 3
	
	for player: Player, checkpointState: CheckpointType.CheckpointState in pairs(self.States) do
		checkpointState.Placement = 1
		checkpointState.Finished = false
		checkpointState.Lap = 1
		checkpointState.MaxLaps = maximumLaps
		table.insert(self.ActivePlacements, player)
		self.Network:CheckpointStateChanged(player, checkpointState)
	end
	
	self.Network:StartCountdown(tick())
	
	RunService:BindToRenderStep("TrackCheckpoints", Enum.RenderPriority.Character, function()
		if self.PlayersReady == #self.States and self.Started == false then
			self.Started = true
			self.Network:StartCountdown(tick())
		else
			return
		end
		
		SortPlayers(self)
	end)
end

function Checkpoint:PlayerReady()
	
end

function Checkpoint:ResetStates()
	for player: Player, checkpointState: CheckpointType.CheckpointState in pairs(self.States) do
		self.States[player] = {
			Checkpoint = 0,
			Lap = 0,
			Placement = 0,
			NextDistance = 0,
			Finished = false,
			FinishedTick = tick()
		}
		
		self.Network:CheckpointStateChanged(player, checkpointState)
	end

	self.ActivePlacements = {}
	self.ReadyPlayers = 0
	self.Started = false
end

function Checkpoint:NewState(player: Player): CheckpointType.CheckpointState
	local newState: CheckpointType.CheckpointState = {
		Checkpoint = 0,
		Lap = 0,
		Placement = 0,
		NextDistance = 0,
		Finished = false,
		FinishedTick = tick(),
	}
	
	self.States[player] = newState
	return self.States[player]
end

function Checkpoint:RemoveState(player: Player)
	self.States[player] = nil
	
	local inActivePlacements = table.find(self.ActivePlacements, player)
	if inActivePlacements then
		table.remove(self.ActivePlacements, inActivePlacements)
	end
end

function Checkpoint:Init(Server)
	local States: {Player: CheckpointState} = {}
	self.ActivePlacements = {}
	self.ReadyPlayers = 0
	self.Started = false
	
	self.States = States
end

return setmetatable(Checkpoint,{})
