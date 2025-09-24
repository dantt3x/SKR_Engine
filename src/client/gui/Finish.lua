local Finish = {}
Finish.__index = Finish

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local FinishSFX: Sound = script.Finish
local FinishLineSFX: Sound = script.FinishLine
local PointSFX: Sound = script.Point
local RankSFX: Sound = script.Rank
local RewardSFX: Sound = script.Reward
local AddPointSFX: Sound = script.AddPoint

local topFollowTweenInfo = TweenInfo.new(.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut, 0, false, .05)

local topPosition: Tween
local topHover: Tween
local topFollowPosition: Tween
local topFollowSize: Tween 
local topFollowTransparency: Tween
local scoreBounce: Tween
local rankBounce: Tween


local isFinishPlaying = false
local isPlacementsWaiting = false

local pointRanks = {
	[1] = {"S++", 15000},
	[2] = {"S+",13000},
	[3] = {"S", 11500},
	[4] = {"A", 10000},
	[5] = {"B", 8500},
	[6] = {"C", 6500},
	[7] = {"D", 4000},
	[8] = {"F", 2000},
}

type statistics = {
	uniques_used: number,
	items_hit: number,
	items_used: number,
	placement: number,
	final_score: number
}

type rewards = {
	exp: number,
	coins: number,
	level_up: boolean,
	new_inventory_item: boolean
}

type placement = {
	name: string,
	time: string,
	addpoints: number | nil,
	currentpoints: number | nil
}

local function getPlacementOrdinal(placement: number)
	local str = tostring(placement)
	local firstDigit = tonumber(string.sub(str,#str,#str))
	
	local ordinal = {"st","nd","rd"}
	if ordinal[firstDigit] and (placement < 4 or placement > 20)  then
		return str..(ordinal[firstDigit])
	else
		return str.."th"
	end
end

local function BackgroundFade(Background: ImageLabel, transparency)
	TweenService:Create(
		Background,
		TweenInfo.new(2),
		{["ImageTransparency"] = transparency}
	):Play()
	
	TweenService:Create(
		Background,
		TweenInfo.new(2),
		{["BackgroundTransparency"] = transparency}
	):Play()
end

local function TopFade(Top: ImageLabel, transparency)
	TweenService:Create(
		Top,
		TweenInfo.new(2),
		{["ImageTransparency"] = transparency}
	):Play()
end

local function SecondaryFade(Secondary: TextLabel, transparency: number)
	TweenService:Create(
		Secondary,
		TweenInfo.new(2),
		{["TextTransparency"] = transparency}
	):Play()
end

local function FadeAllText(parent, transparency)
	for _, label: TextLabel in pairs(parent:GetChildren()) do
		if label:IsA("TextLabel") then
			TweenService:Create(
				label,
				TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, .1),
				{["TextTransparency"] = transparency}
			):Play()

			if label.UIStroke then
				TweenService:Create(
					label.UIStroke,
					TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, .1),
					{["Transparency"] = transparency}
				):Play()
			end
			
			task.wait(.1)
		end
	end
end

function DisplayPlacements(self, placements)
	local Page: UIPageLayout = self.Finish.UIPageLayout
	local Display: Frame = self.Finish.Placements.Display
	
	local dirtyTable = Display:GetChildren()
	local cleanTable = {}
	
	for i, gui in pairs(dirtyTable) do
		if gui:IsA("Frame") and gui.Name == "Destroy" then
			cleanTable[gui.LayoutOrder] = gui
		end
	end
	
	Page:JumpToIndex(1)
	task.wait(1)
	
	local greatestPointAdd = 0
	for _, placement: placement in pairs(placements) do
		if placement.addpoints > greatestPointAdd then
			greatestPointAdd = placement.addpoints
		end
	end
	
	
	for i = 1, greatestPointAdd, 1 do
		for place, placement: placement in pairs(placements) do
			if i > placement.addpoints then
				continue
			end
			
			local entry: Frame = cleanTable[place]
			entry.Points.Text = tostring((placement.currentpoints-placement.addpoints)+i).."pt"
		end
		
		AddPointSFX:Play()
		task.wait(.05)
	end
end

function GeneratePlacements(self, placements: {[number]: placement})
	local Placements: Frame = self.Finish.Placements
	local Display: Frame = Placements.Display
	local Generic: Frame = Display.Generic
	local GenericEmpty: Frame = Display.GenericEmpty
	
	for i = 1, 12, 1 do
		if placements[i] then
			local newEntry = Generic:Clone()
			newEntry.Name = "Destroy"
			newEntry.Parent = Display
			newEntry.Visible = true
			newEntry.LayoutOrder = i
			
			if placements[i].name == game.Players.LocalPlayer.Name then
				newEntry.Default.Enabled = false
				newEntry.LocalPlayer.Enabled = true
				newEntry.UIStroke.Default.Enabled = false
				newEntry.UIStroke.LocalPlayer.Enabled = true
			end
			
			if placements[i].addpoints and placements[i].currentpoints then
				newEntry.NewPoints.Text = "+"..tostring(placements[i].addpoints).."pts"
				newEntry.Points.Text = tostring(placements[i].currentpoints - placements[i].addpoints).."pts"
			end
			
			newEntry.Placement.Text = getPlacementOrdinal(i)
			newEntry.Player.Text = placements[i].name
			newEntry.Time.Text = placements[i].time
 		else
			local newEntry = GenericEmpty:Clone()
			newEntry.Name = "DestroyEmpty"
			newEntry.Parent = Display
			newEntry.Visible = true
			newEntry.LayoutOrder = i
		end
	end	
end

function DisplayPlayerRewards(self, playerRewards: rewards)
	local Reward = self.Finish.PlayerStats.Reward
		
	if playerRewards.level_up then
		Reward.Level.Visible = true
	end

	if playerRewards.new_inventory_item then
		Reward.Item.Visible = true
	end

	Reward.Coins.Text = string.format("+%dC", playerRewards.coins)
	Reward.Exp.Text = string.format("+%dXP", playerRewards.exp)

	FadeAllText(Reward, 0)
	RewardSFX:Play()	
end

function DisplayPlayerStats(self, playerStatistics: statistics, playerRewards: rewards)
	local PlayerStats = self.Finish.PlayerStats
	local Results = PlayerStats.Results
	local Score = PlayerStats.Score
	local Reward = PlayerStats.Reward
	
	task.wait(.6)
	FadeAllText(Results, 0)
	FadeAllText(Score, 0)

	Results.Placement.Text = "Placement: "..getPlacementOrdinal(playerStatistics.placement)

	local dtConn, delta; 
	task.spawn(function()
		dtConn = RunService.Heartbeat:Connect(function(dt)
			delta=dt
		end)
	end)

	task.wait()

	for i = 0, playerStatistics.items_used, 3 do
		task.wait(delta*2)
		Results.Items_Used.Text = "Items Used: "..tostring(i)
	end
	Results.Items_Used.Text = "Items Used: "..tostring(playerStatistics.items_used)


	for i = 0, playerStatistics.items_hit, 3 do
		task.wait(delta*2)
		Results.Players_Hit.Text = "Players Hit: "..tostring(i)
	end
	Results.Players_Hit.Text = "Players Hit: "..tostring(playerStatistics.items_hit)


	for i = 0, playerStatistics.uniques_used, 3 do
		task.wait(delta*2)
		Results.Uniques_Used.Text = "Uniques Used: "..tostring(i)
	end
	Results.Uniques_Used.Text = "Uniques Used: "..tostring(playerStatistics.uniques_used)

	task.wait(.25)

	local currentCheck = #pointRanks
	PointSFX:Play()

	for i = 0, playerStatistics.final_score, 72 do
		Score.Score.Text = "[SCORE]: "..tostring(math.min(i, playerStatistics.final_score))
		scoreBounce:Play()
		
		if currentCheck > 0 then
			local rank = pointRanks[currentCheck][2]

			if i >= rank then
				Score.Rank.Text = "[RANK]: "..pointRanks[currentCheck][1]
				rankBounce:Play()
				RankSFX:Play()
				RankSFX.Level.Octave += .05
				currentCheck -= 1
			end
		end

		task.wait(delta*3)
	end
	
	Score.Score.Text = "[SCORE]: "..tostring(playerStatistics.final_score)

	PointSFX:Stop()
	dtConn:Disconnect()
	task.wait(.2)
end

function Finish:DisplayPlacements(placementsTable: {placement}, callback: () -> void)
	local Page = self.Finish.UIPageLayout

	local timeOut = 0
	repeat
		timeOut += 1
		task.wait(1)
		
		if timeOut > 15 then
			self:Clean()
			callback()
			return
		end
	until (self.isFinishPlaying == false)
		
	GeneratePlacements(self, placementsTable)
	task.wait()
	Page:JumpToIndex(1)
	DisplayPlacements(self, placementsTable)
	
	task.wait(4)
	self:Clean()
	callback()
end

function Finish:Play(plrStats: statistics? | nil, plrRewards: rewards? | nil)
	if self.isFinishPlaying then
		return
	end
	
	self.isFinishPlaying = true
	self.Finish.Enabled = true
	
	local PlayerStats = self.Finish.PlayerStats
	local Top: ImageLabel = PlayerStats.Top
	local Top2: ImageLabel = PlayerStats.Top2
	
	BackgroundFade(PlayerStats.Background :: ImageLabel, 0)
	TopFade(Top :: ImageLabel, 0)
	SecondaryFade(PlayerStats.Secondary :: TextLabel, .7)
	FadeAllText(PlayerStats.Secondary :: TextLabel, 0)

	Top.Position = UDim2.new(.375,0,0,0)
	Top2.Position = UDim2.new(.375,0,0,0)
	Top2.Size = UDim2.new(.375,0,.25,0)
	Top2.ImageTransparency = .5
	topPosition:Play()
	topFollowPosition:Play()
	topFollowSize:Play()
	topFollowTransparency:Play()

	task.delay(.2, function()
		FinishSFX:Play()
	end)

	task.delay(.8, function()
		topHover:Play()
	end)
	
	if plrStats then
		DisplayPlayerStats(self, plrStats)
		task.wait(2)
	end
	
	if plrRewards then
		DisplayPlayerRewards(self, plrRewards)
	end
	
	task.wait(3)
	self.isFinishPlaying = false
end

function Finish:Clean()
	local PlayerStats = self.Finish.PlayerStats
	local Reward = PlayerStats.Reward
	local Score = PlayerStats.Score
	local Results = PlayerStats.Results
	local Display = self.Finish.Placements.Display

	BackgroundFade(PlayerStats.Background :: ImageLabel, 1)
	TopFade(PlayerStats.Top :: ImageLabel, 1)
	SecondaryFade(PlayerStats.Secondary :: TextLabel, 1)
	FadeAllText(Reward, 1)
	FadeAllText(Score, 1)
	FadeAllText(Results, 1)
	
	Results.Items_Used.Text = "Items Used: 0"
	Results.Players_Hit.Text = "Players Hit: 0"
	Results.Uniques_Used.Text = "Uniques Used: 0"
	Results.Placement.Text = "Placement: 12th"
	Score.Rank.Text = "[RANK]: ..."
	Score.Score.Text = "[SCORE]: 0"
	Reward.Coins.Text = string.format("+%dC", 0)
	Reward.Exp.Text = string.format("+%dXP", 0)
	Reward.Level.Visible = false
	Reward.Item.Visible = false
	RankSFX.Level.Octave = .8
	
	self.Finish.UIPageLayout:JumpToIndex(0)
	task.wait(1.5)
	
	topPosition:Cancel()
	topHover:Cancel()
	topFollowPosition:Cancel()
	topFollowSize:Cancel() 
	topFollowTransparency:Cancel()
	scoreBounce:Cancel()
	rankBounce:Cancel()
	
	self.Finish.Enabled = false
	
	for _, entry: Frame in pairs(Display:GetChildren()) do
		if string.sub(entry.Name,1,7) == "Destroy" then
			entry:Destroy()
		end
	end
end

function Finish:Init(coreGui: ScreenGui)
	self.Finish = coreGui.Finish :: ScreenGui
	local PlayerStats = self.Finish.PlayerStats
	
	topPosition = TweenService:Create(
		PlayerStats.Top, 
		TweenInfo.new(.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut), 
		{["Position"] = UDim2.new(0,0,0,0)}
	)
	topHover = TweenService:Create(
		PlayerStats.Top,
		TweenInfo.new(1.875, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut, -1, true),
		{["Position"] = PlayerStats.Top.Position + UDim2.fromOffset(0,5)}
	)
	topFollowPosition = TweenService:Create(
		PlayerStats.Top2, 
		topFollowTweenInfo, 
		{["Position"] = UDim2.new(0,0,0,0)}
	)
	topFollowSize = TweenService:Create(
		PlayerStats.Top2, 
		topFollowTweenInfo, 
		{["Size"] = UDim2.new(.375,75,.25,50)}
	)
	topFollowTransparency = TweenService:Create(
		PlayerStats.Top2, 
		topFollowTweenInfo, 
		{["ImageTransparency"] = 1}
	)
	scoreBounce = TweenService:Create(
		PlayerStats.Score.Score,
		TweenInfo.new(.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, true),
		{["Size"] = UDim2.new(0.7, 3, 1, 3)}
	)
	rankBounce = TweenService:Create(
		PlayerStats.Score.Rank,
		TweenInfo.new(.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, true),
		{["Size"] = UDim2.new(0.7, 10, 1, 10)}
	)
	
	BackgroundFade(PlayerStats.Background :: ImageLabel, 1)
	TopFade(PlayerStats.Top :: ImageLabel, 1)
	SecondaryFade(PlayerStats.Secondary :: TextLabel, 1)
	FadeAllText(PlayerStats.Reward, 1)
	FadeAllText(PlayerStats.Score, 1)
	FadeAllText(PlayerStats.Results, 1)
end

return setmetatable(Finish, {})
