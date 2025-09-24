local Item = {}

local TweenService = game:GetService("TweenService")
local Icons = require(script.Icons)

local function Pop(icon: ImageLabel, background: ImageLabel, direction: number)
	direction = direction ~= nil and direction or 1	
	TweenService:Create(
		icon,
		TweenInfo.new(.125, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, true),
		{["Size"] = icon.Size + UDim2.fromScale(.2*direction,.2*direction)}
	):Play()
	
	
	TweenService:Create(
		background,
		TweenInfo.new(.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, true),
		{["Size"] = background.Size + UDim2.fromScale(.2* direction,.2* direction)}
	):Play()
end
	
local function SetTransparency(icon: ImageLabel, background: ImageLabel, transparency: number)
	TweenService:Create(
		icon,
		TweenInfo.new(.2),
		{["ImageTransparency"] = transparency}
	):Play()
	
	TweenService:Create(
		background,
		TweenInfo.new(.2),
		{["ImageTransparency"] = transparency}
	):Play()
end

function Item:ClearIcon()
	local Main = self.Item.Main
	local Icon: ImageLabel = Main.Icon
	local Background: ImageLabel = Main.Background
	
	SetTransparency(Icon, Background, 1)
	task.delay(.7, function()
		Icon.Image = ""
	end)
end

function Item:Use()
	local Main = self.Item.Main
	local Icon: ImageLabel = Main.Icon
	local Background: ImageLabel = Main.Background
	
	Pop(Icon, Background, -.8)
end

function Item:SetItemIcon(itemName: string, charges: number)
	local Main = self.Item.Main
	local Icon: ImageLabel = Main.Icon
	local Background: ImageLabel = Main.Background
	
	if charges > 1 then
		Icon.Image = Icons[itemName.."_"..tostring(charges)]
	else
		Icon.Image = Icons[itemName]
	end
	
	SetTransparency(Icon, Background, 0)
	
	task.delay(.2, function()
		Pop(Icon, Background)	
	end)
end

function Item:SetEnabled(bool: boolean)
	self.Item.Enabled = bool
end

function Item:Init(coreGui: ScreenGui)
	self.Item = coreGui.Item :: ScreenGui
end

return setmetatable(Item, {})
