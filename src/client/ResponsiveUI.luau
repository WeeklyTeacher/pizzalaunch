local Layout = require(script.Parent.ResponsiveLayout)
local ResponsiveUI = {}

local function box(item, width, height, x, y)
	item.Size = UDim2.fromOffset(width, height)
	item.Position = UDim2.fromOffset(x, y)
end

function ResponsiveUI.apply(ui, layout)
	ui.layout = layout
	local compact, margin = layout.compact, layout.margin
	local w, h = layout.width, layout.height
	box(ui.stats, layout.statsWidth, 44, margin, margin)
	box(ui.coinsLabel, layout.statsWidth - 12, 24, 6, 1)
	ui.coinsLabel.TextSize = compact and 17 or 20
	box(ui.comboLabel, layout.statsWidth - 12, 17, 6, 25)
	ui.comboLabel.TextSize = 14
	box(ui.shopToggle, layout.navWidth, 44, w - margin - layout.navWidth, margin)
	ui.shopToggle.TextSize = 15
	box(ui.exitButton, layout.navWidth, 44, w - margin - layout.navWidth, margin + 50)
	ui.exitButton.TextSize = 14
	ui.exitButton.Text = layout.exitText
	box(ui.changeModeButton, layout.navWidth, 44, w - margin - layout.navWidth, margin + 100)
	ui.changeModeButton.TextSize = 14
	ui.roundCard.AnchorPoint = Vector2.new(0.5, 0)
	box(ui.roundCard, layout.topWidth, 70, w / 2, margin)
	box(ui.roundTitle, layout.topWidth - 20, 21, 10, 5)
	ui.roundTitle.TextSize = 14
	box(ui.targetLabel, layout.topWidth - 20, 27, 10, 27)
	ui.targetLabel.TextSize = compact and 16 or 18
	box(ui.progressBack, layout.topWidth - 24, 5, 12, 59)
	local recordWidth = math.min(compact and 346 or 412, w - (layout.navWidth + 2 * margin) * 2)
	recordWidth = math.max(300, recordWidth)
	ui.recordHud.AnchorPoint = Vector2.new(0.5, 0)
	box(ui.recordHud, recordWidth, 84, w / 2, margin)
	box(ui.recordTitle, recordWidth - 16, 18, 8, 4)
	ui.recordTitle.TextSize = 14
	box(ui.recordTimer, 76, 36, 8, 22)
	ui.recordTimer.TextSize = 30
	box(ui.recordScore, 104, 40, 89, 22)
	ui.recordScore.TextSize = 17
	box(ui.recordCombo, recordWidth - 208, 36, 200, 23)
	ui.recordCombo.TextSize = 14
	box(ui.recordBest, recordWidth - 16, 18, 8, 64)
	ui.recordBest.TextSize = 13
	ui.modeSelection.AnchorPoint = Vector2.new(0.5, 0.5)
	box(ui.modeSelection, layout.pickerWidth, layout.pickerHeight, w / 2, h / 2)
	box(ui.modeSelectionTitle, layout.pickerWidth - 74, 30, 18, 12)
	ui.modeSelectionTitle.TextSize = compact and 23 or 27
	box(ui.modeSelectionSubtitle, layout.pickerWidth - 36, 23, 18, 43)
	ui.modeSelectionSubtitle.TextSize = 15
	box(ui.modeSelectionExit, 44, 44, layout.pickerWidth - 54, 10)
	local choiceWidth = (layout.pickerWidth - 48) / 2
	local choiceHeight = layout.pickerHeight - 86
	for index, choice in { ui.freePlayChoice, ui.recordRunChoice } do
		box(choice, choiceWidth, choiceHeight, 16 + (index - 1) * (choiceWidth + 16), 72)
		local title, description, action = choice:FindFirstChild("Title"), choice:FindFirstChild("Description"), choice:FindFirstChild("Action")
		box(title, choiceWidth - 20, compact and 52 or 60, 10, 4)
		title.TextSize = compact and 21 or 25
		box(description, choiceWidth - 24, compact and 42 or 48, 12, compact and 59 or 70)
		description.TextSize = 16
		box(action, choiceWidth - 24, 36, 12, choiceHeight - 46)
		action.TextSize = 15
	end
	ui.controls.AnchorPoint = Vector2.new(1, 1)
	box(ui.controls, layout.controlsWidth, layout.controlsHeight, w - margin, h - margin)
	ui.controlsConstraint.MinSize = Vector2.new(layout.controlsWidth, layout.controlsHeight)
	ui.controlsConstraint.MaxSize = ui.controlsConstraint.MinSize
	local contentWidth = layout.controlsWidth - layout.fireWidth - 36
	box(ui.powerText, contentWidth, 24, 12, 9)
	ui.powerText.TextSize = compact and 16 or 18
	box(ui.powerBack, contentWidth, 12, 12, 38)
	box(ui.arcText, contentWidth, 19, 12, 53)
	ui.arcText.TextSize = 14
	box(ui.helpText, contentWidth, 21, 12, layout.controlsHeight - 26)
	ui.helpText.TextSize = compact and 12 or 14
	ui.helpText.Text = layout.helpText
	box(ui.fireButton, layout.fireWidth, layout.fireHeight, layout.controlsWidth - layout.fireWidth - 12, (layout.controlsHeight - layout.fireHeight) / 2)
	ui.fireButton.TextSize = compact and 19 or 23
	ui.fireIdleSize = UDim2.fromOffset(layout.fireWidth, layout.fireHeight)
	ui.fireChargeSize = UDim2.fromOffset(layout.fireWidth + 4, layout.fireHeight + 4)
	ui.touchAimPad.AnchorPoint = Vector2.new(0, 1)
	box(ui.touchAimPad, 140, 108, margin, h - margin)
	box(ui.aimButtons.up, 44, 44, 48, 4)
	box(ui.aimButtons.down, 44, 44, 48, 56)
	box(ui.aimButtons.left, 44, 44, 0, 56)
	box(ui.aimButtons.right, 44, 44, 96, 56)
	ui.touchAimPad.BackgroundTransparency = 1
	local aimBorder = ui.touchAimPad:FindFirstChildOfClass("UIStroke")
	if aimBorder then aimBorder.Transparency = 1 end
	ui.recordSummary.AnchorPoint = Vector2.new(0.5, 0.5)
	box(ui.recordSummary, layout.resultWidth, layout.resultHeight, w / 2, h / 2)
	box(ui.recordSummaryTitle, layout.resultWidth - 32, 34, 16, 12)
	ui.recordSummaryTitle.TextSize = 25
	box(ui.recordSummaryDetail, layout.resultWidth - 32, 76, 16, 50)
	ui.recordSummaryDetail.TextSize = 18
	box(ui.recordSummaryHint, layout.resultWidth - 32, 26, 16, 127)
	ui.recordSummaryHint.TextSize = 14
	box(ui.recordContinue, 210, 48, (layout.resultWidth - 210) / 2, layout.resultHeight - 62)
	ui.recordContinue.TextSize = 16
	ui.shopPanel.AnchorPoint = Vector2.new(1, 0)
	box(ui.shopPanel, layout.shopWidth, layout.shopHeight, w - margin, 64)
	box(ui.shopTitle, layout.shopWidth - 28, 26, 14, 10)
	ui.shopTitle.TextSize = 20
	box(ui.shopSubtitle, layout.shopWidth - 28, 22, 14, 38)
	ui.shopSubtitle.TextSize = 14
	ui.shopSubtitle.Text = "SESSION UPGRADES • RESET NEXT VISIT"
	box(ui.shopCoins, layout.shopWidth - 28, 28, 14, 64)
	ui.shopCoins.TextSize = 17
	box(ui.shopScroll, layout.shopWidth - 20, layout.shopHeight - 110, 10, 102)
	ui.shopScroll.CanvasSize = UDim2.fromOffset(0, 456)
	for index, id in ui.upgradeOrder do
		local card = ui.upgradeCards[id]
		box(card.card, layout.shopWidth - 32, 108, 0, (index - 1) * 114)
		box(card.icon, 38, 38, 10, 12)
		box(card.title, layout.shopWidth - 198, 24, 58, 10)
		card.title.TextSize = 16
		box(card.level, layout.shopWidth - 198, 20, 58, 35)
		card.level.TextSize = 13
		box(card.effect, layout.shopWidth - 156, 38, 12, 62)
		card.effect.TextSize = 14
		box(card.action, 112, 76, layout.shopWidth - 158, 16)
		card.action.TextSize = 15
	end
	ui.walkHint.AnchorPoint = Vector2.new(0.5, 1)
	box(ui.walkHint, math.min(460, w - 180), 46, w / 2, h - margin)
	ui.walkHint.TextSize = 16
	ui.tutorial.AnchorPoint = Vector2.zero
	box(ui.tutorial, compact and 214 or 282, 76, margin, compact and 94 or 100)
	box(ui.tutorialTitle, compact and 194 or 262, 23, 10, 6)
	ui.tutorialTitle.TextSize = 14
	box(ui.tutorialText, compact and 194 or 262, 38, 10, 30)
	ui.tutorialText.TextSize = 14
	ui.feedback.AnchorPoint = Vector2.new(0.5, 1)
	box(ui.feedback, layout.feedbackWidth, 64, w / 2, h - layout.controlsHeight - margin - 12)
	ui.feedback.TextSize = compact and 19 or 24
	ui.feedback.TextStrokeTransparency = 1
	ui.feedback.TextColor3 = Color3.fromRGB(62, 50, 40)
	ui.feedbackPosition = ui.feedback.Position
	ui.countdownLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	box(ui.countdownLabel, 180, 120, w / 2, h * 0.42)
	ui.countdownLabel.TextSize = 80
	ui.dialogueCard.AnchorPoint = Vector2.new(0, 0)
	box(ui.dialogueCard, math.min(360, w - margin * 2), 120, margin, 96)
	ui.dialogueText.TextSize = 16
	ui.dialogueMood.TextSize = 13
	box(ui.dialogueClose, 44, 44, ui.dialogueCard.Size.X.Offset - 52, 8)
	ui.eventBanner.AnchorPoint = Vector2.new(0.5, 0)
	box(ui.eventBanner, math.min(350, w - margin * 2), 74, w / 2, compact and 96 or 112)
	ui.eventTitle.TextSize = 17
	ui.eventDetail.TextSize = 14
	ui.eventPosition = ui.eventBanner.Position
	ui.roundOverlay.AnchorPoint = Vector2.new(0.5, 0)
	box(ui.roundOverlay, math.min(410, w - margin * 2), 76, w / 2, compact and 96 or 112)
	ui.roundOverlayTitle.TextSize = 22
	ui.roundOverlayDetail.TextSize = 14
	ui.roundPosition = ui.roundOverlay.Position
end

function ResponsiveUI.new(ui, workspace, inputService)
	local self = {}
	function self.refresh()
		local camera = workspace.CurrentCamera
		local size = ui.safeRoot.AbsoluteSize
		if typeof(size) ~= "Vector2" or size.X <= 0 or size.Y <= 0 then size = camera and camera.ViewportSize or Vector2.new(1024, 720) end
		local kind = Layout.inputKind(inputService.PreferredInput, inputService.TouchEnabled, inputService.KeyboardEnabled)
		local key = string.format("%d:%d:%s", size.X, size.Y, kind)
		if key == self.key then return false end
		self.key = key
		ResponsiveUI.apply(ui, Layout.compute(size.X, size.Y, kind))
		return true
	end
	self.refresh()
	return self
end

return ResponsiveUI
