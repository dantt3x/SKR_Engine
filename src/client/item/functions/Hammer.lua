local Hammer = {}

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

function Hammer.Call(self, caller: string)
	local kartBodies = workspace:FindFirstChild("Body", true)
	local callerBody = kartBodies:FindFirstChild(caller)
	
	if callerBody then
		local effect: Part = script.Effect:Clone()
		local hammerModel: Model = script.Hammer:Clone()
		hammerModel.Parent = callerBody
		hammerModel:PivotTo(callerBody.CFrame + Vector3.new(0,10,0))
		
		local root: Weld = hammerModel.PrimaryPart.Root
		local slam: Sound = hammerModel.PrimaryPart.Slam
		
		local janitor = self.Janitor.new()
		janitor:LinkToInstances(callerBody, effect)
		
		janitor:Add(
			RunService.PreRender:Connect(function(dt)
				if hammerModel then
					hammerModel:PivotTo(callerBody.CFrame + Vector3.new(0,10,0))
				end
				
				effect.CFrame = callerBody.CFrame
			end)
		)
		
		janitor:Add(
			TweenService:Create(
				root,
				TweenInfo.new(.2, Enum.EasingStyle.Quart),
				{C1 = CFrame.Angles(0,0,math.rad(60))}
			),
			'Cancel'
		):Play()
		
		janitor:Add(
			TweenService:Create(
				root,
				TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut, 0, false, .2),
				{C1 = CFrame.Angles(0,0,math.rad(60))}
			),
			'Cancel'
		):Play()
		
		janitor:Add(task.delay(.1, function()
			effect.Parent = workspace
			effect.Attachment.Particle1:Emit(200)
			effect.Attachment.Particle1:Emit(100)
			effect.Attachment.Particle1:Emit(20)
			slam:Play()
		end))
		
		janitor:Add(task.delay(.3, function()
			hammerModel:Destroy()
		end))
		
		janitor:Add(task.delay(.5,function()
			effect:Destroy()
			janitor()
		end))
	end
end

return Hammer
