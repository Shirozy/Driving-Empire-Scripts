local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SETTINGS = {
	ToggleKey = Enum.KeyCode.RightShift,
	CloseKey = Enum.KeyCode.Escape,

	DefaultVisible = true,
	EnableRainbowAccent = true,
	RainbowSpeed = 0.08,

	WindowSize = UDim2.new(0, 560, 0, 640),
	WindowPosition = UDim2.new(0.5, -280, 0.5, -320),

	ResetColorsOnOpenCar = true,
	DefaultBodyColor = Color3.fromRGB(255, 255, 255),
	DefaultInteriorColor = Color3.fromRGB(255, 255, 255),
	DefaultRimsColor = Color3.fromRGB(255, 255, 255),

	ShowDebugPrints = true,
	DestroyOldGui = true,
}

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local vehicleSaveIDs = require(
	ReplicatedStorage:WaitForChild("Modules")
		:WaitForChild("DB")
		:WaitForChild("VehicleSaveIDs")
)

local function debugPrint(...)
	if SETTINGS.ShowDebugPrints then
		print("[CarUI]", ...)
	end
end

if SETTINGS.DestroyOldGui then
	local existingGui = PlayerGui:FindFirstChild("CarColorPickerGui")
	if existingGui then
		existingGui:Destroy()
	end
end

local cars = {}
for carName, _ in pairs(vehicleSaveIDs.ids) do
	table.insert(cars, carName)
end

table.sort(cars, function(a, b)
	return string.lower(a) < string.lower(b)
end)

local gui = Instance.new("ScreenGui")
gui.Name = "CarColorPickerGui"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Enabled = SETTINGS.DefaultVisible
gui.Parent = PlayerGui

local selectedCarName = nil
local selectedTarget = "Body"

local colorState = {
	Body = SETTINGS.DefaultBodyColor,
	Interior = SETTINGS.DefaultInteriorColor,
	Rims = SETTINGS.DefaultRimsColor,
}

local currentHue = 0
local currentSat = 0
local currentVal = 1

local draggingSV = false
local draggingHue = false
local draggingWindow = false
local dragStart = nil
local startPos = nil

local presetColors = {
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(0, 0, 0),
	Color3.fromRGB(255, 0, 0),
	Color3.fromRGB(255, 140, 0),
	Color3.fromRGB(255, 215, 0),
	Color3.fromRGB(0, 255, 0),
	Color3.fromRGB(0, 170, 255),
	Color3.fromRGB(0, 0, 255),
	Color3.fromRGB(128, 0, 255),
	Color3.fromRGB(255, 0, 255),
	Color3.fromRGB(255, 105, 180),
	Color3.fromRGB(120, 120, 120),
}

local function makeCorner(obj, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = obj
	return c
end

local function makeStroke(obj, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.fromRGB(55, 55, 65)
	s.Thickness = thickness or 1
	s.Parent = obj
	return s
end

local function rgbString(color)
	return string.format(
		"%d, %d, %d",
		math.floor(color.R * 255 + 0.5),
		math.floor(color.G * 255 + 0.5),
		math.floor(color.B * 255 + 0.5)
	)
end

local function colorToHex(color)
	return string.format(
		"#%02X%02X%02X",
		math.floor(color.R * 255 + 0.5),
		math.floor(color.G * 255 + 0.5),
		math.floor(color.B * 255 + 0.5)
	)
end

local function hexToColor3(hex)
	hex = hex:gsub("#", "")
	if #hex ~= 6 then
		return nil
	end

	local r = tonumber(hex:sub(1, 2), 16)
	local g = tonumber(hex:sub(3, 4), 16)
	local b = tonumber(hex:sub(5, 6), 16)

	if not r or not g or not b then
		return nil
	end

	return Color3.fromRGB(r, g, b)
end

local function setFromColor3(color)
	local h, s, v = color:ToHSV()
	currentHue = h
	currentSat = s
	currentVal = v
end

local function getCurrentColor()
	return Color3.fromHSV(currentHue, currentSat, currentVal)
end

local function applyCurrentColorToTarget()
	colorState[selectedTarget] = getCurrentColor()
end

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = SETTINGS.WindowSize
main.Position = SETTINGS.WindowPosition
main.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
main.BorderSizePixel = 0
main.Parent = gui
makeCorner(main, 12)
local mainStroke = makeStroke(main, Color3.fromRGB(80, 120, 255), 1.5)

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 42)
topBar.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
topBar.BorderSizePixel = 0
topBar.Parent = main
makeCorner(topBar, 12)

local topFix = Instance.new("Frame")
topFix.Size = UDim2.new(1, 0, 0, 12)
topFix.Position = UDim2.new(0, 0, 1, -12)
topFix.BackgroundColor3 = topBar.BackgroundColor3
topFix.BorderSizePixel = 0
topFix.Parent = topBar

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 14, 0, 0)
title.Size = UDim2.new(1, -150, 1, 0)
title.Font = Enum.Font.GothamBold
title.Text = "Vehicle Browser"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

local keybindLabel = Instance.new("TextLabel")
keybindLabel.BackgroundTransparency = 1
keybindLabel.Position = UDim2.new(1, -140, 0, 0)
keybindLabel.Size = UDim2.new(0, 100, 1, 0)
keybindLabel.Font = Enum.Font.Gotham
keybindLabel.Text = tostring(SETTINGS.ToggleKey.Name)
keybindLabel.TextColor3 = Color3.fromRGB(170, 170, 180)
keybindLabel.TextSize = 12
keybindLabel.TextXAlignment = Enum.TextXAlignment.Right
keybindLabel.Parent = topBar

local destroyButton = Instance.new("TextButton")
destroyButton.Size = UDim2.new(0, 28, 0, 28)
destroyButton.Position = UDim2.new(1, -36, 0.5, -14)
destroyButton.BackgroundColor3 = Color3.fromRGB(170, 60, 60)
destroyButton.BorderSizePixel = 0
destroyButton.Font = Enum.Font.GothamBold
destroyButton.Text = "X"
destroyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
destroyButton.TextSize = 14
destroyButton.Parent = topBar
makeCorner(destroyButton, 8)

destroyButton.MouseButton1Click:Connect(function()
	gui.Enabled = false
end)

topBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingWindow = true
		dragStart = input.Position
		startPos = main.Position
	end
end)

local listPage = Instance.new("Frame")
listPage.Size = UDim2.new(1, 0, 1, -42)
listPage.Position = UDim2.new(0, 0, 0, 42)
listPage.BackgroundTransparency = 1
listPage.Parent = main

local pickerPage = Instance.new("Frame")
pickerPage.Size = UDim2.new(1, 0, 1, -42)
pickerPage.Position = UDim2.new(0, 0, 0, 42)
pickerPage.BackgroundTransparency = 1
pickerPage.Visible = false
pickerPage.Parent = main

local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -24, 0, 38)
searchBox.Position = UDim2.new(0, 12, 0, 12)
searchBox.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
searchBox.BorderSizePixel = 0
searchBox.ClearTextOnFocus = false
searchBox.Font = Enum.Font.Gotham
searchBox.PlaceholderText = "Search for a car..."
searchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 160)
searchBox.Text = ""
searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBox.TextSize = 14
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.Parent = listPage
makeCorner(searchBox, 8)

local searchPadding = Instance.new("UIPadding")
searchPadding.PaddingLeft = UDim.new(0, 12)
searchPadding.PaddingRight = UDim.new(0, 12)
searchPadding.Parent = searchBox

local infoLabel = Instance.new("TextLabel")
infoLabel.BackgroundTransparency = 1
infoLabel.Position = UDim2.new(0, 12, 0, 56)
infoLabel.Size = UDim2.new(1, -24, 0, 18)
infoLabel.Font = Enum.Font.Gotham
infoLabel.Text = "0 vehicles"
infoLabel.TextColor3 = Color3.fromRGB(170, 170, 180)
infoLabel.TextSize = 12
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.Parent = listPage

local listFrame = Instance.new("ScrollingFrame")
listFrame.Position = UDim2.new(0, 12, 0, 80)
listFrame.Size = UDim2.new(1, -24, 1, -92)
listFrame.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 6
listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
listFrame.CanvasSize = UDim2.new()
listFrame.Parent = listPage
makeCorner(listFrame, 8)

local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop = UDim.new(0, 8)
listPadding.PaddingBottom = UDim.new(0, 8)
listPadding.PaddingLeft = UDim.new(0, 8)
listPadding.PaddingRight = UDim.new(0, 8)
listPadding.Parent = listFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.Parent = listFrame

local pickerTitle = Instance.new("TextLabel")
pickerTitle.BackgroundTransparency = 1
pickerTitle.Position = UDim2.new(0, 16, 0, 14)
pickerTitle.Size = UDim2.new(1, -32, 0, 28)
pickerTitle.Font = Enum.Font.GothamBold
pickerTitle.Text = "Customize Vehicle"
pickerTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
pickerTitle.TextSize = 20
pickerTitle.TextXAlignment = Enum.TextXAlignment.Left
pickerTitle.Parent = pickerPage

local carNameLabel = Instance.new("TextLabel")
carNameLabel.BackgroundTransparency = 1
carNameLabel.Position = UDim2.new(0, 16, 0, 42)
carNameLabel.Size = UDim2.new(1, -32, 0, 22)
carNameLabel.Font = Enum.Font.Gotham
carNameLabel.Text = ""
carNameLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
carNameLabel.TextSize = 14
carNameLabel.TextXAlignment = Enum.TextXAlignment.Left
carNameLabel.Parent = pickerPage

local tabsHolder = Instance.new("Frame")
tabsHolder.Size = UDim2.new(1, -32, 0, 40)
tabsHolder.Position = UDim2.new(0, 16, 0, 74)
tabsHolder.BackgroundTransparency = 1
tabsHolder.Parent = pickerPage

local tabsLayout = Instance.new("UIListLayout")
tabsLayout.FillDirection = Enum.FillDirection.Horizontal
tabsLayout.Padding = UDim.new(0, 8)
tabsLayout.Parent = tabsHolder

local function createTab(name)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(0, 110, 1, 0)
	button.BackgroundColor3 = Color3.fromRGB(42, 42, 52)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Text = name
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 13
	makeCorner(button, 9)
	makeStroke(button, Color3.fromRGB(60, 60, 72))
	button.Parent = tabsHolder
	return button
end

local bodyTab = createTab("Body")
local interiorTab = createTab("Interior")
local rimsTab = createTab("Rims")

local svFrame = Instance.new("Frame")
svFrame.Size = UDim2.new(0, 280, 0, 280)
svFrame.Position = UDim2.new(0, 16, 0, 130)
svFrame.BorderSizePixel = 0
svFrame.BackgroundColor3 = Color3.fromHSV(currentHue, 1, 1)
svFrame.Parent = pickerPage
makeCorner(svFrame, 10)
makeStroke(svFrame)

local whiteOverlay = Instance.new("Frame")
whiteOverlay.Size = UDim2.new(1, 0, 1, 0)
whiteOverlay.BackgroundColor3 = Color3.new(1, 1, 1)
whiteOverlay.BorderSizePixel = 0
whiteOverlay.Parent = svFrame
makeCorner(whiteOverlay, 10)

local whiteGradient = Instance.new("UIGradient")
whiteGradient.Rotation = 0
whiteGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(1, 1),
})
whiteGradient.Parent = whiteOverlay

local blackOverlay = Instance.new("Frame")
blackOverlay.Size = UDim2.new(1, 0, 1, 0)
blackOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
blackOverlay.BorderSizePixel = 0
blackOverlay.Parent = svFrame
makeCorner(blackOverlay, 10)

local blackGradient = Instance.new("UIGradient")
blackGradient.Rotation = 90
blackGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(1, 0),
})
blackGradient.Parent = blackOverlay

local svCursor = Instance.new("Frame")
svCursor.Size = UDim2.new(0, 12, 0, 12)
svCursor.AnchorPoint = Vector2.new(0.5, 0.5)
svCursor.BackgroundColor3 = Color3.new(1, 1, 1)
svCursor.BorderSizePixel = 0
svCursor.Parent = svFrame
makeCorner(svCursor, 12)
makeStroke(svCursor, Color3.new(0, 0, 0), 2)

local hueFrame = Instance.new("Frame")
hueFrame.Size = UDim2.new(0, 28, 0, 280)
hueFrame.Position = UDim2.new(0, 308, 0, 130)
hueFrame.BorderSizePixel = 0
hueFrame.BackgroundColor3 = Color3.new(1, 1, 1)
hueFrame.Parent = pickerPage
makeCorner(hueFrame, 10)
makeStroke(hueFrame)

local hueGradient = Instance.new("UIGradient")
hueGradient.Rotation = 90
hueGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0.000, Color3.fromRGB(255, 0, 0)),
	ColorSequenceKeypoint.new(0.166, Color3.fromRGB(255, 255, 0)),
	ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
	ColorSequenceKeypoint.new(0.500, Color3.fromRGB(0, 255, 255)),
	ColorSequenceKeypoint.new(0.666, Color3.fromRGB(0, 0, 255)),
	ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
	ColorSequenceKeypoint.new(1.000, Color3.fromRGB(255, 0, 0)),
})
hueGradient.Parent = hueFrame

local hueCursor = Instance.new("Frame")
hueCursor.Size = UDim2.new(1, 6, 0, 4)
hueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
hueCursor.Position = UDim2.new(0.5, 0, 0, 0)
hueCursor.BackgroundColor3 = Color3.new(1, 1, 1)
hueCursor.BorderSizePixel = 0
hueCursor.Parent = hueFrame
makeCorner(hueCursor, 4)
makeStroke(hueCursor, Color3.new(0, 0, 0), 1)

local previewPanel = Instance.new("Frame")
previewPanel.Size = UDim2.new(0, 210, 0, 170)
previewPanel.Position = UDim2.new(0, 340, 0, 130)
previewPanel.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
previewPanel.BorderSizePixel = 0
previewPanel.Parent = pickerPage
makeCorner(previewPanel, 10)
makeStroke(previewPanel)

local previewTitle = Instance.new("TextLabel")
previewTitle.BackgroundTransparency = 1
previewTitle.Position = UDim2.new(0, 12, 0, 10)
previewTitle.Size = UDim2.new(1, -24, 0, 18)
previewTitle.Font = Enum.Font.GothamBold
previewTitle.Text = "Selected Color"
previewTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
previewTitle.TextSize = 14
previewTitle.TextXAlignment = Enum.TextXAlignment.Left
previewTitle.Parent = previewPanel

local colorPreview = Instance.new("Frame")
colorPreview.Size = UDim2.new(1, -24, 0, 60)
colorPreview.Position = UDim2.new(0, 12, 0, 36)
colorPreview.BackgroundColor3 = Color3.new(1, 1, 1)
colorPreview.BorderSizePixel = 0
colorPreview.Parent = previewPanel
makeCorner(colorPreview, 10)
makeStroke(colorPreview)

local rgbLabel = Instance.new("TextLabel")
rgbLabel.BackgroundTransparency = 1
rgbLabel.Position = UDim2.new(0, 12, 0, 102)
rgbLabel.Size = UDim2.new(1, -24, 0, 18)
rgbLabel.Font = Enum.Font.Gotham
rgbLabel.Text = "255, 255, 255"
rgbLabel.TextColor3 = Color3.fromRGB(210, 210, 220)
rgbLabel.TextSize = 13
rgbLabel.TextXAlignment = Enum.TextXAlignment.Left
rgbLabel.Parent = previewPanel

local hexBox = Instance.new("TextBox")
hexBox.Size = UDim2.new(1, -24, 0, 28)
hexBox.Position = UDim2.new(0, 12, 0, 126)
hexBox.BackgroundColor3 = Color3.fromRGB(38, 38, 46)
hexBox.BorderSizePixel = 0
hexBox.ClearTextOnFocus = false
hexBox.Font = Enum.Font.Gotham
hexBox.PlaceholderText = "#FFFFFF"
hexBox.Text = "#FFFFFF"
hexBox.TextColor3 = Color3.fromRGB(255, 255, 255)
hexBox.TextSize = 13
hexBox.Parent = previewPanel
makeCorner(hexBox, 8)

local targetLabel = Instance.new("TextLabel")
targetLabel.BackgroundTransparency = 1
targetLabel.Position = UDim2.new(0, 16, 0, 418)
targetLabel.Size = UDim2.new(0, 180, 0, 18)
targetLabel.Font = Enum.Font.Gotham
targetLabel.Text = "Editing: Body"
targetLabel.TextColor3 = Color3.fromRGB(170, 170, 180)
targetLabel.TextSize = 12
targetLabel.TextXAlignment = Enum.TextXAlignment.Left
targetLabel.Parent = pickerPage

local presetsLabel = Instance.new("TextLabel")
presetsLabel.BackgroundTransparency = 1
presetsLabel.Position = UDim2.new(0, 16, 0, 446)
presetsLabel.Size = UDim2.new(1, -32, 0, 18)
presetsLabel.Font = Enum.Font.GothamBold
presetsLabel.Text = "Preset Swatches"
presetsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
presetsLabel.TextSize = 13
presetsLabel.TextXAlignment = Enum.TextXAlignment.Left
presetsLabel.Parent = pickerPage

local presetsHolder = Instance.new("Frame")
presetsHolder.Size = UDim2.new(1, -32, 0, 42)
presetsHolder.Position = UDim2.new(0, 16, 0, 470)
presetsHolder.BackgroundTransparency = 1
presetsHolder.Parent = pickerPage

local presetsLayout = Instance.new("UIListLayout")
presetsLayout.FillDirection = Enum.FillDirection.Horizontal
presetsLayout.Padding = UDim.new(0, 8)
presetsLayout.Parent = presetsHolder

local savedPanel = Instance.new("Frame")
savedPanel.Size = UDim2.new(0, 210, 0, 102)
savedPanel.Position = UDim2.new(0, 340, 0, 308)
savedPanel.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
savedPanel.BorderSizePixel = 0
savedPanel.Parent = pickerPage
makeCorner(savedPanel, 10)
makeStroke(savedPanel)

local function createSavedSwatch(name, y)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.new(0, 12, 0, y)
	label.Size = UDim2.new(0, 60, 0, 18)
	label.Font = Enum.Font.Gotham
	label.Text = name
	label.TextColor3 = Color3.fromRGB(220, 220, 230)
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = savedPanel

	local swatch = Instance.new("Frame")
	swatch.Size = UDim2.new(0, 110, 0, 18)
	swatch.Position = UDim2.new(1, -122, 0, y)
	swatch.BackgroundColor3 = Color3.new(1, 1, 1)
	swatch.BorderSizePixel = 0
	swatch.Parent = savedPanel
	makeCorner(swatch, 6)
	makeStroke(swatch)

	return swatch
end

local bodySwatch = createSavedSwatch("Body", 12)
local interiorSwatch = createSavedSwatch("Interior", 40)
local rimsSwatch = createSavedSwatch("Rims", 68)

local backButton = Instance.new("TextButton")
backButton.Size = UDim2.new(0.5, -22, 0, 42)
backButton.Position = UDim2.new(0, 16, 1, -58)
backButton.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
backButton.BorderSizePixel = 0
backButton.Font = Enum.Font.GothamBold
backButton.Text = "Back"
backButton.TextColor3 = Color3.fromRGB(255, 255, 255)
backButton.TextSize = 14
backButton.Parent = pickerPage
makeCorner(backButton, 10)

local buyButton = Instance.new("TextButton")
buyButton.Size = UDim2.new(0.5, -22, 0, 42)
buyButton.Position = UDim2.new(0.5, 6, 1, -58)
buyButton.BackgroundColor3 = Color3.fromRGB(60, 140, 85)
buyButton.BorderSizePixel = 0
buyButton.Font = Enum.Font.GothamBold
buyButton.Text = "Buy"
buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
buyButton.TextSize = 14
buyButton.Parent = pickerPage
makeCorner(buyButton, 10)

local function updateTabStyles()
	for _, button in ipairs({bodyTab, interiorTab, rimsTab}) do
		button.BackgroundColor3 = (button.Name == selectedTarget)
			and Color3.fromRGB(70, 110, 170)
			or Color3.fromRGB(42, 42, 52)
	end
end

local function updatePickerVisuals()
	local current = getCurrentColor()

	svFrame.BackgroundColor3 = Color3.fromHSV(currentHue, 1, 1)
	colorPreview.BackgroundColor3 = current
	rgbLabel.Text = rgbString(current)
	hexBox.Text = colorToHex(current)
	targetLabel.Text = "Editing: " .. selectedTarget

	svCursor.Position = UDim2.new(currentSat, 0, 1 - currentVal, 0)
	hueCursor.Position = UDim2.new(0.5, 0, currentHue, 0)

	bodySwatch.BackgroundColor3 = colorState.Body
	interiorSwatch.BackgroundColor3 = colorState.Interior
	rimsSwatch.BackgroundColor3 = colorState.Rims

	updateTabStyles()
end

local function updateFromSV(inputPosition)
	local absPos = svFrame.AbsolutePosition
	local absSize = svFrame.AbsoluteSize

	local x = math.clamp((inputPosition.X - absPos.X) / absSize.X, 0, 1)
	local y = math.clamp((inputPosition.Y - absPos.Y) / absSize.Y, 0, 1)

	currentSat = x
	currentVal = 1 - y

	applyCurrentColorToTarget()
	updatePickerVisuals()
end

local function updateFromHue(inputPosition)
	local absPos = hueFrame.AbsolutePosition
	local absSize = hueFrame.AbsoluteSize

	local y = math.clamp((inputPosition.Y - absPos.Y) / absSize.Y, 0, 1)
	currentHue = y

	applyCurrentColorToTarget()
	updatePickerVisuals()
end

local function setActiveTarget(target)
	selectedTarget = target
	setFromColor3(colorState[target])
	updatePickerVisuals()
end

bodyTab.MouseButton1Click:Connect(function()
	setActiveTarget("Body")
end)

interiorTab.MouseButton1Click:Connect(function()
	setActiveTarget("Interior")
end)

rimsTab.MouseButton1Click:Connect(function()
	setActiveTarget("Rims")
end)

svFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingSV = true
		updateFromSV(input.Position)
	end
end)

hueFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingHue = true
		updateFromHue(input.Position)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if draggingWindow and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		main.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end

	if input.UserInputType == Enum.UserInputType.MouseMovement then
		if draggingSV then
			updateFromSV(input.Position)
		elseif draggingHue then
			updateFromHue(input.Position)
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingSV = false
		draggingHue = false
		draggingWindow = false
	end
end)

hexBox.FocusLost:Connect(function()
	local color = hexToColor3(hexBox.Text)
	if color then
		setFromColor3(color)
		applyCurrentColorToTarget()
		updatePickerVisuals()
	else
		hexBox.Text = colorToHex(getCurrentColor())
	end
end)

for _, preset in ipairs(presetColors) do
	local swatch = Instance.new("TextButton")
	swatch.Size = UDim2.new(0, 34, 0, 34)
	swatch.BackgroundColor3 = preset
	swatch.BorderSizePixel = 0
	swatch.Text = ""
	swatch.Parent = presetsHolder
	makeCorner(swatch, 8)
	makeStroke(swatch)

	swatch.MouseButton1Click:Connect(function()
		setFromColor3(preset)
		applyCurrentColorToTarget()
		updatePickerVisuals()
	end)
end

local function openPickerPage(carName)
	selectedCarName = carName
	carNameLabel.Text = carName

	if SETTINGS.ResetColorsOnOpenCar then
		colorState.Body = SETTINGS.DefaultBodyColor
		colorState.Interior = SETTINGS.DefaultInteriorColor
		colorState.Rims = SETTINGS.DefaultRimsColor
	end

	setActiveTarget("Body")

	listPage.Visible = false
	pickerPage.Visible = true

	debugPrint("Opened car:", carName)
end

backButton.MouseButton1Click:Connect(function()
	pickerPage.Visible = false
	listPage.Visible = true
	debugPrint("Returned to list")
end)

local function onBuyRequested(carName, bodyColor, interiorColor, rimsColor)
	print("Buy requested:")
	print("Car:", carName)
	print("Body:", bodyColor)
	print("Interior:", interiorColor)
	print("Rims:", rimsColor)

	local args = {
		[1] = {
			[1] = tostring(carName),
			[2] = bodyColor,
			[3] = interiorColor,
			[4] = rimsColor
		}
	}

	game:GetService("ReplicatedStorage")
		:WaitForChild("Remotes")
		:WaitForChild("Purchase")
		:InvokeServer(unpack(args))
end

buyButton.MouseButton1Click:Connect(function()
	if not selectedCarName then
		return
	end

	onBuyRequested(
		selectedCarName,
		colorState.Body,
		colorState.Interior,
		colorState.Rims
	)
end)

local function createCarRow(carName, order)
	local button = Instance.new("TextButton")
	button.Name = carName
	button.Size = UDim2.new(1, 0, 0, 38)
	button.BackgroundColor3 = Color3.fromRGB(36, 36, 46)
	button.BorderSizePixel = 0
	button.LayoutOrder = order
	button.AutoButtonColor = true
	button.Font = Enum.Font.Gotham
	button.Text = carName
	button.TextColor3 = Color3.fromRGB(240, 240, 245)
	button.TextSize = 14
	button.TextXAlignment = Enum.TextXAlignment.Left
	button.Parent = listFrame
	makeCorner(button, 8)
	makeStroke(button, Color3.fromRGB(52, 52, 64))

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.Parent = button

	button.MouseButton1Click:Connect(function()
		openPickerPage(carName)
	end)

	return button
end

local rows = {}
for index, carName in ipairs(cars) do
	rows[#rows + 1] = createCarRow(carName, index)
end

local function refreshList()
	local query = string.lower(searchBox.Text)
	local visibleCount = 0

	for _, row in ipairs(rows) do
		local matches = query == "" or string.find(string.lower(row.Name), query, 1, true) ~= nil
		row.Visible = matches
		if matches then
			visibleCount += 1
		end
	end

	infoLabel.Text = string.format("%d / %d vehicles", visibleCount, #cars)
end

searchBox:GetPropertyChangedSignal("Text"):Connect(refreshList)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == SETTINGS.ToggleKey then
		gui.Enabled = not gui.Enabled
		debugPrint("UI toggled:", gui.Enabled)
	elseif input.KeyCode == SETTINGS.CloseKey then
		gui.Enabled = false
		debugPrint("UI closed")
	end
end)

if SETTINGS.EnableRainbowAccent then
	RunService.RenderStepped:Connect(function()
		if not gui.Parent then
			return
		end

		local hue = (tick() * SETTINGS.RainbowSpeed) % 1
		local accent = Color3.fromHSV(hue, 0.7, 1)

		mainStroke.Color = accent
		title.TextColor3 = accent
	end)
end

setActiveTarget("Body")
updatePickerVisuals()
refreshList()
