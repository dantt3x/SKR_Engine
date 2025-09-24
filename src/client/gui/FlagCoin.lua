local FlagCoin = {}

local TweenService = game:GetService("TweenService")
local LapChangedSFX: Sound = script.LapChanged

function FlagCoin:SetLap(newLap: number, totalLaps: number)
	local Flag = self.FlagCoin.Background.Flag
	Flag.Text = tostring(newLap).."/"..tostring(totalLaps)
	
	TweenService:Create(
		Flag,
		TweenInfo.new(.15,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut, 0, true),
		{["Position"] = UDim2.fromScale(.712, .515)}
	):Play()

	if newLap > 1 then
		LapChangedSFX:Play()
	end
end

function FlagCoin:SetPowerShift(newPowerShift: number)
	local CoinText: TextLabel = self.FlagCoin.Background.Coin
	CoinText.Text = tostring(newPowerShift)
	
	TweenService:Create(
		CoinText,
		TweenInfo.new(.15,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut, 0, true),
		{["Position"] = UDim2.fromScale(.355, .515)}
	):Play()
		
	if newPowerShift >= 10 then
		CoinText.TextColor3 = Color3.new(1, 0.878431, 0.2)
	else
		CoinText.TextColor3 = Color3.new(1,1,1)
	end
end

function FlagCoin:SetEnabled(bool: boolean)
	self.FlagCoin.Enabled = bool
end

function FlagCoin:Init(coreGui: ScreenGui)
	self.FlagCoin = coreGui.FlagCoin :: ScreenGui
end

return setmetatable(FlagCoin, {})
