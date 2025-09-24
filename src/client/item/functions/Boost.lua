local Boost = {}

function Boost.Call(self)
	local boostPower = 1.6
	local boostDuration = 70
	
	self.Physics:Boost(boostPower, boostDuration)
end

return Boost
