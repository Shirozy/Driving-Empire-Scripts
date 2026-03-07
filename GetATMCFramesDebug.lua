local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local criminalATMSpawnersFolder = workspace:WaitForChild("Game")
	:WaitForChild("Jobs")
	:WaitForChild("CriminalATMSpawners")

local ROUND = 2

local ATMTable = {}

local debugFolder = Instance.new("Folder")
debugFolder.Name = "ATM_Debug"
debugFolder.Parent = LocalPlayer

local posValue = Instance.new("StringValue")
posValue.Name = "ATM_Positions"
posValue.Parent = debugFolder

local countValue = Instance.new("IntValue")
countValue.Name = "ATM_Count"
countValue.Parent = debugFolder

local atmFolder = Instance.new("Folder")
atmFolder.Name = "ATM_List"
atmFolder.Parent = debugFolder

local function round(n)
	local m = 10 ^ ROUND
	return math.round(n*m)/m
end

local function keyFromPos(pos)
	return string.format("%.2f,%.2f,%.2f",
		round(pos.X),
		round(pos.Y),
		round(pos.Z)
	)
end

local function updateJSON()
	local list = {}

	for _,pos in pairs(ATMTable) do
		table.insert(list,{
			X = pos.X,
			Y = pos.Y,
			Z = pos.Z
		})
	end

	table.sort(list,function(a,b)
		return a.X < b.X
	end)

	posValue.Value = HttpService:JSONEncode(list)
	countValue.Value = #list
end

local function createATMValue(key,pos)
	local v = Instance.new("StringValue")
	v.Name = "ATM_"..(#atmFolder:GetChildren()+1)
	v.Value = string.format(
		"%.2f, %.2f, %.2f",
		pos.X,pos.Y,pos.Z
	)
	v.Parent = atmFolder
end

local function addATM(atm)
	local pos = atm:IsA("Model") and atm:GetPivot().Position or atm.Position
	local key = keyFromPos(pos)

	if ATMTable[key] then
		return
	end

	ATMTable[key] = pos

	print("[ATM DISCOVERED]", key)

	createATMValue(key,pos)
	updateJSON()
end

local function scan()
	for _,spawner in ipairs(criminalATMSpawnersFolder:GetChildren()) do
		local atm = spawner:FindFirstChild("CriminalATM")
		if atm then
			addATM(atm)
		end
	end
end

criminalATMSpawnersFolder.DescendantAdded:Connect(function(obj)
	if obj.Name == "CriminalATM" then
		task.wait()
		addATM(obj)
	end
end)

-- nearest ATM helper
local function getNearestATM()
	local char = LocalPlayer.Character
	if not char then return end

	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local closest
	local dist = math.huge

	for _,pos in pairs(ATMTable) do
		local d = (root.Position - pos).Magnitude
		if d < dist then
			dist = d
			closest = pos
		end
	end

	return closest,dist
end

RunService.RenderStepped:Connect(function()
	local pos,dist = getNearestATM()
	if pos then
		debugFolder:SetAttribute("NearestATM", string.format(
			"%.1f studs",
			dist
		))
	end
end)

while true do
	scan()
	task.wait(2)
end
