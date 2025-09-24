local Forcefield = {}

local activeForcefield = nil
local usageTime = 6

function Forcefield.Call(self)
	self.Physics:SetInvincibility(true)
	
	if activeForcefield ~= nil then
		task.cancel(activeForcefield)
		activeForcefield = nil
	end

	activeForcefield = task.spawn(function()
		task.wait(usageTime)
		self.Physics:SetInvincibility(false)
	end)
end

return Forcefield
