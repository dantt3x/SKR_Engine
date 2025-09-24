local Sound = {}
Sound.__index = Sound

local DriftLevelPitch = {1,1.05,1.1}

function Sound:Update(
	speed,
	drifting,
	falling,
	in_cannon,
	invincible,
	shocked)
	
	local Engine: Sound = self.sounds.Engine
	local Drifting: Sound = self.sounds.Drifting
	local Air: Sound = self.sounds.Air

	if not Engine.Playing then
		Engine:Play()
	end

	if not Drifting.Playing and drifting then
		Drifting:Play()
	elseif Drifting.Playing and drifting == false then
		Drifting:Stop()
	end

	if Air.Playing == false and falling then
		Air:Play()
	else
		Air:Stop()
	end

	Engine.PlaybackSpeed = 1 + (speed / 100)
end

function Sound:Drift()
	self.sounds.Drift:Play()
end

function Sound:Boost()
	self.sounds.Boost:Play()
end

function Sound:Sticker()

end

function Sound:HitConfimed()
	
end

function Sound:DriftLevel(tier: number)
	if DriftLevelPitch[tier] then
		self.sounds.DriftLevel.Tier.Octave = DriftLevelPitch[tier]
	end
	
	self.sounds.DriftLevel:Play()
end

function Sound:Crashed()
	self.sounds.Crashed:Play()
end

function Sound:Landed()
	self.sounds.Landed:Play()
end

function Sound:Tricked()
	self.sounds.Tricked:Play()
end

function Sound:Clean()
	self = nil
end

function Sound.new(isLocal: boolean, vehicleType: string, vehicle: Model, character: Model)
	local soundsFolder: Folder = vehicle:FindFirstChild("Sounds")
	print(soundsFolder:GetChildren())
	if soundsFolder == nil then
		debug.traceback(warn("Player vehicle has no sounds folder!"))
		return
	end
	
	local newSound = {
		isLocal = isLocal;
		sounds=soundsFolder
	}
	
	return setmetatable(newSound, Sound)
end

return Sound
