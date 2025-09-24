local Animation = {}
Animation.__index = Animation

local AnimationClipProvider = game:GetService("AnimationClipProvider")
local Kart = require(script.Kart)
local Bike = require(script.Bike)

function Animation:Update(dt, ...)
	local steer: number,
		  driftDirection: number,
		  accelerate: number,
		  speed: number,
		  boosting: boolean,
		  crashing: boolean,
		  drifting: boolean,
		  falling: boolean,
		  in_cannon: boolean = ...
		 
	local vehicleCore = "Neutral"
	local playerCore = "Neutral"

	if crashing then
		vehicleCore = "Crashing"
	elseif falling then
		vehicleCore = "Falling"
	end
	
	if crashing then
		playerCore = "Crashing"
	elseif boosting then
		playerCore = "Boosting"
	elseif in_cannon then
		playerCore = "Cannon"
	end
	
	self:ShiftVehicleCore(vehicleCore)
	--self:ShiftPlayerCore(playerCore)
	
	--print(self.VehicleType)
	
	if self.VehicleType == "Kart" then
		Kart.Update(
			self, 
			dt,
			drifting,
			driftDirection,
			steer,
			speed,
			accelerate
		)
	else
		--Bike.Update(self, dt, ...)
	end
end

function Animation:BackpocketChanged(itemName: string, count: number)
	
end

function Animation:HoldingChanged(itemName: string, count: number)
	
end

-- animationData::{fadeTime, weight, speed}
function Animation:PlayVehicleEvent(animationName: string, animationData: {number} | nil)
	print(animationName)
	if self.VehicleEventAnimations[animationName] then
		self.VehicleEventAnimations[animationName]:Play(table.unpack(animationData or {}))
	end
end

-- animationData::{fadeTime, weight, speed}
function Animation:PlayPlayerEvent(animationName: string, animationData: {number})
	if self.PlayerEventAnimations[animationName] then
		self.PlayerEventAnimations[animationName]:Play(table.unpack(animationData))
	end
end

-- Shifts the animation to weight 1 and all others to weight 0
function Animation:ShiftVehicleCore(animationToShift: string)
	for coreName, coreAnimation: AnimationTrack in self.VehicleCoreAnimations do
		if coreName == animationToShift then
			coreAnimation:AdjustWeight(10, .15)
		else
			coreAnimation:AdjustWeight(0.01, 0)
		end
	end
end

-- Shifts the animation to weight 1 and all others to weight 0
function Animation:ShiftPlayerCore(animationToShift: string)
	for coreName, coreAnimation: AnimationTrack in self.PlayerCoreAnimations do
		if coreName == animationToShift then
			coreAnimation:AdjustWeight(1)
		else
			coreAnimation:AdjustWeight(0)
		end
	end
end

function Animation:ListenEvents()
	
	local function LoadEvents(loadedAnimation: AnimationTrack)
		local keyframes: KeyframeSequence = {}
		local events: {[number]: string} = {}

		local success, err = pcall(function()
				keyframes = AnimationClipProvider:GetAnimationClipAsync(loadedAnimation.Animation.AnimationId)
		end)

		if err then
			debug.traceback(warn(err))
			return nil
		end

		local function getMarkers(parent: Instance)
			for _, keyframe in pairs(parent:GetChildren()) do
				if keyframe:IsA("KeyframeMarker") then
					table.insert(events, keyframe)
				elseif #keyframe:GetChildren() > 0 then
					getMarkers(keyframe)
				end
			end
		end


		if keyframes and success then
			getMarkers(keyframes)

			for _, marker in pairs(events) do
				table.insert(self.EventConnections, loadedAnimation:GetMarkerReachedSignal(marker.Name):Connect(function()
					--doSmth
				end))
			end
		end	
	end
	
	for _, animationTrack: AnimationTrack in self.VehicleCoreAnimations do
		LoadEvents(animationTrack)
	end
	for _, animationTrack: AnimationTrack in self.VehicleEventAnimations do
		LoadEvents(animationTrack)
	end
	for _, animationTrack: AnimationTrack in self.PlayerCoreAnimations do
		LoadEvents(animationTrack)
	end
	for _, animationTrack: AnimationTrack in self.PlayerEventAnimations do
		LoadEvents(animationTrack)
	end
end

function Animation:Clean()
	
end

function Animation.new(isLocal: boolean, vehicleType: string, Vehicle: Model, Character: Model, Body: Part | nil)
	
	print(isLocal, vehicleType, Vehicle, Character, Body)
	
	local vehicleAnimations: Folder = Vehicle:FindFirstChild("Animations", true)
	local playerAnimations: Folder = Character:FindFirstChild("Animations", true)
	
	if vehicleAnimations == nil or playerAnimations == nil then
		debug.traceback(warn("Vehicle OR Player has no animation folder. Returning..."))
		return
	end
	
	local playerAnimator: Animator = Character:FindFirstChild("Animator", true)
	local vehicleAnimator: Animator = Vehicle:FindFirstChild("Animator", true)
	
	if vehicleAnimator == nil or playerAnimator == nil then
		debug.traceback(warn("Vehicle OR Player doesn't have an animator. Returning..."))
		return
	end
	
	local VehicleCoreAnimations = {
		Neutral = vehicleAnimator:LoadAnimation(vehicleAnimations.Neutral),
		Falling = vehicleAnimator:LoadAnimation(vehicleAnimations.Falling),
		Crashing = vehicleAnimator:LoadAnimation(vehicleAnimations.Crashed),
	}
	
	local VehicleEventAnimations = {
		Landed = vehicleAnimator:LoadAnimation(vehicleAnimations.Landed),
		Drift = vehicleAnimator:LoadAnimation(vehicleAnimations.Drift),
		NeutralTrick = vehicleAnimator:LoadAnimation(vehicleAnimations.NeutralTrick),
		LeftTrick = vehicleAnimator:LoadAnimation(vehicleAnimations.LeftTrick),
		RightTrick = vehicleAnimator:LoadAnimation(vehicleAnimations.RightTrick),
		ForwardTrick = vehicleAnimator:LoadAnimation(vehicleAnimations.ForwardTrick),
	}
	
	local PlayerCoreAnimations = {
		Neutral = nil,
		Crashing = nil,
		Boosting = nil,
		Cannon = nil,
	}
	
	local PlayerEventAnimations = {
		Sticker = nil,
		HitConfirmed = nil,
		NeutralTrick = nil,
		LeftTrick = nil,
		RightTrick = nil,
		ForwardTrick = nil,
	}
	
	-- TODO: add default values here for fallback
	
	local Humanoid = Character.Humanoid
	local LeftFoot: IKControl = Humanoid.LeftFoot
	local RightFoot: IKControl = Humanoid.RightFoot
	local LeftHand: IKControl = Humanoid.LeftHand
	local RightHand: IKControl = Humanoid.RightHand
	
	if vehicleType == "Kart" then
		LeftFoot.EndEffector = Character.LeftFoot
		LeftFoot.ChainRoot = Character.LeftUpperLeg
		LeftFoot.Target = Vehicle.Body.Character.LeftFoot
		LeftFoot.Pole = Vehicle.Body.Character.LeftKnee
		
		RightFoot.EndEffector = Character.RightFoot
		RightFoot.ChainRoot = Character.RightUpperLeg
		RightFoot.Target = Vehicle.Body.Character.RightFoot
		RightFoot.Pole = Vehicle.Body.Character.RightKnee
		
		LeftHand.EndEffector = Character.LeftHand
		LeftHand.ChainRoot = Character.LeftUpperArm
		LeftHand.Target = Vehicle.SteeringWheel.LeftHand
		
		RightHand.EndEffector = Character.RightHand
		RightHand.ChainRoot = Character.RightUpperArm
		RightHand.Target = Vehicle.SteeringWheel.RightHand
	
		Character.LeftUpperArm.LeftShoulder.C0 *= CFrame.new(0,-.15,-.5)
		Character.RightUpperArm.RightShoulder.C0 *= CFrame.new(0,-.15,-.5)
		Character.LeftUpperLeg.LeftHip.C0 *= CFrame.new(0,.25,-.25)
		Character.RightUpperLeg.RightHip.C0 *= CFrame.new(0,.25,-.25)
	else
		
	end

	
	if isLocal then
		--PlayerCoreAnimations.Neutral = playerAnimator:LoadAnimation(playerAnimations.Neutral)
		--PlayerCoreAnimations.Crashing = playerAnimator:LoadAnimation(playerAnimations.Crashing)
		--PlayerCoreAnimations.Boosting = playerAnimator:LoadAnimation(playerAnimations.Boosting)
		--PlayerCoreAnimations.Cannon = playerAnimator:LoadAnimation(playerAnimations.Cannon)
		
		--PlayerEventAnimations.Sticker = playerAnimator:LoadAnimation(playerAnimations.Sticker)
		--PlayerEventAnimations.HitConfirmed = playerAnimator:LoadAnimation(playerAnimations.HitConfirmed)
		--PlayerEventAnimations.NeutralTrick = playerAnimator:LoadAnimation(playerAnimations.NeutralTrick)
		--PlayerEventAnimations.LeftTrick = playerAnimator:LoadAnimation(playerAnimations.LeftTrick)
		--PlayerEventAnimations.RightTrick = playerAnimator:LoadAnimation(playerAnimations.RightTrick)
		--PlayerEventAnimations.ForwardTrick = playerAnimator:LoadAnimation(playerAnimations.ForwardTrick)

		--[[
			Another reason why roblox's engine lacks animation features:
			You cannot get an already loaded animation on a humanoid animator, despite the animations replicating.
			The script still needs the loaded animation to setup callbacks for animation events without reloading them.
			A solution -> play + stop will load the animations into the "Playing Track" table. Using this, we can get
			the originally loaded animations. very hacky solution
		]]
		
		for _, anim: AnimationTrack in pairs(PlayerCoreAnimations) do
			anim:Play()
			anim:Stop()
		end
		
		for _, anim: AnimationTrack in pairs(PlayerEventAnimations) do
			anim:Play()
			anim:Stop()
		end
		
		for _, anim: AnimationTrack in pairs(VehicleEventAnimations) do
			anim:AdjustWeight(2)
			anim.Priority = Enum.AnimationPriority.Action3
			anim.Looped = false
		end
		
		VehicleEventAnimations.ForwardTrick.Priority = Enum.AnimationPriority.Action4
		VehicleEventAnimations.NeutralTrick.Priority = Enum.AnimationPriority.Action4
		VehicleEventAnimations.LeftTrick.Priority = Enum.AnimationPriority.Action4
		VehicleEventAnimations.RightTrick.Priority = Enum.AnimationPriority.Action4

		for _, anim: AnimationTrack in pairs(VehicleCoreAnimations) do
			anim:AdjustWeight(0.01)
			anim.Priority = Enum.AnimationPriority.Movement
			anim.Looped = true
			anim:Play()
		end
	else
		task.defer(function()
			
			for _, animation: AnimationTrack in pairs(playerAnimator:GetPlayingAnimationTracks()) do
				if PlayerCoreAnimations[animation.Name] then
					PlayerCoreAnimations[animation.Name] = animation
				end
				
				if PlayerEventAnimations[animation.Name] then
					PlayerEventAnimations[animation.Name] = animation
				end
			end
			
		end)
	end	
	
	return setmetatable({
		isLocal = isLocal,
		VehicleType = vehicleType,
		VehicleCoreAnimations = VehicleCoreAnimations,
		VehicleEventAnimations = VehicleEventAnimations,
		PlayerCoreAnimations = PlayerCoreAnimations,
		PlayerEventAnimations = PlayerEventAnimations,
		Vehicle = Vehicle,
		Character = Character,
		VehicleAnimator = vehicleAnimator,
		CharacterAnimator = playerAnimator,
		Body = Body,
		
		LeftHandIK = Character.Humanoid.LeftHand,
		RightHandIK = Character.Humanoid.RightHand,
		LeftFootIK = Character.Humanoid.LeftFoot,
		RightFootIK = Character.Humanoid.RightFoot,
		Backpocket = Vehicle.Backpocket,
		Singular = Vehicle.Root.Backpocket,

		BackLeftWheel = vehicleType == "Kart" and Vehicle.BackLeftWheel.Body or nil,
		BackRightWheel = vehicleType == "Kart" and Vehicle.BackRightWheel.Body or nil,
		FrontLeftWheel = vehicleType == "Kart" and Vehicle.FrontLeftWheel.Body or nil,
		FrontRightWheel = vehicleType == "Kart" and Vehicle.FrontRightWheel.Body or nil,
		SteeringWheel = vehicleType == "Kart" and Vehicle.SteeringWheel.Body or nil,
		
		BackWheel = vehicleType == "Bike" and Vehicle.BackWheel.Body or nil,
		FrontWheel = vehicleType == "Bike" and Vehicle.FrontWheel.Body or nil,
		HandleBars = vehicleType == "Bike" and Vehicle.HandleBars.Body or nil,
		EventConnections = {},
	}, Animation)
end

return Animation 
