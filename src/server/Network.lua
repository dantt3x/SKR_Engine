local Network = {}
Network.__index = Network

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SKR_Engine = ReplicatedStorage:WaitForChild("SKR_Engine")
local NetworkPackets = SKR_Engine.Network
local Library = SKR_Engine.Library

local KartPacket = NetworkPackets.KartPacket
local Packet = require(Library.Packet)
local Packets = require(NetworkPackets.Packets)

function Network:FireAllRegisteredPlayersExcept(playerException: Player, packetToFire: Packet, ...)
	for player: Player, state in pairs(self.Server.RegisteredPlayers) do
		if player == playerException then
			continue
		end
		
		packetToFire:FireClient(player, ...)
	end
end

function Network:FireAllRegisteredPlayers(packetToFire: Packet, ...)
	for player: Player, state in pairs(self.Server.RegisteredPlayers) do
		packetToFire:FireClient(player, ...)
	end
end

function Network:PlayerRegisteredAsPlayer(player: Player)
	Packets.PlayerRegisteredAsPlayer:FireClient(player)
end

function Network:PlayerRegisteredAsSpectator(player: Player)
	Packets.PlayerRegisteredAsSpectator:FireClient(player)
end

function Network:RequestValidated(player: Player, ...)
	Packets.RequestValidated:FireClient(player, ...)
end

function Network:RequestValidatedUnique(...)
	self:FireAllRegisteredPlayers(Packets.RequestValidatedUnique, ...)
end

function Network:StartCountdown(...)
	self:FireAllRegisteredPlayers(Packets.StartCountdown, ...)
end

function Network:CheckpointStateChanged(player: Player, ...)
	Packets.CheckpointStateChanged:FireClient(player, ...)
end

function Network:PocketChanged(player: Player, ...)
	Packets.PocketChanged:FireClient(player, ...)
end

function Network:GameStarted(...)
	self:FireAllRegisteredPlayers(Packets.GameStarted, ...)
end

function Network:Placements(...)
	self:FireAllRegisteredPlayers(Packets.Placements, ...)
end

function Network:GameEnded()
	self:FireAllRegisteredPlayers(Packets.GameEnded)
end

function Network:Init(Server)
	self.Server = Server
	
	KartPacket.OnServerEvent:Connect(function(playerWhoSentPacket: Player, buf: any, int: any)
		self:FireAllRegisteredPlayersExcept(playerWhoSentPacket, KartPacket :: Packet, playerWhoSentPacket, buf, int)
	end)
	
	Packets.KartEvent.OnServerEvent:Connect(function(playerWhoSentEvent: Player, ...)
		-- first slot is nil slot for player
		local args: any = {select(2, ...)}

		self:FireAllRegisteredPlayersExcept( 
			playerWhoSentEvent,
			Packets.KartEvent, 
			playerWhoSentEvent, 
			table.unpack(args)
		)
	end)
	
	Packets.RequestValidation.OnServerEvent:Connect(function(...)
		self.Server.Item:ValidationRequested(...)
	end)
	
	Packets.PlayerFinished.OnServerEvent:Connect(function()
		self.Server:PlayerFinished()
	end)
end

return setmetatable(Network,{})
