local __bundle = {}
local __cache = {}
local __LOADING = {}

local function __normalize_module_name(moduleName)
    if type(moduleName) ~= "string" then
        error(("Expected a module name string, got %s"):format(type(moduleName)), 2)
    end

    return (moduleName:gsub("\\", "/"))
end

local function __split_module_name(moduleName)
    local parts = {}

    for part in moduleName:gmatch("[^/]+") do
        table.insert(parts, part)
    end

    return parts
end

local function __resolve_module_name(currentModule, requestedModule)
    requestedModule = __normalize_module_name(requestedModule)

    if not requestedModule:match("^%.?%.?/") and requestedModule ~= "." and requestedModule ~= ".." then
        return requestedModule
    end

    local parts = __split_module_name(currentModule)
    table.remove(parts, #parts)

    for segment in requestedModule:gmatch("[^/]+") do
        if segment == "." or segment == "" then
            -- Current directory segment; no-op.
        elseif segment == ".." then
            if #parts == 0 then
                error(("Cannot resolve module '%s' from '%s'"):format(requestedModule, currentModule), 2)
            end

            table.remove(parts, #parts)
        else
            table.insert(parts, segment)
        end
    end

    return table.concat(parts, "/")
end

local function __bundle_require(moduleName)
    local normalized = __normalize_module_name(moduleName)
    local cached = __cache[normalized]

    if cached == __LOADING then
        error(("Circular module dependency detected while loading '%s'"):format(normalized), 2)
    end

    if cached ~= nil then
        return cached
    end

    local loader = __bundle[normalized]
    if not loader then
        error(("Bundled module '%s' was not found."):format(normalized), 2)
    end

    __cache[normalized] = __LOADING

    local ok, result = pcall(loader)
    if not ok then
        __cache[normalized] = nil
        error(result, 0)
    end

    if result == nil then
        result = true
    end

    __cache[normalized] = result
    return result
end

__bundle["main"] = function()
    local function require(moduleName)
        return __bundle_require(__resolve_module_name("main", moduleName))
    end

    local config = require("./modules/config")
    local services = require("./modules/services")
    local createLogger = require("./modules/logger")
    local createAtmData = require("./modules/atm_data")
    local createStats = require("./modules/stats")
    local createPlayerUtils = require("./modules/player_utils")
    local createMovement = require("./modules/movement")
    local createDetection = require("./modules/detection")
    local createFlyController = require("./modules/fly_controller")
    local createAtmFarm = require("./modules/atm_farm")
    local uiLoader = require("./modules/ui_loader")
    local uiBuilder = require("./modules/ui_builder")
    local antiAfk = require("./modules/anti_afk")
    
    local settings = config.SETTINGS
    local flySettings = config.FLY_SETTINGS
    local playerUtils = createPlayerUtils(services)
    local atmCFrames = createAtmData(services.HttpService)
    
    local logger = createLogger(settings)
    local ui = uiLoader.create(config.UI_CONFIG)
    logger.setUI(ui)
    
    local stats = createStats(#atmCFrames)
    local movement = createMovement({
        services = services,
        playerUtils = playerUtils,
        settings = settings,
        logger = logger,
    })
    local detection = createDetection(playerUtils)
    local fly = createFlyController({
        services = services,
        playerUtils = playerUtils,
        flySettings = flySettings,
        logger = logger,
    })
    local farm = createAtmFarm({
        services = services,
        settings = settings,
        stats = stats,
        cframes = atmCFrames,
        logger = logger,
        movement = movement,
        detection = detection,
    })
    
    local uiState = uiBuilder.create({
        ui = ui,
        settings = settings,
        flySettings = flySettings,
        stats = stats,
        farm = farm,
        detection = detection,
        movement = movement,
        logger = logger,
        fly = fly,
    })
    
    farm.setRefreshCallback(uiState.refreshStats)
    
    ui:SetKeybindOverlayEnabled(false)
    uiState.refreshStats()
    logger.notify("ATM", "UI loaded successfully", 3)
    
    antiAfk.init(services)
    logger.notify("ANTI AFK", "AFK Script Loaded successfully", 3)
    
    task.spawn(function()
        while true do
            uiState.refreshStats()
            task.wait(0.5)
        end
    end)
    
end

__bundle["modules/anti_afk"] = function()
    local function require(moduleName)
        return __bundle_require(__resolve_module_name("modules/anti_afk", moduleName))
    end

    local antiAfk = {}
    
    function antiAfk.init(services)
        services.player.Idled:Connect(function()
            local camera = services.getCamera()
    
            services.VirtualUser:Button2Down(Vector2.zero, camera.CFrame)
            task.wait(1)
            services.VirtualUser:Button2Up(Vector2.zero, camera.CFrame)
    
            print("Player Successfully UnIdled.")
        end)
    end
    
    return antiAfk
    
end

__bundle["modules/atm_data"] = function()
    local function require(moduleName)
        return __bundle_require(__resolve_module_name("modules/atm_data", moduleName))
    end

    local atmJSON = [[
     [{"Y":8.335907936096192,"X":-3458.85302734375,"Z":-1322.001708984375},{"Y":9.46590805053711,"X":-3352.716552734375,"Z":-853.64404296875},{"Y":8.335907936096192,"X":-3317.169921875,"Z":-1155.743408203125},{"Y":2.421398162841797,"X":-3279.8798828125,"Z":4313.75146484375},{"Y":3.1513986587524416,"X":-3126.921875,"Z":2933.145263671875},{"Y":27.611074447631837,"X":-2937.361083984375,"Z":2049.0126953125},{"Y":3.1513986587524416,"X":-2931.210205078125,"Z":-2899.0068359375},{"Y":27.61272430419922,"X":-2876.5869140625,"Z":2115.640869140625},{"Y":8.282910346984864,"X":-2843.140380859375,"Z":-1547.345458984375},{"Y":3.1513986587524416,"X":-2840.73046875,"Z":2465.15869140625},{"Y":9.014866828918457,"X":-2804.191650390625,"Z":3059.3515625},{"Y":5.852411270141602,"X":-2782.415283203125,"Z":2828.408203125},{"Y":9.46590805053711,"X":-2780.579833984375,"Z":-1059.8782958984376},{"Y":12.393074035644532,"X":-2739.50537109375,"Z":3874.071044921875},{"Y":12.434408187866211,"X":-2676.43701171875,"Z":4529.00927734375},{"Y":13.064408302307129,"X":-2648.786865234375,"Z":4322.97900390625},{"Y":27.610130310058595,"X":-2556.254150390625,"Z":2477.1708984375},{"Y":13.82291030883789,"X":-2534.52783203125,"Z":-1435.7349853515626},{"Y":8.335907936096192,"X":-2527.855224609375,"Z":-1831.643798828125},{"Y":3.1513986587524416,"X":-2510.55224609375,"Z":1858.1083984375},{"Y":-9.368600845336914,"X":-2484.19482421875,"Z":5077.54931640625},{"Y":8.352495193481446,"X":-2352.291748046875,"Z":2264.55419921875},{"Y":12.390100479125977,"X":-2225.52685546875,"Z":4091.53076171875},{"Y":-9.398601531982422,"X":-2190.065185546875,"Z":-4280.0341796875},{"Y":12.473175048828125,"X":-2120.874755859375,"Z":4751.21142578125},{"Y":12.769351959228516,"X":-2099.611328125,"Z":1961.70703125},{"Y":12.397994041442871,"X":-2081.524658203125,"Z":2822.916748046875},{"Y":12.400482177734375,"X":-2061.996826171875,"Z":3416.317138671875},{"Y":12.391409873962403,"X":-1992.78857421875,"Z":2693.77685546875},{"Y":11.888984680175782,"X":-1896.49755859375,"Z":2196.01171875},{"Y":12.391712188720704,"X":-1895.6649169921876,"Z":2705.315185546875},{"Y":3.1513986587524416,"X":-1844.9290771484376,"Z":5888.22216796875},{"Y":13.129859924316407,"X":-1773.1834716796876,"Z":1977.243896484375},{"Y":12.308558464050293,"X":-1696.702880859375,"Z":4919.95556640625},{"Y":12.54220962524414,"X":-1619.0902099609376,"Z":1825.7215576171876},{"Y":11.794267654418946,"X":-1600.7808837890626,"Z":2804.310791015625},{"Y":12.63897705078125,"X":-1480.68603515625,"Z":1657.9246826171876},{"Y":11.564801216125489,"X":-1415.0499267578126,"Z":2840.72216796875},{"Y":11.807580947875977,"X":-1346.863037109375,"Z":4332.49951171875},{"Y":12.463729858398438,"X":-1249.5594482421876,"Z":2329.84033203125},{"Y":12.380024909973145,"X":-1211.641357421875,"Z":3697.88720703125},{"Y":13.17477035522461,"X":-1203.720458984375,"Z":2547.57275390625},{"Y":23.534896850585939,"X":-1177.0750732421876,"Z":-1010.3767700195313},{"Y":23.53590965270996,"X":-1168.0009765625,"Z":-874.2249145507813},{"Y":12.378620147705079,"X":-1130.0889892578126,"Z":3246.25634765625},{"Y":9.140939712524414,"X":-1053.4998779296876,"Z":5045.58642578125},{"Y":23.5076904296875,"X":-959.7918701171875,"Z":-793.5988159179688},{"Y":23.68375015258789,"X":-947.7096557617188,"Z":-1622.4022216796876},{"Y":23.50715446472168,"X":-896.1318969726563,"Z":-615.3422241210938},{"Y":12.389113426208496,"X":-859.392822265625,"Z":3780.761962890625},{"Y":12.51364517211914,"X":-815.7994995117188,"Z":3097.138671875},{"Y":23.683349609375,"X":-615.494384765625,"Z":-692.9234008789063},{"Y":23.487428665161134,"X":-550.2677001953125,"Z":-924.6089477539063},{"Y":3.1513986587524416,"X":-527.4019775390625,"Z":5973.55126953125},{"Y":23.707956314086915,"X":-480.17913818359377,"Z":-984.172607421875},{"Y":23.574384689331056,"X":-477.6053466796875,"Z":451.8768005371094},{"Y":12.392912864685059,"X":-461.28253173828127,"Z":3672.66259765625},{"Y":23.58274269104004,"X":-419.5953369140625,"Z":-188.6639404296875},{"Y":14.708148956298829,"X":-378.81378173828127,"Z":-1836.7772216796876},{"Y":23.57790756225586,"X":-366.9688415527344,"Z":-381.8194580078125},{"Y":23.570114135742189,"X":-365.8956604003906,"Z":68.78761291503906},{"Y":12.39174747467041,"X":-356.29437255859377,"Z":3194.325927734375},{"Y":23.560131072998048,"X":-297.5867004394531,"Z":-653.8375244140625},{"Y":3.1513986587524416,"X":-145.59585571289063,"Z":5528.01318359375},{"Y":30.763137817382814,"X":-101.8733139038086,"Z":-130.5723876953125},{"Y":33.0269889831543,"X":5.755457401275635,"Z":44.52651596069336},{"Y":26.567304611206056,"X":134.1066436767578,"Z":2186.60888671875},{"Y":12.197174072265625,"X":145.550048828125,"Z":3657.989501953125},{"Y":9.53598403930664,"X":239.68470764160157,"Z":815.8911743164063},{"Y":33.01137161254883,"X":269.2803955078125,"Z":478.4219970703125},{"Y":33.02302932739258,"X":547.8510131835938,"Z":78.18355560302735},{"Y":33.11363220214844,"X":595.930908203125,"Z":1622.7442626953126},{"Y":3.1513986587524416,"X":695.0578002929688,"Z":1165.994873046875},{"Y":3.1513986587524416,"X":773.6299438476563,"Z":5719.01513671875},{"Y":33.0456657409668,"X":820.2252807617188,"Z":189.70469665527345},{"Y":3.1513986587524416,"X":846.4816284179688,"Z":4426.40234375},{"Y":33.02302932739258,"X":886.73486328125,"Z":-86.29102325439453},{"Y":33.11841583251953,"X":992.3524780273438,"Z":1796.124755859375},{"Y":3.1513986587524416,"X":1958.742431640625,"Z":2101.491943359375},{"Y":3.1513986587524416,"X":2153.075927734375,"Z":19.78546905517578}]
    ]]
    
    local function createAtmData(httpService)
        local decoded = httpService:JSONDecode(atmJSON)
        local cframes = {}
    
        for _, position in ipairs(decoded) do
            table.insert(cframes, CFrame.new(position.X, position.Y, position.Z))
        end
    
        return cframes
    end
    
    return createAtmData
    
end

__bundle["modules/atm_farm"] = function()
    local function require(moduleName)
        return __bundle_require(__resolve_module_name("modules/atm_farm", moduleName))
    end

    local function createAtmFarm(deps)
        local services = deps.services
        local settings = deps.settings
        local stats = deps.stats
        local cframes = deps.cframes
        local logger = deps.logger
        local movement = deps.movement
        local detection = deps.detection
    
        local activeLoopToken = 0
        local loopRunning = false
        local refreshStatsUI = function() end
    
        local farm = {}
    
        local function isEnabled(loopToken)
            if loopToken ~= nil and loopToken ~= activeLoopToken then
                return false
            end
    
            return settings.Enabled
        end
    
        local function safeWait(duration, loopToken)
            local endTime = time() + duration
    
            while time() < endTime do
                if not isEnabled(loopToken) then
                    return false
                end
    
                task.wait(0.05)
            end
    
            return true
        end
    
        local function waitUntilEscapeTimerEnds(loopToken)
            local nilTimerStartedAt = nil
    
            while isEnabled(loopToken) do
                local secondsLeft = detection.getEscapeNotification("seconds")
    
                if secondsLeft == nil then
                    if nilTimerStartedAt == nil then
                        nilTimerStartedAt = time()
                    end
    
                    if time() - nilTimerStartedAt >= settings.MissingTimerGracePeriod then
                        logger.debug("No escape timer found for grace period; continuing")
                        return true
                    end
    
                    if not safeWait(settings.WaitCheckInterval, loopToken) then
                        return false
                    end
    
                    continue
                end
    
                nilTimerStartedAt = nil
    
                if secondsLeft <= 0 then
                    logger.debug("Escape timer finished")
                    return true
                end
    
                logger.debug("Waiting for timer to finish. Seconds left:", secondsLeft)
                movement.teleportExact(CFrame.new(settings.CooldownPosition))
    
                if not safeWait(math.min(settings.WaitCheckInterval, secondsLeft), loopToken) then
                    return false
                end
            end
    
            return false
        end
    
        local function handlePostAtmWait(loopToken)
            logger.info("handle_post_atm_wait called. Mode:", settings.WaitMode)
    
            if settings.WaitMode == 1 then
                logger.info("WaitMode 1: waiting for timer after ATM")
                return waitUntilEscapeTimerEnds(loopToken)
            end
    
            if settings.WaitMode == 2 then
                local cashValue = detection.getSafeCash()
    
                logger.debug(
                    "WaitMode 2 check. Cash:",
                    cashValue,
                    "Threshold:",
                    settings.MoneyThresholdBeforeWaiting
                )
    
                if cashValue >= settings.MoneyThresholdBeforeWaiting then
                    logger.info("Money threshold reached, waiting for timer to finish")
                    return waitUntilEscapeTimerEnds(loopToken)
                end
    
                logger.debug("Money threshold not reached, continuing immediately")
                return true
            end
    
            if settings.WaitMode == 3 then
                local currentTimer = detection.getEscapeNotification("seconds")
    
                logger.debug(
                    "WaitMode 3 check. Timer:",
                    currentTimer,
                    "Threshold:",
                    settings.TimeThresholdBeforeWaiting
                )
    
                if currentTimer ~= nil and currentTimer > settings.TimeThresholdBeforeWaiting then
                    logger.info("Timer threshold exceeded, waiting for timer to finish")
                    return waitUntilEscapeTimerEnds(loopToken)
                end
    
                logger.debug("Timer threshold not exceeded, continuing immediately")
                return true
            end
    
            logger.warn("Unknown WaitMode:", settings.WaitMode)
            return true
        end
    
        local function doCooldownWait(originalCf, loopToken)
            logger.info("Entered cooldown wait")
    
            if not isEnabled(loopToken) then
                return
            end
    
            if not safeWait(1, loopToken) then
                return
            end
    
            logger.info("Moving to cooldown position...")
            movement.teleportExact(CFrame.new(settings.CooldownPosition))
    
            logger.info("Waiting at cooldown position...")
    
            if not handlePostAtmWait(loopToken) then
                return
            end
    
            if isEnabled(loopToken) then
                logger.info("Returning from cooldown...")
                movement.teleportExact(originalCf)
            end
        end
    
        local function evaluateAttemptSuccess(atm, startTimer, startCash, loopToken)
            local endTime = time() + settings.SuccessCheckWindow
    
            while time() < endTime and isEnabled(loopToken) do
                local currentTimer = detection.getEscapeNotification("seconds")
                local currentCash = detection.getSafeCash()
                local _, refreshedPrompt = movement.getATMData(atm)
    
                local timerIncreased = detection.timerIndicatesSuccess(startTimer, currentTimer)
                local cashIncreased = currentCash > startCash
                local promptDisabled = refreshedPrompt ~= nil and refreshedPrompt.Enabled == false
    
                logger.debug(
                    "Success check:",
                    "Timer:",
                    startTimer,
                    "->",
                    currentTimer,
                    "Cash:",
                    startCash,
                    "->",
                    currentCash,
                    "TimerIncreased:",
                    timerIncreased,
                    "CashIncreased:",
                    cashIncreased,
                    "PromptDisabled:",
                    promptDisabled
                )
    
                local success
                if settings.WaitMode == 1 then
                    success = timerIncreased or promptDisabled
                else
                    success = timerIncreased or cashIncreased or promptDisabled
                end
    
                if success then
                    return true
                end
    
                task.wait(settings.SuccessCheckPollInterval)
            end
    
            return false
        end
    
        local function tryRobATM(atm, loopToken)
            local _, prompt, atmPart = movement.getATMData(atm)
            if not movement.isPromptValid(prompt) or not isEnabled(loopToken) then
                logger.debug("Prompt invalid before rob attempt")
                return false
            end
    
            local robCFrame = atmPart and atmPart.CFrame or atm:GetPivot()
    
            local function releaseAttemptState()
                movement.setCharacterAnchored(false)
                movement.restoreCamera()
            end
    
            for attempt = 1, settings.RetryAttemptsPerATM do
                if not isEnabled(loopToken) then
                    return false
                end
    
                local startTimer = detection.getEscapeNotification("seconds")
                local startCash = detection.getSafeCash()
    
                logger.debug("ATM rob attempt", attempt, "at", robCFrame.Position)
                logger.debug("Attempt start state:", "Timer:", startTimer, "Cash:", startCash)
    
                stats.ATMRetryCount += 1
                refreshStatsUI()
    
                movement.teleportExact(robCFrame)
                movement.setCharacterAnchored(true)
                movement.pointCameraAtATMFront(atm)
    
                if not safeWait(settings.PromptRecheckDelay, loopToken) then
                    releaseAttemptState()
                    return false
                end
    
                local _, recheckPrompt = movement.getATMData(atm)
                if not movement.isPromptValid(recheckPrompt) then
                    logger.debug("Prompt invalid after recheck delay")
                    releaseAttemptState()
                    continue
                end
    
                if atmPart then
                    logger.debug(
                        "ATM part found. Distance from player:",
                        math.floor(movement.getDistanceFromPlayer(atmPart.Position) * 100) / 100
                    )
                end
    
                local action = movement.fireProximityPrompt(recheckPrompt, 1, settings.PromptHoldTime)
                local promptSuccess = action.Completed:Wait()
                if not promptSuccess then
                    releaseAttemptState()
                    logger.debug("Prompt activation failed; retrying ATM attempt")
                    continue
                end
    
                if not safeWait(settings.PromptPostHoldDelay, loopToken) then
                    releaseAttemptState()
                    return false
                end
    
                local success = evaluateAttemptSuccess(atm, startTimer, startCash, loopToken)
                if not success then
                    releaseAttemptState()
                    logger.warn("ATM attempt considered FAILED (logic-based)")
                    continue
                end
    
                if not safeWait(settings.ExtraFinishedDelay, loopToken) then
                    releaseAttemptState()
                    return false
                end
    
                releaseAttemptState()
                stats.ATMsRobbed += 1
                refreshStatsUI()
                logger.info("ATM robbed successfully at:", robCFrame.Position)
    
                doCooldownWait(robCFrame, loopToken)
    
                return true
            end
    
            releaseAttemptState()
            logger.warn("ATM rob failed after retries:", robCFrame.Position)
            return false
        end
    
        local function findValidATM(loopToken)
            stats.FindChecks += 1
            refreshStatsUI()
            logger.debug("Scanning for valid ATMs. Check #", stats.FindChecks)
    
            local spawnersFolder = services.getCriminalATMSpawnersFolder(false)
            if not spawnersFolder then
                logger.debug("ATM spawners folder is not available yet")
                return false
            end
    
            local loadedATMs = movement.getLoadedATMs(spawnersFolder)
    
            table.sort(loadedATMs, function(a, b)
                local positionA = movement.getATMPosition(a)
                local positionB = movement.getATMPosition(b)
    
                local distanceA = positionA and movement.getDistanceFromPlayer(positionA) or math.huge
                local distanceB = positionB and movement.getDistanceFromPlayer(positionB) or math.huge
    
                return distanceA < distanceB
            end)
    
            logger.debug("Loaded ATM candidates:", #loadedATMs)
    
            for _, atm in ipairs(loadedATMs) do
                if not isEnabled(loopToken) then
                    return false
                end
    
                local _, prompt = movement.getATMData(atm)
                if not movement.isPromptValid(prompt) then
                    logger.debug("ATM exists but prompt invalid:", atm:GetFullName())
                    continue
                end
    
                logger.debug("Found candidate ATM:", atm:GetFullName())
    
                if tryRobATM(atm, loopToken) then
                    return true
                end
            end
    
            logger.debug("No valid ATM found this scan")
            return false
        end
    
        local function runATMPosition(index, cf, usedPositions, loopToken)
            if settings.SkipUsedPositions and usedPositions[index] then
                logger.debug("Skipping used position index:", index)
                return
            end
    
            if not isEnabled(loopToken) then
                return
            end
    
            movement.closeLocationUI()
            logger.info(("Visiting ATM position %d / %d"):format(index, stats.PositionsTotal))
    
            -- Saved ATM positions are used as streaming/load zones; the actual ATM is resolved after teleport.
            movement.teleportExact(cf)
            usedPositions[index] = true
            stats.PositionsVisited += 1
            refreshStatsUI()
    
            if not safeWait(settings.WaitAfterTeleportToATM, loopToken) then
                return
            end
    
            local found = findValidATM(loopToken)
            if found then
                logger.info("ATM interaction complete at position index:", index)
            else
                logger.debug("No ATM found at position index:", index)
            end
    
            if not safeWait(settings.WaitAfterReturningFromCooldown, loopToken) then
                return
            end
    
            local foundAgain = findValidATM(loopToken)
            if foundAgain then
                logger.info("ATM interaction complete after return at position index:", index)
            else
                logger.debug("Still no ATM found after returning to position index:", index)
            end
        end
    
        function farm.setRefreshCallback(callback)
            refreshStatsUI = callback or function() end
        end
    
        function farm.isLoopRunning()
            return loopRunning
        end
    
        function farm.printSummary()
            if settings.PrintLoopSummary then
                stats.printSummary()
            end
        end
    
        function farm.start()
            local completedEvent = Instance.new("BindableEvent")
    
            if loopRunning then
                logger.warn("Loop already running")
                completedEvent:Fire()
    
                return {
                    Completed = completedEvent.Event,
                }
            end
    
            settings.Enabled = true
            activeLoopToken += 1
    
            local myLoopToken = activeLoopToken
    
            task.spawn(function()
                loopRunning = true
                logger.notify("ATM", "Loop started", 3)
                refreshStatsUI()
    
                while isEnabled(myLoopToken) do
                    stats.LoopCount += 1
                    stats.PositionsVisited = 0
                    refreshStatsUI()
    
                    local usedPositions = {}
                    logger.info("Starting ATM loop #", stats.LoopCount, "with", stats.PositionsTotal, "positions")
    
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
                    farm.printSummary()
    
                    if settings.MoveToCooldownAtEnd then
                        movement.moveToPosition(settings.CooldownPosition)
                    end
    
                    if not settings.LoopInfinitely then
                        break
                    end
    
                    logger.info("Waiting", settings.WaitBetweenFullLoops, "seconds before next loop")
                    if not safeWait(settings.WaitBetweenFullLoops, myLoopToken) then
                        break
                    end
                end
    
                loopRunning = false
                movement.setCharacterAnchored(false)
                movement.restoreCamera()
                refreshStatsUI()
                logger.notify("ATM", "Loop stopped", 3)
                completedEvent:Fire()
            end)
    
            return {
                Completed = completedEvent.Event,
            }
        end
    
        function farm.stop()
            settings.Enabled = false
            activeLoopToken += 1
            movement.setCharacterAnchored(false)
            movement.restoreCamera()
            refreshStatsUI()
        end
    
        return farm
    end
    
    return createAtmFarm
    
end

__bundle["modules/config"] = function()
    local function require(moduleName)
        return __bundle_require(__resolve_module_name("modules/config", moduleName))
    end

    local config = {}
    
    config.UI_CONFIG = {
        ThemeUrl = "https://raw.githubusercontent.com/Shirozy/NekoHub-UI-Lib/refs/heads/main/themes.lua",
        LibraryUrl = "https://raw.githubusercontent.com/Shirozy/NekoHub-UI-Lib/refs/heads/main/RobloxUILibraryShell.lua",
        DefaultTheme = "Gruvbox",
        ToggleKey = Enum.KeyCode.RightShift,
        PromptText = "Press RightShift to open UI",
    }
    
    config.SETTINGS = {
        Debug = true,
    
        WaitAfterTeleportToATM = 2,
        WaitAfterReturningFromCooldown = 1.5,
        RetryAttemptsPerATM = 2,
    
        WaitMode = 3,
        MoneyThresholdBeforeWaiting = 50000,
        TimeThresholdBeforeWaiting = 300,
        WaitCheckInterval = 0.25,
    
        SuccessCheckWindow = 2.25,
        SuccessCheckPollInterval = 0.15,
        MissingTimerGracePeriod = 3,
    
        PromptHoldTime = 6,
        PromptMaxActivationDistance = 5,
        PromptRecheckDelay = 1.3,
        PromptPostHoldDelay = 1.25,
        ExtraFinishedDelay = 1.75,
    
        UseATMFrontCamera = true,
        RestoreCameraAfterRob = true,
        CameraFrontDistance = 6,
        CameraHeightOffset = 2.5,
        CameraLookHeightOffset = 1.5,
    
        AnchorDuringTeleport = true,
        TeleportSettleDelay = 0.05,
    
        CooldownPosition = Vector3.new(-20, 731, 3255),
    
        LoopInfinitely = true,
        WaitBetweenFullLoops = 60,
    
        Enabled = false,
        ToggleKey = Enum.KeyCode.RightShift,
        StopKey = Enum.KeyCode.End,
    
        SkipUsedPositions = true,
        PrintLoopSummary = true,
        MoveToCooldownAtEnd = true,
        CloseLocationUIBeforeEachTP = true,
    
        fly = false,
    }
    
    config.FLY_SETTINGS = {
        Enabled = false,
        ToggleKey = Enum.KeyCode.F,
        Speed = 80,
        AscendSpeed = 60,
        Smoothing = 0.15,
    }
    
    return config
    
end

__bundle["modules/detection"] = function()
    local function require(moduleName)
        return __bundle_require(__resolve_module_name("modules/detection", moduleName))
    end

    local function createDetection(playerUtils)
        local player = playerUtils.getPlayer()
        local notifications
        local lastCash = 0
    
        local detection = {}
    
        local function getNotificationsFolder()
            if notifications and notifications.Parent then
                return notifications
            end
    
            local playerGui = player:FindFirstChild("PlayerGui")
            local mainHUD = playerGui and playerGui:FindFirstChild("MainHUD")
            notifications = mainHUD and mainHUD:FindFirstChild("Notification")
    
            return notifications
        end
    
        function detection.timeToSeconds(timeText)
            local minutes, seconds = string.match(timeText, "^(%d+):(%d+)$")
    
            if not minutes or not seconds then
                return 0
            end
    
            return (tonumber(minutes) * 60) + tonumber(seconds)
        end
    
        function detection.getEscapeNotification(mode)
            local notificationsFolder = getNotificationsFolder()
            if not notificationsFolder then
                return nil
            end
    
            for _, notification in ipairs(notificationsFolder:GetChildren()) do
                if not notification:IsA("ImageLabel") then
                    continue
                end
    
                local title = notification:FindFirstChild("Title")
                if not title or not title:IsA("TextLabel") then
                    continue
                end
    
                local timeText = string.match(title.Text, "^Escape the security:%s*(%d+:%d+)$")
                if not timeText then
                    continue
                end
    
                local seconds = detection.timeToSeconds(timeText)
    
                if mode == "time_text" then
                    return timeText
                end
    
                if mode == "seconds" then
                    return seconds
                end
    
                if mode == "both" then
                    return timeText, seconds
                end
            end
    
            return nil
        end
    
        local function getPlayerCriminalCashLabel()
            local character = playerUtils.getCharacter()
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
    
        local function parseCashText(text)
            local cleaned = text:gsub("[%$,]", "")
            local dollars, cents = string.match(cleaned, "^(%d+)%.?(%d*)$")
    
            return tonumber(dollars) or 0, tonumber(cents) or 0
        end
    
        function detection.getPlayerCash(mode)
            local label = getPlayerCriminalCashLabel()
            if not label then
                return nil
            end
    
            local dollars, cents = parseCashText(label.Text)
    
            if mode == "no_cents" then
                return dollars
            end
    
            if mode == "with_cents" then
                return dollars + (cents / 100)
            end
    
            if mode == "split" then
                return dollars, cents
            end
    
            return nil
        end
    
        function detection.getSafeCash()
            local ok, value = pcall(function()
                return detection.getPlayerCash("no_cents")
            end)
    
            if ok and value ~= nil then
                lastCash = value
            end
    
            return lastCash
        end
    
        function detection.timerIndicatesSuccess(startTimer, endTimer)
            if startTimer == nil and endTimer ~= nil then
                return true
            end
    
            if startTimer ~= nil and endTimer ~= nil then
                return endTimer > startTimer
            end
    
            return false
        end
    
        return detection
    end
    
    return createDetection
    
end

__bundle["modules/fly_controller"] = function()
    local function require(moduleName)
        return __bundle_require(__resolve_module_name("modules/fly_controller", moduleName))
    end

    local function createFlyController(deps)
        local services = deps.services
        local playerUtils = deps.playerUtils
        local flySettings = deps.flySettings
        local logger = deps.logger
        local player = playerUtils.getPlayer()
        local character
        local humanoid
        local rootPart
        local bodyVelocity
        local bodyGyro
        local currentVelocity = Vector3.zero
    
        local moveState = {
            forward = 0,
            backward = 0,
            left = 0,
            right = 0,
            up = 0,
            down = 0,
        }
    
        local fly = {}
    
        local function syncCharacter()
            character = playerUtils.getCharacter()
            humanoid = character:WaitForChild("Humanoid")
            rootPart = character:WaitForChild("HumanoidRootPart")
        end
    
        local function resetMoveState()
            moveState.forward = 0
            moveState.backward = 0
            moveState.left = 0
            moveState.right = 0
            moveState.up = 0
            moveState.down = 0
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
    
        local function createFlyObjects()
            removeFlyObjects()
    
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
            bodyGyro.CFrame = services.getCamera().CFrame
            bodyGyro.Parent = rootPart
        end
    
        local function setFlyState(state, force)
            state = not not state
    
            if state == flySettings.Enabled and not force then
                return
            end
    
            if not character or not character.Parent or not humanoid or not rootPart then
                syncCharacter()
            end
    
            flySettings.Enabled = state
    
            if flySettings.Enabled then
                createFlyObjects()
                humanoid.PlatformStand = true
                currentVelocity = Vector3.zero
                resetMoveState()
                logger.info("Fly Enabled")
            else
                if humanoid then
                    humanoid.PlatformStand = false
                end
    
                currentVelocity = Vector3.zero
                resetMoveState()
                removeFlyObjects()
                logger.info("Fly Disabled")
            end
        end
    
        function fly.setEnabled(state)
            setFlyState(state)
        end
    
        function fly.toggle()
            setFlyState(not flySettings.Enabled)
        end
    
        function fly.isEnabled()
            return flySettings.Enabled
        end
    
        syncCharacter()
    
        player.CharacterAdded:Connect(function()
            syncCharacter()
    
            if flySettings.Enabled then
                task.defer(function()
                    if character and character.Parent then
                        setFlyState(true, true)
                    end
                end)
            end
        end)
    
        services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then
                return
            end
    
            if input.KeyCode == flySettings.ToggleKey then
                fly.toggle()
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
    
        services.UserInputService.InputEnded:Connect(function(input)
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
    
        services.RunService.RenderStepped:Connect(function()
            if not flySettings.Enabled then
                return
            end
    
            if not character or not character.Parent or not rootPart or not humanoid then
                return
            end
    
            if not bodyVelocity or not bodyGyro then
                return
            end
    
            local camera = services.getCamera()
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
                (flatLook * forward * flySettings.Speed) +
                (flatRight * strafe * flySettings.Speed) +
                Vector3.new(0, vertical * flySettings.AscendSpeed, 0)
    
            currentVelocity = currentVelocity:Lerp(targetVelocity, flySettings.Smoothing)
            bodyVelocity.Velocity = currentVelocity
            bodyGyro.CFrame = CFrame.new(rootPart.Position, rootPart.Position + camCFrame.LookVector)
        end)
    
        return fly
    end
    
    return createFlyController
    
end

__bundle["modules/logger"] = function()
    local function require(moduleName)
        return __bundle_require(__resolve_module_name("modules/logger", moduleName))
    end

    local function createLogger(settings)
        local ui
    
        local logger = {}
    
        function logger.setUI(nextUI)
            ui = nextUI
        end
    
        function logger.debug(...)
            if settings.Debug then
                print("[ATM DEBUG]", ...)
            end
        end
    
        function logger.info(...)
            print("[ATM INFO]", ...)
        end
    
        function logger.warn(...)
            warn("[ATM WARN]", ...)
        end
    
        function logger.notify(title, content, duration)
            if not ui then
                return
            end
    
            pcall(function()
                ui:Notify({
                    Title = title or "ATM",
                    Content = content or "",
                    Duration = duration or 3,
                })
            end)
        end
    
        return logger
    end
    
    return createLogger
    
end

__bundle["modules/movement"] = function()
    local function require(moduleName)
        return __bundle_require(__resolve_module_name("modules/movement", moduleName))
    end

    local function createMovement(deps)
        local services = deps.services
        local playerUtils = deps.playerUtils
        local settings = deps.settings
        local logger = deps.logger
        local movement = {}
    
        local function isWaterATMInstance(instance)
            local current = instance
    
            while current do
                if string.find(current.Name, "Water", 1, true) then
                    return true
                end
    
                current = current.Parent
            end
    
            return false
        end
    
        local function isATMModel(instance)
            return instance
                and instance:IsA("Model")
                and string.match(instance.Name, "^CriminalATM") ~= nil
                and string.find(instance.Name, "Spawner", 1, true) == nil
                and not isWaterATMInstance(instance)
        end
    
        local function findATMPart(atm)
            if not atm then
                return nil
            end
    
            if atm:IsA("BasePart") and atm.Name == "ATM" then
                return atm
            end
    
            local atmObject = atm:FindFirstChild("ATM", true)
            if atmObject then
                if atmObject:IsA("BasePart") then
                    return atmObject
                end
    
                if atmObject:IsA("Model") then
                    return atmObject.PrimaryPart or atmObject:FindFirstChildWhichIsA("BasePart", true)
                end
            end
    
            if atm:IsA("Model") then
                return atm.PrimaryPart or atm:FindFirstChildWhichIsA("BasePart", true)
            end
    
            return nil
        end
    
        local function findPromptAttachment(searchRoot)
            if not searchRoot then
                return nil
            end
    
            local promptAttachment = searchRoot:FindFirstChild("PromptAttachment", true)
            if promptAttachment and promptAttachment:IsA("Attachment") then
                return promptAttachment
            end
    
            local attachment = searchRoot:FindFirstChild("Attachment", true)
            if attachment and attachment:IsA("Attachment") then
                return attachment
            end
    
            return nil
        end
    
        function movement.getDistanceFromPlayer(worldPosition)
            return (playerUtils.getRoot().Position - worldPosition).Magnitude
        end
    
        function movement.teleportExact(cf)
            local root = playerUtils.getRoot()
    
            if settings.AnchorDuringTeleport then
                root.Anchored = true
            end
    
            root.CFrame = cf
            task.wait(settings.TeleportSettleDelay)
    
            if settings.AnchorDuringTeleport then
                root.Anchored = false
            end
        end
    
        function movement.moveToPosition(position)
            playerUtils.getCharacter():MoveTo(position)
            logger.debug("MoveTo:", position)
        end
    
        function movement.setCharacterAnchored(state)
            local root = playerUtils.getRoot()
            if root and root.Parent then
                root.Anchored = state and true or false
            end
        end
    
        function movement.restoreCamera()
            if settings.RestoreCameraAfterRob then
                local camera = services.getCamera()
                camera.CameraType = Enum.CameraType.Custom
                logger.debug("Camera restored")
            end
        end
    
        function movement.pointCameraAtATMFront(atmModel)
            if not settings.UseATMFrontCamera then
                return false
            end
    
            local _, _, atmPart = movement.getATMData(atmModel)
            if not atmPart or not atmPart:IsA("BasePart") then
                logger.debug("ATM part missing for front camera")
                return false
            end
    
            local camera = services.getCamera()
            camera.CameraType = Enum.CameraType.Scriptable
    
            local frontOffset = atmPart.CFrame.LookVector * -settings.CameraFrontDistance
            local upOffset = Vector3.new(0, settings.CameraHeightOffset, 0)
            local cameraPosition = atmPart.Position + frontOffset + upOffset
            local lookTarget = atmPart.Position + Vector3.new(0, settings.CameraLookHeightOffset, 0)
    
            camera.CFrame = CFrame.new(cameraPosition, lookTarget)
            logger.debug("Camera pointed at ATM front:", atmPart.Position)
    
            return true
        end
    
        function movement.fireProximityPrompt(prompt, amount, holdTime)
            local completedEvent = Instance.new("BindableEvent")
    
            task.spawn(function()
                if not movement.isPromptValid(prompt) then
                    logger.warn("Prompt activation skipped because prompt was nil/invalid at fire time")
                    completedEvent:Fire(false)
                    return
                end
    
                local originalHold = prompt.HoldDuration
                local originalDistance = prompt.MaxActivationDistance
                local duration = holdTime or settings.PromptHoldTime
                local success = pcall(function()
                    prompt.HoldDuration = duration
                    prompt.MaxActivationDistance = settings.PromptMaxActivationDistance
    
                    logger.debug("Holding prompt. Duration:", duration, "MaxDistance:", settings.PromptMaxActivationDistance)
    
                    for _ = 1, amount or 1 do
                        if not movement.isPromptValid(prompt) then
                            error("Prompt became invalid during hold")
                        end
    
                        prompt:InputHoldBegin()
    
                        local startTime = time()
                        repeat
                            services.RunService.Heartbeat:Wait()
                        until time() - startTime >= duration
    
                        if prompt and prompt.Parent then
                            prompt:InputHoldEnd()
                        end
                    end
                end)
    
                if prompt and prompt.Parent then
                    prompt.HoldDuration = originalHold
                    prompt.MaxActivationDistance = originalDistance
                end
    
                if success then
                    logger.debug("Prompt finished, restored values")
                else
                    logger.warn("Prompt activation failed because ATM prompt changed or unloaded")
                end
    
                completedEvent:Fire(success)
            end)
    
            return {
                Completed = completedEvent.Event,
            }
        end
    
        function movement.getATMData(atm)
            local atmPart = findATMPart(atm)
            local attachment = findPromptAttachment(atmPart) or findPromptAttachment(atm)
            local prompt = nil
    
            if attachment then
                prompt = attachment:FindFirstChildWhichIsA("ProximityPrompt")
                    or attachment:FindFirstChildWhichIsA("ProximityPrompt", true)
            end
    
            if not prompt and atm then
                prompt = atm:FindFirstChildWhichIsA("ProximityPrompt", true)
            end
    
            if prompt and not attachment and prompt.Parent and prompt.Parent:IsA("Attachment") then
                attachment = prompt.Parent
            end
    
            return attachment, prompt, atmPart
        end
    
        function movement.getATMPosition(instance)
            if not instance then
                return nil
            end
    
            local _, _, atmPart = movement.getATMData(instance)
            if atmPart then
                return atmPart.Position
            end
    
            if instance:IsA("BasePart") then
                return instance.Position
            end
    
            if instance:IsA("Model") then
                return instance:GetPivot().Position
            end
    
            return nil
        end
    
        function movement.getLoadedATMFromSpawner(spawner)
            if isATMModel(spawner) then
                local _, prompt, atmPart = movement.getATMData(spawner)
                if prompt or atmPart or movement.getATMPosition(spawner) then
                    return spawner
                end
            end
    
            for _, child in ipairs(spawner:GetChildren()) do
                if isATMModel(child) then
                    local _, prompt, atmPart = movement.getATMData(child)
                    if prompt or atmPart or movement.getATMPosition(child) then
                        return child
                    end
                end
            end
    
            for _, descendant in ipairs(spawner:GetDescendants()) do
                if isATMModel(descendant) then
                    local _, prompt, atmPart = movement.getATMData(descendant)
                    if prompt or atmPart or movement.getATMPosition(descendant) then
                        return descendant
                    end
                end
            end
    
            return nil
        end
    
        function movement.getLoadedATMs(spawnersFolder)
            local atms = {}
            local seen = {}
    
            for _, spawner in ipairs(spawnersFolder:GetChildren()) do
                local atm = movement.getLoadedATMFromSpawner(spawner)
                if atm and not seen[atm] then
                    seen[atm] = true
                    table.insert(atms, atm)
                end
            end
    
            return atms
        end
    
        function movement.isPromptValid(prompt)
            return prompt ~= nil
                and typeof(prompt) == "Instance"
                and prompt:IsA("ProximityPrompt")
                and prompt.Parent ~= nil
                and prompt.Enabled == true
        end
    
        function movement.closeLocationUI()
            if not settings.CloseLocationUIBeforeEachTP then
                return
            end
    
            local remoteFolder = services.ReplicatedStorage:FindFirstChild("Remotes")
            local remote = remoteFolder and remoteFolder:FindFirstChild("Location")
            if remote then
                pcall(function()
                    remote:FireServer("Leave")
                end)
    
                logger.debug("Closed Any UI")
            end
        end
    
        return movement
    end
    
    return createMovement
    
end

__bundle["modules/player_utils"] = function()
    local function require(moduleName)
        return __bundle_require(__resolve_module_name("modules/player_utils", moduleName))
    end

    local function createPlayerUtils(services)
        local playerUtils = {}
    
        function playerUtils.getPlayer()
            return services.player
        end
    
        function playerUtils.getCharacter()
            return services.player.Character or services.player.CharacterAdded:Wait()
        end
    
        function playerUtils.getHumanoid(character)
            character = character or playerUtils.getCharacter()
            return character:WaitForChild("Humanoid")
        end
    
        function playerUtils.getRoot(character)
            character = character or playerUtils.getCharacter()
            return character:WaitForChild("HumanoidRootPart")
        end
    
        return playerUtils
    end
    
    return createPlayerUtils
    
end

__bundle["modules/services"] = function()
    local function require(moduleName)
        return __bundle_require(__resolve_module_name("modules/services", moduleName))
    end

    local Players = game:GetService("Players")
    
    local services = {
        RunService = game:GetService("RunService"),
        HttpService = game:GetService("HttpService"),
        Players = Players,
        UserInputService = game:GetService("UserInputService"),
        ReplicatedStorage = game:GetService("ReplicatedStorage"),
        VirtualUser = game:GetService("VirtualUser"),
        player = Players.LocalPlayer,
    }
    
    local function findCriminalATMSpawnersFolder()
        local gameFolder = workspace:FindFirstChild("Game")
        local jobsFolder = gameFolder and gameFolder:FindFirstChild("Jobs")
    
        return jobsFolder and jobsFolder:FindFirstChild("CriminalATMSpawners")
    end
    
    function services.getCriminalATMSpawnersFolder(waitForIt)
        if services.criminalATMSpawnersFolder and services.criminalATMSpawnersFolder.Parent then
            return services.criminalATMSpawnersFolder
        end
    
        if waitForIt then
            local gameFolder = workspace:WaitForChild("Game")
            local jobsFolder = gameFolder:WaitForChild("Jobs")
    
            services.criminalATMSpawnersFolder = jobsFolder:WaitForChild("CriminalATMSpawners")
            return services.criminalATMSpawnersFolder
        end
    
        services.criminalATMSpawnersFolder = findCriminalATMSpawnersFolder()
        return services.criminalATMSpawnersFolder
    end
    
    services.criminalATMSpawnersFolder = services.getCriminalATMSpawnersFolder(false)
    
    function services.getCamera()
        return workspace.CurrentCamera
    end
    
    return services
    
end

__bundle["modules/stats"] = function()
    local function require(moduleName)
        return __bundle_require(__resolve_module_name("modules/stats", moduleName))
    end

    local function createStats(totalPositions)
        local stats = {
            PositionsTotal = totalPositions,
            PositionsVisited = 0,
            ATMsRobbed = 0,
            ATMRetryCount = 0,
            FindChecks = 0,
            LoopCount = 0,
        }
    
        function stats.reset()
            stats.PositionsVisited = 0
            stats.ATMsRobbed = 0
            stats.ATMRetryCount = 0
            stats.FindChecks = 0
            stats.LoopCount = 0
        end
    
        function stats.printSummary()
            print("========== ATM LOOP SUMMARY ==========")
            print("Loop count:", stats.LoopCount)
            print("Total positions:", stats.PositionsTotal)
            print("Visited positions:", stats.PositionsVisited)
            print("ATMs robbed:", stats.ATMsRobbed)
            print("Find checks:", stats.FindChecks)
            print("Retry attempts:", stats.ATMRetryCount)
            print("======================================")
        end
    
        return stats
    end
    
    return createStats
    
end

__bundle["modules/ui_builder"] = function()
    local function require(moduleName)
        return __bundle_require(__resolve_module_name("modules/ui_builder", moduleName))
    end

    local function createUI(deps)
        local ui = deps.ui
        local settings = deps.settings
        local flySettings = deps.flySettings
        local stats = deps.stats
        local farm = deps.farm
        local detection = deps.detection
        local movement = deps.movement
        local logger = deps.logger
        local fly = deps.fly
    
        local mainTab = ui:AddTab({
            Name = "ATM Farm",
        })
    
        local controlSection = mainTab:AddSection({
            Name = "ATM Farm",
            Description = "Core controls and live status.",
        })
    
        local statsParagraph = controlSection:AddParagraph({
            Name = "Live Stats",
            Text = "Initializing...",
        })
    
        local waitModeDefault = "Timer Threshold"
        if settings.WaitMode == 1 then
            waitModeDefault = "Always Wait"
        elseif settings.WaitMode == 2 then
            waitModeDefault = "Money Threshold"
        end
    
        local cooldownPlaceholder = ("%.2f, %.2f, %.2f"):format(
            settings.CooldownPosition.X,
            settings.CooldownPosition.Y,
            settings.CooldownPosition.Z
        )
    
        local advancedBuilt = false
    
        local function parseCooldownPosition(text)
            local x, y, z = string.match(text, "([^,]+),%s*([^,]+),%s*([^,]+)")
            x, y, z = tonumber(x), tonumber(y), tonumber(z)
    
            if x and y and z then
                return Vector3.new(x, y, z)
            end
    
            return nil
        end
    
        local function refreshStats()
            local statusText = settings.Enabled and (farm.isLoopRunning() and "Running" or "Enabled") or "Stopped"
            local currentCash = detection.getSafeCash()
            local timerValue = detection.getEscapeNotification("seconds")
    
            statsParagraph:SetText(table.concat({
                ("Status: %s"):format(statusText),
                ("Loop Count: %d"):format(stats.LoopCount),
                ("Visited This Loop: %d / %d"):format(stats.PositionsVisited, stats.PositionsTotal),
                ("ATMs Robbed: %d"):format(stats.ATMsRobbed),
                ("Retry Attempts: %d"):format(stats.ATMRetryCount),
                ("Find Checks: %d"):format(stats.FindChecks),
                ("Current Cash: $%s"):format(tostring(currentCash or 0)),
                ("Escape Timer: %s"):format(timerValue and (tostring(timerValue) .. "s") or "nil"),
            }, "\n"))
        end
    
        local function buildAdvancedSections()
            if advancedBuilt then
                return
            end
    
            advancedBuilt = true
    
            local loopSection = mainTab:AddSection({
                Name = "Loop Settings",
                Description = "Movement, retries, and loop timing.",
            })
    
            local waitSection = mainTab:AddSection({
                Name = "Wait Logic",
                Description = "Cooldown and threshold behavior.",
            })
    
            local promptSection = mainTab:AddSection({
                Name = "Prompt / Camera",
                Description = "Prompt handling and ATM camera behavior.",
            })
    
            local miscSection = mainTab:AddSection({
                Name = "Misc",
                Description = "QoL, debug, and fly controls.",
            })
    
            loopSection:AddButton({
                Name = "Reset Stats",
                Tooltip = "Resets counters shown in the UI.",
                Callback = function()
                    stats.reset()
                    refreshStats()
                    logger.notify("ATM", "Stats reset", 3)
                end,
            })
    
            loopSection:AddSlider({
                Name = "Wait After Teleport",
                Min = 0,
                Max = 10,
                Default = settings.WaitAfterTeleportToATM,
                Increment = 0.1,
                Callback = function(value)
                    settings.WaitAfterTeleportToATM = value
                end,
            })
    
            loopSection:AddSlider({
                Name = "Wait After Return",
                Min = 0,
                Max = 10,
                Default = settings.WaitAfterReturningFromCooldown,
                Increment = 0.1,
                Callback = function(value)
                    settings.WaitAfterReturningFromCooldown = value
                end,
            })
    
            loopSection:AddSlider({
                Name = "Retry Attempts Per ATM",
                Min = 1,
                Max = 10,
                Default = settings.RetryAttemptsPerATM,
                Increment = 1,
                Callback = function(value)
                    settings.RetryAttemptsPerATM = value
                end,
            })
    
            loopSection:AddToggle({
                Name = "Loop Infinitely",
                Default = settings.LoopInfinitely,
                Callback = function(state)
                    settings.LoopInfinitely = state
                end,
            })
    
            loopSection:AddSlider({
                Name = "Wait Between Full Loops",
                Min = 0,
                Max = 300,
                Default = settings.WaitBetweenFullLoops,
                Increment = 1,
                Callback = function(value)
                    settings.WaitBetweenFullLoops = value
                end,
            })
    
            waitSection:AddSlider({
                Name = "Wait Check Interval",
                Min = 0.05,
                Max = 2,
                Default = settings.WaitCheckInterval,
                Increment = 0.05,
                Callback = function(value)
                    settings.WaitCheckInterval = value
                end,
            })
    
            waitSection:AddSlider({
                Name = "Success Check Window",
                Min = 0.5,
                Max = 10,
                Default = settings.SuccessCheckWindow,
                Increment = 0.05,
                Callback = function(value)
                    settings.SuccessCheckWindow = value
                end,
            })
    
            waitSection:AddSlider({
                Name = "Success Poll Interval",
                Min = 0.05,
                Max = 1,
                Default = settings.SuccessCheckPollInterval,
                Increment = 0.05,
                Callback = function(value)
                    settings.SuccessCheckPollInterval = value
                end,
            })
    
            waitSection:AddSlider({
                Name = "Missing Timer Grace",
                Min = 0,
                Max = 15,
                Default = settings.MissingTimerGracePeriod,
                Increment = 0.25,
                Callback = function(value)
                    settings.MissingTimerGracePeriod = value
                end,
            })
    
            promptSection:AddSlider({
                Name = "Prompt Hold Time",
                Min = 0.5,
                Max = 15,
                Default = settings.PromptHoldTime,
                Increment = 0.1,
                Callback = function(value)
                    settings.PromptHoldTime = value
                end,
            })
    
            promptSection:AddSlider({
                Name = "Prompt Max Distance",
                Min = 1,
                Max = 20,
                Default = settings.PromptMaxActivationDistance,
                Increment = 0.5,
                Callback = function(value)
                    settings.PromptMaxActivationDistance = value
                end,
            })
    
            promptSection:AddSlider({
                Name = "Prompt Recheck Delay",
                Min = 0,
                Max = 5,
                Default = settings.PromptRecheckDelay,
                Increment = 0.05,
                Callback = function(value)
                    settings.PromptRecheckDelay = value
                end,
            })
    
            promptSection:AddSlider({
                Name = "Prompt Post Hold Delay",
                Min = 0,
                Max = 5,
                Default = settings.PromptPostHoldDelay,
                Increment = 0.05,
                Callback = function(value)
                    settings.PromptPostHoldDelay = value
                end,
            })
    
            promptSection:AddSlider({
                Name = "Extra Finished Delay",
                Min = 0,
                Max = 5,
                Default = settings.ExtraFinishedDelay,
                Increment = 0.05,
                Callback = function(value)
                    settings.ExtraFinishedDelay = value
                end,
            })
    
            promptSection:AddToggle({
                Name = "Use ATM Front Camera",
                Default = settings.UseATMFrontCamera,
                Callback = function(state)
                    settings.UseATMFrontCamera = state
                    if not state then
                        movement.restoreCamera()
                    end
                end,
            })
    
            promptSection:AddToggle({
                Name = "Restore Camera After Rob",
                Default = settings.RestoreCameraAfterRob,
                Callback = function(state)
                    settings.RestoreCameraAfterRob = state
                    if state then
                        movement.restoreCamera()
                    end
                end,
            })
    
            promptSection:AddSlider({
                Name = "Camera Front Distance",
                Min = 1,
                Max = 20,
                Default = settings.CameraFrontDistance,
                Increment = 0.1,
                Callback = function(value)
                    settings.CameraFrontDistance = value
                end,
            })
    
            promptSection:AddSlider({
                Name = "Camera Height Offset",
                Min = -5,
                Max = 10,
                Default = settings.CameraHeightOffset,
                Increment = 0.1,
                Callback = function(value)
                    settings.CameraHeightOffset = value
                end,
            })
    
            promptSection:AddSlider({
                Name = "Camera Look Height",
                Min = -5,
                Max = 10,
                Default = settings.CameraLookHeightOffset,
                Increment = 0.1,
                Callback = function(value)
                    settings.CameraLookHeightOffset = value
                end,
            })
    
            miscSection:AddToggle({
                Name = "Anchor During Teleport",
                Default = settings.AnchorDuringTeleport,
                Callback = function(state)
                    settings.AnchorDuringTeleport = state
                end,
            })
    
            miscSection:AddSlider({
                Name = "Teleport Settle Delay",
                Min = 0,
                Max = 1,
                Default = settings.TeleportSettleDelay,
                Increment = 0.01,
                Callback = function(value)
                    settings.TeleportSettleDelay = value
                end,
            })
    
            miscSection:AddToggle({
                Name = "Skip Used Positions",
                Default = settings.SkipUsedPositions,
                Callback = function(state)
                    settings.SkipUsedPositions = state
                end,
            })
    
            miscSection:AddToggle({
                Name = "Move To Cooldown At End",
                Default = settings.MoveToCooldownAtEnd,
                Callback = function(state)
                    settings.MoveToCooldownAtEnd = state
                end,
            })
    
            miscSection:AddToggle({
                Name = "Close Location UI Before TP",
                Default = settings.CloseLocationUIBeforeEachTP,
                Callback = function(state)
                    settings.CloseLocationUIBeforeEachTP = state
                end,
            })
    
            miscSection:AddToggle({
                Name = "Print Loop Summary",
                Default = settings.PrintLoopSummary,
                Callback = function(state)
                    settings.PrintLoopSummary = state
                end,
            })
    
            miscSection:AddToggle({
                Name = "Debug Prints",
                Default = settings.Debug,
                Callback = function(state)
                    settings.Debug = state
                end,
            })
    
            miscSection:AddToggle({
                Name = "Fly",
                Default = flySettings.Enabled,
                Tooltip = "Fly mode. WASD to move, Space/Shift to go up/down.",
                Callback = function(state)
                    fly.setEnabled(state)
                end,
            })
    
            miscSection:AddSlider({
                Name = "Fly Speed",
                Default = flySettings.Speed,
                Min = 10,
                Max = 300,
                Increment = 1,
                Tooltip = "Horizontal fly movement speed.",
                Callback = function(value)
                    flySettings.Speed = value
                end,
            })
    
            miscSection:AddSlider({
                Name = "Ascent Speed",
                Default = flySettings.AscendSpeed,
                Min = 10,
                Max = 300,
                Increment = 1,
                Tooltip = "Vertical fly movement speed.",
                Callback = function(value)
                    flySettings.AscendSpeed = value
                end,
            })
    
            miscSection:AddSlider({
                Name = "Fly Smoothing",
                Default = flySettings.Smoothing,
                Min = 0.01,
                Max = 1,
                Increment = 0.01,
                Tooltip = "Higher = snappier movement, lower = smoother acceleration.",
                Callback = function(value)
                    flySettings.Smoothing = value
                end,
            })
    
            logger.notify("ATM", "Advanced options loaded", 3)
        end
    
        controlSection:AddToggle({
            Name = "ATM Loop",
            Default = settings.Enabled,
            Tooltip = "Starts or stops the ATM farm loop.",
            Callback = function(state)
                settings.Enabled = state
                refreshStats()
    
                if state then
                    if not farm.isLoopRunning() then
                        local loop = farm.start()
                        task.spawn(function()
                            loop.Completed:Wait()
                        end)
                    end
                else
                    farm.stop()
                end
            end,
        })
    
        controlSection:AddButton({
            Name = "Print Summary",
            Callback = function()
                farm.printSummary()
                logger.notify("ATM", "Printed summary to console", 3)
            end,
        })
    
        controlSection:AddDropdown({
            Name = "Wait Mode",
            Items = { "Always Wait", "Money Threshold", "Timer Threshold" },
            Default = waitModeDefault,
            Tooltip = "Chooses how the script decides to wait after robbing an ATM.",
            Callback = function(value)
                if value == "Always Wait" then
                    settings.WaitMode = 1
                elseif value == "Money Threshold" then
                    settings.WaitMode = 2
                elseif value == "Timer Threshold" then
                    settings.WaitMode = 3
                end
    
                refreshStats()
            end,
        })
    
        controlSection:AddSlider({
            Name = "Money Threshold",
            Min = 0,
            Max = 500000,
            Default = settings.MoneyThresholdBeforeWaiting,
            Increment = 1000,
            Callback = function(value)
                settings.MoneyThresholdBeforeWaiting = value
                refreshStats()
            end,
        })
    
        controlSection:AddSlider({
            Name = "Timer Threshold (Seconds)",
            Min = 0,
            Max = 1200,
            Default = settings.TimeThresholdBeforeWaiting,
            Increment = 5,
            Callback = function(value)
                settings.TimeThresholdBeforeWaiting = value
                refreshStats()
            end,
        })
    
        controlSection:AddTextbox({
            Name = "Cooldown Position",
            Placeholder = cooldownPlaceholder,
            Tooltip = "Format: x, y, z",
            Callback = function(text, submitted)
                if not submitted then
                    return
                end
    
                local parsed = parseCooldownPosition(text)
                if parsed then
                    settings.CooldownPosition = parsed
                    logger.notify("ATM", "Cooldown position updated", 3)
                else
                    logger.notify("ATM", "Invalid Vector3 format", 3)
                end
            end,
        })
    
        controlSection:AddToggle({
            Name = "Show Advanced Options",
            Default = false,
            Tooltip = "Adds the advanced sections below.",
            Callback = function(state)
                if state then
                    buildAdvancedSections()
                end
            end,
        })
    
        local settingsKeybindsSection = ui:AddSettingsSection({
            Name = "Keybinds",
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
            Default = settings.ToggleKey,
            Callback = function(newKey)
                settings.ToggleKey = newKey
    
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
            Default = settings.StopKey,
            Mode = "Press",
            Callback = function()
                if farm.isLoopRunning() or settings.Enabled then
                    farm.stop()
                    logger.notify("ATM", "Stopped from keybind", 3)
                else
                    settings.Enabled = true
                    refreshStats()
    
                    if not farm.isLoopRunning() then
                        local loop = farm.start()
                        task.spawn(function()
                            loop.Completed:Wait()
                        end)
                    end
    
                    logger.notify("ATM", "Started from keybind", 3)
                end
            end,
        })
    
        ui:AddKeybind({
            Name = "Toggle Fly",
            Section = settingsKeybindsSection,
            Default = flySettings.ToggleKey,
            Mode = "Press",
            Callback = function()
                fly.toggle()
            end,
        })
    
        return {
            refreshStats = refreshStats,
        }
    end
    
    return {
        create = createUI,
    }
    
end

__bundle["modules/ui_loader"] = function()
    local function require(moduleName)
        return __bundle_require(__resolve_module_name("modules/ui_loader", moduleName))
    end

    local uiLoader = {}
    
    function uiLoader.create(uiConfig)
        local themes = loadstring(game:HttpGet(uiConfig.ThemeUrl))()
        local library = loadstring(game:HttpGet(uiConfig.LibraryUrl))()
    
        local ui = library.new({
            Themes = themes,
            DefaultTheme = uiConfig.DefaultTheme,
            ToggleKey = uiConfig.ToggleKey,
        })
    
        ui:SetPromptText(uiConfig.PromptText)
        ui:ShowPrompt(true)
        ui:SetKeybindOverlayEnabled(true)
    
        return ui
    end
    
    return uiLoader
    
end

__bundle_require("main")
