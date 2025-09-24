local Kart = {}
Kart.__index = Kart

local RunService = game:GetService("RunService")
local PlayerService = game:GetService("Players")
local LocalPlayer = PlayerService.LocalPlayer

local Animation = require(script.Animation)
local Effects = require(script.Effects)
local Sound = require(script.Sound)

function Kart:Boost(player: Player, boostPower, boostDuration)
	self.Loaded[player].Effects:Boost(boostPower, boostDuration)
	self.Loaded[player].Sound:Boost()
	
	if player == LocalPlayer then
		self.Network:KartEvent("Boost")
	end
end

-- Sticker effect / animation
function Kart:Sticker(player: Player)
	self.Loaded[player].Effects:Sticker()
	self.Loaded[player].Sound:Sticker()
	
	if player == LocalPlayer then
		self.Loaded[player].Animation:PlayPlayerEvent("Sticker")
		self.Network:KartEvent("Sticker")
	end
end

-- Hit confirmed effect
function Kart:HitConfirmed(player: Player)
	self.Load[player].Sound:HitConfirmed()
	
	if player == LocalPlayer then
		self.Loaded[player].Animation:PlayPlayerEvent("HitConfirmed")
	end
end

-- Drift Lvl pop effect
function Kart:DriftLevel(player: Player, tier: number)
	self.Loaded[player].Effects:DriftLevel(tier)
	self.Loaded[player].Sound:DriftLevel(tier)
	
	if player == LocalPlayer then
		self.Network:KartEvent("DriftLevel", tier)
	end
end

-- Land Animation
function Kart:Landed(player: Player)
	self.Loaded[player].Animation:PlayVehicleEvent("Landed")
	self.Loaded[player].Effects:Landed()
	self.Loaded[player].Sound:Landed()
	
	if player == LocalPlayer then
		self.Network:KartEvent("Landed")
	end
end

-- Crash Animation
function Kart:Crashed(player: Player, duration: number)
	--self.Loaded[player].Animation:PlayVehicleEvent("Crashed")
	self.Loaded[player].Effects:Crashed()
	self.Loaded[player].Sound:Crashed()
	
	if player == LocalPlayer then
		self.Network:KartEvent("Crashed")
	end
end

-- Trick Effect / Animation
function Kart:Tricked(player: Player, trickDirection: string)
	self.Loaded[player].Animation:PlayVehicleEvent(trickDirection.."Trick")
	self.Loaded[player].Effects:Tricked()
	self.Loaded[player].Sound:Tricked()
	
	if player == LocalPlayer then
		self.Loaded[player].Animation:PlayPlayerEvent(trickDirection.."Trick")
		self.Network:KartEvent("Tricked", trickDirection)
	end
end

-- Drift Hop
function Kart:Drift(player: Player)
	self.Loaded[player].Animation:PlayVehicleEvent("Drift")
	self.Loaded[player].Sound:Drift()
	
	if player == LocalPlayer then
		self.Network:KartEvent("Drift")
	end
end

function Kart:BackpocketChanged(player: Player, itemName: string, count: number)
	self.Loaded[player].Animation:BackpocketChanged(itemName, count)
	self.Loaded[player].Sound:BackpocketChanged()
	
	if player == LocalPlayer then
		self.Network:KartEvent("BackpocketChanged", itemName, count)
	end
end

function Kart:RemoteEvent(player: Player, arg: string, ...)
	if player == LocalPlayer then
		return
	end
	
	local case = {
		Boost = function(...)
			self:Boost(player, ...)
		end,
		Sticker = function(...)
			self:Sticker(player, ...)
		end,
		DriftLevel = function(...)
			self:DriftLevel(player, ...)
		end,
		Landed = function(...)
			self:Landed(player, ...)
		end,	
		Crashed = function(...)
			self:Crashed(player, ...)
		end,
		Tricked = function(...)
			self:Tricked(player, ...)
		end,
		Drift = function(...)
			self:Drift(player, ...)
		end,
		BackpocketChanged = function(...)
			self:BackpocketChanged(player, ...)
		end,
	}
	
	if case[arg] then
		case[arg](...)
	end
end

function Kart:Update(player: Player, ...)
	local steer: number,
		  driftDirection: number,
		  accelerate: number,
		  speed: number,
		  boosting: boolean,
		  crashing: boolean,
		  drifting: boolean,
		  falling: boolean,
		  in_cannon: boolean,
		  invincible: boolean,
		  shocked: boolean,
		  hacked: boolean = ...
		 
	local kartState = self.Loaded[player]

	kartState.Animation:Update(
		self.dt,
		steer,
		driftDirection,
		accelerate,
		speed,
		boosting,
		crashing,
		drifting,
		falling,
		in_cannon
	)

	kartState.Effects:Update(
		speed,
		boosting,
		crashing,
		drifting,
		falling,
		invincible,
		shocked
	)
	
	kartState.Sound:Update(
		speed,
		drifting,
		falling,
		in_cannon,
		invincible,
		shocked
	)

	if player == LocalPlayer then
		self.Network:KartPacket(
			steer,
			driftDirection,
			accelerate,
			speed,
			boosting,
			crashing,
			drifting,
			falling,
			in_cannon,
			invincible,
			shocked,
			hacked
		)
	end
end

function Kart:RemotePacket(player, ...)
	Kart:Update(player, ...)
end

function Kart:UpdateLocal(dt)
	self.dt = dt
	local steer: number = self.Input.Steer
	local driftDirection: number = self.Input.DriftDirection
	local accelerate: number = self.Input.Accelerate
	local speed: number = (self.Physics.Mover.AssemblyLinearVelocity).Magnitude
	
	local boosting: boolean = self.Physics.boosting
	local crashing: boolean = self.Physics.crashing
	local drifting: boolean = self.Physics.drifting
	local falling: boolean = self.Physics.falling
	local in_cannon: boolean = self.Physics.in_cannon
	local invincible: boolean = self.Physics.invincible
	local shocked: boolean = self.Physics.shocked
	local hacked: boolean = self.Physics.hacked
	
	Kart:Update(
		LocalPlayer,
		steer,
		driftDirection,
		accelerate,
		speed,
		boosting,
		crashing,
		drifting,
		falling,
		in_cannon,
		invincible,
		shocked,
		hacked
	)
end

function Kart:LoadTrickAnimations(...)
	local trickLeft, trickRight, trickNeutral, trickForward = ...

end

function Kart:LoadKart(player: Player, vehicleType: string, vehicle: Model)
	print("LOAD CALLED")	
	if vehicleType == nil or vehicle == nil then
		debug.traceback(warn("LoadKart args were not given.. returning"))
		return
	end
	
	local Character = player.Character or player.CharacterAdded:Wait()
	local modelJanitor = self.Janitor.new()
	modelJanitor:LinkToInstances(Character, vehicle)

	local isLocal = player == LocalPlayer
	local Body: Part | nil = isLocal == true and self.Physics.Body or nil
	
	local newAnimation = modelJanitor:AddObject(Animation, "Clean", nil,
		isLocal,
		vehicleType,
		vehicle,
		Character,
		Body
	)
	
	local newEffects = modelJanitor:AddObject(Effects, "Clean", nil,
		isLocal,
		vehicleType,
		vehicle,
		Character
	)
	
	local newSound = modelJanitor:AddObject(Sound, "Clean", nil,
		isLocal,
		vehicleType,
		vehicle,
		Character
	)
	
	self.Loaded[player] = {
		Animation = newAnimation,
		Effects = newEffects,
		Sound = newSound,
	}
	
	if isLocal then
		modelJanitor:Add(
			RunService.Heartbeat:Connect(function(dt)
				self:UpdateLocal(dt)
			end)
		)
	end
	
	modelJanitor:Add(vehicle.AncestryChanged:Connect(function(_, parent: string | nil)
		if parent == nil then
			modelJanitor()
		end
	end))
	
	modelJanitor:Add(function()
		self.Loaded[player] = nil
	end)
	
	print("Kart has been loaded: [" .. player.Name .. "]")
end

function Kart:Init(Client)
	self.Loaded = {} :: {[Player]: {}}
	
	self.Input = Client.Input
	self.Physics = Client.Physics
	self.Network = Client.Network
	self.Janitor = require(script.Parent.Parent:FindFirstChild("Janitor", true))
	
	local Karts: Folder = workspace:WaitForChild("Karts")
	local Rigs: Folder = Karts.Rig
	
	Rigs.ChildAdded:Connect(function(newKartRig)
		local player: Player = PlayerService:FindFirstChild(newKartRig.Name)
		
		if player then
			print(newKartRig:GetAttribute("VehicleType"))
			self:LoadKart(player, newKartRig:GetAttribute("VehicleType"), newKartRig)
		end
	end)
	
	print("Kart Loaded")
end

return setmetatable(Kart, {})
