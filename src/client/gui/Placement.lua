local Placement = {}

local DebrisService = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Icons = require(script.Icons)

function Placement:SetPlacement(newPlacement: number)
	self.Placement.Placement.Image = Icons[newPlacement]
	self.Placement.Placement.ImageTransparency = 0
	self.Placement.Placement.Rotation = 0
	
	TweenService:Create(
		self.Placement.Placement,
		TweenInfo.new(.25, Enum.EasingStyle.Back),
		{["Rotation"] = 360}
	):Play()
	
	TweenService:Create(
		self.Placement.Placement,
		TweenInfo.new(.25, Enum.EasingStyle.Back,Enum.EasingDirection.InOut, 0, true),
		{["ImageTransparency"] = .15}
	):Play()
end

function Placement:SetEnable(bool: boolean)
	self.Placement.Enabled = bool
end

function Placement:Init(coreGui: ScreenGui)
	self.Placement = coreGui.Placement :: ScreenGui
end


return setmetatable(Placement, {})
