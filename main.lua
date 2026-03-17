local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local criminalATMSpawnersFolder = workspace:WaitForChild("Game")
	:WaitForChild("Jobs")
	:WaitForChild("CriminalATMSpawners")

--// =========================
--// SETTINGS
--// =========================

local SETTINGS = {
	Debug = true,

	-- Main loop
	WaitAfterTeleportToATM = 2,
	WaitAfterReturningFromCooldown = 1.5,
	RetryAttemptsPerATM = 2,

	-- Prompt
	PromptHoldTime = 6,
	PromptMaxActivationDistance = 5,
	PromptRecheckDelay = 1.3,
	PromptPostHoldDelay = 0.3,
	ExtraFinishedDelay = 0.75, -- extra settle time after a successful rob

	-- Camera
	UseATMFrontCamera = true,
	RestoreCameraAfterRob = true,
	CameraFrontDistance = 6,
	CameraHeightOffset = 2.5,
	CameraLookHeightOffset = 1.5,

	-- Teleport / movement
	AnchorDuringTeleport = true,
	TeleportSettleDelay = 0.05,

	-- Cooldown movement between ATMs
	UseCooldownTeleportLoop = true,
	CooldownPosition = Vector3.new(-20, 731, 3255),
	CooldownDuration = 1.5,
	CooldownMoveInterval = 0.15,

	-- Looping
	LoopInfinitely = true,
	WaitBetweenFullLoops = 60,

	-- Toggle / controls
	Enabled = true,
	ToggleKey = Enum.KeyCode.RightShift,
	StopKey = Enum.KeyCode.End,

	-- Extra QoL
	SkipUsedPositions = true,
	PrintLoopSummary = true,
	MoveToCooldownAtEnd = true,
}

--// =========================
--// ATM JSON
--// =========================

local atmJSON = [[
[{"Y":8.601656913757325,"X":-2775.947998046875,"Z":10241.5595703125},{"Y":27.110130310058595,"X":-2556.254150390625,"Z":2477.1708984375},{"Y":11.890100479125977,"X":-2225.52685546875,"Z":4091.53076171875},{"Y":11.384407997131348,"X":-2172.5068359375,"Z":4740.88916015625},{"Y":11.900482177734375,"X":-2085.01318359375,"Z":3411.333740234375},{"Y":11.897994041442871,"X":-2081.524658203125,"Z":2822.916748046875},{"Y":11.891409873962403,"X":-1992.78857421875,"Z":2693.77685546875},{"Y":11.808558464050293,"X":-1696.702880859375,"Z":4919.95556640625},{"Y":12.040742874145508,"X":-1681.794921875,"Z":1773.5260009765626},{"Y":11.064801216125489,"X":-1415.0499267578126,"Z":2840.72216796875},{"Y":11.307580947875977,"X":-1346.863037109375,"Z":4332.49951171875},{"Y":11.963729858398438,"X":-1249.5594482421876,"Z":2329.84033203125},{"Y":11.880024909973145,"X":-1206.79541015625,"Z":3698.99072265625},{"Y":23.032424926757814,"X":-1203.240966796875,"Z":-1144.1619873046876},{"Y":12.67477035522461,"X":-1201.1339111328126,"Z":2548.10107421875},{"Y":11.878620147705079,"X":-1129.900634765625,"Z":3246.55126953125},{"Y":23.03590965270996,"X":-1115.2147216796876,"Z":-833.89111328125},{"Y":8.640939712524414,"X":-1053.4998779296876,"Z":5045.58642578125},{"Y":23.00715446472168,"X":-976.2227172851563,"Z":-585.3759765625},{"Y":23.063749313354493,"X":-967.3648681640625,"Z":-1730.4329833984376},{"Y":8.627490043640137,"X":-872.58349609375,"Z":10614.3857421875},{"Y":11.889113426208496,"X":-859.392822265625,"Z":3780.761962890625},{"Y":12.01364517211914,"X":-815.7994995117188,"Z":3097.138671875},{"Y":22.519317626953126,"X":-631.2166137695313,"Z":-727.0564575195313},{"Y":23.23828887939453,"X":-611.370849609375,"Z":-31.71861457824707},{"Y":22.98494529724121,"X":-576.1636962890625,"Z":-972.8796997070313},{"Y":24.232742309570314,"X":-524.8099975585938,"Z":-431.9997863769531},{"Y":11.892912864685059,"X":-461.389892578125,"Z":3672.638671875},{"Y":23.236806869506837,"X":-372.7074890136719,"Z":63.74726104736328},{"Y":11.89174747467041,"X":-356.29437255859377,"Z":3194.325927734375},{"Y":23.182723999023439,"X":-271.8390808105469,"Z":-235.3688507080078},{"Y":24.21013069152832,"X":-251.64183044433595,"Z":-475.45245361328127},{"Y":23.133136749267579,"X":-97.7276382446289,"Z":-107.99128723144531},{"Y":23.18956184387207,"X":93.02099609375,"Z":-984.1406860351563},{"Y":26.067304611206056,"X":134.1066436767578,"Z":2186.60888671875},{"Y":11.697174072265625,"X":145.550048828125,"Z":3657.989501953125},{"Y":32.51835250854492,"X":195.1944580078125,"Z":-15.687950134277344},{"Y":9.03598403930664,"X":237.11480712890626,"Z":815.8687744140625},{"Y":23.19205093383789,"X":399.0374450683594,"Z":-978.0632934570313},{"Y":32.5456657409668,"X":591.8954467773438,"Z":189.41554260253907},{"Y":32.61363220214844,"X":595.930908203125,"Z":1622.7442626953126},{"Y":32.5269889831543,"X":881.5899047851563,"Z":187.8155517578125},{"Y":32.52302932739258,"X":886.73486328125,"Z":-86.29102325439453},{"Y":32.61841583251953,"X":992.3524780273438,"Z":1796.124755859375}]
]]

--// =========================
--// DEBUG / LOGGING
--// =========================

local function debugPrint(...)
	if SETTINGS.Debug then
		print("[ATM DEBUG]", ...)
	end
end

local function infoPrint(...)
	print("[ATM INFO]", ...)
end

local function warnPrint(...)
	warn("[ATM WARN]", ...)
end

--// =========================
--// STATE
--// =========================

local decoded = HttpService:JSONDecode(atmJSON)
local cframes = {}

for _, pos in ipairs(decoded) do
	table.insert(cframes, CFrame.new(pos.X, pos.Y, pos.Z))
end

local stats = {
	PositionsTotal = #cframes,
	PositionsVisited = 0,
	ATMsRobbed = 0,
	ATMRetryCount = 0,
	FindChecks = 0,
	LoopCount = 0,
}

local activeLoopToken = 0
local loopRunning = false

--// =========================
--// HELPERS
--// =========================

local function getCharacter()
	return player.Character or player.CharacterAdded:Wait()
end

local function getRoot()
	return getCharacter():WaitForChild("HumanoidRootPart")
end

local function getDistanceFromPlayer(worldPos: Vector3): number
	return (getRoot().Position - worldPos).Magnitude
end

local function isEnabled(loopToken: number?): boolean
	if loopToken ~= nil and loopToken ~= activeLoopToken then
		return false
	end
	return SETTINGS.Enabled
end

local function safeWait(duration: number, loopToken: number?): boolean
	local endTime = time() + duration
	while time() < endTime do
		if not isEnabled(loopToken) then
			return false
		end
		task.wait(0.05)
	end
	return true
end

local function tpExact(cf: CFrame)
	local hrp = getRoot()

	if SETTINGS.AnchorDuringTeleport then
		hrp.Anchored = true
	end

	hrp.CFrame = cf
	task.wait(SETTINGS.TeleportSettleDelay)

	if SETTINGS.AnchorDuringTeleport then
		hrp.Anchored = false
	end

	debugPrint("Teleported to:", cf.Position)
end

local function moveToPosition(pos: Vector3)
	getCharacter():MoveTo(pos)
	debugPrint("MoveTo:", pos)
end

local function restoreCamera()
	if SETTINGS.RestoreCameraAfterRob then
		camera.CameraType = Enum.CameraType.Custom
		debugPrint("Camera restored")
	end
end

local function pointCameraAtATMFront(atmModel: Model): boolean
	if not SETTINGS.UseATMFrontCamera then
		return false
	end

	local atmPart = atmModel:FindFirstChild("ATM")
	if not atmPart or not atmPart:IsA("BasePart") then
		debugPrint("ATM part missing for front camera")
		return false
	end

	camera.CameraType = Enum.CameraType.Scriptable

	local frontOffset = atmPart.CFrame.LookVector * -SETTINGS.CameraFrontDistance
	local upOffset = Vector3.new(0, SETTINGS.CameraHeightOffset, 0)
	local cameraPosition = atmPart.Position + frontOffset + upOffset
	local lookTarget = atmPart.Position + Vector3.new(0, SETTINGS.CameraLookHeightOffset, 0)

	camera.CFrame = CFrame.new(cameraPosition, lookTarget)
	debugPrint("Camera pointed at ATM front:", atmPart.Position)
	return true
end

local function fireProximityPrompt(prompt: ProximityPrompt, amount: number?, holdTime: number?)
	assert(prompt, "Argument #1 Missing or nil")
	assert(typeof(prompt) == "Instance" and prompt:IsA("ProximityPrompt"), "Not a ProximityPrompt")

	local completedEvent = Instance.new("BindableEvent")

	task.spawn(function()
		local originalHold = prompt.HoldDuration
		local originalDistance = prompt.MaxActivationDistance
		local duration = holdTime or SETTINGS.PromptHoldTime

		prompt.HoldDuration = duration
		prompt.MaxActivationDistance = SETTINGS.PromptMaxActivationDistance

		debugPrint("Holding prompt. Duration:", duration, "MaxDistance:", SETTINGS.PromptMaxActivationDistance)

		for _ = 1, amount or 1 do
			prompt:InputHoldBegin()

			local start = time()
			repeat
				RunService.Heartbeat:Wait()
			until time() - start >= duration

			prompt:InputHoldEnd()
		end

		prompt.HoldDuration = originalHold
		prompt.MaxActivationDistance = originalDistance
		debugPrint("Prompt finished, restored values")

		completedEvent:Fire()
	end)

	return {
		Completed = completedEvent.Event
	}
end

local function getATMData(atm: Model)
	local attachment = atm:FindFirstChild("Attachment")
	local prompt = attachment and attachment:FindFirstChildWhichIsA("ProximityPrompt")
	local atmPart = atm:FindFirstChild("ATM")
	return attachment, prompt, atmPart
end

local function isPromptValid(prompt: ProximityPrompt?): boolean
	return prompt ~= nil and prompt.Enabled == true
end

local function doCooldownMoveLoop(originalCF: CFrame, loopToken: number)
	if not SETTINGS.UseCooldownTeleportLoop or not isEnabled(loopToken) then
		debugPrint("Cooldown move loop skipped")
		return
	end

	debugPrint("Starting cooldown move loop for", SETTINGS.CooldownDuration, "seconds")

	local endTime = time() + SETTINGS.CooldownDuration
	while time() < endTime do
		if not isEnabled(loopToken) then
			return
		end
		moveToPosition(SETTINGS.CooldownPosition)
		task.wait(SETTINGS.CooldownMoveInterval)
	end

	if isEnabled(loopToken) then
		debugPrint("Returning from cooldown move loop")
		tpExact(originalCF)
	end
end

--// =========================
--// ATM LOGIC
--// =========================

local function tryRobATM(atm: Model, loopToken: number): boolean
	local _, prompt, atmPart = getATMData(atm)
	if not isPromptValid(prompt) or not isEnabled(loopToken) then
		debugPrint("Prompt invalid before rob attempt")
		return false
	end

	local atmPivot = atm:GetPivot()

	for attempt = 1, SETTINGS.RetryAttemptsPerATM do
		if not isEnabled(loopToken) then
			return false
		end

		debugPrint("ATM rob attempt", attempt, "at", atmPivot.Position)
		stats.ATMRetryCount += 1

		tpExact(atmPivot)
		pointCameraAtATMFront(atm)

		if not safeWait(SETTINGS.PromptRecheckDelay, loopToken) then
			restoreCamera()
			return false
		end

		local _, recheckPrompt = getATMData(atm)
		if not isPromptValid(recheckPrompt) then
			debugPrint("Prompt invalid after recheck delay")
			restoreCamera()
			continue
		end

		if atmPart then
			debugPrint("ATM part found. Distance from player:", math.floor(getDistanceFromPlayer(atmPart.Position) * 100) / 100)
		end

		local action = fireProximityPrompt(recheckPrompt, 1, SETTINGS.PromptHoldTime)
		action.Completed:Wait()

		if not safeWait(SETTINGS.PromptPostHoldDelay, loopToken) then
			restoreCamera()
			return false
		end

		local _, finalPrompt = getATMData(atm)

		if finalPrompt and finalPrompt.Enabled then
			restoreCamera()
			warnPrint("Prompt still enabled after attempt", attempt)
			continue
		end

		-- success path; do not move away immediately
		if not safeWait(SETTINGS.ExtraFinishedDelay, loopToken) then
			restoreCamera()
			return false
		end

		restoreCamera()
		stats.ATMsRobbed += 1
		infoPrint("ATM robbed successfully at:", atmPivot.Position)
		return true
	end

	restoreCamera()
	warnPrint("ATM rob failed after retries:", atmPivot.Position)
	return false
end

local function findValidATM(loopToken: number): boolean
	stats.FindChecks += 1
	debugPrint("Scanning for valid ATMs. Check #", stats.FindChecks)

	for _, atmSpawner in ipairs(criminalATMSpawnersFolder:GetChildren()) do
		if not isEnabled(loopToken) then
			return false
		end

		local atm = atmSpawner:FindFirstChild("CriminalATM")
		if not atm or not atm:IsA("Model") then
			continue
		end

		local _, prompt = getATMData(atm)
		if not isPromptValid(prompt) then
			debugPrint("ATM exists but prompt invalid:", atm:GetFullName())
			continue
		end

		debugPrint("Found candidate ATM:", atm:GetFullName())

		if tryRobATM(atm, loopToken) then
			return true
		end
	end

	debugPrint("No valid ATM found this scan")
	return false
end

local function runATMPosition(index: number, cf: CFrame, usedPositions: {[number]: boolean}, loopToken: number)
	if SETTINGS.SkipUsedPositions and usedPositions[index] then
		debugPrint("Skipping used position index:", index)
		return
	end

	if not isEnabled(loopToken) then
		return
	end

	infoPrint(("Visiting ATM position %d / %d"):format(index, stats.PositionsTotal))

	tpExact(cf)
	usedPositions[index] = true
	stats.PositionsVisited += 1

	if not safeWait(SETTINGS.WaitAfterTeleportToATM, loopToken) then
		return
	end

	local found = findValidATM(loopToken)
	if found then
		infoPrint("ATM interaction complete at position index:", index)
	else
		debugPrint("No ATM found at position index:", index)
	end

	-- only do cooldown after the full ATM attempt is done
	doCooldownMoveLoop(cf, loopToken)

	if not safeWait(SETTINGS.WaitAfterReturningFromCooldown, loopToken) then
		return
	end

	local foundAgain = findValidATM(loopToken)
	if foundAgain then
		infoPrint("ATM interaction complete after return at position index:", index)
	else
		debugPrint("Still no ATM found after returning to position index:", index)
	end
end

local function printSummary()
	if not SETTINGS.PrintLoopSummary then
		return
	end

	print("========== ATM LOOP SUMMARY ==========")
	print("Loop count:", stats.LoopCount)
	print("Total positions:", stats.PositionsTotal)
	print("Visited positions:", stats.PositionsVisited)
	print("ATMs robbed:", stats.ATMsRobbed)
	print("Find checks:", stats.FindChecks)
	print("Retry attempts:", stats.ATMRetryCount)
	print("======================================")
end

local function startLoop()
	local completedEvent = Instance.new("BindableEvent")
	activeLoopToken += 1
	local myLoopToken = activeLoopToken

	task.spawn(function()
		if loopRunning then
			warnPrint("Loop already running")
			completedEvent:Fire()
			return
		end

		loopRunning = true

		while isEnabled(myLoopToken) do
			stats.LoopCount += 1
			stats.PositionsVisited = 0

			local usedPositions = {}
			infoPrint("Starting ATM loop #", stats.LoopCount, "with", stats.PositionsTotal, "positions")

			for index, cf in ipairs(cframes) do
				if not isEnabled(myLoopToken) then
					break
				end
				runATMPosition(index, cf, usedPositions, myLoopToken)
			end

			if not isEnabled(myLoopToken) then
				break
			end

			print("Loop Complete")
			printSummary()

			if SETTINGS.MoveToCooldownAtEnd then
				moveToPosition(SETTINGS.CooldownPosition)
			end

			if not SETTINGS.LoopInfinitely then
				break
			end

			infoPrint("Waiting", SETTINGS.WaitBetweenFullLoops, "seconds before next loop")
			if not safeWait(SETTINGS.WaitBetweenFullLoops, myLoopToken) then
				break
			end
		end

		loopRunning = false
		completedEvent:Fire()
	end)

	return {
		Completed = completedEvent.Event
	}
end

--// =========================
--// TOGGLE / QOL
--// =========================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == SETTINGS.ToggleKey then
		SETTINGS.Enabled = not SETTINGS.Enabled
		infoPrint("ATM loop toggled:", SETTINGS.Enabled)

		if SETTINGS.Enabled and not loopRunning then
			local loop = startLoop()
			task.spawn(function()
				loop.Completed:Wait()
				debugPrint("Loop task completed after toggle")
			end)
		else
			activeLoopToken += 1
			restoreCamera()
		end
	elseif input.KeyCode == SETTINGS.StopKey then
		SETTINGS.Enabled = false
		activeLoopToken += 1
		restoreCamera()
		infoPrint("ATM loop stopped")
	end
end)

--// =========================
--// START
--// =========================

local loop = startLoop()
loop.Completed:Wait()
