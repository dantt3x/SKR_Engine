local Network = {}
Network.__index = Network

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SKR_Engine = ReplicatedStorage:WaitForChild("SKR_Engine")
local NetworkPackets = SKR_Engine.Network
local Library = SKR_Engine.Library

local KartPacket = NetworkPackets.KartPacket
local Packet = require(Library.Packet)
local Packets = require(NetworkPackets.Packets)

function Network:PlayerCompleted()
	Packets.PlayerFinished:Fire()
end

function Network:RequestValidation(...)
	Packets.RequestValidation:Fire(...)
end

function Network:KartEvent(...)
	Packets.KartEvent:Fire(nil,...)
end

function Network:KartPacket(...)
	local buf, int = Packets.KartPacket:Serialize(...)
	KartPacket:FireServer(buf, int)
end

function Network:Init(Client)
	self.Client = Client
	
	KartPacket.OnClientEvent:Connect(function(player: Player, buf, int)
		local data = Packets.KartPacket:Deserialize(buf, int)
		self.Client.Kart:Update(player, data)
	end)
	
	Packets.KartEvent.OnClientEvent:Connect(function(...)
		self.Client.Kart:RemoteEvent(...)
	end)
	
	Packets.RequestValidated.OnClientEvent:Connect(function(...)
		self.Client.Item:RequestValidated(...)
	end)
	
	Packets.RequestValidatedUnique.OnClientEvent:Connect(function(...)
		self.Client.Item:RequestValidated(...)
	end)
	
	Packets.PlayerFinished.OnClientEvent:Connect(function(...)
		self.Client.Gui:Finish(...)
	end)
	
	Packets.GameStarted.OnClientEvent:Connect(function(mapName: string, waitForCountdown: boolean)
		self.Client.Gui:GameStarted(mapName)
		self.Client.Physics:SetAnchor(waitForCountdown)
	end)
	
	Packets.Placements.OnClientEvent:Connect(function(...)
		self.Client.Gui:DisplayPlacements(...)
	end)
	
	Packets.GameEnded.OnClientEvent:Connect(function(...)
		-- dosmth
	end)
	
	Packets.PocketChanged.OnClientEvent:Connect(function(...)
		self.Client.Item:PocketChanged(...)
	end)
	
	Packets.CheckpointStateChanged.OnClientEvent:Connect(function(...)
		self.Client.Gui:CheckpointStateChanged(...)
	end)
end

return setmetatable(Network, {})
