local Hack = {}

local RunService = game:GetService("RunService")
local localPlayer = game.Players.LocalPlayer

function Hack.Call(self, caller: string, victims: {string})
	local kartModels = workspace:FindFirstChild("Model", true)
	local kartBodies = workspace:FindFirstChild("Body", true)
	
	if localPlayer.Name == caller then else
		for _, victim: string in victims do
			local victimModel: Model = kartModels:FindFirstChild(victim)
			local victimBody: Part = kartBodies:FindFirstChild(victim)
			
			if victimModel == nil or victimBody == nil then
				continue
			end
			
			local lazer = script.Lazer:Clone()
			lazer.Parent = victimBody
			lazer.Beam:Play()
			
			local janitor = self.Janitor.new()
			janitor:LinkToInstances(victimModel, victimBody, lazer)
			
			janitor:Add(
				RunService.PreRender:Connect(function()
					lazer.Position = victimBody.Position + Vector3.new(0,2,0)
				end)
			)
			
			janitor:Add(
				task.delay(1, function()
					lazer.Grid.Enabled = false
					lazer.Laser.Enabled = false
					lazer.Attachment0.ParticleEmitter.Enabled = false
					
					lazer.Beam:Stop()
					lazer.Explode:Play()

					lazer.Explosion.ParticleExplosion1:Emit(125)
					lazer.Explosion.ParticleExplosion2:Emit(125)
				
					if victim == localPlayer.Name then
						self.Physics:Hack()
					end
				end)
			)
			
			janitor:Add(
				task.delay(1.65, function()
					if lazer then
						lazer:Destroy()
					end
				end)
			)		
		end
	end
end

return Hack
