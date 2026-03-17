local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local criminal_atm_spawners_folder = workspace:WaitForChild("Game")
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

	-- Wait modes
	WaitMode = 2, -- 1 = always wait for timer, 2 = threshold-based, 3 = placeholder
	MoneyThresholdBeforeWaiting = 50000,
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

	-- Cooldown movement between ATMs
	CooldownPosition = Vector3.new(-20, 731, 3255),

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

local atm_json = [[
[{"Y":8.601656913757325,"X":-2775.947998046875,"Z":10241.5595703125},{"Y":27.110130310058595,"X":-2556.254150390625,"Z":2477.1708984375},{"Y":11.890100479125977,"X":-2225.52685546875,"Z":4091.53076171875},{"Y":11.384407997131348,"X":-2172.5068359375,"Z":4740.88916015625},{"Y":11.900482177734375,"X":-2085.01318359375,"Z":3411.333740234375},{"Y":11.897994041442871,"X":-2081.524658203125,"Z":2822.916748046875},{"Y":11.891409873962403,"X":-1992.78857421875,"Z":2693.77685546875},{"Y":11.808558464050293,"X":-1696.702880859375,"Z":4919.95556640625},{"Y":12.040742874145508,"X":-1681.794921875,"Z":1773.5260009765626},{"Y":11.064801216125489,"X":-1415.0499267578126,"Z":2840.72216796875},{"Y":11.307580947875977,"X":-1346.863037109375,"Z":4332.49951171875},{"Y":11.963729858398438,"X":-1249.5594482421876,"Z":2329.84033203125},{"Y":11.880024909973145,"X":-1206.79541015625,"Z":3698.99072265625},{"Y":23.032424926757814,"X":-1203.240966796875,"Z":-1144.1619873046876},{"Y":12.67477035522461,"X":-1201.1339111328126,"Z":2548.10107421875},{"Y":11.878620147705079,"X":-1129.900634765625,"Z":3246.55126953125},{"Y":23.03590965270996,"X":-1115.2147216796876,"Z":-833.89111328125},{"Y":8.640939712524414,"X":-1053.4998779296876,"Z":5045.58642578125},{"Y":23.00715446472168,"X":-976.2227172851563,"Z":-585.3759765625},{"Y":23.063749313354493,"X":-967.3648681640625,"Z":-1730.4329833984376},{"Y":8.627490043640137,"X":-872.58349609375,"Z":10614.3857421875},{"Y":11.889113426208496,"X":-859.392822265625,"Z":3780.761962890625},{"Y":12.01364517211914,"X":-815.7994995117188,"Z":3097.138671875},{"Y":22.519317626953126,"X":-631.2166137695313,"Z":-727.0564575195313},{"Y":23.23828887939453,"X":-611.370849609375,"Z":-31.71861457824707},{"Y":22.98494529724121,"X":-576.1636962890625,"Z":-972.8796997070313},{"Y":24.232742309570314,"X":-524.8099975585938,"Z":-431.9997863769531},{"Y":11.892912864685059,"X":-461.389892578125,"Z":3672.638671875},{"Y":23.236806869506837,"X":-372.7074890136719,"Z":63.74726104736328},{"Y":11.89174747467041,"X":-356.29437255859377,"Z":3194.325927734375},{"Y":23.182723999023439,"X":-271.8390808105469,"Z":-235.3688507080078},{"Y":24.21013069152832,"X":-251.64183044433595,"Z":-475.45245361328127},{"Y":23.133136749267579,"X":-97.7276382446289,"Z":-107.99128723144531},{"Y":23.18956184387207,"X":93.02099609375,"Z":-984.1406860351563},{"Y":26.067304611206056,"X":134.1066436767578,"Z":2186.60888671875},{"Y":11.697174072265625,"X":145.550048828125,"Z":3657.989501953125},{"Y":32.51835250854492,"X":195.1944580078125,"Z":-15.687950134277344},{"Y":9.03598403930664,"X":237.11480712890626,"Z":815.8687744140625},{"Y":23.19205093383789,"X":399.0374450683594,"Z":-978.0632934570313},{"Y":32.5456657409668,"X":591.8954467773438,"Z":189.41554260253907},{"Y":32.61363220214844,"X":595.930908203125,"Z":1622.7442626953126},{"Y":32.5269889831543,"X":881.5899047851563,"Z":187.8155517578125},{"Y":32.52302932739258,"X":886.73486328125,"Z":-86.29102325439453},{"Y":32.61841583251953,"X":992.3524780273438,"Z":1796.124755859375}]
]]

--// =========================
--// DEBUG / LOGGING
--// =========================

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

--// =========================
--// STATE
--// =========================

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

--// =========================
--// FORWARD DECLARATIONS
--// =========================

local get_player_cash
local handle_post_atm_wait

--// =========================
--// HELPERS
--// =========================

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

	debug_print("Teleported to:", cf.Position)
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

--// =========================
--// NOTIFICATION + CASH
--// =========================

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
		-- debug_print("Timer check returned:", seconds_left)

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
		warn_print("WaitMode 3 is not implemented yet")
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

--// =========================
--// ATM LOGIC
--// =========================

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

	info_print(("Visiting ATM position %d / %d"):format(index, stats.PositionsTotal))

	tp_exact(cf)
	used_positions[index] = true
	stats.PositionsVisited += 1

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

local function start_loop()
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

		while is_enabled(my_loop_token) do
			stats.LoopCount += 1
			stats.PositionsVisited = 0

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
		completed_event:Fire()
	end)

	return {
		Completed = completed_event.Event,
	}
end

--// =========================
--// TOGGLE / QOL
--// =========================

UserInputService.InputBegan:Connect(function(input, game_processed)
	if game_processed then
		return
	end

	if input.KeyCode == SETTINGS.ToggleKey then
		SETTINGS.Enabled = not SETTINGS.Enabled
		info_print("ATM loop toggled:", SETTINGS.Enabled)

		if SETTINGS.Enabled and not loop_running then
			local loop = start_loop()
			task.spawn(function()
				loop.Completed:Wait()
				debug_print("Loop task completed after toggle")
			end)
		else
			active_loop_token += 1
			restore_camera()
		end
	elseif input.KeyCode == SETTINGS.StopKey then
		SETTINGS.Enabled = false
		active_loop_token += 1
		restore_camera()
		info_print("ATM loop stopped")
	end
end)

--// =========================
--// START
--// =========================

local loop = start_loop()
loop.Completed:Wait()
