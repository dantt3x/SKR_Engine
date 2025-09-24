local Client = {}
Client.__index = Client

function Client:Start()
	self.Types = script.Parent:FindFirstChild("Types", true) :: Folder
	
	for _, module in pairs(script:GetChildren()) do
		self[module.Name] = require(module)
	end
	
	for _, module in pairs(script:GetChildren()) do
		self[module.Name]:Init(self)
	end
end

return setmetatable(Client, {})



