local Item = {}
Item.__index = Item

function Item:RequestValidated(arg: string, ...)
	local case = {
		Use = function(...)
			self.Functions:Call(...)
		end,
		
		Unique = function(...)
			self.Functions:Call(...)
		end,
		
		Hit = function(stunTime: number)
			self.Physics:Crash(stunTime)
		end,
		
		HitConfirmed = function(...)
			self.Kart:HitConfirmed()
		end,
	}
	
	if case[arg] then
		case[arg](...)
	end
end

function Item:PocketChanged(pocket: string, changes: {string: any})
	local pocketToChange = self.ItemState[pocket]

	if pocketToChange then
		for index, newValue in pairs(changes) do
			if pocketToChange[index] ~= nil then
				pocketToChange[index] = newValue
			end
		end
	end
end

function Item:RequestValidation(...)
	self.Network:RequestValidation(...)
end

function Item:Use(pocket: string)
	local itemData = self.ItemState[pocket]
	
	if itemData.Name ~= "None" then
		self:RequestValidation("Use", pocket)
	end
end

function Item:Init(Client)
	self.ItemState = {
		Holding = {
			Name = "None",
			Function = "None",
			Charges = 0
		},
		Backpocket = {
			Name = "None",
			Function = "None",
			Charges = 0
		}
	}
	
	self.Janitor = require(script.Parent.Parent.Library.Janitor)
	self.Functions = require(script.Functions)
	self.Visual = require(script.Visual)
	self.Functions:Init(self)
	self.Visual:Init(self)
	
	self.Network = Client.Network
end

return setmetatable(Item, {})
