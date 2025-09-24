local Kart = {}
Kart.__index = Kart

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vehicles: Folder = ServerStorage.Vehicles
local Wheels: Folder = ServerStorage.Wheels

local SKR_Engine = ReplicatedStorage.SKR_Engine
local Types = SKR_Engine.Types
local KartType = require(Types.Kart)

local function createKart(self, player: Player)
	local kartState = self.States[player]
	
	if kartState == nil then
		return
	end
	
	if kartState.Mover then
		kartState.Mover:Destroy()
	end
	
	if kartState.Body then
		kartState.Body:Destroy()
	end
	
	local newMover = script.Mover:Clone()
	newMover.Name = player.Name
	newMover.Parent = workspace.Karts.Mover
	newMover.Position = Vector3.new(0,5,0)
	newMover:SetNetworkOwner(player)

	local newBody = script.Body:Clone()
	newBody.Name = player.Name
	newBody.Parent = workspace.Karts.Body
	newBody.Position = Vector3.new(0,5,0)
	newBody:SetNetworkOwner(player)
	
	kartState.Mover = newMover
	kartState.Body = newBody
	task.wait(.25)
	kartState.Rig.Parent = workspace.Karts.Rig
	
	
	for	i, v in pairs(kartState.Rig:GetChildren()) do
		if v:IsA("Part") or v:IsA("MeshPart") then
			v:SetNetworkOwner(player)
		end
	end

	local function updateCharacter(parent)
		for _, child: BasePart | MeshPart in pairs(parent:GetChildren()) do
			if child:IsA("BasePart") or child:IsA("MeshPart") then
				child.CollisionGroup = "Player"
				child.Anchored = false
				child.CanCollide = false
				child.CanQuery = false
				child.CanTouch = false
				child.Massless = true
				child:SetNetworkOwner(player)
			end

			if #child:GetChildren() > 0 then
				updateCharacter(child)
			end
		end	
	end

	local Character = player.Character or player.CharacterAdded:Wait()
	Character:PivotTo(kartState.Rig.Player.CFrame)
	
	local weld = Instance.new("WeldConstraint")
	weld.Parent = Character.PrimaryPart
	weld.Part0 = kartState.Rig.Player
	weld.Part1 = Character.PrimaryPart
	updateCharacter(Character)	
end

function Kart:SpawnPlayerOnPosition(player: Player, spawnPosition: Vector3)
	createKart(self, player)
	self.States[player].Mover.Position = spawnPosition
end

function Kart:SpawnPlayer(player: Player, specificSpawnPoint: number | nil)
	local startingPositions: Folder = workspace.Map.StartingPositions
	
	if #startingPositions:GetChildren() == 0 then
		debug.traceback(warn("No starting points are loaded. Please load the start points before spawning a player."))
	end
	
	createKart(self, player)
	
	local kartState = self.States[player]
	local mover = kartState.Mover
	
	if specificSpawnPoint then
		local spawnPoint: Part = startingPositions:FindFirstChild(tostring(specificSpawnPoint))
		
		if spawnPoint then
			mover.CFrame = spawnPoint.CFrame
			spawnPoint:SetAttribute("Taken", true)
			return
		else
			debug.traceback(warn("specificStartingPosition doesn't exist. SpawnPoint: "..specificSpawnPoint))
		end
	end
	
	for _, spawnPoint: Part in pairs(startingPositions:GetChildren()) do
		if spawnPoint:GetAttribute("Taken") then
			continue
		end
		
		mover.CFrame = spawnPoint.CFrame
		spawnPoint:SetAttribute("Taken", true)
	end
end

function Kart:DespawnPlayer(player: Player)
	local kartState = self.States[player]

	if kartState then
		kartState.Body:Destory()
		kartState.Mover:Destroy()
		kartState.Body = nil
		kartState.Mover = nil
		kartState.Rig.Parent = script.LoadedRigs
	end
end

function Kart:ResetStates()
	for player, kartState in pairs(self.States) do
		self:DespawnPlayer(player)
	end
end

function Kart:NewState(player, vehicle: string, wheel: string, utility: string): KartType.KartState
	local newState: KartType.KartState = {
		Vehicle = vehicle,
		Wheel = wheel,
		Utility = utility,
		Body = nil,
		Mover = nil,
		Rig = nil
	}
	
	local vehicleRig: Model = Vehicles:FindFirstChild(vehicle) or Vehicles.DefaultKart
	local wheelMesh: MeshPart = Wheels:FindFirstChild(wheel) or Wheels.DefaultWheel
	local vehicleType = vehicleRig:GetAttribute("VehicleType")
	
	local newRig = vehicleRig:Clone()
	newRig.Name = player.Name
	
	--[[
	if vehicleType == "Kart" then
		newRig.BackLeftWheel.MeshId = wheelMesh.MeshId
		newRig.BackRightWheel.MeshId = wheelMesh.MeshId
		newRig.FrontLeftWheel.MeshId = wheelMesh.MeshId
		newRig.FrontRightWheel.MeshId = wheelMesh.MeshId
	elseif vehicleType == "Bike" then
		newRig.FrontWheel.MeshId = wheelMesh.MeshId
		newRig.BackWheel.MeshId = wheelMesh.MeshId
	end]]
	
	newRig.Parent = script.LoadedRigs
	newState.Rig = newRig
	
	self.States[player] = newState
	return self.States[player]
end

function Kart:DeleteState(player)
	local state: KartType.KartState = self.States[player]
	
	if state ~= nil then
		state.Body:Destroy()
		state.Mover:Destroy()
		self.States[player] = nil
	end
end

function Kart:Init(Server)
	local States: {Player: KartState} = {}
	self.States = States
	
	self.Item = Server.Item
	self.Checkpoint = Server.Checkpoint
	self.Types = Server.Types
end

return setmetatable(Kart, {})
