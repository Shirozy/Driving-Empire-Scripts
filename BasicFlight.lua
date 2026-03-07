local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local FLY_KEY = Enum.KeyCode.F
local FLY_SPEED = 80
local ASCEND_SPEED = 60
local CONTROL_SMOOTHING = 0.15

local flying = false
local character, humanoid, rootPart
local bodyVelocity, bodyGyro

local moveState = {
	forward = 0,
	backward = 0,
	left = 0,
	right = 0,
	up = 0,
	down = 0
}

local currentVelocity = Vector3.zero

local function getCharacter()
	character = player.Character or player.CharacterAdded:Wait()
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
end

getCharacter()

player.CharacterAdded:Connect(function()
	getCharacter()
	if flying then
		flying = false
	end
end)

local function createFlyObjects()
	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Name = "DevFlyVelocity"
	bodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	bodyVelocity.Velocity = Vector3.zero
	bodyVelocity.P = 25000
	bodyVelocity.Parent = rootPart

	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.Name = "DevFlyGyro"
	bodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
	bodyGyro.P = 25000
	bodyGyro.D = 1000
	bodyGyro.CFrame = camera.CFrame
	bodyGyro.Parent = rootPart
end

local function removeFlyObjects()
	if bodyVelocity then
		bodyVelocity:Destroy()
		bodyVelocity = nil
	end

	if bodyGyro then
		bodyGyro:Destroy()
		bodyGyro = nil
	end
end

local function setFlying(state)
	flying = state

	if flying then
		if not character or not character.Parent then
			getCharacter()
		end

		createFlyObjects()
		humanoid.PlatformStand = true
		currentVelocity = Vector3.zero
	else
		humanoid.PlatformStand = false
		currentVelocity = Vector3.zero
		removeFlyObjects()
	end
end

local function toggleFly()
	setFlying(not flying)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == FLY_KEY then
		toggleFly()
	elseif input.KeyCode == Enum.KeyCode.W then
		moveState.forward = 1
	elseif input.KeyCode == Enum.KeyCode.S then
		moveState.backward = 1
	elseif input.KeyCode == Enum.KeyCode.A then
		moveState.left = 1
	elseif input.KeyCode == Enum.KeyCode.D then
		moveState.right = 1
	elseif input.KeyCode == Enum.KeyCode.Space then
		moveState.up = 1
	elseif input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.LeftShift then
		moveState.down = 1
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.W then
		moveState.forward = 0
	elseif input.KeyCode == Enum.KeyCode.S then
		moveState.backward = 0
	elseif input.KeyCode == Enum.KeyCode.A then
		moveState.left = 0
	elseif input.KeyCode == Enum.KeyCode.D then
		moveState.right = 0
	elseif input.KeyCode == Enum.KeyCode.Space then
		moveState.up = 0
	elseif input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.LeftShift then
		moveState.down = 0
	end
end)

RunService.RenderStepped:Connect(function()
	if not flying then
		return
	end

	if not character or not character.Parent or not rootPart or not humanoid then
		return
	end

	local camCFrame = camera.CFrame
	local lookVector = camCFrame.LookVector
	local rightVector = camCFrame.RightVector

	local forward = moveState.forward - moveState.backward
	local strafe = moveState.right - moveState.left
	local vertical = moveState.up - moveState.down

	local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z)
	if flatLook.Magnitude > 0 then
		flatLook = flatLook.Unit
	end

	local flatRight = Vector3.new(rightVector.X, 0, rightVector.Z)
	if flatRight.Magnitude > 0 then
		flatRight = flatRight.Unit
	end

	local targetVelocity =
		(flatLook * forward * FLY_SPEED) +
		(flatRight * strafe * FLY_SPEED) +
		(Vector3.new(0, vertical * ASCEND_SPEED, 0))

	currentVelocity = currentVelocity:Lerp(targetVelocity, CONTROL_SMOOTHING)
	bodyVelocity.Velocity = currentVelocity

	bodyGyro.CFrame = CFrame.new(rootPart.Position, rootPart.Position + camCFrame.LookVector)
end)
