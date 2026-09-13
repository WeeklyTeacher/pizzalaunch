local UITheme = require(script.Parent.UITheme)
local UIConstruction = {}

function UIConstruction.build(context)
	local playerGui, UserInputService, purchaseRemote = context.playerGui, context.UserInputService, context.purchaseRemote
	local Config, charge = context.Config, context.charge
	local COLORS = UITheme.colors
	local addCorner, addStroke, makeLabel, makeButton = UITheme.addCorner, UITheme.addStroke, UITheme.makeLabel, UITheme.makeButton
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
local recordContinue = makeButton(recordSummary, "Continue", "CHOOSE MODE", UDim2.fromOffset(160, 52), UDim2.new(1, -174, 0, 14), COLORS.green)
recordContinue.TextSize = 13
recordContinue.ZIndex = 12

local modeSelection = Instance.new("Frame")
modeSelection.Name = "LauncherModeSelection"
modeSelection.AnchorPoint = Vector2.new(0.5, 0.5)
modeSelection.Size = UDim2.fromOffset(650, 286)
modeSelection.Position = UDim2.fromScale(0.5, 0.5)
modeSelection.BackgroundColor3 = COLORS.cream
modeSelection.Visible = false
modeSelection.ZIndex = 20
modeSelection.Parent = gui
addCorner(modeSelection, 22)
addStroke(modeSelection, COLORS.darkRed, 4)
local modeSelectionTitle = makeLabel(modeSelection, "Title", "CHOOSE HOW TO PLAY", UDim2.new(1, -76, 0, 38), UDim2.fromOffset(20, 12), 27)
modeSelectionTitle.TextColor3 = COLORS.darkRed
modeSelectionTitle.ZIndex = 21
local modeSelectionSubtitle = makeLabel(modeSelection, "Subtitle", "Both modes use the same Pizza Launcher.", UDim2.new(1, -40, 0, 26), UDim2.fromOffset(20, 49), 15)
modeSelectionSubtitle.TextColor3 = COLORS.ink
modeSelectionSubtitle.ZIndex = 21
local modeSelectionExit = makeButton(modeSelection, "Exit", "X", UDim2.fromOffset(42, 42), UDim2.new(1, -54, 0, 12), COLORS.darkRed)
modeSelectionExit.TextSize = 16
modeSelectionExit.ZIndex = 23

local function makeModeChoice(name: string, titleText: string, descriptionText: string, actionText: string, position: UDim2, color: Color3)
	local button = makeButton(modeSelection, name, "", UDim2.fromOffset(292, 176), position, color)
	button.ZIndex = 21
	button.Selectable = true
	local title = makeLabel(button, "Title", titleText, UDim2.new(1, -24, 0, 52), UDim2.fromOffset(12, 14), 23)
	title.TextColor3 = name == "FreePlay" and COLORS.ink or Color3.new(1, 1, 1)
	title.ZIndex = 22
	local description = makeLabel(button, "Description", descriptionText, UDim2.new(1, -28, 0, 54), UDim2.fromOffset(14, 70), 15)
	description.Font = Enum.Font.GothamMedium
	description.TextColor3 = name == "FreePlay" and COLORS.ink or COLORS.cream
	description.ZIndex = 22
	local action = makeLabel(button, "Action", actionText, UDim2.new(1, -28, 0, 34), UDim2.fromOffset(14, 132), 15)
	action.BackgroundColor3 = name == "FreePlay" and COLORS.darkRed or COLORS.yellow
	action.BackgroundTransparency = 0
	action.TextColor3 = name == "FreePlay" and Color3.new(1, 1, 1) or COLORS.darkRed
	action.ZIndex = 22
	addCorner(action, 10)
	return button
end

local freePlayChoice = makeModeChoice("FreePlay", "FREE PLAY", "Practice launches with no time limit.", "START FREE PLAY", UDim2.fromOffset(20, 88), COLORS.yellow)
local recordRunChoice = makeModeChoice("RecordRun", "1-MINUTE\nRECORD RUN", "Score as many points as you can in 60 seconds.", "START RECORD RUN", UDim2.fromOffset(338, 88), COLORS.red)
freePlayChoice.NextSelectionRight = recordRunChoice
recordRunChoice.NextSelectionLeft = freePlayChoice
modeSelectionExit.NextSelectionDown = freePlayChoice

local changeModeButton = makeButton(gui, "ChangeMode", "CHANGE MODE", UDim2.fromOffset(150, 44), UDim2.new(1, -168, 0, 138), COLORS.yellow)
changeModeButton.TextColor3 = COLORS.ink
changeModeButton.TextSize = 14
changeModeButton.Font = Enum.Font.GothamBold
changeModeButton.TextStrokeTransparency = 1
changeModeButton.Visible = false

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
-- Persistent navigation must have a deterministic first frame. Launcher and
-- onboarding state may temporarily cover it with the mode picker, but never
-- decide whether the upgrades system exists for this player.
shopToggle.Visible = true
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
local shopTitle = makeLabel(shopPanel, "Title", "UPGRADE THE PIZZA LAUNCHER", UDim2.new(1, -24, 0, 30), UDim2.fromOffset(12, 8), 19)
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
	exitButton.Text = "EXIT"
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
	recordContinue.Text = "CHOOSE MODE"
	recordContinue.TextSize = 9
	modeSelection.Size = UDim2.fromOffset(560, 246)
	modeSelectionTitle.Size = UDim2.new(1, -66, 0, 30)
	modeSelectionTitle.Position = UDim2.fromOffset(16, 8)
	modeSelectionTitle.TextSize = 21
	modeSelectionSubtitle.Position = UDim2.fromOffset(16, 38)
	modeSelectionSubtitle.TextSize = 12
	modeSelectionExit.Size = UDim2.fromOffset(38, 38)
	modeSelectionExit.Position = UDim2.new(1, -46, 0, 8)
	freePlayChoice.Size = UDim2.fromOffset(250, 154)
	freePlayChoice.Position = UDim2.fromOffset(18, 76)
	recordRunChoice.Size = UDim2.fromOffset(250, 154)
	recordRunChoice.Position = UDim2.fromOffset(292, 76)
	for _, choice in { freePlayChoice, recordRunChoice } do
		local title = choice:FindFirstChild("Title")
		local description = choice:FindFirstChild("Description")
		local action = choice:FindFirstChild("Action")
		if title and title:IsA("TextLabel") then
			title.Size = UDim2.new(1, -20, 0, 43)
			title.Position = UDim2.fromOffset(10, 8)
			title.TextSize = 18
		end
		if description and description:IsA("TextLabel") then
			description.Size = UDim2.new(1, -22, 0, 47)
			description.Position = UDim2.fromOffset(11, 54)
			description.TextSize = 12
		end
		if action and action:IsA("TextLabel") then
			action.Size = UDim2.new(1, -22, 0, 32)
			action.Position = UDim2.fromOffset(11, 111)
			action.TextSize = 12
		end
	end
	changeModeButton.Size = UDim2.fromOffset(108, 38)
	changeModeButton.Position = UDim2.new(1, -126, 0, 104)
	changeModeButton.TextSize = 11

end

local walkHint = makeLabel(gui, "WalkHint", "FOLLOW THE PIZZA ARROWS  •  USE THE LAUNCHER PAD", UDim2.fromOffset(500, 48), UDim2.new(0.5, -250, 1, -68), 15)
walkHint.BackgroundTransparency = 0.05
walkHint.BackgroundColor3 = COLORS.cream
walkHint.TextColor3 = COLORS.red
addCorner(walkHint, 16)
addStroke(walkHint, COLORS.darkRed, 2)
if UserInputService.TouchEnabled then
	walkHint.Size = UDim2.fromOffset(390, 38)
	walkHint.Position = UDim2.new(0.5, -195, 1, -48)
	walkHint.Text = "FOLLOW THE PIZZA ARROWS • TAP USE LAUNCHER"
	walkHint.TextSize = 11
end


return { gui = gui, screenTint = screenTint, stats = stats, coinsLabel = coinsLabel, comboLabel = comboLabel, roundCard = roundCard, roundTitle = roundTitle, targetLabel = targetLabel, progressBack = progressBack, progressFill = progressFill, tutorial = tutorial, tutorialTitle = tutorialTitle, tutorialText = tutorialText, feedback = feedback, dialogueCard = dialogueCard, dialoguePortrait = dialoguePortrait, dialogueName = dialogueName, dialogueMood = dialogueMood, dialogueText = dialogueText, dialogueClose = dialogueClose, eventBanner = eventBanner, eventIcon = eventIcon, eventTitle = eventTitle, eventDetail = eventDetail, roundOverlay = roundOverlay, roundOverlayTitle = roundOverlayTitle, roundOverlayDetail = roundOverlayDetail, recordHud = recordHud, recordTitle = recordTitle, recordTimer = recordTimer, recordScore = recordScore, recordCombo = recordCombo, recordBest = recordBest, countdownLabel = countdownLabel, recordSummary = recordSummary, recordSummaryTitle = recordSummaryTitle, recordSummaryDetail = recordSummaryDetail, recordSummaryHint = recordSummaryHint, recordContinue = recordContinue, modeSelection = modeSelection, modeSelectionTitle = modeSelectionTitle, modeSelectionSubtitle = modeSelectionSubtitle, modeSelectionExit = modeSelectionExit, freePlayChoice = freePlayChoice, recordRunChoice = recordRunChoice, changeModeButton = changeModeButton, controls = controls, controlsConstraint = controlsConstraint, powerText = powerText, arcText = arcText, powerBack = powerBack, powerFill = powerFill, powerGradient = powerGradient, helpText = helpText, fireButton = fireButton, shopToggle = shopToggle, exitButton = exitButton, shopPanel = shopPanel, shopTitle = shopTitle, shopSubtitle = shopSubtitle, shopCoins = shopCoins, shopScroll = shopScroll, upgradeCards = upgradeCards, upgradeOrder = upgradeOrder, touchAimPad = touchAimPad, aimButtons = aimButtons, walkHint = walkHint }
end

return UIConstruction
