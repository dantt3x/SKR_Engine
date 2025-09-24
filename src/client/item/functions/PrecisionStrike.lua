local PrecisionStrike = {}

local RunService = game:GetService("RunService")
local localPlayer = game.Players.LocalPlayer

function PrecisionStrike.Call(self, victim: string)
	local kartBodies = workspace:FindFirstChild("Body", true)
	local victimBody = kartBodies:FindFirstChild(victim)
	
	if victimBody then
		local lazer = script.PrecisionLazer:Clone()
		lazer.Parent = victimBody
		lazer.Beam:Play()
		
		local janitor = self.Janitor.new()
		janitor:LinkToInstances(victimBody, lazer)
		
		janitor:Add(
			RunService.PreRender:Connect(function(dt)
				lazer.Position = victimBody.Position + Vector3.new(0,2,0)
			end)
		)
		
		janitor:Add(task.delay(2, function()
			lazer.Grid.Enabled = false
			lazer.Laser.Enabled = false
			lazer.Attachment0.ParticleEmitter.Enabled = false

			lazer.Beam:Stop()
			lazer.Explode:Play()
			
			lazer.Explosion.ParticleExplosion1:Emit(500)
			lazer.Explosion.ParticleExplosion2:Emit(80)
			lazer.Explosion.ParticleExplosion2:Emit(50)
			
			if localPlayer.Name == victim then
				self.Physics:Crash(3)
			end 
		end))
		
		janitor:Add(task.delay(3.5, function()
			lazer:Destroy()
			janitor()
		end))
		
	end
end

return PrecisionStrike
