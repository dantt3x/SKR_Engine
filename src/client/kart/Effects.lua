local Effects = {}
Effects.__index = Effects

local DriftTierColors = {
	[0]=script:GetAttribute("T0"), 
	script:GetAttribute("T1"), 
	script:GetAttribute("T2"), 
	script:GetAttribute("T3")
}

local function setAllEnabled(attachment: Attachment, bool: boolean)
	for _, particle in pairs(attachment:GetChildren()) do
		if particle:IsA("ParticleEmitter") then
			particle.Enabled = bool
		end
	end
end

local function setAllColor(attachment: Attachment, color: Color3) 
	for _, particle in pairs(attachment:GetChildren()) do
		if particle:IsA("ParticleEmitter") then
			particle.Color = color
		end
	end
end

function Effects:Update(
	speed,
	boosting,
	crashing,
	drifting,
	falling,
	invincible,
	shocked)
	
	local drift = self.vehicle.Body.Drift
	local boost = self.vehicle.Body.Boost
		
	if self.vehicleType == "Kart" then
		setAllEnabled(drift.DriftL, drifting and not falling)
		setAllEnabled(drift.DriftR, drifting and not falling)
		drift.DriftTrailL.Trail.Enabled = drifting and not falling
		drift.DriftTrailR.Trail.Enabled = drifting and not falling
		
		if self.boostTick then
			if tick() - self.boostTick > self.boostTimer then
				self.boostTick = nil
				self.boostTimer = nil
				
				setAllEnabled(boost.BoostL, false)
				setAllEnabled(boost.BoostR, false)
			else
				setAllEnabled(boost.BoostL, true)
				setAllEnabled(boost.BoostR, true)
			end
		end
	else
		
	end
	
	if drifting then
		local drift = self.vehicle.Body.Drift
		
	end
end

function Effects:Crashed()
	local crash = self.vehicle.Body.Crash
	crash.Shine:Emit(1)
	crash.Swirl:Emit(1)
	crash.Star:Emit(5)
end

function Effects:Boost(boostPower, boostDuration)
	local color = DriftTierColors[0]
	local body = self.vehicle.Body
	setAllColor(body.Drift.DriftL, color)
	setAllColor(body.Drift.DriftR, color)
	setAllColor(body.DriftPop.PopL, color)
	setAllColor(body.DriftPop.PopR, color)
	
	self.boostTick = tick()
	self.boostTimer = boostDuration/100
end

function Effects:Sticker()
	
end

function Effects:DriftLevel(tier: number)
	local color = DriftTierColors[tier]
	local body = self.vehicle.Body
	
	if color then
		body.DriftPop.PopL.Shine1:Emit(1)
		body.DriftPop.PopL.Shine2:Emit(1)
		body.DriftPop.PopR.Shine1:Emit(1)
		body.DriftPop.PopR.Shine2:Emit(1)
		
		setAllColor(body.Drift.DriftL, color)
		setAllColor(body.Drift.DriftR, color)
	end
end

function Effects:Landed()
	print(self.vehicle:GetChildren())
	self.vehicle.Body.Land.Dust1:Emit(10)
	self.vehicle.Body.Land.Dust2:Emit(10)
	self.vehicle.Body.Land.Dust3:Emit(1)
end

function Effects:Tricked()
	self.vehicle.Body.Trick.Bubble:Emit(1)
	self.vehicle.Body.Trick.Specle:Emit(1)
	self.vehicle.Body.Trick.Star:Emit(5)
end

function Effects:Clean()
	self = nil
end

function Effects.new(isLocal, vehicleType: string, vehicle: Model, Character: Model)
	local newEffects = {
		isLocal = isLocal;
		vehicleType = vehicleType,
		vehicle = vehicle,
		Character = Character
	}
	
	return setmetatable(newEffects,Effects)
end

return Effects
