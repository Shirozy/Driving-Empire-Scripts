--// =========================================
--// ATM AUTO ROBBER + NEKOHUB UI
--// Full file
--// =========================================

--// Services
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local anti_afk_connection = nil

local criminal_atm_spawners_folder = workspace:WaitForChild("Game")
	:WaitForChild("Jobs")
	:WaitForChild("CriminalATMSpawners")

--// =========================================
--// UI LIB
--// =========================================

local Themes = loadstring(game:HttpGet("https://raw.githubusercontent.com/Shirozy/NekoHub-UI-Lib/refs/heads/main/themes.lua"))()
local UILibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/Shirozy/NekoHub-UI-Lib/refs/heads/main/RobloxUILibraryShell.lua"))()

local ui = UILibrary.new({
	Themes = Themes,
	DefaultTheme = "Gruvbox",
    ToggleKey = Enum.KeyCode.RightShift,
})

ui:SetPromptText("Press RightShift to open UI")
ui:ShowPrompt(true)
ui:SetKeybindOverlayEnabled(true)

--// =========================================
--// SETTINGS
--// =========================================

local SETTINGS = {
	Debug = true,

	-- Main loop
	WaitAfterTeleportToATM = 2,
	WaitAfterReturningFromCooldown = 1.5,
	RetryAttemptsPerATM = 2,

	-- Wait modes
	WaitMode = 3, -- 1 = always wait for timer, 2 = money threshold-based, 3 = timer threshold-based
	MoneyThresholdBeforeWaiting = 50000,
	TimeThresholdBeforeWaiting = 300,
	WaitCheckInterval = 0.25,

	-- Success detection
	SuccessCheckWindow = 2.25,
	SuccessCheckPollInterval = 0.15,
	MissingTimerGracePeriod = 3,

	-- Prompt
	PromptHoldTime = 6,
	PromptMaxActivationDistance = 5,
	PromptRecheckDelay = 1.3,
	PromptPostHoldDelay = 1.25,
	ExtraFinishedDelay = 1.75,

	-- Camera
	UseATMFrontCamera = true,
	RestoreCameraAfterRob = true,
	CameraFrontDistance = 6,
	CameraHeightOffset = 2.5,
	CameraLookHeightOffset = 1.5,

	-- Teleport / movement
	AnchorDuringTeleport = true,
	TeleportSettleDelay = 0.05,

	-- Cooldown movement between ATM
	CooldownPosition = Vector3.new(-20, 731, 3255),

	-- Looping
	LoopInfinitely = true,
	WaitBetweenFullLoops = 60,

	-- Toggle / controls
	Enabled = false,
	ToggleKey = Enum.KeyCode.RightShift,
	StopKey = Enum.KeyCode.End,

	-- Extra QoL
	SkipUsedPositions = true,
	PrintLoopSummary = true,
	MoveToCooldownAtEnd = true,
	CloseLocationUIBeforeEachTP = true,

    fly = false,
}

--// =========================================
--// ATM JSON
--// =========================================

local atm_json = [[
[{"Y":8.601656913757325,"X":-2775.947998046875,"Z":10241.5595703125},{"Y":27.110130310058595,"X":-2556.254150390625,"Z":2477.1708984375},{"Y":11.890100479125977,"X":-2225.52685546875,"Z":4091.53076171875},{"Y":11.384407997131348,"X":-2172.5068359375,"Z":4740.88916015625},{"Y":11.900482177734375,"X":-2085.01318359375,"Z":3411.333740234375},{"Y":11.897994041442871,"X":-2081.524658203125,"Z":2822.916748046875},{"Y":11.891409873962403,"X":-1992.78857421875,"Z":2693.77685546875},{"Y":11.808558464050293,"X":-1696.702880859375,"Z":4919.95556640625},{"Y":12.040742874145508,"X":-1681.794921875,"Z":1773.5260009765626},{"Y":11.064801216125489,"X":-1415.0499267578126,"Z":2840.72216796875},{"Y":11.307580947875977,"X":-1346.863037109375,"Z":4332.49951171875},{"Y":11.963729858398438,"X":-1249.5594482421876,"Z":2329.84033203125},{"Y":11.880024909973145,"X":-1206.79541015625,"Z":3698.99072265625},{"Y":23.032424926757814,"X":-1203.240966796875,"Z":-1144.1619873046876},{"Y":12.67477035522461,"X":-1201.1339111328126,"Z":2548.10107421875},{"Y":11.878620147705079,"X":-1129.900634765625,"Z":3246.55126953125},{"Y":23.03590965270996,"X":-1115.2147216796876,"Z":-833.89111328125},{"Y":8.640939712524414,"X":-1053.4998779296876,"Z":5045.58642578125},{"Y":23.00715446472168,"X":-976.2227172851563,"Z":-585.3759765625},{"Y":23.063749313354493,"X":-967.3648681640625,"Z":-1730.4329833984376},{"Y":8.627490043640137,"X":-872.58349609375,"Z":10614.3857421875},{"Y":11.889113426208496,"X":-859.392822265625,"Z":3780.761962890625},{"Y":12.01364517211914,"X":-815.7994995117188,"Z":3097.138671875},{"Y":22.519317626953126,"X":-631.2166137695313,"Z":-727.0564575195313},{"Y":23.23828887939453,"X":-611.370849609375,"Z":-31.71861457824707},{"Y":22.98494529724121,"X":-576.1636962890625,"Z":-972.8796997070313},{"Y":24.232742309570314,"X":-524.8099975585938,"Z":-431.9997863769531},{"Y":11.892912864685059,"X":-461.389892578125,"Z":3672.638671875},{"Y":23.236806869506837,"X":-372.7074890136719,"Z":63.74726104736328},{"Y":11.89174747467041,"X":-356.29437255859377,"Z":3194.325927734375},{"Y":23.182723999023439,"X":-271.8390808105469,"Z":-235.3688507080078},{"Y":24.21013069152832,"X":-251.64183044433595,"Z":-475.45245361328127},{"Y":23.133136749267579,"X":-97.7276382446289,"Z":-107.99128723144531},{"Y":23.18956184387207,"X":93.02099609375,"Z":-984.1406860351563},{"Y":26.067304611206056,"X":134.1066436767578,"Z":2186.60888671875},{"Y":11.697174072265625,"X":145.550048828125,"Z":3657.989501953125},{"Y":32.51835250854492,"X":195.1944580078125,"Z":-15.687950134277344},{"Y":9.03598403930664,"X":237.11480712890626,"Z":815.8687744140625},{"Y":23.19205093383789,"X":399.0374450683594,"Z":-978.0632934570313},{"Y":32.5456657409668,"X":591.8954467773438,"Z":189.41554260253907},{"Y":32.61363220214844,"X":595.930908203125,"Z":1622.7442626953126},{"Y":32.5269889831543,"X":881.5899047851563,"Z":187.8155517578125},{"Y":32.52302932739258,"X":886.73486328125,"Z":-86.29102325439453},{"Y":32.61841583251953,"X":992.3524780273438,"Z":1796.124755859375}]
]]

--// =========================================
--// DEBUG / LOGGING
--// =========================================

local function debug_print(...)
	if SETTINGS.Debug then
		print("[ATM DEBUG]", ...)
	end
end

local function info_print(...)
	print("[ATM INFO]", ...)
end

local function warn_print(...)
	warn("[ATM WARN]", ...)
end

local function notify(title, content, duration)
	pcall(function()
		ui:Notify({
			Title = title or "ATM",
			Content = content or "",
			Duration = duration or 3,
		})
	end)
end

--// =========================================
--// STATE
--// =========================================

local decoded = HttpService:JSONDecode(atm_json)
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

local active_loop_token = 0
local loop_running = false
local last_cash = 0

--// =========================================
--// FORWARD DECLARATIONS
--// =========================================

local get_player_cash
local handle_post_atm_wait
local start_loop
local stop_loop
local refresh_stats_ui

--// =========================================
--// HELPERS
--// =========================================

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

local function reset_move_state()
	moveState.forward = 0
	moveState.backward = 0
	moveState.left = 0
	moveState.right = 0
	moveState.up = 0
	moveState.down = 0
end

local function createFlyObjects()
	if bodyVelocity then
		bodyVelocity:Destroy()
	end

	if bodyGyro then
		bodyGyro:Destroy()
	end

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

local function set_fly_state(state)
	state = not not state

	if state == flying then
		return
	end

	if not character or not character.Parent or not humanoid or not rootPart then
		getCharacter()
	end

	flying = state

	if flying then
		createFlyObjects()
		humanoid.PlatformStand = true
		currentVelocity = Vector3.zero
		reset_move_state()
		print("Fly Enabled")
	else
		if humanoid then
			humanoid.PlatformStand = false
		end

		currentVelocity = Vector3.zero
		reset_move_state()
		removeFlyObjects()
		print("Fly Disabled")
	end
end

local function toggleFly()
	set_fly_state(not flying)
end

getCharacter()

player.CharacterAdded:Connect(function()
	getCharacter()

	if flying then
		task.defer(function()
			if character and character.Parent then
				set_fly_state(true)
			end
		end)
	end
end)

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

	if not bodyVelocity or not bodyGyro then
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

local function get_character()
	return player.Character or player.CharacterAdded:Wait()
end

local function get_root()
	return get_character():WaitForChild("HumanoidRootPart")
end

local function get_distance_from_player(world_pos: Vector3): number
	return (get_root().Position - world_pos).Magnitude
end

local function is_enabled(loop_token: number?): boolean
	if loop_token ~= nil and loop_token ~= active_loop_token then
		return false
	end

	return SETTINGS.Enabled
end

local function safe_wait(duration: number, loop_token: number?): boolean
	local end_time = time() + duration

	while time() < end_time do
		if not is_enabled(loop_token) then
			return false
		end

		task.wait(0.05)
	end

	return true
end

local function tp_exact(cf: CFrame)
	local hrp = get_root()

	if SETTINGS.AnchorDuringTeleport then
		hrp.Anchored = true
	end

	hrp.CFrame = cf
	task.wait(SETTINGS.TeleportSettleDelay)

	if SETTINGS.AnchorDuringTeleport then
		hrp.Anchored = false
	end
end

local function move_to_position(pos: Vector3)
	get_character():MoveTo(pos)
	debug_print("MoveTo:", pos)
end

local function restore_camera()
	if SETTINGS.RestoreCameraAfterRob then
		camera.CameraType = Enum.CameraType.Custom
		debug_print("Camera restored")
	end
end

local function point_camera_at_atm_front(atm_model: Model): boolean
	if not SETTINGS.UseATMFrontCamera then
		return false
	end

	local atm_part = atm_model:FindFirstChild("ATM")
	if not atm_part or not atm_part:IsA("BasePart") then
		debug_print("ATM part missing for front camera")
		return false
	end

	camera.CameraType = Enum.CameraType.Scriptable

	local front_offset = atm_part.CFrame.LookVector * -SETTINGS.CameraFrontDistance
	local up_offset = Vector3.new(0, SETTINGS.CameraHeightOffset, 0)
	local camera_position = atm_part.Position + front_offset + up_offset
	local look_target = atm_part.Position + Vector3.new(0, SETTINGS.CameraLookHeightOffset, 0)

	camera.CFrame = CFrame.new(camera_position, look_target)
	debug_print("Camera pointed at ATM front:", atm_part.Position)
	return true
end

local function fire_proximity_prompt(prompt: ProximityPrompt, amount: number?, hold_time: number?)
	assert(prompt, "Argument #1 Missing or nil")
	assert(typeof(prompt) == "Instance" and prompt:IsA("ProximityPrompt"), "Not a ProximityPrompt")

	local completed_event = Instance.new("BindableEvent")

	task.spawn(function()
		local original_hold = prompt.HoldDuration
		local original_distance = prompt.MaxActivationDistance
		local duration = hold_time or SETTINGS.PromptHoldTime

		prompt.HoldDuration = duration
		prompt.MaxActivationDistance = SETTINGS.PromptMaxActivationDistance

		debug_print("Holding prompt. Duration:", duration, "MaxDistance:", SETTINGS.PromptMaxActivationDistance)

		for _ = 1, amount or 1 do
			prompt:InputHoldBegin()

			local start_time = time()
			repeat
				RunService.Heartbeat:Wait()
			until time() - start_time >= duration

			prompt:InputHoldEnd()
		end

		prompt.HoldDuration = original_hold
		prompt.MaxActivationDistance = original_distance
		debug_print("Prompt finished, restored values")

		completed_event:Fire()
	end)

	return {
		Completed = completed_event.Event,
	}
end

local function get_atm_data(atm: Model)
	local attachment = atm:FindFirstChild("Attachment")
	local prompt = attachment and attachment:FindFirstChildWhichIsA("ProximityPrompt")
	local atm_part = atm:FindFirstChild("ATM")
	return attachment, prompt, atm_part
end

local function is_prompt_valid(prompt: ProximityPrompt?): boolean
	return prompt ~= nil and prompt.Enabled == true
end

local function close_location_ui()
	if not SETTINGS.CloseLocationUIBeforeEachTP then
		return
	end

	local remoteFolder = ReplicatedStorage:FindFirstChild("Remotes")
	local remote = remoteFolder and remoteFolder:FindFirstChild("Location")
	if remote then
		pcall(function()
			remote:FireServer("Leave")
		end)
		debug_print("Closed Any UI")
	end
end

--// =========================================
--// NOTIFICATION + CASH
--// =========================================

local notifications = player.PlayerGui:WaitForChild("MainHUD"):WaitForChild("Notification")

local function time_to_seconds(time_text: string): number
	local minutes, seconds = string.match(time_text, "^(%d+):(%d+)$")

	if not minutes or not seconds then
		return 0
	end

	return (tonumber(minutes) * 60) + tonumber(seconds)
end

type NotificationMode = "time_text" | "seconds" | "both"

local function get_escape_notification(mode: NotificationMode)
	for _, notification in ipairs(notifications:GetChildren()) do
		if not notification:IsA("ImageLabel") then
			continue
		end

		local title = notification:FindFirstChild("Title")
		if not title or not title:IsA("TextLabel") then
			continue
		end

		local time_text = string.match(title.Text, "^Escape the security:%s*(%d+:%d+)$")
		if not time_text then
			continue
		end

		local seconds = time_to_seconds(time_text)

		if mode == "time_text" then
			return time_text
		elseif mode == "seconds" then
			return seconds
		elseif mode == "both" then
			return time_text, seconds
		end
	end

	return nil
end

local function get_player_criminal_cash_label(): TextLabel?
	local character = player.Character or player.CharacterAdded:Wait()
	local head = character:FindFirstChild("Head")
	if not head then
		return nil
	end

	local billboard = head:FindFirstChild("CharacterBillboard")
	if not billboard then
		return nil
	end

	for _, instance in ipairs(billboard:GetChildren()) do
		if instance:IsA("TextLabel") and string.match(instance.Text, "^%$") then
			return instance
		end
	end

	return nil
end

local function parse_cash_text(text: string): (number, number)
	local cleaned = text:gsub("[%$,]", "")
	local dollars, cents = string.match(cleaned, "^(%d+)%.?(%d*)$")

	return tonumber(dollars) or 0, tonumber(cents) or 0
end

type CashMode = "no_cents" | "with_cents" | "split"

get_player_cash = function(mode: CashMode)
	local label = get_player_criminal_cash_label()
	if not label then
		return nil
	end

	local dollars, cents = parse_cash_text(label.Text)

	if mode == "no_cents" then
		return dollars
	elseif mode == "with_cents" then
		return dollars + (cents / 100)
	elseif mode == "split" then
		return dollars, cents
	end

	return nil
end

local function get_safe_cash(): number
	local ok, value = pcall(function()
		return get_player_cash("no_cents")
	end)

	if ok and value ~= nil then
		last_cash = value
	end

	return last_cash
end

local function timer_indicates_success(start_timer: number?, end_timer: number?): boolean
	if start_timer == nil and end_timer ~= nil then
		return true
	end

	if start_timer ~= nil and end_timer ~= nil then
		return end_timer > start_timer
	end

	return false
end

local function wait_until_escape_timer_ends(loop_token: number?): boolean
	local nil_timer_started_at = nil :: number?

	while is_enabled(loop_token) do
		local seconds_left = get_escape_notification("seconds")

		if seconds_left == nil then
			if nil_timer_started_at == nil then
				nil_timer_started_at = time()
			end

			if time() - nil_timer_started_at >= SETTINGS.MissingTimerGracePeriod then
				debug_print("No escape timer found for grace period; continuing")
				return true
			end

			if not safe_wait(SETTINGS.WaitCheckInterval, loop_token) then
				return false
			end

			continue
		end

		nil_timer_started_at = nil

		if seconds_left <= 0 then
			debug_print("Escape timer finished")
			return true
		end

		debug_print("Waiting for timer to finish. Seconds left:", seconds_left)
		tp_exact(CFrame.new(SETTINGS.CooldownPosition))

		if not safe_wait(math.min(SETTINGS.WaitCheckInterval, seconds_left), loop_token) then
			return false
		end
	end

	return false
end

handle_post_atm_wait = function(loop_token: number?): boolean
	info_print("handle_post_atm_wait called. Mode:", SETTINGS.WaitMode)

	if SETTINGS.WaitMode == 1 then
		info_print("WaitMode 1: waiting for timer after ATM")
		return wait_until_escape_timer_ends(loop_token)
	end

	if SETTINGS.WaitMode == 2 then
		local cash_value = get_safe_cash()

		debug_print(
			"WaitMode 2 check. Cash:",
			cash_value,
			"Threshold:",
			SETTINGS.MoneyThresholdBeforeWaiting
		)

		if cash_value >= SETTINGS.MoneyThresholdBeforeWaiting then
			info_print("Money threshold reached, waiting for timer to finish")
			return wait_until_escape_timer_ends(loop_token)
		end

		debug_print("Money threshold not reached, continuing immediately")
		return true
	end

	if SETTINGS.WaitMode == 3 then
		local current_timer = get_escape_notification("seconds")

		debug_print(
			"WaitMode 3 check. Timer:",
			current_timer,
			"Threshold:",
			SETTINGS.TimeThresholdBeforeWaiting
		)

		if current_timer ~= nil and current_timer > SETTINGS.TimeThresholdBeforeWaiting then
			info_print("Timer threshold exceeded, waiting for timer to finish")
			return wait_until_escape_timer_ends(loop_token)
		end

		debug_print("Timer threshold not exceeded, continuing immediately")
		return true
	end

	warn_print("Unknown WaitMode:", SETTINGS.WaitMode)
	return true
end

local function do_cooldown_wait(original_cf: CFrame, loop_token: number)
	info_print("Entered cooldown wait")

	if not is_enabled(loop_token) then
		return
	end

	if not safe_wait(1, loop_token) then
		return
	end

	info_print("Moving to cooldown position...")
	tp_exact(CFrame.new(SETTINGS.CooldownPosition))

	info_print("Waiting at cooldown position...")

	if not handle_post_atm_wait(loop_token) then
		return
	end

	if is_enabled(loop_token) then
		info_print("Returning from cooldown...")
		tp_exact(original_cf)
	end
end

local function evaluate_attempt_success(
	atm: Model,
	final_prompt: ProximityPrompt?,
	start_timer: number?,
	start_cash: number,
	loop_token: number
): boolean
	local end_time = time() + SETTINGS.SuccessCheckWindow

	while time() < end_time and is_enabled(loop_token) do
		local current_timer = get_escape_notification("seconds")
		local current_cash = get_safe_cash()
		local _, refreshed_prompt = get_atm_data(atm)

		local timer_increased = timer_indicates_success(start_timer, current_timer)
		local cash_increased = current_cash > start_cash
		local prompt_disabled = refreshed_prompt ~= nil and refreshed_prompt.Enabled == false

		debug_print(
			"Success check:",
			"Timer:", start_timer, "->", current_timer,
			"Cash:", start_cash, "->", current_cash,
			"TimerIncreased:", timer_increased,
			"CashIncreased:", cash_increased,
			"PromptDisabled:", prompt_disabled
		)

		local success = false

		if SETTINGS.WaitMode == 1 then
			success = timer_increased or prompt_disabled
		elseif SETTINGS.WaitMode == 2 then
			success = timer_increased or cash_increased or prompt_disabled
		else
			success = timer_increased or cash_increased or prompt_disabled
		end

		if success then
			return true
		end

		task.wait(SETTINGS.SuccessCheckPollInterval)
	end

	return false
end

--// =========================================
--// ATM LOGIC
--// =========================================

local function try_rob_atm(atm: Model, loop_token: number): boolean
	local _, prompt, atm_part = get_atm_data(atm)
	if not is_prompt_valid(prompt) or not is_enabled(loop_token) then
		debug_print("Prompt invalid before rob attempt")
		return false
	end

	local atm_pivot = atm:GetPivot()

	for attempt = 1, SETTINGS.RetryAttemptsPerATM do
		if not is_enabled(loop_token) then
			return false
		end

		local start_timer = get_escape_notification("seconds")
		local start_cash = get_safe_cash()

		debug_print("ATM rob attempt", attempt, "at", atm_pivot.Position)
		debug_print("Attempt start state:", "Timer:", start_timer, "Cash:", start_cash)

		stats.ATMRetryCount += 1
		refresh_stats_ui()

		tp_exact(atm_pivot)
		point_camera_at_atm_front(atm)

		if not safe_wait(SETTINGS.PromptRecheckDelay, loop_token) then
			restore_camera()
			return false
		end

		local _, recheck_prompt = get_atm_data(atm)
		if not is_prompt_valid(recheck_prompt) then
			debug_print("Prompt invalid after recheck delay")
			restore_camera()
			continue
		end

		if atm_part then
			debug_print(
				"ATM part found. Distance from player:",
				math.floor(get_distance_from_player(atm_part.Position) * 100) / 100
			)
		end

		local action = fire_proximity_prompt(recheck_prompt, 1, SETTINGS.PromptHoldTime)
		action.Completed:Wait()

		if not safe_wait(SETTINGS.PromptPostHoldDelay, loop_token) then
			restore_camera()
			return false
		end

		local _, final_prompt = get_atm_data(atm)

		local success = evaluate_attempt_success(
			atm,
			final_prompt,
			start_timer,
			start_cash,
			loop_token
		)

		if not success then
			restore_camera()
			warn_print("ATM attempt considered FAILED (logic-based)")
			continue
		end

		if not safe_wait(SETTINGS.ExtraFinishedDelay, loop_token) then
			restore_camera()
			return false
		end

		restore_camera()
		stats.ATMsRobbed += 1
		refresh_stats_ui()
		info_print("ATM robbed successfully at:", atm_pivot.Position)

		do_cooldown_wait(atm_pivot, loop_token)

		return true
	end

	restore_camera()
	warn_print("ATM rob failed after retries:", atm_pivot.Position)
	return false
end

local function find_valid_atm(loop_token: number): boolean
	stats.FindChecks += 1
	refresh_stats_ui()
	debug_print("Scanning for valid ATMs. Check #", stats.FindChecks)

	for _, atm_spawner in ipairs(criminal_atm_spawners_folder:GetChildren()) do
		if not is_enabled(loop_token) then
			return false
		end

		local atm = atm_spawner:FindFirstChild("CriminalATM")
		if not atm or not atm:IsA("Model") then
			continue
		end

		local _, prompt = get_atm_data(atm)
		if not is_prompt_valid(prompt) then
			debug_print("ATM exists but prompt invalid:", atm:GetFullName())
			continue
		end

		debug_print("Found candidate ATM:", atm:GetFullName())

		if try_rob_atm(atm, loop_token) then
			return true
		end
	end

	debug_print("No valid ATM found this scan")
	return false
end

local function run_atm_position(index: number, cf: CFrame, used_positions: {[number]: boolean}, loop_token: number)
	if SETTINGS.SkipUsedPositions and used_positions[index] then
		debug_print("Skipping used position index:", index)
		return
	end

	if not is_enabled(loop_token) then
		return
	end

	close_location_ui()

	info_print(("Visiting ATM position %d / %d"):format(index, stats.PositionsTotal))

	tp_exact(cf)
	used_positions[index] = true
	stats.PositionsVisited += 1
	refresh_stats_ui()

	if not safe_wait(SETTINGS.WaitAfterTeleportToATM, loop_token) then
		return
	end

	local found = find_valid_atm(loop_token)
	if found then
		info_print("ATM interaction complete at position index:", index)
	else
		debug_print("No ATM found at position index:", index)
	end

	if not safe_wait(SETTINGS.WaitAfterReturningFromCooldown, loop_token) then
		return
	end

	local found_again = find_valid_atm(loop_token)
	if found_again then
		info_print("ATM interaction complete after return at position index:", index)
	else
		debug_print("Still no ATM found after returning to position index:", index)
	end
end

local function print_summary()
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

start_loop = function()
	local completed_event = Instance.new("BindableEvent")
	active_loop_token += 1
	local my_loop_token = active_loop_token

	task.spawn(function()
		if loop_running then
			warn_print("Loop already running")
			completed_event:Fire()
			return
		end

		loop_running = true
		notify("ATM", "Loop started", 3)

		while is_enabled(my_loop_token) do
			stats.LoopCount += 1
			stats.PositionsVisited = 0
			refresh_stats_ui()

			local used_positions = {}
			info_print("Starting ATM loop #", stats.LoopCount, "with", stats.PositionsTotal, "positions")

			for index, cf in ipairs(cframes) do
				if not is_enabled(my_loop_token) then
					break
				end

				run_atm_position(index, cf, used_positions, my_loop_token)
			end

			if not is_enabled(my_loop_token) then
				break
			end

			print("Loop Complete")
			print_summary()

			if SETTINGS.MoveToCooldownAtEnd then
				move_to_position(SETTINGS.CooldownPosition)
			end

			if not SETTINGS.LoopInfinitely then
				break
			end

			info_print("Waiting", SETTINGS.WaitBetweenFullLoops, "seconds before next loop")
			if not safe_wait(SETTINGS.WaitBetweenFullLoops, my_loop_token) then
				break
			end
		end

		loop_running = false
		restore_camera()
		refresh_stats_ui()
		notify("ATM", "Loop stopped", 3)
		completed_event:Fire()
	end)

	return {
		Completed = completed_event.Event,
	}
end

stop_loop = function()
	SETTINGS.Enabled = false
	active_loop_token += 1
	restore_camera()
	refresh_stats_ui()
end

--// =========================================
--// UI
--// =========================================

local mainTab = ui:AddTab({
	Name = "ATM Farm",
})

local controlSection = mainTab:AddSection({
	Name = "Controls",
	Description = "Main loop controls and live stats"
})

local loopSection = mainTab:AddSection({
	Name = "Loop Settings",
	Description = "Movement, retries, timing"
})

local waitSection = mainTab:AddSection({
	Name = "Wait Logic",
	Description = "Cooldown and threshold behavior"
})

local promptSection = mainTab:AddSection({
	Name = "Prompt / Camera",
	Description = "Prompt and ATM camera behavior"
})

local miscSection = mainTab:AddSection({
	Name = "Misc",
	Description = "QoL and debug options"
})

local statsParagraph = controlSection:AddParagraph({
	Name = "Live Stats",
	Text = "Initializing..."
})

refresh_stats_ui = function()
	local statusText = SETTINGS.Enabled and (loop_running and "Running" or "Enabled") or "Stopped"
	local currentCash = get_safe_cash()
	local timerValue = get_escape_notification("seconds")

	statsParagraph:SetText(table.concat({
		("Status: %s"):format(statusText),
		("Loop Running: %s"):format(tostring(loop_running)),
		("Loop Count: %d"):format(stats.LoopCount),
		("Positions Total: %d"):format(stats.PositionsTotal),
		("Visited This Loop: %d"):format(stats.PositionsVisited),
		("ATMs Robbed: %d"):format(stats.ATMsRobbed),
		("Retry Attempts: %d"):format(stats.ATMRetryCount),
		("Find Checks: %d"):format(stats.FindChecks),
		("Current Cash: $%s"):format(tostring(currentCash or 0)),
		("Escape Timer: %s"):format(timerValue and (tostring(timerValue) .. "s") or "nil"),
	}, "\n"))
end

controlSection:AddToggle({
	Name = "Enable ATM Loop",
	Default = SETTINGS.Enabled,
	Tooltip = "Starts or stops the ATM farm loop",
	Callback = function(state)
		SETTINGS.Enabled = state
		refresh_stats_ui()

		if state then
			if not loop_running then
				local loop = start_loop()
				task.spawn(function()
					loop.Completed:Wait()
				end)
			end
		else
			stop_loop()
		end
	end
})

controlSection:AddButton({
	Name = "Reset Stats",
	Tooltip = "Resets counters shown in the UI",
	Callback = function()
		stats.PositionsVisited = 0
		stats.ATMsRobbed = 0
		stats.ATMRetryCount = 0
		stats.FindChecks = 0
		stats.LoopCount = 0
		refresh_stats_ui()
		notify("ATM", "Stats reset", 3)
	end
})

controlSection:AddButton({
	Name = "Print Summary",
	Callback = function()
		print_summary()
		notify("ATM", "Printed summary to console", 3)
	end
})

loopSection:AddSlider({
	Name = "Wait After Teleport",
	Min = 0,
	Max = 10,
	Default = SETTINGS.WaitAfterTeleportToATM,
	Increment = 0.1,
	Callback = function(value)
		SETTINGS.WaitAfterTeleportToATM = value
	end
})

loopSection:AddSlider({
	Name = "Wait After Return",
	Min = 0,
	Max = 10,
	Default = SETTINGS.WaitAfterReturningFromCooldown,
	Increment = 0.1,
	Callback = function(value)
		SETTINGS.WaitAfterReturningFromCooldown = value
	end
})

loopSection:AddSlider({
	Name = "Retry Attempts Per ATM",
	Min = 1,
	Max = 10,
	Default = SETTINGS.RetryAttemptsPerATM,
	Increment = 1,
	Callback = function(value)
		SETTINGS.RetryAttemptsPerATM = value
	end
})

loopSection:AddToggle({
	Name = "Loop Infinitely",
	Default = SETTINGS.LoopInfinitely,
	Callback = function(state)
		SETTINGS.LoopInfinitely = state
	end
})

loopSection:AddSlider({
	Name = "Wait Between Full Loops",
	Min = 0,
	Max = 300,
	Default = SETTINGS.WaitBetweenFullLoops,
	Increment = 1,
	Callback = function(value)
		SETTINGS.WaitBetweenFullLoops = value
	end
})

waitSection:AddDropdown({
	Name = "Wait Mode",
	Items = {"Always Wait", "Money Threshold", "Timer Threshold"},
	Default = "Timer Threshold",
	Tooltip = "Chooses how the script decides to wait after robbing an ATM",
	Callback = function(value)
		if value == "Always Wait" then
			SETTINGS.WaitMode = 1
		elseif value == "Money Threshold" then
			SETTINGS.WaitMode = 2
		elseif value == "Timer Threshold" then
			SETTINGS.WaitMode = 3
		end
	end
})

waitSection:AddSlider({
	Name = "Money Threshold",
	Min = 0,
	Max = 500000,
	Default = SETTINGS.MoneyThresholdBeforeWaiting,
	Increment = 1000,
	Callback = function(value)
		SETTINGS.MoneyThresholdBeforeWaiting = value
	end
})

waitSection:AddSlider({
	Name = "Timer Threshold (Seconds)",
	Min = 0,
	Max = 1200,
	Default = SETTINGS.TimeThresholdBeforeWaiting,
	Increment = 5,
	Callback = function(value)
		SETTINGS.TimeThresholdBeforeWaiting = value
	end
})

waitSection:AddSlider({
	Name = "Wait Check Interval",
	Min = 0.05,
	Max = 2,
	Default = SETTINGS.WaitCheckInterval,
	Increment = 0.05,
	Callback = function(value)
		SETTINGS.WaitCheckInterval = value
	end
})

waitSection:AddSlider({
	Name = "Success Check Window",
	Min = 0.5,
	Max = 10,
	Default = SETTINGS.SuccessCheckWindow,
	Increment = 0.05,
	Callback = function(value)
		SETTINGS.SuccessCheckWindow = value
	end
})

waitSection:AddSlider({
	Name = "Success Poll Interval",
	Min = 0.05,
	Max = 1,
	Default = SETTINGS.SuccessCheckPollInterval,
	Increment = 0.05,
	Callback = function(value)
		SETTINGS.SuccessCheckPollInterval = value
	end
})

waitSection:AddSlider({
	Name = "Missing Timer Grace",
	Min = 0,
	Max = 15,
	Default = SETTINGS.MissingTimerGracePeriod,
	Increment = 0.25,
	Callback = function(value)
		SETTINGS.MissingTimerGracePeriod = value
	end
})

promptSection:AddSlider({
	Name = "Prompt Hold Time",
	Min = 0.5,
	Max = 15,
	Default = SETTINGS.PromptHoldTime,
	Increment = 0.1,
	Callback = function(value)
		SETTINGS.PromptHoldTime = value
	end
})

promptSection:AddSlider({
	Name = "Prompt Max Distance",
	Min = 1,
	Max = 20,
	Default = SETTINGS.PromptMaxActivationDistance,
	Increment = 0.5,
	Callback = function(value)
		SETTINGS.PromptMaxActivationDistance = value
	end
})

promptSection:AddSlider({
	Name = "Prompt Recheck Delay",
	Min = 0,
	Max = 5,
	Default = SETTINGS.PromptRecheckDelay,
	Increment = 0.05,
	Callback = function(value)
		SETTINGS.PromptRecheckDelay = value
	end
})

promptSection:AddSlider({
	Name = "Prompt Post Hold Delay",
	Min = 0,
	Max = 5,
	Default = SETTINGS.PromptPostHoldDelay,
	Increment = 0.05,
	Callback = function(value)
		SETTINGS.PromptPostHoldDelay = value
	end
})

promptSection:AddSlider({
	Name = "Extra Finished Delay",
	Min = 0,
	Max = 5,
	Default = SETTINGS.ExtraFinishedDelay,
	Increment = 0.05,
	Callback = function(value)
		SETTINGS.ExtraFinishedDelay = value
	end
})

promptSection:AddToggle({
	Name = "Use ATM Front Camera",
	Default = SETTINGS.UseATMFrontCamera,
	Callback = function(state)
		SETTINGS.UseATMFrontCamera = state
		if not state then
			restore_camera()
		end
	end
})

promptSection:AddToggle({
	Name = "Restore Camera After Rob",
	Default = SETTINGS.RestoreCameraAfterRob,
	Callback = function(state)
		SETTINGS.RestoreCameraAfterRob = state
		if state then
			restore_camera()
		end
	end
})

promptSection:AddSlider({
	Name = "Camera Front Distance",
	Min = 1,
	Max = 20,
	Default = SETTINGS.CameraFrontDistance,
	Increment = 0.1,
	Callback = function(value)
		SETTINGS.CameraFrontDistance = value
	end
})

promptSection:AddSlider({
	Name = "Camera Height Offset",
	Min = -5,
	Max = 10,
	Default = SETTINGS.CameraHeightOffset,
	Increment = 0.1,
	Callback = function(value)
		SETTINGS.CameraHeightOffset = value
	end
})

promptSection:AddSlider({
	Name = "Camera Look Height",
	Min = -5,
	Max = 10,
	Default = SETTINGS.CameraLookHeightOffset,
	Increment = 0.1,
	Callback = function(value)
		SETTINGS.CameraLookHeightOffset = value
	end
})

miscSection:AddToggle({
	Name = "Anchor During Teleport",
	Default = SETTINGS.AnchorDuringTeleport,
	Callback = function(state)
		SETTINGS.AnchorDuringTeleport = state
	end
})

miscSection:AddSlider({
	Name = "Teleport Settle Delay",
	Min = 0,
	Max = 1,
	Default = SETTINGS.TeleportSettleDelay,
	Increment = 0.01,
	Callback = function(value)
		SETTINGS.TeleportSettleDelay = value
	end
})

miscSection:AddToggle({
	Name = "Skip Used Positions",
	Default = SETTINGS.SkipUsedPositions,
	Callback = function(state)
		SETTINGS.SkipUsedPositions = state
	end
})

miscSection:AddToggle({
	Name = "Move To Cooldown At End",
	Default = SETTINGS.MoveToCooldownAtEnd,
	Callback = function(state)
		SETTINGS.MoveToCooldownAtEnd = state
	end
})

miscSection:AddToggle({
	Name = "Close Location UI Before TP",
	Default = SETTINGS.CloseLocationUIBeforeEachTP,
	Callback = function(state)
		SETTINGS.CloseLocationUIBeforeEachTP = state
	end
})

miscSection:AddToggle({
	Name = "Print Loop Summary",
	Default = SETTINGS.PrintLoopSummary,
	Callback = function(state)
		SETTINGS.PrintLoopSummary = state
	end
})

miscSection:AddToggle({
	Name = "Debug Prints",
	Default = SETTINGS.Debug,
	Callback = function(state)
		SETTINGS.Debug = state
	end
})

miscSection:AddTextbox({
	Name = "Cooldown Position",
	Placeholder = "-20, 731, 3255",
	Tooltip = "Format: x, y, z",
	Callback = function(text, submitted)
		if not submitted then
			return
		end

		local x, y, z = string.match(text, "([^,]+),%s*([^,]+),%s*([^,]+)")
		x, y, z = tonumber(x), tonumber(y), tonumber(z)

		if x and y and z then
			SETTINGS.CooldownPosition = Vector3.new(x, y, z)
			notify("ATM", "Cooldown position updated", 3)
		else
			notify("ATM", "Invalid Vector3 format", 3)
		end
	end
})

local miscTab = ui:AddTab({
	Name = "Misc",
})

local miscMainSection = miscTab:AddSection({
	Name = "Utility",
	Description = "Extra helpers and quality-of-life"
})

miscMainSection:AddToggle({
	Name = "Fly",
	Default = false,
	Tooltip = "Fly mode. WASD to move, Space/Shift to go up/down",
	Callback = function(state)
		set_fly_state(state)
	end
})

miscMainSection:AddSlider({
	Name = "Fly Speed",
	Default = FLY_SPEED,
	Min = 10,
	Max = 300,
	Increment = 1,
	Tooltip = "Horizontal fly movement speed",
	Callback = function(value)
		FLY_SPEED = value
	end
})

miscMainSection:AddSlider({
	Name = "Ascent Speed",
	Default = ASCEND_SPEED,
	Min = 10,
	Max = 300,
	Increment = 1,
	Tooltip = "Vertical fly movement speed",
	Callback = function(value)
		ASCEND_SPEED = value
	end
})

miscMainSection:AddSlider({
	Name = "Fly Smoothing",
	Default = CONTROL_SMOOTHING,
	Min = 0.01,
	Max = 1,
	Increment = 0.01,
	Tooltip = "Higher = snappier movement, lower = smoother acceleration",
	Callback = function(value)
		CONTROL_SMOOTHING = value
	end
})

--// =========================================
--// KEYBINDS / FALLBACK HOTKEYS
--// =========================================

UserInputService.InputBegan:Connect(function(input, game_processed)
	if game_processed then
		return
	end

	if input.KeyCode == SETTINGS.ToggleKey then
		-- UI lib already handles RightShift for UI toggle
		return
	end
end)

--// =========================================
--// SETTINGS PAGE
--// =========================================

local settingsKeybindsSection = ui:AddSettingsSection({
	Name = "Keybinds"
})

ui:AddToSettings("Toggle", {
	Name = "Show Keybind Overlay",
	Section = "General",
	Default = false,
	Callback = function(state)
		ui:SetKeybindOverlayEnabled(state)
	end,
})

ui:AddToggleKeybind({
	Name = "Toggle UI",
	Section = settingsKeybindsSection,
	Default = Enum.KeyCode.RightShift,
	Callback = function(newKey)
		SETTINGS.ToggleKey = newKey

		ui:Notify({
			Title = "Toggle Key Updated",
			Content = "New key: " .. tostring(newKey):gsub("Enum.KeyCode.", ""),
			Duration = 2.5,
		})
	end,
})

ui:AddKeybind({
	Name = "Toggle ATM Farm",
	Section = settingsKeybindsSection,
	Default = SETTINGS.StopKey,
	Mode = "Press",
	Callback = function()
		if loop_running or SETTINGS.Enabled then
			stop_loop()
			notify("ATM", "Stopped from keybind", 3)
		else
			SETTINGS.Enabled = true
			refresh_stats_ui()

			if not loop_running then
				local loop = start_loop()
				task.spawn(function()
					loop.Completed:Wait()
				end)
			end

			notify("ATM", "Started from keybind", 3)
		end
	end
})

ui:AddKeybind({
	Name = "Toggle Fly",
	Section = settingsKeybindsSection,
	Default = FLY_KEY,
	Mode = "Press",
	Callback = function()
		toggleFly()
	end
})

--// =========================================
--// BOOT
--// =========================================

ui:SetKeybindOverlayEnabled(false)
refresh_stats_ui()
-- ui:Open()
notify("ATM", "UI loaded successfully", 3)

local VirtualUser = game:GetService("VirtualUser") 
local currentCamera = game.Workspace.CurrentCamera 

player.Idled:Connect(function() 
    VirtualUser:Button2Down(Vector2.zero, currentCamera.CFrame) 
    task.wait(1) 
    VirtualUser:Button2Up(Vector2.zero, currentCamera.CFrame) 
    
    print("Player Successfully UnIdled.") 
    
end) 

notify("ANTI AFK", "AFK Script Loaded successfully", 3)

task.spawn(function()
	while true do
		refresh_stats_ui()
		task.wait(0.5)
	end
end)
