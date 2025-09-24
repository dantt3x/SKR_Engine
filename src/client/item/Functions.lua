local Functions = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Janitor = require(ReplicatedStorage:FindFirstChild("Janitor", true))

local Lookup = {}

function Functions:RequestValidation(...)
	self.Item:RequestValidation(...)
end

function Functions:CreateGrounded(itemFunction, ...)
	if Lookup[itemFunction] then
		if Lookup[itemFunction].CreateGrounded then
			Lookup[itemFunction].CreateGrounded(self, ...)
		else
			warn("Item function doesn't include a CreateGrounded function: ".. itemFunction)
		end
	end
end

function Functions:CreateDebris(itemFunction, ...)
	if Lookup[itemFunction] then
		if Lookup[itemFunction].CreateDebris then
			Lookup[itemFunction].CreateDebris(self, ...)
		else
			warn("Item function doesn't include a CreateDebris function: ".. itemFunction)
		end
	end
end

function Functions:CreateVisual(itemFunction, ...)
	if Lookup[itemFunction] then
		if Lookup[itemFunction].CreateVisual then
			Lookup[itemFunction].CreateVisual(self, ...)
		else
			warn("Item function doesn't include a CreateVisual function: ".. itemFunction)
		end
	end
end

function Functions:Call(itemFunction, ...)
	if Lookup[itemFunction] then
		if Lookup[itemFunction].Call then
			Lookup[itemFunction].Call(self, ...)
		else
			warn("Item function doesn't include a Call function: ".. itemFunction)
		end
	end
end

function Functions:Init(Item)
	task.wait()
	
	for _, itemFunction in pairs(script:GetChildren()) do
		if itemFunction:IsA("ModuleScript") then
			Lookup[itemFunction.Name] = require(itemFunction)
		end
	end
	
	self.Janitor = Item.Janitor
	self.Physics = Item.Physics
	self.Atmosphere = Item.Atmosphere
	self.Item = Item
end

return setmetatable(Functions, {})
