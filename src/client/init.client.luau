local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
playerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor
local camera = Workspace.CurrentCamera
local remotes = ReplicatedStorage:WaitForChild(Config.REMOTES_FOLDER)
local launchRemote = remotes:WaitForChild(Config.LAUNCH_REMOTE)
local stateRemote = remotes:WaitForChild(Config.STATE_REMOTE)
local purchaseRemote = remotes:WaitForChild(Config.PURCHASE_REMOTE)
local modeRemote = remotes:WaitForChild(Config.MODE_REMOTE)

local COLORS = {
	red = Color3.fromRGB(205, 48, 53),
	darkRed = Color3.fromRGB(123, 31, 38),
	cream = Color3.fromRGB(255, 242, 207),
	ink = Color3.fromRGB(55, 38, 40),
	yellow = Color3.fromRGB(255, 203, 55),
	green = Color3.fromRGB(75, 200, 116),
	orange = Color3.fromRGB(244, 112, 54),
	blue = Color3.fromRGB(80, 187, 230),
}

local state = {
	targetId = 1,
	targetCustomer = "Mia",
	round = 1,
	roundProgress = 0,
	roundGoal = 3,
	mode = "walk",
	upgrades = { tips = 0, assist = 0, reload = 0, power = 0 },
}
local aimYaw = 0
local aimPitch = (Config.DEFAULT_PITCH - Config.MIN_PITCH) / (Config.MAX_PITCH - Config.MIN_PITCH)
local charge = 0.34
local charging = false
local chargeStarted = 0
local ready = true
local activeFireInput: InputObject? = nil
local targetHighlight: Highlight? = nil
local yourOrderBillboard: BillboardGui? = nil
local trajectoryParts = {}
local keyboardHeld = {}
local touchHeld = {}
local shakeUntil = 0
local shakeStrength = 0
local operating = false
local hasLaunched = false
local playerControls

local function addCorner(parent: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

local function addStroke(parent: GuiObject, color: Color3, thickness: number)
	local border = Instance.new("UIStroke")
	border.Color = color
	border.Thickness = thickness
	border.Transparency = 0.05
	border.Parent = parent
end

local function addPadding(parent: GuiObject, amount: number)
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, amount)
	padding.PaddingRight = UDim.new(0, amount)
	padding.PaddingTop = UDim.new(0, amount)
	padding.PaddingBottom = UDim.new(0, amount)
	padding.Parent = parent
end

local function makeLabel(parent: Instance, name: string, displayText: string, size: UDim2, position: UDim2, textSize: number): TextLabel
	local item = Instance.new("TextLabel")
	item.Name = name
	item.Size = size
	item.Position = position
	item.BackgroundTransparency = 1
	item.Text = displayText
	item.TextColor3 = COLORS.ink
	item.TextSize = textSize
	item.Font = Enum.Font.GothamBold
	item.TextWrapped = true
	item.Parent = parent
	return item
end

local function makeButton(parent: Instance, name: string, displayText: string, size: UDim2, position: UDim2, color: Color3): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = color
	button.Text = displayText
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextSize = 19
	button.TextWrapped = true
	button.Font = Enum.Font.GothamBlack
	button.AutoButtonColor = false
	button.Parent = parent
	addCorner(button, 15)
	addStroke(button, COLORS.darkRed, 3)
	return button
end

local gui = Instance.new("ScreenGui")
gui.Name = "PizzaLaunchHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 20
gui.Parent = playerGui

local screenTint = Instance.new("Frame")
screenTint.Name = "ScreenTint"
screenTint.Size = UDim2.fromScale(1, 1)
screenTint.BackgroundColor3 = COLORS.yellow
screenTint.BackgroundTransparency = 1
screenTint.BorderSizePixel = 0
screenTint.ZIndex = 0
screenTint.Parent = gui

local stats = Instance.new("Frame")
stats.Name = "Stats"
stats.Size = UDim2.fromOffset(254, 62)
stats.Position = UDim2.fromOffset(18, 16)
stats.BackgroundColor3 = COLORS.cream
stats.Parent = gui
addCorner(stats, 18)
addStroke(stats, COLORS.red, 3)
local coinsLabel = makeLabel(stats, "Coins", "COINS  0", UDim2.fromScale(0.58, 1), UDim2.fromScale(0, 0), 22)
coinsLabel.TextColor3 = COLORS.red
local comboLabel = makeLabel(stats, "Combo", "COMBO  x0", UDim2.fromScale(0.42, 1), UDim2.fromScale(0.58, 0), 17)

local roundCard = Instance.new("Frame")
roundCard.Name = "RoundCard"
roundCard.AnchorPoint = Vector2.new(0.5, 0)
roundCard.Size = UDim2.fromOffset(410, 102)
roundCard.Position = UDim2.new(0.5, 0, 0, 14)
roundCard.BackgroundColor3 = COLORS.green
roundCard.Parent = gui
addCorner(roundCard, 20)
addStroke(roundCard, COLORS.darkRed, 3)
local roundTitle = makeLabel(roundCard, "RoundTitle", "ROUND 1 • FIRST ORDERS", UDim2.new(1, -20, 0, 23), UDim2.fromOffset(10, 6), 14)
roundTitle.TextColor3 = COLORS.cream
local targetLabel = makeLabel(roundCard, "Target", "MIA • TABLE 1", UDim2.new(1, -20, 0, 38), UDim2.fromOffset(10, 28), 25)
targetLabel.TextColor3 = Color3.new(1, 1, 1)
local progressBack = Instance.new("Frame")
progressBack.Name = "Progress"
progressBack.Size = UDim2.new(1, -34, 0, 15)
progressBack.Position = UDim2.fromOffset(17, 76)
progressBack.BackgroundColor3 = COLORS.darkRed
progressBack.BackgroundTransparency = 0.35
progressBack.ClipsDescendants = true
progressBack.Parent = roundCard
addCorner(progressBack, 8)
local progressFill = Instance.new("Frame")
progressFill.Name = "Fill"
progressFill.Size = UDim2.fromScale(0, 1)
progressFill.BackgroundColor3 = COLORS.yellow
progressFill.Parent = progressBack
addCorner(progressFill, 8)

local tutorial = Instance.new("Frame")
tutorial.Name = "Tutorial"
tutorial.Size = UDim2.fromOffset(294, 145)
tutorial.Position = UDim2.new(0, 18, 0, 94)
tutorial.BackgroundColor3 = COLORS.cream
tutorial.BackgroundTransparency = 0.03
tutorial.Parent = gui
addCorner(tutorial, 18)
addStroke(tutorial, COLORS.darkRed, 2)
local tutorialTitle = makeLabel(tutorial, "Title", "WELCOME, PIZZA CHEF!", UDim2.new(1, -20, 0, 28), UDim2.fromOffset(10, 9), 16)
tutorialTitle.TextColor3 = COLORS.red
local tutorialText = makeLabel(tutorial, "Steps", "1  WALK around the restaurant\n2  FIND the glowing launcher\n3  PRESS E to start serving!", UDim2.new(1, -28, 0, 92), UDim2.fromOffset(14, 41), 16)
tutorialText.TextXAlignment = Enum.TextXAlignment.Left
tutorialText.TextYAlignment = Enum.TextYAlignment.Top

local feedback = makeLabel(gui, "Feedback", "", UDim2.fromOffset(580, 140), UDim2.new(0.5, -290, 0.34, 0), 49)
feedback.TextColor3 = COLORS.yellow
feedback.TextStrokeColor3 = COLORS.ink
feedback.TextStrokeTransparency = 0.12
feedback.Visible = false
feedback.ZIndex = 5

local roundOverlay = Instance.new("Frame")
roundOverlay.Name = "RoundOverlay"
roundOverlay.AnchorPoint = Vector2.new(0.5, 0.5)
roundOverlay.Size = UDim2.fromOffset(510, 190)
roundOverlay.Position = UDim2.fromScale(0.5, 0.46)
roundOverlay.BackgroundColor3 = COLORS.red
roundOverlay.BackgroundTransparency = 0.05
roundOverlay.Visible = false
roundOverlay.ZIndex = 8
roundOverlay.Parent = gui
addCorner(roundOverlay, 28)
addStroke(roundOverlay, COLORS.yellow, 5)
local roundOverlayTitle = makeLabel(roundOverlay, "Title", "ROUND CLEARED!", UDim2.new(1, -30, 0, 75), UDim2.fromOffset(15, 20), 40)
roundOverlayTitle.TextColor3 = COLORS.yellow
roundOverlayTitle.ZIndex = 9
local roundOverlayDetail = makeLabel(roundOverlay, "Detail", "+25 COINS • NEXT: DINNER RUSH", UDim2.new(1, -30, 0, 65), UDim2.fromOffset(15, 100), 22)
roundOverlayDetail.TextColor3 = Color3.new(1, 1, 1)
roundOverlayDetail.ZIndex = 9

local controls = Instance.new("Frame")
controls.Name = "Controls"
controls.AnchorPoint = Vector2.new(1, 1)
controls.Size = UDim2.new(1, -24, 0, 136)
controls.Position = UDim2.new(1, -18, 1, -20)
controls.BackgroundColor3 = COLORS.cream
controls.Visible = false
controls.Parent = gui
addCorner(controls, 22)
addStroke(controls, COLORS.red, 3)
local controlsConstraint = Instance.new("UISizeConstraint")
controlsConstraint.MinSize = Vector2.new(320, 136)
controlsConstraint.MaxSize = Vector2.new(550, 136)
controlsConstraint.Parent = controls

local powerText = makeLabel(controls, "PowerText", "POWER 34%", UDim2.new(0.52, 0, 0, 27), UDim2.fromOffset(18, 9), 18)
powerText.TextXAlignment = Enum.TextXAlignment.Left
local arcText = makeLabel(controls, "ArcText", "ARC  MEDIUM", UDim2.fromOffset(145, 27), UDim2.new(1, -322, 0, 9), 17)
arcText.TextColor3 = COLORS.red
local powerBack = Instance.new("Frame")
powerBack.Name = "PowerBar"
powerBack.Size = UDim2.new(1, -205, 0, 36)
powerBack.Position = UDim2.fromOffset(18, 42)
powerBack.BackgroundColor3 = Color3.fromRGB(213, 193, 167)
powerBack.ClipsDescendants = true
powerBack.Parent = controls
addCorner(powerBack, 11)
local powerFill = Instance.new("Frame")
powerFill.Name = "Fill"
powerFill.Size = UDim2.fromScale(charge, 1)
powerFill.BackgroundColor3 = COLORS.green
powerFill.Parent = powerBack
addCorner(powerFill, 11)
local powerGradient = Instance.new("UIGradient")
powerGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, COLORS.green),
	ColorSequenceKeypoint.new(0.62, COLORS.yellow),
	ColorSequenceKeypoint.new(1, COLORS.orange),
})
powerGradient.Parent = powerFill
local helpText = makeLabel(controls, "Help", "MOUSE AIM • W/S ARC • A/D TURN • SPACE LAUNCH", UDim2.new(1, -205, 0, 34), UDim2.fromOffset(18, 88), 12)
helpText.TextXAlignment = Enum.TextXAlignment.Left
helpText.TextColor3 = Color3.fromRGB(105, 79, 70)
local fireButton = makeButton(controls, "LaunchButton", "HOLD\nLAUNCH", UDim2.fromOffset(160, 104), UDim2.new(1, -177, 0, 16), COLORS.red)
fireButton.TextSize = 23

local shopToggle = makeButton(gui, "ShopToggle", "UPGRADES", UDim2.fromOffset(150, 54), UDim2.new(1, -168, 0, 16), COLORS.yellow)
shopToggle.TextColor3 = COLORS.red
local exitButton = makeButton(gui, "ExitLauncher", "EXIT LAUNCHER  [Q]", UDim2.fromOffset(150, 48), UDim2.new(1, -168, 0, 78), COLORS.red)
exitButton.TextSize = 14
exitButton.Visible = false
local shopPanel = Instance.new("Frame")
shopPanel.Name = "ShopPanel"
shopPanel.AnchorPoint = Vector2.new(1, 0)
shopPanel.Size = UDim2.fromOffset(310, 353)
shopPanel.Position = UDim2.new(1, -18, 0, 82)
shopPanel.BackgroundColor3 = COLORS.cream
shopPanel.Visible = false
shopPanel.ZIndex = 6
shopPanel.Parent = gui
addCorner(shopPanel, 20)
addStroke(shopPanel, COLORS.red, 3)
local shopTitle = makeLabel(shopPanel, "Title", "LAUNCHER UPGRADES", UDim2.new(1, -20, 0, 32), UDim2.fromOffset(10, 8), 16)
shopTitle.TextColor3 = COLORS.red
shopTitle.ZIndex = 7
local upgradeButtons = {}
local upgradeOrder = { "tips", "assist", "reload", "power" }
for index, upgradeId in upgradeOrder do
	local button = makeButton(shopPanel, upgradeId, "", UDim2.new(1, -24, 0, 65), UDim2.fromOffset(12, 43 + (index - 1) * 75), index % 2 == 0 and Color3.fromRGB(229, 205, 174) or Color3.fromRGB(255, 221, 141))
	button.TextColor3 = COLORS.ink
	button.TextSize = 14
	button.ZIndex = 7
	upgradeButtons[upgradeId] = button
	button.Activated:Connect(function()
		purchaseRemote:FireServer(upgradeId)
	end)
end

local touchAimPad = Instance.new("Frame")
touchAimPad.Name = "TouchAimPad"
touchAimPad.AnchorPoint = Vector2.new(0, 1)
touchAimPad.Size = UDim2.fromOffset(142, 108)
touchAimPad.Position = UDim2.new(0, 18, 1, -14)
touchAimPad.BackgroundColor3 = COLORS.cream
touchAimPad.BackgroundTransparency = 0.12
touchAimPad.Visible = false
touchAimPad.Parent = gui
addCorner(touchAimPad, 20)
addStroke(touchAimPad, COLORS.red, 2)
local aimButtons = {
	up = makeButton(touchAimPad, "Up", "▲", UDim2.fromOffset(42, 42), UDim2.fromOffset(50, 8), COLORS.orange),
	down = makeButton(touchAimPad, "Down", "▼", UDim2.fromOffset(42, 42), UDim2.fromOffset(50, 58), COLORS.orange),
	left = makeButton(touchAimPad, "Left", "◀", UDim2.fromOffset(42, 42), UDim2.fromOffset(5, 58), COLORS.red),
	right = makeButton(touchAimPad, "Right", "▶", UDim2.fromOffset(42, 42), UDim2.fromOffset(95, 58), COLORS.red),
}

for directionName, button in aimButtons do
	button.TextSize = 22
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			touchHeld[directionName] = true
			button.BackgroundColor3 = COLORS.yellow
		end
	end)
	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			touchHeld[directionName] = false
			button.BackgroundColor3 = (directionName == "up" or directionName == "down") and COLORS.orange or COLORS.red
		end
	end)
end

if UserInputService.TouchEnabled then
	tutorial.Visible = false
	stats.Size = UDim2.fromOffset(154, 50)
	stats.Position = UDim2.fromOffset(18, 8)
	coinsLabel.TextSize = 16
	comboLabel.TextSize = 12
	roundCard.Size = UDim2.fromOffset(282, 75)
	roundCard.Position = UDim2.new(0.5, 0, 0, 6)
	roundTitle.Size = UDim2.new(1, -14, 0, 18)
	roundTitle.Position = UDim2.fromOffset(7, 3)
	roundTitle.TextSize = 10
	targetLabel.Size = UDim2.new(1, -14, 0, 29)
	targetLabel.Position = UDim2.fromOffset(7, 20)
	targetLabel.TextSize = 17
	progressBack.Size = UDim2.new(1, -24, 0, 10)
	progressBack.Position = UDim2.fromOffset(12, 57)
	shopToggle.Size = UDim2.fromOffset(108, 45)
	shopToggle.Position = UDim2.new(1, -126, 0, 8)
	shopToggle.TextSize = 13
	exitButton.Size = UDim2.fromOffset(108, 40)
	exitButton.Position = UDim2.new(1, -126, 0, 58)
	exitButton.Text = "EXIT [Q]"
	exitButton.TextSize = 12
	shopPanel.Size = UDim2.fromOffset(270, 280)
	shopPanel.Position = UDim2.new(1, -16, 0, 60)
	shopTitle.TextSize = 13
	for index, upgradeId in upgradeOrder do
		local button = upgradeButtons[upgradeId]
		button.Size = UDim2.new(1, -20, 0, 50)
		button.Position = UDim2.fromOffset(10, 36 + (index - 1) * 57)
		button.TextSize = 11
	end
	controls.Size = UDim2.new(1, -24, 0, 108)
	controls.Position = UDim2.new(1, -10, 1, -12)
	controlsConstraint.MinSize = Vector2.new(300, 108)
	controlsConstraint.MaxSize = Vector2.new(440, 108)
	powerText.Position = UDim2.fromOffset(14, 5)
	powerText.TextSize = 14
	arcText.Size = UDim2.fromOffset(120, 27)
	arcText.Position = UDim2.new(1, -260, 0, 5)
	arcText.TextSize = 13
	powerBack.Size = UDim2.new(1, -168, 0, 29)
	powerBack.Position = UDim2.fromOffset(14, 34)
	helpText.Size = UDim2.new(1, -165, 0, 26)
	helpText.Position = UDim2.fromOffset(14, 69)
	helpText.Text = "DRAG OR TAP ARROWS • HOLD + RELEASE"
	helpText.TextSize = 9
	fireButton.Size = UDim2.fromOffset(128, 80)
	fireButton.Position = UDim2.new(1, -140, 0, 14)
	fireButton.TextSize = 18
	roundOverlay.Size = UDim2.fromOffset(390, 150)
	roundOverlayTitle.TextSize = 31
	roundOverlayDetail.TextSize = 17

end

local walkHint = makeLabel(gui, "WalkHint", "WALK TO THE GLOWING LAUNCHER  •  PRESS E / TAP TO OPERATE", UDim2.fromOffset(500, 48), UDim2.new(0.5, -250, 1, -68), 15)
walkHint.BackgroundTransparency = 0.05
walkHint.BackgroundColor3 = COLORS.cream
walkHint.TextColor3 = COLORS.red
addCorner(walkHint, 16)
addStroke(walkHint, COLORS.darkRed, 2)
if UserInputService.TouchEnabled then
	walkHint.Size = UDim2.fromOffset(390, 38)
	walkHint.Position = UDim2.new(0.5, -195, 1, -48)
	walkHint.Text = "WALK TO THE GLOWING LAUNCHER • TAP OPERATE"
	walkHint.TextSize = 11
end

local trajectoryFolder = Instance.new("Folder")
trajectoryFolder.Name = "LocalAimGuide"
trajectoryFolder.Parent = Workspace
for index = 1, 18 do
	local dot = Instance.new("Part")
	dot.Name = "TrajectoryDot"
	dot.Shape = Enum.PartType.Ball
	dot.Size = Vector3.new(0.72, 0.72, 0.72) * (1 - index * 0.018)
	dot.Anchored = true
	dot.CanCollide = false
	dot.CanTouch = false
	dot.CanQuery = false
	dot.Material = Enum.Material.Neon
	dot.Color = COLORS.yellow
	dot.Transparency = 0.1 + index * 0.025
	dot.Parent = trajectoryFolder
	table.insert(trajectoryParts, dot)
end
local landingRing = Instance.new("Part")
landingRing.Name = "LandingRing"
landingRing.Shape = Enum.PartType.Cylinder
landingRing.Size = Vector3.new(0.16, 5.2, 5.2)
landingRing.CFrame = CFrame.new(0, 6.9, 0) * CFrame.Angles(0, 0, math.pi / 2)
landingRing.Anchored = true
landingRing.CanCollide = false
landingRing.CanTouch = false
landingRing.CanQuery = false
landingRing.Material = Enum.Material.Neon
landingRing.Color = COLORS.yellow
landingRing.Transparency = 0.25
landingRing.Parent = trajectoryFolder
local landingLight = Instance.new("PointLight")
landingLight.Brightness = 1
landingLight.Range = 9
landingLight.Color = COLORS.yellow
landingLight.Parent = landingRing

local function currentDirection(): Vector3
	return Config.directionFromAim(aimYaw, aimPitch)
end

local function tableDefinition(id: number)
	for _, definition in Config.TABLES do
		if definition.id == id then
			return definition
		end
	end
	return Config.TABLES[1]
end

local function findTargetModel(id: number): Model?
	local world = Workspace:FindFirstChild("PizzaLaunchWorld")
	if not world then
		return nil
	end
	for _, child in world:GetChildren() do
		if child:IsA("Model") and child:GetAttribute("TableId") == id then
			return child
		end
	end
	return nil
end

local function updateShop(upgrades)
	for _, upgradeId in upgradeOrder do
		local definition = Config.UPGRADES[upgradeId]
		local level = upgrades and upgrades[upgradeId] or 0
		local cost = definition.costs[level + 1]
		if cost then
			upgradeButtons[upgradeId].Text = string.format("%s  •  LEVEL %d\n%s  •  %d COINS", definition.name, level, definition.description, cost)
		else
			upgradeButtons[upgradeId].Text = string.format("%s  •  LEVEL %d\nMAXED OUT!", definition.name, level)
		end
	end
end

local function updateTargetVisuals()
	local definition = tableDefinition(state.targetId)
	local round = Config.ROUNDS[math.clamp(state.round or 1, 1, #Config.ROUNDS)]
	local activeTables = {}
	for _, tableId in round.tables do
		activeTables[tableId] = true
	end
	if targetHighlight then
		targetHighlight:Destroy()
	end
	if yourOrderBillboard then
		yourOrderBillboard:Destroy()
	end
	local model = findTargetModel(state.targetId)
	local world = Workspace:FindFirstChild("PizzaLaunchWorld")
	if world then
		for _, tableModel in world:GetChildren() do
			if tableModel:IsA("Model") and tableModel:GetAttribute("TableId") then
				local tableId = tableModel:GetAttribute("TableId")
				local isActive = activeTables[tableId] == true
				local targetRing = tableModel:FindFirstChild("TargetRing")
				local isTarget = tableId == state.targetId
				local customer = tableModel:FindFirstChild("Customer")
				if customer then
					for _, descendant in customer:GetDescendants() do
						if descendant:IsA("BasePart") then
							descendant.LocalTransparencyModifier = isActive and 0 or 1
						elseif descendant:IsA("SurfaceGui") and descendant.Name == "Face" then
							descendant.Enabled = isActive
						elseif descendant:IsA("ProximityPrompt") then
							descendant.Enabled = isActive and not operating
						end
					end
					local waitingMarker = customer:FindFirstChild("WaitingMarker", true)
					if waitingMarker and waitingMarker:IsA("BillboardGui") then
						waitingMarker.Enabled = isActive and not isTarget
					end
				end
				if targetRing and targetRing:IsA("BasePart") then
					targetRing.LocalTransparencyModifier = isTarget and 0 or 1
				end
			end
		end
	end
	if not model then
		return
	end
	targetHighlight = Instance.new("Highlight")
	targetHighlight.Name = "YourOrderHighlight"
	targetHighlight.Adornee = model
	targetHighlight.FillColor = definition.color
	targetHighlight.FillTransparency = 0.82
	targetHighlight.OutlineColor = Color3.new(1, 1, 1)
	targetHighlight.OutlineTransparency = 0
	targetHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	targetHighlight.Parent = model

	local top = model:FindFirstChild("TableTop")
	if top and top:IsA("BasePart") then
		yourOrderBillboard = Instance.new("BillboardGui")
		yourOrderBillboard.Name = "YourOrder"
		yourOrderBillboard.Adornee = top
		yourOrderBillboard.Size = UDim2.fromOffset(150, 40)
		yourOrderBillboard.StudsOffsetWorldSpace = Vector3.new(0, 7, 0)
		yourOrderBillboard.AlwaysOnTop = true
		yourOrderBillboard.Parent = top
		local label = makeLabel(yourOrderBillboard, "Label", "DELIVER HERE!", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), 19)
		label.TextColor3 = definition.color
		label.TextStrokeColor3 = COLORS.ink
		label.TextStrokeTransparency = 0.1
	end

	local ring = model:FindFirstChild("TargetRing")
	if ring and ring:IsA("BasePart") then
		local scale = round.accuracyScale * (1 + (state.upgrades.assist or 0) * 0.12)
		ring.Size = Vector3.new(0.15, 8 * scale, 8 * scale)
	end
end

local feedbackToken = 0
local function showFeedback(displayText: string, color: Color3, detail: string?)
	feedbackToken += 1
	local token = feedbackToken
	feedback.Text = detail and string.format("%s\n%s", displayText, detail) or displayText
	feedback.TextColor3 = color
	feedback.TextTransparency = 0
	feedback.Position = UDim2.new(0.5, -290, 0.39, 0)
	feedback.Rotation = -4
	feedback.Visible = true
	TweenService:Create(feedback, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -290, 0.31, 0), Rotation = 0,
	}):Play()
	task.delay(1.25, function()
		if token ~= feedbackToken then
			return
		end
		local tween = TweenService:Create(feedback, TweenInfo.new(0.25), { TextTransparency = 1 })
		tween:Play()
		tween.Completed:Wait()
		if token == feedbackToken then
			feedback.Visible = false
		end
	end)
end

local function showRoundComplete(payload)
	roundOverlayTitle.Text = string.format("ROUND %d CLEARED!", payload.completedRound or state.round)
	roundOverlayDetail.Text = string.format("%s\n+%d COIN BONUS • NEXT: %s", payload.completedRoundName or "GREAT WORK", payload.roundReward or 0, state.roundName or "MORE ORDERS")
	roundOverlay.Size = UserInputService.TouchEnabled and UDim2.fromOffset(340, 20) or UDim2.fromOffset(450, 20)
	roundOverlay.BackgroundTransparency = 0.25
	roundOverlay.Visible = true
	TweenService:Create(roundOverlay, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UserInputService.TouchEnabled and UDim2.fromOffset(390, 150) or UDim2.fromOffset(510, 190),
		BackgroundTransparency = 0.05,
	}):Play()
	task.delay(2.25, function()
		local tween = TweenService:Create(roundOverlay, TweenInfo.new(0.25), { BackgroundTransparency = 1 })
		tween:Play()
		tween.Completed:Wait()
		roundOverlay.Visible = false
	end)
end

local movementLocked = false
local function blockMovement()
	return Enum.ContextActionResult.Sink
end

local function setMovementLocked(locked: boolean)
	if movementLocked == locked then
		return
	end
	movementLocked = locked
	if locked then
		ContextActionService:BindActionAtPriority("BlockMovement", blockMovement, false, Enum.ContextActionPriority.High.Value,
			Enum.PlayerActions.CharacterForward, Enum.PlayerActions.CharacterBackward, Enum.PlayerActions.CharacterLeft,
			Enum.PlayerActions.CharacterRight, Enum.PlayerActions.CharacterJump)
	else
		ContextActionService:UnbindAction("BlockMovement")
	end
	if playerControls then
		if locked then
			playerControls:Disable()
		else
			playerControls:Enable()
		end
	end
	local touchGui = playerGui:FindFirstChild("TouchGui")
	if touchGui and touchGui:IsA("ScreenGui") then
		touchGui.Enabled = not locked
	end
end

local function restoreTutorialAppearance()
	tutorial.BackgroundTransparency = 0.03
	for _, descendant in tutorial:GetDescendants() do
		if descendant:IsA("TextLabel") then
			descendant.TextTransparency = 0
		elseif descendant:IsA("UIStroke") then
			descendant.Transparency = 0.05
		end
	end
end

local function applyMode()
	operating = state.mode == "launcher"
	shopPanel.Visible = false
	shopToggle.Text = "UPGRADES"
	controls.Visible = operating
	touchAimPad.Visible = operating and UserInputService.TouchEnabled
	exitButton.Visible = operating
	walkHint.Visible = not operating
	setMovementLocked(operating)

	if operating then
		tutorialTitle.Text = "DELIVER SOME HAPPINESS!"
		tutorialText.Text = "1  AIM the landing ring\n2  ADJUST the arc up or down\n3  HOLD power, then RELEASE!"
		tutorial.Visible = not UserInputService.TouchEnabled and not hasLaunched
		if tutorial.Visible then
			restoreTutorialAppearance()
		end
	else
		charging = false
		activeFireInput = nil
		table.clear(keyboardHeld)
		table.clear(touchHeld)
		controls.Visible = false
		touchAimPad.Visible = false
		exitButton.Visible = false
		if not hasLaunched and not UserInputService.TouchEnabled then
			tutorialTitle.Text = "WELCOME, PIZZA CHEF!"
			tutorialText.Text = "1  WALK around the restaurant\n2  FIND the glowing launcher\n3  PRESS E to start serving!"
			tutorial.Visible = true
			restoreTutorialAppearance()
		else
			tutorial.Visible = false
		end
		for _, dot in trajectoryParts do
			dot.Transparency = 1
		end
		landingRing.Transparency = 1
		landingLight.Enabled = false
		camera.CameraType = Enum.CameraType.Custom
		camera.FieldOfView = 70
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			camera.CameraSubject = humanoid
		end
	end
	updateTargetVisuals()
end

task.defer(function()
	local playerModule = player.PlayerScripts:WaitForChild("PlayerModule", 8)
	if playerModule then
		local success, module = pcall(require, playerModule)
		if success and module.GetControls then
			playerControls = module:GetControls()
			if operating then
				playerControls:Disable()
			else
				playerControls:Enable()
			end
		end
	end
	local touchGui = playerGui:WaitForChild("TouchGui", 8)
	if touchGui and touchGui:IsA("ScreenGui") then
		touchGui:GetPropertyChangedSignal("Enabled"):Connect(function()
			if operating and touchGui.Enabled then
				touchGui.Enabled = false
			end
		end)
		if operating then
			touchGui.Enabled = false
		end
	end
end)

local function setAimFromScreen(position: Vector3)
	local viewport = camera.ViewportSize
	if viewport.X <= 0 or viewport.Y <= 0 then
		return
	end
	aimYaw = math.clamp((position.X / viewport.X - 0.5) * 2, -1, 1)
	local vertical = 1 - math.clamp((position.Y / viewport.Y - 0.12) / 0.7, 0, 1)
	aimPitch = vertical
end

local function beginCharge(input: InputObject?)
	if not operating or not ready or charging then
		return
	end
	charging = true
	chargeStarted = os.clock()
	charge = 0
	activeFireInput = input
	fireButton.Text = "RELEASE!"
	fireButton.BackgroundColor3 = COLORS.orange
	local size = UserInputService.TouchEnabled and UDim2.fromOffset(134, 86) or UDim2.fromOffset(166, 110)
	TweenService:Create(fireButton, TweenInfo.new(0.12), { Size = size }):Play()
end

local function launch()
	if not operating or not charging or not ready then
		return
	end
	charging = false
	activeFireInput = nil
	ready = false
	hasLaunched = true
	launchRemote:FireServer(currentDirection(), charge)
	fireButton.Text = "OVEN\nRELOAD"
	fireButton.BackgroundColor3 = Color3.fromRGB(142, 128, 119)
	local size = UserInputService.TouchEnabled and UDim2.fromOffset(128, 80) or UDim2.fromOffset(160, 104)
	TweenService:Create(fireButton, TweenInfo.new(0.1), { Size = size }):Play()
	shakeUntil = os.clock() + 0.22
	shakeStrength = 0.7
	TweenService:Create(screenTint, TweenInfo.new(0.08), { BackgroundTransparency = 0.82 }):Play()
	task.delay(0.1, function()
		TweenService:Create(screenTint, TweenInfo.new(0.18), { BackgroundTransparency = 1 }):Play()
	end)
	TweenService:Create(tutorial, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
	for _, descendant in tutorial:GetDescendants() do
		if descendant:IsA("TextLabel") then
			TweenService:Create(descendant, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
		elseif descendant:IsA("UIStroke") then
			TweenService:Create(descendant, TweenInfo.new(0.35), { Transparency = 1 }):Play()
		end
	end
end

shopToggle.Activated:Connect(function()
	shopPanel.Visible = not shopPanel.Visible
	shopToggle.Text = shopPanel.Visible and "CLOSE" or "UPGRADES"
	controls.Visible = operating and not shopPanel.Visible
	touchAimPad.Visible = operating and UserInputService.TouchEnabled and not shopPanel.Visible
	exitButton.Visible = operating and not shopPanel.Visible
end)
exitButton.Activated:Connect(function()
	if operating then
		modeRemote:FireServer("walk")
	end
end)
fireButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		beginCharge(input)
	end
end)
fireButton.InputEnded:Connect(function(input)
	if input == activeFireInput then
		launch()
	end
end)

local aimKeyMap = {
	[Enum.KeyCode.A] = "left", [Enum.KeyCode.Left] = "left",
	[Enum.KeyCode.D] = "right", [Enum.KeyCode.Right] = "right",
	[Enum.KeyCode.W] = "up", [Enum.KeyCode.Up] = "up",
	[Enum.KeyCode.S] = "down", [Enum.KeyCode.Down] = "down",
}
UserInputService.InputBegan:Connect(function(input, processed)
	if operating and input.KeyCode == Enum.KeyCode.Q then
		modeRemote:FireServer("walk")
		return
	end
	if not operating then
		return
	end
	local aimKey = aimKeyMap[input.KeyCode]
	if aimKey then
		keyboardHeld[aimKey] = true
	elseif input.KeyCode == Enum.KeyCode.Space then
		beginCharge(input)
	elseif processed then
		return
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
		beginCharge(input)
	end
end)
UserInputService.InputEnded:Connect(function(input, _processed)
	if not operating then
		return
	end
	local aimKey = aimKeyMap[input.KeyCode]
	if aimKey then
		keyboardHeld[aimKey] = false
	end
	if input == activeFireInput or (charging and input.KeyCode == Enum.KeyCode.Space) then
		launch()
	end
end)
UserInputService.InputChanged:Connect(function(input, processed)
	if not operating or processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		setAimFromScreen(input.Position)
	elseif input.UserInputType == Enum.UserInputType.Touch and input ~= activeFireInput then
		setAimFromScreen(input.Position)
	end
end)

stateRemote.OnClientEvent:Connect(function(newState)
	local changedMode = (newState.mode == "launcher") ~= operating
	state = newState
	state.upgrades = state.upgrades or { tips = 0, assist = 0, reload = 0, power = 0 }
	coinsLabel.Text = string.format("COINS  %d", state.coins or 0)
	comboLabel.Text = string.format("COMBO  x%d", state.combo or 0)
	roundTitle.Text = string.format("ROUND %d • %s", state.round or 1, state.roundName or "FIRST ORDERS")
	targetLabel.Text = string.format("%s • TABLE %d", string.upper(state.targetCustomer or "CUSTOMER"), state.targetId or 1)
	progressFill.Size = UDim2.fromScale(math.clamp((state.roundProgress or 0) / math.max(state.roundGoal or 1, 1), 0, 1), 1)
	roundCard.BackgroundColor3 = state.roundColor or COLORS.green
	updateShop(state.upgrades)
	if changedMode then
		applyMode()
	else
		updateTargetVisuals()
	end

	if state.event == "shotResult" and state.payload then
		local payload = state.payload
		local detail
		if payload.coinsEarned and payload.coinsEarned > 0 then
			detail = string.format("+%d COINS", payload.coinsEarned)
			if payload.comboBonus and payload.comboBonus > 0 then
				detail ..= string.format(" • COMBO +%d", payload.comboBonus)
			end
			if payload.comboMilestone then
				detail ..= "\nTHE WHOLE ROOM CHEERS!"
				screenTint.BackgroundColor3 = COLORS.yellow
				TweenService:Create(screenTint, TweenInfo.new(0.08), { BackgroundTransparency = 0.76 }):Play()
				task.delay(0.1, function()
					TweenService:Create(screenTint, TweenInfo.new(0.28), { BackgroundTransparency = 1 }):Play()
				end)
			end
			shakeStrength = payload.result == "PERFECT!" and 1.15 or 0.65
			if payload.comboMilestone then
				shakeStrength = 1.4
			end
			shakeUntil = os.clock() + 0.34
		else
			detail = "Quick reload — give it another whirl!"
			shakeStrength = 0.85
			shakeUntil = os.clock() + 0.28
		end
		showFeedback(payload.result or "PIZZA!", payload.color or COLORS.yellow, detail)
		if payload.roundComplete then
			task.delay(0.45, function()
				showRoundComplete(payload)
			end)
		end
		task.delay(payload.reloadDelay or 0.35, function()
			ready = true
			fireButton.Text = "HOLD\nLAUNCH"
			fireButton.BackgroundColor3 = COLORS.red
		end)
	elseif state.event == "purchaseResult" and state.payload then
		showFeedback(state.payload.result, state.payload.success and COLORS.green or COLORS.orange, state.payload.success and "Upgrade equipped!" or "Deliver more pizzas!")
	elseif state.event == "modeChanged" and state.payload then
		showFeedback(state.payload.result or (operating and "READY!" or "LET'S WALK!"), operating and COLORS.green or COLORS.yellow,
			operating and "Aim for the glowing delivery plate" or "Explore, greet customers, or check the register")
	elseif state.event == "notice" and state.payload then
		showFeedback(state.payload.result or "PIZZA PLACE", state.payload.color or COLORS.yellow, state.payload.detail)
	elseif state.event == "welcome" then
		showFeedback("WELCOME, CHEF!", COLORS.yellow, "Walk to the glowing launcher and press E")
	end
end)

RunService:BindToRenderStep("PizzaLaunchRender", Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
	if not operating then
		return
	end
	local horizontalInput = ((keyboardHeld.right or touchHeld.right) and 1 or 0) - ((keyboardHeld.left or touchHeld.left) and 1 or 0)
	local verticalInput = ((keyboardHeld.up or touchHeld.up) and 1 or 0) - ((keyboardHeld.down or touchHeld.down) and 1 or 0)
	aimYaw = math.clamp(aimYaw + horizontalInput * deltaTime * 0.72, -1, 1)
	aimPitch = math.clamp(aimPitch + verticalInput * deltaTime * 0.72, 0, 1)
	if charging then
		charge = math.clamp((os.clock() - chargeStarted) / Config.CHARGE_TIME, 0, 1)
	end

	local cameraFrame = CFrame.lookAt(Config.CAMERA_POSITION, Config.CAMERA_FOCUS)
	if os.clock() < shakeUntil then
		local fade = (shakeUntil - os.clock()) / 0.35
		cameraFrame *= CFrame.new((math.random() - 0.5) * shakeStrength * fade, (math.random() - 0.5) * shakeStrength * fade, 0)
	end
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = cameraFrame
	camera.FieldOfView = 57

	powerFill.Size = UDim2.fromScale(math.max(charge, 0.02), 1)
	powerText.Text = string.format("POWER  %d%%", math.floor(charge * 100 + 0.5))
	local pitchDegrees = math.deg(Config.MIN_PITCH + aimPitch * (Config.MAX_PITCH - Config.MIN_PITCH))
	local arcName = pitchDegrees < 37 and "LOW" or (pitchDegrees < 49 and "MEDIUM" or "HIGH")
	arcText.Text = "ARC  " .. arcName

	local direction = currentDirection()
	local speed = Config.speedFromCharge(charge, state.upgrades and state.upgrades.power or 0)
	local landing, flightTime = Config.landingPoint(direction, speed, 6.85)
	local target = tableDefinition(state.targetId)
	local missDistance = Vector3.new(landing.X - target.position.X, 0, landing.Z - target.position.Z).Magnitude
	local guideColor = missDistance < 4.5 and COLORS.green or (missDistance < 10 and COLORS.yellow or COLORS.orange)
	for index, dot in trajectoryParts do
		local t = flightTime * index / (#trajectoryParts + 1)
		dot.Position = Config.LAUNCH_ORIGIN + direction * speed * t + Vector3.new(0, -0.5 * Config.GRAVITY * t * t, 0)
		dot.Color = guideColor
		dot.Transparency = ready and (0.1 + index * 0.025) or 1
	end
	landingRing.CFrame = CFrame.new(landing + Vector3.new(0, 0.08, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	landingRing.Color = guideColor
	landingRing.Transparency = ready and 0.22 or 1
	landingLight.Color = guideColor
	landingLight.Enabled = ready

	local world = Workspace:FindFirstChild("PizzaLaunchWorld")
	local station = world and world:FindFirstChild("LauncherStation")
	local rig = station and station:FindFirstChild("AimRig")
	if rig and rig:IsA("Model") then
		rig:PivotTo(CFrame.lookAt(Config.LAUNCH_ORIGIN, Config.LAUNCH_ORIGIN + direction))
	end
end)

task.defer(function()
	local world = Workspace:WaitForChild("PizzaLaunchWorld", 10)
	if world then
		applyMode()
		updateTargetVisuals()
	end
end)

player.CharacterAdded:Connect(function(character)
	if not operating then
		local humanoid = character:WaitForChild("Humanoid", 8)
		if humanoid then
			camera.CameraType = Enum.CameraType.Custom
			camera.CameraSubject = humanoid
			camera.FieldOfView = 70
		end
	end
end)
