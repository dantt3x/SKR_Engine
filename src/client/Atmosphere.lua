local Atmosphere = {}
Atmosphere.__index = Atmosphere

local DebrisService = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local function setHackProperty(hack: Atmosphere, property: string, value: number)
	TweenService:Create(
		hack,
		TweenInfo.new(.85, Enum.EasingStyle.Quart),
		{[property] = value}
	):Play()
end

function Atmosphere:Shock()
	local shockAtmosphere = script.Shock:Clone()
	shockAtmosphere.Parent = game.Lighting
	DebrisService:AddItem(shockAtmosphere, .25)
	self.Sound:SetShock(true)
end

function Atmosphere:ShockEnded()
	self.Sound:SetShock(false)
end

function Atmosphere:Hack()
	if self.ActiveHack then
		self.ActiveHack:Destroy()
		self.ActiveHack = nil
	end
	
	self.Sound:SetHack(true)
	self.ActiveHack = script.Hack:Clone()
	self.ActiveHack.Parent = game.Lighting
	
	setHackProperty(self.ActiveHack, "Density", .5)
	setHackProperty(self.ActiveHack, "Offset", 1)
	setHackProperty(self.ActiveHack, "Glare", .7)
	setHackProperty(self.ActiveHack, "Haze", 10)
end

function Atmosphere:HackEnded()
	if self.ActiveHack then
		setHackProperty(self.ActiveHack, "Density", 0)
		setHackProperty(self.ActiveHack, "Offset", 0)
		setHackProperty(self.ActiveHack, "Glare", 0)
		setHackProperty(self.ActiveHack, "Haze", 0)
		DebrisService:AddItem(self.ActiveHack, .85)
		self.ActiveHack = nil
	end
	
	self.Sound:SetHack(false)
end

function Atmosphere:Changed(change: string, atmosphere: string, part: Part)
	local Enter = {
		Underwater = function()
			local waterAtmosphere = Instance.new("Atmosphere")
			local waterBlur = Instance.new("BlurEffect")
			
			waterAtmosphere.Name = "WaterAtmosphere"
			waterBlur.Name = "WaterBlur"
			
			waterAtmosphere.Density = .75
			waterAtmosphere.Haze = 1
			waterAtmosphere.Color = part:GetAttribute("WaterColor") or Color3.new(0.219608, 0.494118, 1)
			waterAtmosphere.Decay = waterAtmosphere.Color:Lerp(Color3.new(), .05)
			waterBlur.Size = 5
			
			waterAtmosphere.Parent = game.Lighting
			waterBlur.Parent = game.Lighting
			
			self.Sound:SetUnderwater(true)
			self.LoadedAtmospheres[part] = {waterAtmosphere,waterBlur}
		end,
		
		Cave = function()
			self.Sound:SetCave(true)
		end,
	}
	
	local Leave = {
		Underwater = function()
			self.Sound:SetUnderwater(false)
			
			if self.LoadedAtmospheres[part] then
				self.LoadedAtmospheres[part][1]:Destroy()
				self.LoadedAtmospheres[part][2]:Destroy()
				self.LoadedAtmospheres[part] = nil
			end
		end,
		
		Cave = function()
			self.Sound:SetCave(false)
		end,
	}
	
	if change == "Enter" then
		if Enter[atmosphere] then
			Enter[atmosphere]()
		end
	elseif change == "Leave" then
		if Leave[atmosphere] then
			Leave[atmosphere]()
		end
	else
		debug.traceback(warn("Atmosphere change occured, but the change doesn't exist: ["..change.."]"))
	end
end

function Atmosphere:Init(Client)
	self.Sound = Client.Sound
	self.LoadedAtmospheres = {}
	print("Atmosphere Loaded")
end

return setmetatable(Atmosphere, {})
