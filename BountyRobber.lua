local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local test = true
local BOUNTY_THRESHOLD = 10000

-- Debug print helper
local function debugPrint(...)
    print("[BountyDebug]", ...)
end

local function extractNumber(text: string): number?
    local digits = text:gsub("[^%d]", "")
    if digits == "" then
        return nil
    end
    return tonumber(digits)
end


local function getCharacter(player: Player): Model?
    local character = player.Character
    if not character then
        return nil
    end
    local head = character:FindFirstChild("Head")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not head or not root then
        return nil
    end
    return character
end

-- Get bounty from billboard
local function getBountyFromBillboard(character: Model): number?
    local head = character:FindFirstChild("Head")
    if not head then return nil end

    local billboard = head:FindFirstChild("CharacterBillboard")
    if not billboard then return nil end

    for _, child in ipairs(billboard:GetDescendants()) do
        if child:IsA("TextLabel") then
            local bounty = extractNumber(child.Text)
            if bounty then
                return bounty
            end
        end
    end
    return nil
end


local function teleportToPlayer(targetPlayer: Player)
    while test do
        task.wait(0.2)

        local myCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local myRoot = myCharacter:FindFirstChild("HumanoidRootPart")
        if not myRoot then
            debugPrint("LocalPlayer missing HumanoidRootPart")
            return
        end

        local targetCharacter = getCharacter(targetPlayer)
        if not targetCharacter then
            debugPrint("Target lost character:", targetPlayer.Name)
            return
        end

        local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
        if not targetRoot then
            debugPrint("Target missing HumanoidRootPart:", targetPlayer.Name)
            return
        end

        local bounty = getBountyFromBillboard(targetCharacter)
        if not bounty or bounty <= BOUNTY_THRESHOLD then
            debugPrint("Bounty gone or below threshold for", targetPlayer.Name)
            return
        end

        -- Teleport slightly behind target
        myRoot.CFrame = targetRoot.CFrame + Vector3.new(0, 0, -3)
    end
end

-- Main loop
while true do
    task.wait(0.1)
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then
            continue
        end

        local character = getCharacter(player)
        if not character then
            continue
        end

        local bounty = getBountyFromBillboard(character)
        if bounty and bounty > BOUNTY_THRESHOLD then
            debugPrint(player.Name, "has bounty over", BOUNTY_THRESHOLD, "(", bounty, ")")
            teleportToPlayer(player)
            -- Once the target loses bounty, loop will scan again
        end
    end
end
