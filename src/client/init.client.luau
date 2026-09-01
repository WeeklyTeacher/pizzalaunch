local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
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
	recordRun = { status = "idle", personalBest = 0, score = 0, combo = 0, multiplier = 1 },
	shiftEvent = nil,
}
local aimYaw = 0
local aimPitch = (Config.DEFAULT_PITCH - Config.MIN_PITCH) / (Config.MAX_PITCH - Config.MIN_PITCH)
local charge = 0.34
local charging = false
local chargeStarted = 0
local ready = true
local reloadReadyAt = 0
local activeFireInput: InputObject? = nil
local targetHighlight: Highlight? = nil
local yourOrderBillboard: BillboardGui? = nil
local recordTargetBillboards = {}
local tableAvailabilityConnections = {}
local trajectoryParts = {}
local keyboardHeld = {}
local touchHeld = {}
local shakeUntil = 0
local shakeStrength = 0
local operating = false
local playerControls
local onboardingCompleted = false
local onboardingReplayActive = false
local onboardingReachedLauncher = false
local onboardingTrailActive = true
local onboardingTrailFolder: Folder? = nil
local onboardingTrailParts = {}
local onboardingInteractionAnchor: BasePart? = nil
local onboardingHighlight: Highlight? = nil
local onboardingNextDistanceCheck = 0
local restoreTutorialAppearance

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
tutorial.Size = UDim2.fromOffset(276, 92)
tutorial.Position = UDim2.new(0, 18, 0, 126)
tutorial.BackgroundColor3 = COLORS.cream
tutorial.BackgroundTransparency = 0.03
tutorial.Active = false
tutorial.Visible = false
tutorial.Parent = gui
addCorner(tutorial, 18)
addStroke(tutorial, COLORS.darkRed, 2)
local tutorialTitle = makeLabel(tutorial, "Title", "AIM  •  CHARGE  •  LAUNCH!", UDim2.new(1, -20, 0, 25), UDim2.fromOffset(10, 7), 15)
tutorialTitle.TextColor3 = COLORS.red
local tutorialText = makeLabel(tutorial, "Steps", "MOUSE / W A S D TO AIM\nHOLD SPACE OR CLICK, THEN RELEASE", UDim2.new(1, -24, 0, 50), UDim2.fromOffset(12, 35), 12)
tutorialText.TextXAlignment = Enum.TextXAlignment.Left
tutorialText.TextYAlignment = Enum.TextYAlignment.Top

local feedback = makeLabel(gui, "Feedback", "", UDim2.fromOffset(580, 140), UDim2.new(0.5, -290, 0.34, 0), 49)
feedback.TextColor3 = COLORS.yellow
feedback.TextStrokeColor3 = COLORS.ink
feedback.TextStrokeTransparency = 0.12
feedback.Visible = false
feedback.ZIndex = 5

local dialogueCard = Instance.new("Frame")
dialogueCard.Name = "CustomerDialogueCard"
dialogueCard.AnchorPoint = Vector2.new(0, 0.5)
dialogueCard.Size = UDim2.fromOffset(360, 116)
dialogueCard.Position = UDim2.new(0, 18, 0.55, 0)
dialogueCard.BackgroundColor3 = COLORS.cream
dialogueCard.BackgroundTransparency = 0.03
dialogueCard.Active = false
dialogueCard.Visible = false
dialogueCard.ZIndex = 14
dialogueCard.Parent = gui
addCorner(dialogueCard, 18)
addStroke(dialogueCard, COLORS.darkRed, 3)
local dialoguePortrait = makeLabel(dialogueCard, "Portrait", "M", UDim2.fromOffset(56, 56), UDim2.fromOffset(14, 16), 27)
dialoguePortrait.BackgroundTransparency = 0
dialoguePortrait.BackgroundColor3 = COLORS.red
dialoguePortrait.TextColor3 = Color3.new(1, 1, 1)
dialoguePortrait.Font = Enum.Font.GothamBlack
dialoguePortrait.ZIndex = 15
addCorner(dialoguePortrait, 28)
local dialogueName = makeLabel(dialogueCard, "CustomerName", "MIA", UDim2.new(1, -114, 0, 24), UDim2.fromOffset(82, 11), 18)
dialogueName.TextColor3 = COLORS.darkRed
dialogueName.TextXAlignment = Enum.TextXAlignment.Left
dialogueName.ZIndex = 15
local dialogueMood = makeLabel(dialogueCard, "Personality", "SUPER HUNGRY", UDim2.new(1, -114, 0, 18), UDim2.fromOffset(82, 34), 11)
dialogueMood.TextColor3 = COLORS.green
dialogueMood.TextXAlignment = Enum.TextXAlignment.Left
dialogueMood.ZIndex = 15
local dialogueText = makeLabel(dialogueCard, "Line", "A hot cheese pizza would be perfect.", UDim2.new(1, -98, 0, 46), UDim2.fromOffset(82, 57), 16)
dialogueText.Font = Enum.Font.GothamMedium
dialogueText.TextWrapped = true
dialogueText.TextScaled = false
dialogueText.TextXAlignment = Enum.TextXAlignment.Left
dialogueText.TextYAlignment = Enum.TextYAlignment.Top
dialogueText.ZIndex = 15
local dialogueClose = makeButton(dialogueCard, "Close", "X", UDim2.fromOffset(30, 30), UDim2.new(1, -39, 0, 8), COLORS.darkRed)
dialogueClose.TextSize = 13
dialogueClose.ZIndex = 16

local eventBanner = Instance.new("Frame")
eventBanner.Name = "ShiftEventBanner"
eventBanner.AnchorPoint = Vector2.new(1, 0)
eventBanner.Size = UDim2.fromOffset(310, 76)
eventBanner.Position = UDim2.new(1, -18, 0, 212)
eventBanner.BackgroundColor3 = COLORS.darkRed
eventBanner.BackgroundTransparency = 0.04
eventBanner.Active = false
eventBanner.Visible = false
eventBanner.ZIndex = 13
eventBanner.Parent = gui
addCorner(eventBanner, 17)
addStroke(eventBanner, COLORS.yellow, 3)
local eventIcon = makeLabel(eventBanner, "Icon", ">>", UDim2.fromOffset(54, 54), UDim2.fromOffset(10, 11), 19)
eventIcon.BackgroundTransparency = 0
eventIcon.BackgroundColor3 = COLORS.orange
eventIcon.TextColor3 = Color3.new(1, 1, 1)
eventIcon.ZIndex = 14
addCorner(eventIcon, 14)
local eventTitle = makeLabel(eventBanner, "Title", "DINNER RUSH", UDim2.new(1, -78, 0, 25), UDim2.fromOffset(72, 10), 17)
eventTitle.TextColor3 = COLORS.yellow
eventTitle.TextXAlignment = Enum.TextXAlignment.Left
eventTitle.ZIndex = 14
local eventDetail = makeLabel(eventBanner, "Detail", "Serve quickly for bonus coins.", UDim2.new(1, -80, 0, 34), UDim2.fromOffset(72, 36), 12)
eventDetail.TextColor3 = Color3.new(1, 1, 1)
eventDetail.TextXAlignment = Enum.TextXAlignment.Left
eventDetail.TextYAlignment = Enum.TextYAlignment.Top
eventDetail.ZIndex = 14

local roundOverlay = Instance.new("Frame")
roundOverlay.Name = "RoundClearedBanner"
roundOverlay.AnchorPoint = Vector2.new(0.5, 0)
roundOverlay.Size = UDim2.fromOffset(510, 78)
roundOverlay.Position = UDim2.new(0.5, 0, 0, 126)
roundOverlay.BackgroundColor3 = COLORS.darkRed
roundOverlay.BackgroundTransparency = 0.04
roundOverlay.Active = false
roundOverlay.Visible = false
roundOverlay.ZIndex = 8
roundOverlay.Parent = gui
addCorner(roundOverlay, 18)
addStroke(roundOverlay, COLORS.yellow, 3)
local roundOverlayTitle = makeLabel(roundOverlay, "Title", "ROUND CLEARED!", UDim2.new(1, -28, 0, 30), UDim2.fromOffset(14, 7), 23)
roundOverlayTitle.TextColor3 = COLORS.yellow
roundOverlayTitle.ZIndex = 9
local roundOverlayDetail = makeLabel(roundOverlay, "Detail", "+25 COINS  -  NEXT: DINNER RUSH", UDim2.new(1, -28, 0, 27), UDim2.fromOffset(14, 40), 15)
roundOverlayDetail.TextColor3 = Color3.new(1, 1, 1)
roundOverlayDetail.ZIndex = 9

local recordHud = Instance.new("Frame")
recordHud.Name = "RecordRunHUD"
recordHud.AnchorPoint = Vector2.new(0.5, 0)
recordHud.Size = UDim2.fromOffset(470, 108)
recordHud.Position = UDim2.new(0.5, 0, 0, 12)
recordHud.BackgroundColor3 = COLORS.darkRed
recordHud.Visible = false
recordHud.ZIndex = 6
recordHud.Parent = gui
addCorner(recordHud, 20)
addStroke(recordHud, COLORS.yellow, 4)
local recordTitle = makeLabel(recordHud, "Title", "1-MINUTE RECORD RUN", UDim2.new(1, -20, 0, 24), UDim2.fromOffset(10, 5), 15)
recordTitle.TextColor3 = COLORS.yellow
recordTitle.ZIndex = 7
local recordTimer = makeLabel(recordHud, "Timer", "1:00", UDim2.fromOffset(118, 52), UDim2.fromOffset(12, 30), 37)
recordTimer.TextColor3 = Color3.new(1, 1, 1)
recordTimer.ZIndex = 7
local recordScore = makeLabel(recordHud, "Score", "SCORE\n0", UDim2.fromOffset(150, 52), UDim2.fromOffset(132, 31), 19)
recordScore.TextColor3 = COLORS.cream
recordScore.ZIndex = 7
local recordCombo = makeLabel(recordHud, "Combo", "COMBO 0\nx1.00", UDim2.fromOffset(165, 52), UDim2.fromOffset(288, 31), 18)
recordCombo.TextColor3 = COLORS.green
recordCombo.ZIndex = 7
local recordBest = makeLabel(recordHud, "Best", "PERSONAL BEST  0", UDim2.new(1, -24, 0, 18), UDim2.fromOffset(12, 86), 12)
recordBest.TextColor3 = COLORS.yellow
recordBest.ZIndex = 7

local countdownLabel = makeLabel(gui, "RecordCountdown", "3", UDim2.fromOffset(500, 170), UDim2.new(0.5, -250, 0.28, 0), 100)
countdownLabel.TextColor3 = COLORS.yellow
countdownLabel.TextStrokeColor3 = COLORS.darkRed
countdownLabel.TextStrokeTransparency = 0
countdownLabel.Visible = false
countdownLabel.ZIndex = 12

local recordSummary = Instance.new("Frame")
recordSummary.Name = "RecordSummary"
recordSummary.AnchorPoint = Vector2.new(0.5, 0)
recordSummary.Size = UDim2.fromOffset(540, 154)
recordSummary.Position = UDim2.new(0.5, 0, 0, 124)
recordSummary.BackgroundColor3 = COLORS.darkRed
recordSummary.Active = false
recordSummary.Visible = false
recordSummary.ZIndex = 10
recordSummary.Parent = gui
addCorner(recordSummary, 20)
addStroke(recordSummary, COLORS.yellow, 3)
local recordSummaryTitle = makeLabel(recordSummary, "Title", "TIME!", UDim2.new(1, -190, 0, 34), UDim2.fromOffset(16, 9), 27)
recordSummaryTitle.TextColor3 = COLORS.yellow
recordSummaryTitle.TextXAlignment = Enum.TextXAlignment.Left
recordSummaryTitle.ZIndex = 11
local recordSummaryDetail = makeLabel(recordSummary, "Detail", "FINAL SCORE  0\nPERSONAL BEST  0", UDim2.new(1, -188, 0, 78), UDim2.fromOffset(16, 43), 18)
recordSummaryDetail.TextColor3 = Color3.new(1, 1, 1)
recordSummaryDetail.TextXAlignment = Enum.TextXAlignment.Left
recordSummaryDetail.ZIndex = 11
local recordSummaryHint = makeLabel(recordSummary, "Hint", "EXIT THE LAUNCHER TO WALK AROUND OR TRY AGAIN", UDim2.new(1, -28, 0, 23), UDim2.fromOffset(14, 125), 11)
recordSummaryHint.TextColor3 = COLORS.cream
recordSummaryHint.TextXAlignment = Enum.TextXAlignment.Left
recordSummaryHint.ZIndex = 11
local recordContinue = makeButton(recordSummary, "Continue", "BACK TO RESTAURANT", UDim2.fromOffset(160, 52), UDim2.new(1, -174, 0, 14), COLORS.green)
recordContinue.TextSize = 13
recordContinue.ZIndex = 12

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
shopPanel.Size = UDim2.fromOffset(420, 555)
shopPanel.Position = UDim2.new(1, -18, 0, 82)
shopPanel.BackgroundColor3 = COLORS.cream
shopPanel.Visible = false
shopPanel.ZIndex = 6
shopPanel.Parent = gui
addCorner(shopPanel, 20)
addStroke(shopPanel, COLORS.red, 3)
local shopTitle = makeLabel(shopPanel, "Title", "UPGRADE THE PIZZA CANNON", UDim2.new(1, -24, 0, 30), UDim2.fromOffset(12, 8), 19)
shopTitle.TextColor3 = COLORS.ink
shopTitle.ZIndex = 7
local shopSubtitle = makeLabel(shopPanel, "Subtitle", "SESSION-ONLY UPGRADES  •  EFFECTS APPLY RIGHT AWAY", UDim2.new(1, -24, 0, 22), UDim2.fromOffset(12, 37), 11)
shopSubtitle.TextColor3 = Color3.fromRGB(91, 74, 68)
shopSubtitle.ZIndex = 7
local shopCoins = makeLabel(shopPanel, "ShopCoins", "YOUR COINS  0", UDim2.new(1, -24, 0, 29), UDim2.fromOffset(12, 57), 17)
shopCoins.BackgroundColor3 = COLORS.yellow
shopCoins.BackgroundTransparency = 0
shopCoins.TextColor3 = COLORS.ink
shopCoins.ZIndex = 7
addCorner(shopCoins, 10)
local shopScroll = Instance.new("ScrollingFrame")
shopScroll.Name = "UpgradeCards"
shopScroll.Size = UDim2.new(1, -16, 1, -102)
shopScroll.Position = UDim2.fromOffset(8, 94)
shopScroll.BackgroundTransparency = 1
shopScroll.BorderSizePixel = 0
shopScroll.CanvasSize = UDim2.fromOffset(0, 424)
shopScroll.ScrollBarThickness = 6
shopScroll.ZIndex = 7
shopScroll.Parent = shopPanel
local upgradeCards = {}
local upgradeOrder = { "tips", "assist", "reload", "power" }
for index, upgradeId in upgradeOrder do
	local card = Instance.new("TextButton")
	card.Name = upgradeId
	card.Size = UDim2.new(1, -4, 0, 100)
	card.Position = UDim2.fromOffset(0, (index - 1) * 106)
	card.BackgroundColor3 = Color3.fromRGB(255, 255, 248)
	card.Text = ""
	card.AutoButtonColor = false
	card.ZIndex = 8
	card.Parent = shopScroll
	addCorner(card, 16)
	addStroke(card, Color3.fromRGB(137, 116, 105), 2)
	local icon = makeLabel(card, "Icon", "", UDim2.fromOffset(50, 50), UDim2.fromOffset(12, 25), 28)
	icon.BackgroundColor3 = index % 2 == 0 and COLORS.blue or COLORS.orange
	icon.BackgroundTransparency = 0
	icon.TextColor3 = Color3.new(1, 1, 1)
	icon.ZIndex = 9
	addCorner(icon, 14)
	local title = makeLabel(card, "Title", "", UDim2.new(1, -188, 0, 24), UDim2.fromOffset(72, 10), 16)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = COLORS.ink
	title.ZIndex = 9
	local level = makeLabel(card, "Level", "", UDim2.new(1, -188, 0, 19), UDim2.fromOffset(72, 34), 11)
	level.TextXAlignment = Enum.TextXAlignment.Left
	level.TextColor3 = Color3.fromRGB(77, 118, 89)
	level.ZIndex = 9
	local effect = makeLabel(card, "Effect", "", UDim2.new(1, -188, 0, 32), UDim2.fromOffset(72, 55), 12)
	effect.TextXAlignment = Enum.TextXAlignment.Left
	effect.TextYAlignment = Enum.TextYAlignment.Top
	effect.TextColor3 = Color3.fromRGB(73, 60, 55)
	effect.ZIndex = 9
	local action = makeLabel(card, "Action", "", UDim2.fromOffset(112, 66), UDim2.new(1, -122, 0.5, -33), 14)
	action.BackgroundColor3 = COLORS.green
	action.BackgroundTransparency = 0
	action.TextColor3 = Color3.new(1, 1, 1)
	action.ZIndex = 9
	addCorner(action, 13)
	upgradeCards[upgradeId] = { card = card, icon = icon, title = title, level = level, effect = effect, action = action }
	card.Activated:Connect(function()
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
	tutorial.Size = UDim2.fromOffset(180, 60)
	tutorial.Position = UDim2.new(0, 8, 0, 86)
	tutorialTitle.Size = UDim2.new(1, -16, 0, 22)
	tutorialTitle.Position = UDim2.fromOffset(8, 5)
	tutorialTitle.TextSize = 11
	tutorialText.Size = UDim2.new(1, -16, 0, 30)
	tutorialText.Position = UDim2.fromOffset(8, 26)
	tutorialText.TextSize = 9
	dialogueCard.Size = UDim2.fromOffset(320, 110)
	dialogueCard.Position = UDim2.new(0, 10, 0.55, 0)
	dialogueName.Size = UDim2.new(1, -108, 0, 21)
	dialogueName.TextSize = 16
	dialogueMood.Size = UDim2.new(1, -108, 0, 16)
	dialogueMood.TextSize = 9
	dialogueText.Size = UDim2.new(1, -96, 0, 42)
	dialogueText.TextSize = 14
	eventBanner.Size = UDim2.fromOffset(280, 64)
	eventBanner.Position = UDim2.new(1, -10, 0, 148)
	eventIcon.Size = UDim2.fromOffset(44, 44)
	eventIcon.Position = UDim2.fromOffset(9, 10)
	eventIcon.TextSize = 14
	eventTitle.Position = UDim2.fromOffset(61, 7)
	eventTitle.Size = UDim2.new(1, -70, 0, 21)
	eventTitle.TextSize = 14
	eventDetail.Position = UDim2.fromOffset(61, 29)
	eventDetail.Size = UDim2.new(1, -70, 0, 29)
	eventDetail.TextSize = 10
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
	shopPanel.Size = UDim2.fromOffset(290, 270)
	shopPanel.Position = UDim2.new(1, -16, 0, 60)
	shopTitle.TextSize = 13
	shopSubtitle.TextSize = 8
	shopCoins.TextSize = 14
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
	roundOverlay.Size = UDim2.fromOffset(340, 58)
	roundOverlay.Position = UDim2.new(0.5, 0, 0, 84)
	roundOverlayTitle.Size = UDim2.new(1, -20, 0, 22)
	roundOverlayTitle.Position = UDim2.fromOffset(10, 4)
	roundOverlayTitle.TextSize = 17
	roundOverlayDetail.Size = UDim2.new(1, -20, 0, 22)
	roundOverlayDetail.Position = UDim2.fromOffset(10, 29)
	roundOverlayDetail.TextSize = 11
	recordHud.Size = UDim2.fromOffset(330, 74)
	recordHud.Position = UDim2.new(0.5, 0, 0, 5)
	recordTitle.Size = UDim2.new(1, -12, 0, 16)
	recordTitle.Position = UDim2.fromOffset(6, 2)
	recordTitle.TextSize = 10
	recordTimer.Size = UDim2.fromOffset(78, 35)
	recordTimer.Position = UDim2.fromOffset(8, 19)
	recordTimer.TextSize = 26
	recordScore.Size = UDim2.fromOffset(105, 35)
	recordScore.Position = UDim2.fromOffset(88, 19)
	recordScore.TextSize = 14
	recordCombo.Size = UDim2.fromOffset(122, 35)
	recordCombo.Position = UDim2.fromOffset(196, 19)
	recordCombo.TextSize = 13
	recordBest.Size = UDim2.new(1, -16, 0, 14)
	recordBest.Position = UDim2.fromOffset(8, 56)
	recordBest.TextSize = 9
	countdownLabel.Size = UDim2.fromOffset(360, 120)
	countdownLabel.Position = UDim2.new(0.5, -180, 0.22, 0)
	countdownLabel.TextSize = 74
	recordSummary.Size = UDim2.fromOffset(350, 134)
	recordSummary.Position = UDim2.new(0.5, 0, 0, 82)
	recordSummaryTitle.Size = UDim2.new(1, -132, 0, 27)
	recordSummaryTitle.Position = UDim2.fromOffset(12, 7)
	recordSummaryTitle.TextSize = 19
	recordSummaryDetail.Position = UDim2.fromOffset(12, 34)
	recordSummaryDetail.Size = UDim2.new(1, -126, 0, 67)
	recordSummaryDetail.TextSize = 13
	recordSummaryHint.Position = UDim2.fromOffset(10, 105)
	recordSummaryHint.Size = UDim2.new(1, -20, 0, 22)
	recordSummaryHint.TextSize = 8
	recordContinue.Size = UDim2.fromOffset(108, 45)
	recordContinue.Position = UDim2.new(1, -118, 0, 11)
	recordContinue.Text = "CONTINUE"
	recordContinue.TextSize = 9

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

local onboardingHelpButton = makeButton(gui, "PizzaTrailHelp", "?  HELP", UDim2.fromOffset(92, 38), UDim2.new(1, -110, 0, 140), COLORS.yellow)
onboardingHelpButton.TextColor3 = COLORS.darkRed
onboardingHelpButton.TextSize = 13
onboardingHelpButton.ZIndex = 4
if UserInputService.TouchEnabled then
	onboardingHelpButton.Size = UDim2.fromOffset(76, 34)
	onboardingHelpButton.Position = UDim2.new(1, -86, 0, 104)
	onboardingHelpButton.TextSize = 11
end

local PIZZA_TRAIL_ANCHOR_OFFSETS = {
	-- All seven markers derive from LauncherInteractionAnchor. The first offset
	-- lands directly ahead of spawn; the zero offset is the final floor marker.
	Vector3.new(-14.7, 0, -1.5),
	Vector3.new(-12, 0, -1),
	Vector3.new(-9.4, 0, -0.5),
	Vector3.new(-6.8, 0, -0.2),
	Vector3.new(-4.5, 0, 0),
	Vector3.new(-2.3, 0, 0),
	Vector3.new(0, 0, 0),
}

local function registerTrailPart(part: BasePart, baseTransparency: number)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part:SetAttribute("TrailBaseTransparency", baseTransparency)
	part.Transparency = baseTransparency
	table.insert(onboardingTrailParts, part)
end

local function makePizzaArrow(parent: Instance, position: Vector3, nextPosition: Vector3, index: number)
	local direction = Vector3.new(nextPosition.X - position.X, 0, nextPosition.Z - position.Z)
	if direction.Magnitude < 0.01 then
		direction = Vector3.new(0, 0, -1)
	end
	local arrowFrame = CFrame.lookAt(position, position + direction.Unit)
	local model = Instance.new("Model")
	model.Name = string.format("PizzaArrow%02d", index)
	model.Parent = parent

	local shaft = Instance.new("Part")
	shaft.Name = "CheeseShaft"
	shaft.Size = Vector3.new(1.8, 0.12, 3.2)
	shaft.CFrame = arrowFrame * CFrame.new(0, 0, 0.35)
	shaft.Color = COLORS.yellow
	shaft.Material = Enum.Material.Neon
	shaft.Parent = model
	registerTrailPart(shaft, 0.02)

	for side = -1, 1, 2 do
		local arrowHead = Instance.new("Part")
		arrowHead.Name = "CheeseArrowHead"
		arrowHead.Size = Vector3.new(1.15, 0.12, 2.8)
		arrowHead.CFrame = arrowFrame * CFrame.new(side * 0.88, 0, -1.5) * CFrame.Angles(0, math.rad(side * 40), 0)
		arrowHead.Color = COLORS.yellow
		arrowHead.Material = Enum.Material.Neon
		arrowHead.Parent = model
		registerTrailPart(arrowHead, 0.02)
	end

	for _, pepperoniOffset in {
		Vector3.new(-0.48, 0.1, 0.72),
		Vector3.new(0.48, 0.1, 0.08),
		Vector3.new(0, 0.1, -0.72),
	} do
		local pepperoni = Instance.new("Part")
		pepperoni.Name = "Pepperoni"
		pepperoni.Shape = Enum.PartType.Cylinder
		pepperoni.Size = Vector3.new(0.12, 0.72, 0.72)
		pepperoni.CFrame = arrowFrame * CFrame.new(pepperoniOffset) * CFrame.Angles(0, 0, math.pi / 2)
		pepperoni.Color = COLORS.red
		pepperoni.Material = Enum.Material.SmoothPlastic
		pepperoni.Parent = model
		registerTrailPart(pepperoni, 0)
	end
end

local function ensurePizzaTrailWorld()
	if onboardingTrailFolder and onboardingTrailFolder.Parent then
		return
	end
	local world = Workspace:FindFirstChild("PizzaLaunchWorld")
	local interactionAnchor = world and world:FindFirstChild("LauncherInteractionAnchor", true)
	if not interactionAnchor or not interactionAnchor:IsA("BasePart") then
		return
	end
	onboardingInteractionAnchor = interactionAnchor

	onboardingTrailParts = {}
	local folder = Instance.new("Folder")
	folder.Name = "LocalPizzaTrail"
	folder:SetAttribute("ClientOnly", true)
	folder.Parent = Workspace
	onboardingTrailFolder = folder
	local trailFloorY = -0.39
	local trailPoints = {}
	for _, offset in PIZZA_TRAIL_ANCHOR_OFFSETS do
		table.insert(trailPoints, Vector3.new(interactionAnchor.Position.X + offset.X, trailFloorY, interactionAnchor.Position.Z + offset.Z))
	end
	for index, position in trailPoints do
		local nextPosition = trailPoints[index + 1] or (position + Vector3.new(0, 0, -1))
		makePizzaArrow(folder, position, nextPosition, index)
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = "PizzaCannonInteractionHighlight"
	highlight.Adornee = interactionAnchor
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillColor = COLORS.yellow
	highlight.FillTransparency = 0.82
	highlight.OutlineColor = COLORS.red
	highlight.OutlineTransparency = 0.05
	highlight.Enabled = false
	highlight.Parent = folder
	onboardingHighlight = highlight
end

local function updateOnboardingWalkHint()
	if onboardingTrailActive and not onboardingReachedLauncher then
		walkHint.Text = "Follow the pizza arrows to the Pizza Cannon!"
	else
		walkHint.Text = "Press E or tap the Pizza Cannon to start!"
	end
end

local function setPizzaTrailVisible(visible: boolean, immediate: boolean?)
	ensurePizzaTrailWorld()
	onboardingTrailActive = visible
	for _, part in onboardingTrailParts do
		local target = visible and (part:GetAttribute("TrailBaseTransparency") or 0.1) or 1
		if immediate then
			part.Transparency = target
		else
			TweenService:Create(part, TweenInfo.new(0.35), { Transparency = target }):Play()
		end
	end
	if onboardingHighlight then
		onboardingHighlight.Enabled = onboardingReachedLauncher and not operating
	end
	updateOnboardingWalkHint()
end

local function beginPizzaTrail(replay: boolean)
	if onboardingCompleted and not replay then
		return
	end
	onboardingReplayActive = replay
	onboardingReachedLauncher = false
	tutorial.Visible = false
	setPizzaTrailVisible(true, true)
end

local function showFirstPizzaHint()
	tutorialTitle.Text = "AIM  •  CHARGE  •  LAUNCH!"
	tutorialText.Text = UserInputService.TouchEnabled
		and "DRAG / ARROWS • AIM\nHOLD + RELEASE"
		or "MOUSE / W A S D TO AIM\nHOLD SPACE OR CLICK, THEN RELEASE"
	restoreTutorialAppearance()
	tutorial.Visible = true
end

local function updatePizzaTrail()
	ensurePizzaTrailWorld()
	if onboardingTrailActive then
		local pulse = math.sin(os.clock() * 3.4) * 0.045
		for _, part in onboardingTrailParts do
			local baseTransparency = part:GetAttribute("TrailBaseTransparency") or 0.1
			part.Transparency = math.clamp(baseTransparency + pulse, 0, 0.1)
		end
	end
	if operating or (onboardingCompleted and not onboardingReplayActive) then
		return
	end
	if os.clock() < onboardingNextDistanceCheck then
		return
	end
	onboardingNextDistanceCheck = os.clock() + 0.1
	local interactionAnchor = onboardingInteractionAnchor
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not interactionAnchor or not interactionAnchor.Parent or not root or not root:IsA("BasePart") then
		return
	end
	local distance = (root.Position - interactionAnchor.Position).Magnitude
	if onboardingTrailActive and not onboardingReachedLauncher and distance <= 12 then
		onboardingReachedLauncher = true
		if onboardingHighlight then onboardingHighlight.Enabled = true end
		updateOnboardingWalkHint()
	elseif onboardingReachedLauncher and distance > 18 then
		onboardingReachedLauncher = false
		if onboardingHighlight then onboardingHighlight.Enabled = false end
		updateOnboardingWalkHint()
	end
end

onboardingHelpButton.Activated:Connect(function()
	beginPizzaTrail(true)
	if operating then
		showFirstPizzaHint()
	end
end)

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

local function recordStatus(): string
	return state.recordRun and state.recordRun.status or "idle"
end

local function isRecordSession(): boolean
	return recordStatus() ~= "idle"
end

local function updatePersonalBestDisplay()
	local world = Workspace:FindFirstChild("PizzaLaunchWorld")
	local display = world and world:FindFirstChild("PersonalBestDisplay", true)
	local surface = display and display:FindFirstChild("PersonalBestGui")
	local label = surface and surface:FindFirstChild("Label")
	if label and label:IsA("TextLabel") then
		label.Text = string.format("YOUR BEST\n%d POINTS", state.recordRun and state.recordRun.personalBest or 0)
	end
end

local function updateRecordUI()
	local run = state.recordRun or { status = "idle", score = 0, combo = 0, multiplier = 1, personalBest = 0 }
	local status = run.status or "idle"
	local session = status ~= "idle"
	recordHud.Visible = operating and (status == "countdown" or status == "running" or status == "saving")
	recordScore.Text = string.format("SCORE\n%d", run.score or 0)
	recordCombo.Text = string.format("COMBO %d\nx%.2f", run.combo or 0, run.multiplier or 1)
	recordBest.Text = string.format("PERSONAL BEST  %d", run.personalBest or 0)
	recordCombo.TextColor3 = (run.combo or 0) >= 4 and COLORS.yellow or COLORS.green
	roundCard.Visible = not session
	stats.Visible = not session
	shopToggle.Visible = not session
	onboardingHelpButton.Visible = not session
	if session then
		local canAim = operating and (status == "countdown" or status == "running")
		controls.Visible = canAim
		touchAimPad.Visible = canAim and UserInputService.TouchEnabled
		if onboardingCompleted and not onboardingReplayActive then
			tutorial.Visible = false
		end
	end
	if status == "saving" then
		recordSummary.Visible = true
		recordSummaryTitle.Text = "TIME!"
		recordSummaryDetail.Text = string.format("FINAL SCORE  %d\nChecking the Legends board...", run.score or 0)
		recordSummaryHint.Text = "YOUR SCORE WAS CALCULATED ON THE SERVER"
	elseif status == "finished" then
		recordSummary.Visible = true
		if run.madeTopTen and run.rank then
			recordSummaryTitle.Text = string.format("LEGEND!  #%d", run.rank)
		else
			recordSummaryTitle.Text = run.isNewBest and "NEW PERSONAL BEST!" or "RUN COMPLETE!"
		end
		local rankLine = run.madeTopTen and string.format("GLOBAL TOP 10  -  RANK #%d", run.rank) or "GLOBAL TOP 10  -  NOT THIS TIME"
		if not run.globalBoardAvailable then
			rankLine = UserInputService.TouchEnabled and "GLOBAL BOARD: STUDIO SAMPLE" or "GLOBAL BOARD: STUDIO SAMPLE / RECONNECTING"
		end
		recordSummaryDetail.Text = string.format("FINAL SCORE  %d\nPERSONAL BEST  %d\n%s", run.score or 0, run.personalBest or 0, rankLine)
		recordSummaryHint.Text = run.globalBoardAvailable and "SCORE SAVED SEPARATELY FROM THE BOARD - TRY AGAIN ANYTIME" or (run.globalBoardMessage or "Studio: enable API Services for live records.")
	else
		recordSummary.Visible = false
	end
	if not session then
		countdownLabel.Visible = false
	end
	updatePersonalBestDisplay()
end

local function updateShop(upgrades)
	shopCoins.Text = string.format("YOUR COINS  %d", state.coins or 0)
	for _, upgradeId in upgradeOrder do
		local definition = Config.UPGRADES[upgradeId]
		local level = upgrades and upgrades[upgradeId] or 0
		local cost = definition.costs[level + 1]
		local card = upgradeCards[upgradeId]
		card.icon.Text = definition.icon or "?"
		card.title.Text = definition.name
		card.effect.Text = definition.effect or "Improves this cannon part"
		if cost then
			card.level.Text = level > 0 and string.format("CURRENT LEVEL %d  -  OWNED", level) or "CURRENT LEVEL 0  -  AVAILABLE"
			local remaining = cost - (state.coins or 0)
			if remaining <= 0 then
				card.action.Text = string.format("BUY\n%d COINS", cost)
				card.action.BackgroundColor3 = COLORS.green
				card.card.BackgroundColor3 = Color3.fromRGB(255, 255, 248)
			else
				card.action.Text = string.format("NEED %d\nMORE COINS", remaining)
				card.action.BackgroundColor3 = Color3.fromRGB(126, 111, 103)
				card.card.BackgroundColor3 = Color3.fromRGB(246, 241, 232)
			end
		else
			card.level.Text = string.format("CURRENT LEVEL %d  -  OWNED", level)
			card.action.Text = "MAXED"
			card.action.BackgroundColor3 = COLORS.blue
			card.card.BackgroundColor3 = Color3.fromRGB(231, 246, 237)
		end
	end
end

local function updateTargetVisuals()
	local round = Config.ROUNDS[math.clamp(state.round or 1, 1, #Config.ROUNDS)]
	local status = recordStatus()
	local recordVisuals = status == "countdown" or status == "running"
	local activeTables = {}
	if isRecordSession() then
		for _, tableData in Config.TABLES do
			activeTables[tableData.id] = true
		end
	else
		for _, tableId in round.tables do
			activeTables[tableId] = true
		end
		local shiftEvent = state.shiftEvent
		if shiftEvent then
			local eventTableId = shiftEvent.extraTableId or shiftEvent.specialTableId
			if eventTableId then activeTables[eventTableId] = true end
		end
	end
	if targetHighlight then
		targetHighlight:Destroy()
	end
	if yourOrderBillboard then
		yourOrderBillboard:Destroy()
		yourOrderBillboard = nil
	end
	for _, billboardGui in recordTargetBillboards do
		billboardGui:Destroy()
	end
	table.clear(recordTargetBillboards)
	local world = Workspace:FindFirstChild("PizzaLaunchWorld")
	if world then
		for _, tableModel in world:GetChildren() do
			if tableModel:IsA("Model") and tableModel:GetAttribute("TableId") then
				local tableId = tableModel:GetAttribute("TableId")
				local isActive = activeTables[tableId] == true
				local available = tableModel:GetAttribute("DeliveryAvailable") == true
				local targetRing = tableModel:FindFirstChild("TargetRing")
				local customer = tableModel:FindFirstChild("Customer")
				if customer then
					for _, descendant in customer:GetDescendants() do
						if descendant:IsA("BasePart") then
							descendant.LocalTransparencyModifier = isActive and 0 or 1
						elseif descendant:IsA("SurfaceGui") and descendant.Name == "Face" then
							descendant.Enabled = isActive and tableModel:GetAttribute("Occupied") ~= false
						elseif descendant:IsA("ProximityPrompt") then
							descendant.Enabled = isActive and available and not operating
						end
					end
					local waitingMarker = customer:FindFirstChild("WaitingMarker", true)
					if waitingMarker and waitingMarker:IsA("BillboardGui") then
						waitingMarker.Enabled = isActive and available and not isRecordSession()
					end
				end
				if targetRing and targetRing:IsA("BasePart") then
					local zoneScale = isRecordSession() and 1.12 or (1 + (state.upgrades and state.upgrades.assist or 0) * 0.12)
					local diameter = (Config.DELIVERY_ZONE_DIAMETER or 8) * zoneScale
					targetRing.Size = Vector3.new(0.15, diameter, diameter)
					local showRing = available and (recordVisuals or (operating and tableId == state.targetId))
					targetRing.Transparency = tableId == state.targetId and 0.16 or 0.55
					targetRing.LocalTransparencyModifier = showRing and 0 or 1
				end
				local top = tableModel:FindFirstChild("TableTop")
				if recordVisuals and available and top and top:IsA("BasePart") then
					local definition = tableDefinition(tableId)
					local value = Config.RECORD_RUN_TABLE_POINTS[tableId] or 100
					-- A small physical score plaque is more legible than a BillboardGui at
					-- shallow launcher-camera angles and never scales into a giant speech bubble.
					local tag = Instance.new("Part")
					tag.Name = "RecordValue"
					tag.Size = Vector3.new(4.6, 1.45, 0.14)
					tag.Color = COLORS.darkRed
					tag.Material = Enum.Material.SmoothPlastic
					tag.Anchored = true
					tag.CanCollide = false
					tag.CanQuery = false
					tag.CanTouch = false
					tag.CastShadow = false
					local position = top.Position + Vector3.new(0, 3.25, 0)
					tag.CFrame = CFrame.lookAt(position, Vector3.new(0, position.Y, 74))
					tag.Parent = Workspace
					local surface = Instance.new("SurfaceGui")
					surface.Name = "ScoreFace"
					surface.Face = Enum.NormalId.Front
					surface.CanvasSize = Vector2.new(460, 145)
					surface.AlwaysOnTop = true
					surface.LightInfluence = 0
					surface.Adornee = tag
					surface.Parent = tag
					local label = makeLabel(surface, "Label", string.format("%d PTS", value), UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), 70)
					label.BackgroundTransparency = 0
					label.BackgroundColor3 = COLORS.darkRed
					label.TextColor3 = Color3.new(1, 1, 1)
					label.TextStrokeColor3 = definition.color
					label.TextStrokeTransparency = 0.4
					addStroke(label, definition.color, 7)
					table.insert(recordTargetBillboards, tag)
				end
			end
		end
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

local dialogueToken = 0
local function hideCustomerDialogue(immediate: boolean?)
	dialogueToken += 1
	local token = dialogueToken
	if immediate or not dialogueCard.Visible then
		dialogueCard.Visible = false
		return
	end
	local tween = TweenService:Create(dialogueCard, TweenInfo.new(0.2), { BackgroundTransparency = 1 })
	for _, item in dialogueCard:GetDescendants() do
		if item:IsA("TextLabel") or item:IsA("TextButton") then
			TweenService:Create(item, TweenInfo.new(0.18), { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
		elseif item:IsA("UIStroke") then
			TweenService:Create(item, TweenInfo.new(0.18), { Transparency = 1 }):Play()
		end
	end
	tween:Play()
	tween.Completed:Once(function()
		if token == dialogueToken then
			dialogueCard.Visible = false
		end
	end)
end

local function showCustomerDialogue(payload)
	dialogueToken += 1
	local token = dialogueToken
	local name = payload.name or "Customer"
	local line = payload.line or "A hot cheese pizza would be perfect."
	local textWidth = UserInputService.TouchEnabled and 222 or 262
	local textSize = UserInputService.TouchEnabled and 14 or 16
	local bounds = TextService:GetTextSize(line, textSize, Enum.Font.GothamMedium, Vector2.new(textWidth, 500))
	local cardHeight = math.max(UserInputService.TouchEnabled and 104 or 110, 70 + bounds.Y)
	dialogueCard.Size = UDim2.fromOffset(UserInputService.TouchEnabled and 320 or 360, cardHeight)
	dialogueText.Size = UDim2.new(1, -98, 0, bounds.Y + 4)
	dialoguePortrait.Text = string.upper(string.sub(name, 1, 1))
	dialoguePortrait.BackgroundColor3 = payload.color or COLORS.red
	dialogueName.Text = string.upper(name)
	dialogueMood.Text = string.format("%s  -  %s", payload.mood or "HUNGRY", payload.patience or "HAPPY")
	dialogueText.Text = line
	dialogueCard.BackgroundTransparency = 1
	dialoguePortrait.BackgroundTransparency = 1
	dialogueClose.BackgroundTransparency = 1
	for _, label in { dialoguePortrait, dialogueName, dialogueMood, dialogueText, dialogueClose } do
		label.TextTransparency = 1
	end
	local border = dialogueCard:FindFirstChildOfClass("UIStroke")
	if border then border.Transparency = 1 end
	dialogueCard.Visible = true
	TweenService:Create(dialogueCard, TweenInfo.new(0.22), { BackgroundTransparency = 0.03 }):Play()
	TweenService:Create(dialoguePortrait, TweenInfo.new(0.2), { TextTransparency = 0, BackgroundTransparency = 0 }):Play()
	TweenService:Create(dialogueClose, TweenInfo.new(0.2), { TextTransparency = 0, BackgroundTransparency = 0 }):Play()
	for _, label in { dialogueName, dialogueMood, dialogueText } do
		TweenService:Create(label, TweenInfo.new(0.2), { TextTransparency = 0 }):Play()
	end
	for _, descendant in dialogueCard:GetDescendants() do
		if descendant:IsA("UIStroke") then
			TweenService:Create(descendant, TweenInfo.new(0.2), { Transparency = 0.05 }):Play()
		end
	end
	task.delay(4.5, function()
		if token == dialogueToken then
			hideCustomerDialogue(false)
		end
	end)
end

dialogueClose.Activated:Connect(function()
	hideCustomerDialogue(false)
end)

local eventBannerToken = 0
local function showEventBanner(payload)
	eventBannerToken += 1
	local token = eventBannerToken
	eventIcon.Text = payload.icon or "!"
	eventTitle.Text = payload.title or "SHIFT EVENT"
	eventDetail.Text = payload.description or payload.detail or payload.message or "Keep serving!"
	eventBanner.BackgroundTransparency = 1
	local targetPosition = UserInputService.TouchEnabled and UDim2.new(1, -10, 0, 148) or UDim2.new(1, -18, 0, 212)
	eventBanner.Position = targetPosition + UDim2.fromOffset(18, 0)
	for _, label in { eventIcon, eventTitle, eventDetail } do label.TextTransparency = 1 end
	local border = eventBanner:FindFirstChildOfClass("UIStroke")
	if border then border.Transparency = 1 end
	eventBanner.Visible = true
	TweenService:Create(eventBanner, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = targetPosition, BackgroundTransparency = 0.04,
	}):Play()
	for _, label in { eventIcon, eventTitle, eventDetail } do
		TweenService:Create(label, TweenInfo.new(0.18), { TextTransparency = 0 }):Play()
	end
	if border then TweenService:Create(border, TweenInfo.new(0.18), { Transparency = 0.05 }):Play() end
	task.delay(3.4, function()
		if token ~= eventBannerToken then return end
		local tween = TweenService:Create(eventBanner, TweenInfo.new(0.22), { BackgroundTransparency = 1 })
		for _, label in { eventIcon, eventTitle, eventDetail } do
			TweenService:Create(label, TweenInfo.new(0.18), { TextTransparency = 1 }):Play()
		end
		if border then TweenService:Create(border, TweenInfo.new(0.18), { Transparency = 1 }):Play() end
		tween:Play()
		tween.Completed:Wait()
		if token == eventBannerToken then eventBanner.Visible = false end
	end)
end

local roundBannerToken = 0
local function showRoundComplete(payload)
	roundBannerToken += 1
	local token = roundBannerToken
	roundOverlayTitle.Text = string.format("ROUND %d CLEARED!", payload.completedRound or state.round)
	roundOverlayDetail.Text = string.format("%s  -  +%d COINS  -  NEXT: %s", payload.completedRoundName or "GREAT WORK", payload.roundReward or 0, state.roundName or "MORE ORDERS")
	local targetPosition = UserInputService.TouchEnabled and UDim2.new(0.5, 0, 0, 84) or UDim2.new(0.5, 0, 0, 126)
	roundOverlay.Position = targetPosition - UDim2.fromOffset(0, 18)
	roundOverlay.BackgroundTransparency = 1
	roundOverlayTitle.TextTransparency = 1
	roundOverlayDetail.TextTransparency = 1
	local border = roundOverlay:FindFirstChildOfClass("UIStroke")
	if border then
		border.Transparency = 1
	end
	roundOverlay.Visible = true
	TweenService:Create(roundOverlay, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = targetPosition,
		BackgroundTransparency = 0.04,
	}):Play()
	TweenService:Create(roundOverlayTitle, TweenInfo.new(0.18), { TextTransparency = 0 }):Play()
	TweenService:Create(roundOverlayDetail, TweenInfo.new(0.18), { TextTransparency = 0 }):Play()
	if border then
		TweenService:Create(border, TweenInfo.new(0.18), { Transparency = 0.05 }):Play()
	end
	task.delay(2.15, function()
		if token ~= roundBannerToken then
			return
		end
		local tween = TweenService:Create(roundOverlay, TweenInfo.new(0.25), {
			Position = targetPosition - UDim2.fromOffset(0, 12),
			BackgroundTransparency = 1,
		})
		TweenService:Create(roundOverlayTitle, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
		TweenService:Create(roundOverlayDetail, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
		if border then
			TweenService:Create(border, TweenInfo.new(0.2), { Transparency = 1 }):Play()
		end
		tween:Play()
		tween.Completed:Wait()
		if token == roundBannerToken then
			roundOverlay.Visible = false
		end
	end)
end

local launcherEffectToken = 0
local function playLauncherFire(reloadTime: number?)
	launcherEffectToken += 1
	local token = launcherEffectToken
	local world = Workspace:FindFirstChild("PizzaLaunchWorld")
	local station = world and world:FindFirstChild("LauncherStation")
	local rig = station and station:FindFirstChild("AimRig")
	if not station or not rig then
		return
	end

	for _, descendant in rig:GetDescendants() do
		if descendant:IsA("BasePart") and (descendant.Name == "LoadedPizza" or descendant.Name == "LoadedPepperoni") then
			descendant.LocalTransparencyModifier = 1
		elseif descendant:IsA("ParticleEmitter") then
			if descendant.Name == "FlourPuff" then
				descendant:Emit(10)
			elseif descendant.Name == "CheeseSpark" then
				descendant:Emit(16)
			end
		end
	end

	local flash = rig:FindFirstChild("CosmeticMuzzleFlash", true)
	if flash and flash:IsA("BasePart") then
		flash.Transparency = 0.08
		local fireLight = flash:FindFirstChild("FireLight")
		if fireLight and fireLight:IsA("PointLight") then
			fireLight.Enabled = true
		end
		TweenService:Create(flash, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Transparency = 1 }):Play()
		task.delay(0.12, function()
			if fireLight and fireLight:IsA("PointLight") then
				fireLight.Enabled = false
			end
		end)
	end

	local ovenGlow = station:FindFirstChild("OvenGlow")
	local ovenLight = ovenGlow and ovenGlow:FindFirstChildOfClass("PointLight")
	if ovenLight then
		ovenLight.Brightness = 4.8
		local restingBrightness = 2.3 + (state.upgrades and state.upgrades.power or 0) * 0.6
		TweenService:Create(ovenLight, TweenInfo.new(0.3), { Brightness = restingBrightness }):Play()
	end
	local feedOven = station:FindFirstChild("PizzaFeedOven")
	local steam = feedOven and feedOven:FindFirstChild("WarmOvenSteam")
	if steam and steam:IsA("Smoke") then
		steam.Opacity = 0.5
		task.delay(0.3, function()
			if steam.Parent then
				steam.Opacity = 0.24
			end
		end)
	end

	task.delay(math.max(0.18, (reloadTime or 0.55) * 0.72), function()
		if token ~= launcherEffectToken or not rig.Parent then
			return
		end
		for _, descendant in rig:GetDescendants() do
			if descendant:IsA("BasePart") and (descendant.Name == "LoadedPizza" or descendant.Name == "LoadedPepperoni") then
				descendant.LocalTransparencyModifier = 0
			end
		end
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

restoreTutorialAppearance = function()
	tutorial.BackgroundTransparency = 0.03
	for _, descendant in tutorial:GetDescendants() do
		if descendant:IsA("TextLabel") then
			descendant.TextTransparency = 0
		elseif descendant:IsA("UIStroke") then
			descendant.Transparency = 0.05
		end
	end
end

-- Client counterpart to the server's idempotent launcher cleanup.  Input and
-- camera state never survive a mode transition, respawn, cancelled run, or the
-- Record Run results handoff.
local function resetLauncherInput()
	charging = false
	activeFireInput = nil
	ready = true
	reloadReadyAt = 0
	charge = 0.34
	aimYaw = 0
	aimPitch = (Config.DEFAULT_PITCH - Config.MIN_PITCH) / (Config.MAX_PITCH - Config.MIN_PITCH)
	table.clear(keyboardHeld)
	table.clear(touchHeld)
	shakeUntil = 0
	shakeStrength = 0
	fireButton.Text = "HOLD\nLAUNCH"
	fireButton.BackgroundColor3 = COLORS.red
end

local function applyMode()
	operating = state.mode == "launcher"
	if operating then
		hideCustomerDialogue(true)
	end
	local runStatus = recordStatus()
	local recordSession = runStatus ~= "idle"
	shopPanel.Visible = false
	shopToggle.Text = "UPGRADES"
	controls.Visible = operating and (not recordSession or runStatus == "countdown" or runStatus == "running")
	touchAimPad.Visible = operating and UserInputService.TouchEnabled
	exitButton.Visible = operating
	walkHint.Visible = not operating
	setMovementLocked(operating)

	if operating then
		onboardingReachedLauncher = true
		setPizzaTrailVisible(false, false)
		if onboardingHighlight then onboardingHighlight.Enabled = false end
		if not onboardingCompleted or onboardingReplayActive then
			showFirstPizzaHint()
		else
			tutorial.Visible = false
		end
	else
		resetLauncherInput()
		controls.Visible = false
		touchAimPad.Visible = false
		exitButton.Visible = false
		tutorial.Visible = false
		if not onboardingCompleted or onboardingReplayActive then
			beginPizzaTrail(onboardingReplayActive)
		else
			onboardingReachedLauncher = false
			setPizzaTrailVisible(false, true)
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
	updateRecordUI()
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
	local status = recordStatus()
	if status ~= "idle" and status ~= "running" then
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
	-- The first-pizza card waits for the server-accepted `launched` event so a
	-- rejected input can never falsely complete onboarding.
end

shopToggle.Activated:Connect(function()
	shopPanel.Visible = not shopPanel.Visible
	shopToggle.Text = shopPanel.Visible and "CLOSE" or "UPGRADES"
	controls.Visible = operating and not shopPanel.Visible
	touchAimPad.Visible = operating and UserInputService.TouchEnabled and not shopPanel.Visible
	exitButton.Visible = operating and not shopPanel.Visible
end)
recordContinue.Activated:Connect(function()
	modeRemote:FireServer("walk")
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
	state.recordRun = state.recordRun or { status = "idle", personalBest = 0, score = 0, combo = 0, multiplier = 1 }
	coinsLabel.Text = string.format("COINS  %d", state.coins or 0)
	comboLabel.Text = string.format("COMBO  x%d", state.combo or 0)
	local eventSuffix = state.shiftEvent and string.format("  -  EVENT %s", state.shiftEvent.icon or "!") or ""
	roundTitle.Text = string.format("ROUND %d • %s%s", state.round or 1, state.roundName or "FIRST ORDERS", eventSuffix)
	targetLabel.Text = "SERVE ANY HUNGRY CUSTOMER"
	progressFill.Size = UDim2.fromScale(math.clamp((state.roundProgress or 0) / math.max(state.roundGoal or 1, 1), 0, 1), 1)
	roundCard.BackgroundColor3 = state.roundColor or COLORS.green
	updateShop(state.upgrades)
	if changedMode then
		applyMode()
	else
		updateRecordUI()
		updateTargetVisuals()
	end
	if newState.event == "launcherReset" then
		resetLauncherInput()
		applyMode()
	end

	if state.event == "launched" then
		local reloadTime = state.payload and state.payload.reloadTime or Config.RELOAD_TIME
		reloadReadyAt = os.clock() + reloadTime
		playLauncherFire(reloadTime)
		if not onboardingCompleted or onboardingReplayActive then
			onboardingCompleted = true
			onboardingReplayActive = false
			onboardingReachedLauncher = false
			setPizzaTrailVisible(false, true)
			if onboardingHighlight then onboardingHighlight.Enabled = false end
			TweenService:Create(tutorial, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
			for _, descendant in tutorial:GetDescendants() do
				if descendant:IsA("TextLabel") then
					TweenService:Create(descendant, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
				elseif descendant:IsA("UIStroke") then
					TweenService:Create(descendant, TweenInfo.new(0.2), { Transparency = 1 }):Play()
				end
			end
			task.delay(0.26, function() tutorial.Visible = false end)
			showEventBanner({ title = "YOU'RE COOKING!", icon = "OK", detail = "Serve hungry customers for coins." })
		end
	elseif state.event == "shotResult" and state.payload then
		local payload = state.payload
		local detail
		if payload.recordRun then
			if payload.recordPoints and payload.recordPoints > 0 then
				detail = string.format("+%d POINTS  -  COMBO %d  x%.2f", payload.recordPoints, payload.recordCombo or 0, payload.recordMultiplier or 1)
				if payload.recordComboMilestone then
					detail ..= "\nMULTIPLIER UP - THE ROOM CHEERS!"
				end
				shakeStrength = payload.result == "PERFECT!" and 1.15 or 0.65
			else
				detail = "COMBO RESET - NEXT PIZZA!"
				shakeStrength = 0.75
			end
			shakeUntil = os.clock() + 0.28
		elseif payload.coinsEarned and payload.coinsEarned > 0 then
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
			if payload.tipBonus and payload.tipBonus > 0 then
				detail ..= string.format("  -  BIGGER TIPS +%d", payload.tipBonus)
			end
			if payload.eventMessage then
				detail ..= "\n" .. payload.eventMessage
			end
			shakeStrength = payload.result == "PERFECT!" and 1.15 or 0.65
			if payload.comboMilestone then
				shakeStrength = 1.4
			end
			shakeUntil = os.clock() + 0.34
		else
			detail = payload.comboSaved and "COMBO SAVED - the critic only skips the bonus!" or "Quick reload — give it another whirl!"
			if payload.eventMessage then detail ..= "\n" .. payload.eventMessage end
			shakeStrength = 0.85
			shakeUntil = os.clock() + 0.28
		end
		if not payload.recordRun or recordStatus() == "running" then
			showFeedback(payload.result or "PIZZA!", payload.color or COLORS.yellow, detail)
		end
		if payload.roundComplete then
			task.delay(0.45, function()
				showRoundComplete(payload)
			end)
		end
		if payload.shiftEventStarted then
			showEventBanner(payload.shiftEventStarted)
		elseif payload.shiftEventEnded and payload.eventMessage then
			showEventBanner({ title = payload.shiftEventEnded.title or "SHIFT EVENT", icon = "OK", detail = payload.eventMessage })
		end
		task.delay(payload.reloadDelay or 0.35, function()
			local status = recordStatus()
			ready = status == "idle" or status == "running"
			fireButton.Text = "HOLD\nLAUNCH"
			fireButton.BackgroundColor3 = COLORS.red
		end)
	elseif state.event == "recordCountdown" then
		ready = true
		charging = false
		showFeedback("RECORD RUN!", COLORS.yellow, "Far tables score more - keep the combo alive")
	elseif state.event == "recordStarted" then
		ready = true
		showFeedback("LAUNCH!", COLORS.green, "60 seconds - hit the glowing order")
	elseif state.event == "recordEnding" then
		ready = false
		charging = false
		fireButton.Text = "TIME!"
	elseif state.event == "recordFinished" then
		ready = false
		charging = false
	elseif state.event == "purchaseResult" and state.payload then
		if state.payload.success then
			showEventBanner({ title = state.payload.result, icon = "UP", detail = state.payload.changeMessage or state.payload.effect or "Upgrade applied now!" })
		else
			showFeedback(state.payload.result, COLORS.orange, "Deliver more pizzas!")
		end
	elseif state.event == "customerDialogue" and state.payload then
		showCustomerDialogue(state.payload)
	elseif state.event == "shiftEventStarted" and state.payload then
		showEventBanner(state.payload)
	elseif state.event == "shiftEventEnded" and state.payload then
		showEventBanner({ title = state.payload.title or "SHIFT EVENT", icon = "OK", detail = state.payload.detail })
	elseif state.event == "modeChanged" and state.payload then
		if onboardingCompleted and not onboardingReplayActive then
			showFeedback(state.payload.result or (operating and "READY!" or "LET'S WALK!"), operating and COLORS.green or COLORS.yellow,
				operating and "Aim for the glowing delivery plate" or "Explore, greet customers, or check the register")
		end
	elseif state.event == "notice" and state.payload then
		showFeedback(state.payload.result or "PIZZA PLACE", state.payload.color or COLORS.yellow, state.payload.detail)
	elseif state.event == "welcome" then
		beginPizzaTrail(false)
	end
end)

RunService:BindToRenderStep("PizzaLaunchRender", Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
	updatePizzaTrail()
	if not operating then
		return
	end
	local run = state.recordRun or { status = "idle" }
	local status = run.status or "idle"
	if status == "countdown" then
		local remaining = math.max(1, math.ceil((run.countdownEndsAt or 0) - Workspace:GetServerTimeNow()))
		countdownLabel.Text = tostring(remaining)
		countdownLabel.Visible = true
		recordTimer.Text = "1:00"
		recordTimer.TextColor3 = Color3.new(1, 1, 1)
	elseif status == "running" then
		local remaining = math.max(0, (run.endsAt or 0) - Workspace:GetServerTimeNow())
		local wholeSeconds = math.ceil(remaining)
		recordTimer.Text = wholeSeconds >= 60 and "1:00" or string.format("0:%02d", wholeSeconds)
		recordTimer.TextColor3 = remaining <= 10 and COLORS.orange or Color3.new(1, 1, 1)
		countdownLabel.Visible = false
	elseif status == "saving" or status == "finished" then
		recordTimer.Text = "0:00"
		countdownLabel.Visible = false
	else
		countdownLabel.Visible = false
	end
	if status ~= "idle" then
		recordTitle.Text = "RECORD RUN  -  CHOOSE A GLOWING TABLE"
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
	local powerLevel = status ~= "idle" and 0 or (state.upgrades and state.upgrades.power or 0)
	powerText.Text = string.format("POWER  %d%%  -  RANGE +%d%%", math.floor(charge * 100 + 0.5), powerLevel * 4)
	local pitchDegrees = math.deg(Config.MIN_PITCH + aimPitch * (Config.MAX_PITCH - Config.MIN_PITCH))
	local arcName = pitchDegrees < 37 and "LOW" or (pitchDegrees < 49 and "MEDIUM" or "HIGH")
	arcText.Text = "ARC  " .. arcName

	local direction = currentDirection()
	local speed = Config.speedFromCharge(charge, powerLevel)
	if not ready and reloadReadyAt > os.clock() and status ~= "saving" and status ~= "finished" then
		fireButton.Text = string.format("RELOAD\n%.1fs", reloadReadyAt - os.clock())
	end
	local landing, flightTime = Config.landingPoint(direction, speed, 6.85)
	local missDistance = math.huge
	local activeRound = Config.ROUNDS[math.clamp(state.round or 1, 1, #Config.ROUNDS)]
	local activeIds = {}
	for _, tableId in activeRound.tables do activeIds[tableId] = true end
	for _, candidate in Config.TABLES do
		local model = findTargetModel(candidate.id)
		local eligible = model and model:GetAttribute("DeliveryAvailable") == true and (status ~= "idle" or activeIds[candidate.id])
		if eligible then
			local distance = Vector3.new(landing.X - candidate.position.X, 0, landing.Z - candidate.position.Z).Magnitude
			missDistance = math.min(missDistance, distance)
		end
	end
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
	if station then
		local crankRig = station:FindFirstChild("CosmeticCrankRig")
		local crankBase = crankRig and crankRig:GetAttribute("BasePivot")
		if crankRig and crankRig:IsA("Model") and typeof(crankBase) == "CFrame" then
			local motion = math.rad(charge * 58 + (charging and math.sin(os.clock() * 12) * 3 or 0))
			crankRig:PivotTo(crankBase * CFrame.Angles(0, 0, motion))
		end
		for _, item in station:GetChildren() do
			if item:IsA("BasePart") and item.Name == "FeedRoller" then
				local rollerBase = item:GetAttribute("CosmeticBaseCFrame")
				if typeof(rollerBase) == "CFrame" then
					item.CFrame = rollerBase * CFrame.Angles((os.clock() * (ready and 0.65 or 4.2)) % (math.pi * 2), 0, 0)
				end
			end
		end
		local gauge = station:FindFirstChild("PressureGauge")
		local readout = gauge and gauge:FindFirstChild("PressureReadout")
		local gaugeLabel = readout and readout:FindFirstChild("Label")
		if gaugeLabel and gaugeLabel:IsA("TextLabel") then
			gaugeLabel.Text = string.format("POWER\n%d%%", math.floor(charge * 100 + 0.5))
			gaugeLabel.TextColor3 = charge >= 0.8 and COLORS.red or COLORS.ink
		end
	end
end)

task.defer(function()
	local world = Workspace:WaitForChild("PizzaLaunchWorld", 10)
	if world then
		ensurePizzaTrailWorld()
		if not onboardingCompleted then
			beginPizzaTrail(false)
		end
		local function watchTable(tableModel)
			if tableModel:IsA("Model") and tableModel:GetAttribute("TableId") then
				table.insert(tableAvailabilityConnections, tableModel:GetAttributeChangedSignal("DeliveryAvailable"):Connect(function()
					updateTargetVisuals()
				end))
			end
		end
		for _, tableModel in world:GetChildren() do
			watchTable(tableModel)
		end
		world.ChildAdded:Connect(function(child)
			watchTable(child)
			task.defer(updateTargetVisuals)
		end)
		applyMode()
		updateTargetVisuals()
		for _, delaySeconds in { 0.75, 1.5, 2.5 } do task.delay(delaySeconds, updateTargetVisuals) end
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
		if not onboardingCompleted then
			task.defer(function()
				beginPizzaTrail(false)
			end)
		end
	end
end)
