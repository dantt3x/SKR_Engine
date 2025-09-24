local Sound = {}
Sound.__index = Sound

local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local Music = require(script.Music)

function Sound:SetUnderwater(bool: boolean)
	SoundService.Sounds.UnderwaterEffect1.Enabled = bool
	SoundService.Sounds.UnderwaterEffect2.Enabled = bool	
end

function Sound:SetCave(bool: boolean)
	SoundService.Sounds.CaveEffect.Enabled = bool
end

function Sound:SetShocked(bool: boolean)
	SoundService.Sounds.ShockEffect1.Enabled = bool
	SoundService.Sounds.ShockEffect2.Enabled = bool
end

function Sound:SetHacked(bool: boolean)
	SoundService.Sounds.HackEffect1.Enabled = bool
	SoundService.Sounds.HackEffect2.Enabled = bool
end

function Sound:ChangeTrack(newTrack: string)
	if Music[newTrack] == nil then
		debug.traceback(warn("Sound is called to change tracks, but track wasn't found in music library."))
		return
	end	

	if self.CurrentTrack ~= nil then
		TweenService:Create(
			script.Track,
			TweenInfo.new(1, Enum.EasingStyle.Sine),
			{["Volume"] = 0}
		):Play()
		
		task.wait(1)
		script.Track:Stop()
	end
	
	self.CurrentTrack = newTrack
	script.Track.SoundId = Music[newTrack]
	script.Track:Play()
	
	TweenService:Create(
		script.Track,
		TweenInfo.new(1, Enum.EasingStyle.Sine),
		{["Volume"] = .5}
	):Play()
end

function Sound:SetMusicEnable(bool: boolean)
	self.Music:SetEnable(bool)
end

function Sound:SetGroupVolume(soundGroup: string, volume: number)
	if SoundService.Sounds:FindFirstChild(soundGroup) then
		SoundService.Sounds[soundGroup].Volume = volume
	end
end

function Sound:Init(Client)
	self.CurrentTrack = nil
end

return setmetatable(Sound, {})
