local Kart = {}

local Offset = Vector3.new(0,1.5,0)

function UpdateCharacter(Character, RotationChange, DriftDirection, dt)
	local Root: Motor6D = Character.LowerTorso.Root
	local Neck: Motor6D = Character.Head.Neck
	
	Neck.C0 = Neck.C0:Lerp(
		CFrame.new(Neck.C0.Position) * CFrame.fromEulerAnglesXYZ(
			0,
			math.rad(32 * -DriftDirection),
			0
		),
		
		12 * dt
	)

	Root.C0 = Root.C0:Lerp(

		CFrame.new(Root.C0.Position) * CFrame.fromEulerAnglesXYZ(
			0,
			0,
			math.rad(8 * RotationChange)
		), 

		12 * dt
	)
	
end

function UpdateSteeringWheel(Steer, steerDirection, dt)
	Steer.C1 = Steer.C1:Lerp(

		CFrame.fromEulerAnglesXYZ(
			0, 
			0, 
			math.rad(25 * -steerDirection)
		), 

		12 * dt
	)
end

function UpdateBackWheels(Left: Motor6D, Right: Motor6D, Accelerate: number, Speed: number, dt)

	--print(Accelerate, Left, Right, Speed, dt)

	local signed = math.sign(Accelerate)
	Accelerate = signed ~= 0 and signed or 1

	Left.C1 = Left.C1.Rotation:Lerp(
		Left.C1 * CFrame.fromEulerAnglesXYZ(math.rad(Accelerate * math.min(Speed, 100)),0,0),

		8 * dt
	)

	Right.C1 = Right.C1.Rotation:Lerp(
		Right.C1 * CFrame.fromEulerAnglesXYZ(math.rad(Accelerate * math.min(Speed, 100)), 0,0), 

		8 * dt
	)

end

function UpdateFrontWheels(Left: Motor6D, Right: Motor6D, Accelerate: number, Steer: number, Speed: number, dt: number)	
	--C0

	-------


	--C1
	--
	local signed = math.sign(Accelerate)
	Accelerate = signed ~= 0 and signed or 1
	--

	Left.C1 = Left.C1.Rotation:Lerp(
		Left.C1 * CFrame.fromEulerAnglesXYZ(math.rad(Accelerate * math.min(Speed, 100)),0,0),

		8 * dt
	)

	Right.C1 = Right.C1.Rotation:Lerp(
		Right.C1 * CFrame.fromEulerAnglesXYZ(math.rad(Accelerate * math.min(Speed, 100)), 0,0), 

		8 * dt
	)


	local x,_,z = Left.C1:ToEulerAnglesXYZ()

	Left.C0 = Left.C0:Lerp(
		CFrame.new(Left.C0.Position) * CFrame.fromEulerAnglesXYZ(0,math.rad(25 * Steer),0),

		8 * dt
	)

	Right.C0 = Right.C0:Lerp(
		CFrame.new(Right.C0.Position) * CFrame.fromEulerAnglesXYZ(0,math.rad(25 * Steer),0), 

		8 * dt
	)

end

--self, Kart: Model, BodyCFrame: CFrame, isDrifting, driftDirection, dt: number
function UpdateCFrame(Kart: Model, BodyCFrame: CFrame, isDrifting, driftDirection, steer, dt: number)
	local Position: Vector3 = BodyCFrame.Position
	local Rotation: CFrame = BodyCFrame.Rotation

	if isDrifting then	
		local newCFrame = CFrame.new(Position) * Kart.WorldPivot.Rotation:Lerp(
			Rotation * CFrame.fromEulerAnglesXYZ(
				0, 
				math.rad(5 * (driftDirection + steer)), 
				0
			), 

			12 * dt
		)

		Kart:PivotTo(newCFrame - Offset)
	else
		local newCFrame = CFrame.new(Position) * Kart.WorldPivot.Rotation:Lerp(Rotation, 12 * dt)
		Kart:PivotTo(newCFrame - Offset)
	end
end

function UpdateRotation(isDrifting, driftDirection, steerDirection)
	local min = driftDirection*.5
	local rotationChange = steerDirection

	if isDrifting then
		if min > 0 then
			rotationChange = math.max(steerDirection + driftDirection, min)
		else
			rotationChange = math.min(steerDirection + driftDirection, min)
		end
	end

	return rotationChange
end

function Kart.Update(self, dt, ...)
	local drifting: boolean,
		  driftDirection: number,
		  steer: number,
		  speed: number,
		  accelerate: number = ...
		  	
	
	local rotationChange = UpdateRotation(drifting, driftDirection, steer)
	
	if self.isLocal then
		UpdateCFrame(self.Vehicle, self.Body.CFrame, drifting, driftDirection, rotationChange, dt)
	end
	
	UpdateFrontWheels(self.FrontLeftWheel, self.FrontRightWheel, accelerate, steer, speed, dt)
	UpdateBackWheels(self.BackLeftWheel, self.BackRightWheel, accelerate, speed, dt)
	UpdateSteeringWheel(self.SteeringWheel, rotationChange, dt)
	UpdateCharacter(self.Character, rotationChange, driftDirection, dt)
end

return Kart	
