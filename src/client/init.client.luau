local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local UITheme = require(script.UITheme)
local UIConstruction = require(script.UIConstruction)
local UIPresentation = require(script.UIPresentation)
local Onboarding = require(script.Onboarding)
local Feedback = require(script.Feedback)
local LauncherInputState = require(script.LauncherInputState)
local ClientInput = require(script.ClientInput)
local ClientCamera = require(script.ClientCamera)
local ActivityHUD = require(script.ActivityHUD)
local ResponsiveUI = require(script.ResponsiveUI)
local inputState = LauncherInputState.new((Config.DEFAULT_PITCH - Config.MIN_PITCH) / (Config.MAX_PITCH - Config.MIN_PITCH), Config.CHARGE_TIME)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
playerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor
local remotes = ReplicatedStorage:WaitForChild(Config.REMOTES_FOLDER)
local launchRemote = remotes:WaitForChild(Config.LAUNCH_REMOTE)
local stateRemote = remotes:WaitForChild(Config.STATE_REMOTE)
local purchaseRemote = remotes:WaitForChild(Config.PURCHASE_REMOTE)
local modeRemote = remotes:WaitForChild(Config.MODE_REMOTE)
local activityRemote = remotes:WaitForChild(Config.ACTIVITY_REMOTE)
local takeoutRemote = remotes:WaitForChild(Config.TAKEOUT_REMOTE)
local queueRemote = remotes:WaitForChild(Config.QUEUE_REMOTE)

local COLORS = UITheme.colors
local addCorner, addStroke, makeLabel = UITheme.addCorner, UITheme.addStroke, UITheme.makeLabel
local state = {
	targetId = 1,
	targetCustomer = "Mia",
	round = 1,
	roundProgress = 0,
	roundGoal = 3,
	mode = "walk",
	launcherMode = "none",
	cleanupEpoch = 0,
	upgrades = { tips = 0, assist = 0, reload = 0, power = 0 },
	recordRun = { status = "idle", personalBest = 0, score = 0, combo = 0, multiplier = 1 },
	shiftEvent = nil,
}
local targetHighlight: Highlight? = nil
local yourOrderBillboard: BillboardGui? = nil
local recordTargetBillboards = {}
local tableAvailabilityConnections = {}
local trajectoryParts = {}
local shakeUntil = 0
local shakeStrength = 0
local operating = false
local activityHud
local activityGuidance = false
local restoreTutorialAppearance
local cameraController = ClientCamera.new({ player = player, playerGui = playerGui, Workspace = Workspace, GuiService = GuiService, ContextActionService = ContextActionService, UserInputService = UserInputService })
local uiEpoch = 0
local invalidLeaseEpoch = -1
local uiTweens = {}
local function tweenUI(target, info, properties)
	local tween = TweenService:Create(target, info, properties)
	uiTweens[tween] = true
	tween.Completed:Once(function() uiTweens[tween] = nil end)
	return tween
end
local function cancelUITweens()
	for tween in uiTweens do tween:Cancel() end
	table.clear(uiTweens)
end
local function delayUI(seconds, callback)
	local epoch = uiEpoch
	task.delay(seconds, function() if epoch == uiEpoch then callback() end end)
end

local ui = UIConstruction.build({ playerGui = playerGui, UserInputService = UserInputService, purchaseRemote = purchaseRemote, Config = Config, charge = inputState.charge })
local responsiveUI = ResponsiveUI.new(ui, Workspace, UserInputService)

local screenTint = ui.screenTint
local stats = ui.stats
local coinsLabel = ui.coinsLabel
local comboLabel = ui.comboLabel
local roundCard = ui.roundCard
local roundTitle = ui.roundTitle
local targetLabel = ui.targetLabel
local progressFill = ui.progressFill
local tutorial = ui.tutorial
local feedback = ui.feedback
local recordHud = ui.recordHud
local recordTitle = ui.recordTitle
local recordTimer = ui.recordTimer
local recordScore = ui.recordScore
local recordCombo = ui.recordCombo
local recordBest = ui.recordBest
local countdownLabel = ui.countdownLabel
local recordSummary = ui.recordSummary
local recordSummaryTitle = ui.recordSummaryTitle
local recordSummaryDetail = ui.recordSummaryDetail
local recordSummaryHint = ui.recordSummaryHint
local recordContinue = ui.recordContinue
local modeSelection = ui.modeSelection
local modeSelectionExit = ui.modeSelectionExit
local freePlayChoice = ui.freePlayChoice
local recordRunChoice = ui.recordRunChoice
local changeModeButton = ui.changeModeButton
local controls = ui.controls
local powerText = ui.powerText
local arcText = ui.arcText
local powerFill = ui.powerFill
local shopToggle = ui.shopToggle
local exitButton = ui.exitButton
local shopPanel = ui.shopPanel
local shopCoins = ui.shopCoins
local upgradeCards = ui.upgradeCards
local upgradeOrder = ui.upgradeOrder
local touchAimPad = ui.touchAimPad
local walkHint = ui.walkHint

local onboarding = Onboarding.new({ Workspace = Workspace, UserInputService = UserInputService, TweenService = TweenService, player = player, COLORS = COLORS, ui = ui, isOperating = function() return operating end, getInputKind = function() return ui.layout.inputKind end, restoreTutorialAppearance = function() restoreTutorialAppearance() end })
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
	return Config.directionFromAim(inputState.aimYaw, inputState.aimPitch)
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

local function applyPresentation()
	local view = UIPresentation.select(state, shopPanel.Visible, onboarding.onboardingCompleted)
	local objective = false
	if activityHud then
		activityHud.setContext(operating, view.shop or view.picker)
		objective = activityHud.hasObjective()
	end
	if objective ~= activityGuidance then
		activityGuidance = objective
		if objective then
			onboarding.setPizzaTrailVisible(false, true)
		elseif not operating and not onboarding.onboardingCompleted then
			onboarding.beginPizzaTrail()
		end
	end
	modeSelection.Visible = view.picker
	shopPanel.Visible = view.shop
	shopToggle.Visible = view.upgrades
	shopToggle.Text = view.shop and "CLOSE" or "UPGRADES"
	controls.Visible = view.controls
	touchAimPad.Visible = view.controls and ui.layout.inputKind == "touch"
	if ui.layout.compact or view.shop or view.picker then tutorial.Visible = false end
	exitButton.Visible = view.exit
	walkHint.Visible = view.walking and not objective
	roundCard.Visible = view.round and not objective
	stats.Visible = view.stats
	recordHud.Visible = view.recordHud
	recordSummary.Visible = view.results
	recordContinue.Visible = view.continue
	changeModeButton.Visible = view.changeMode
	if view.shop or view.picker or view.results then
		for _, item in { ui.feedback, ui.dialogueCard, ui.eventBanner, ui.roundOverlay } do item.Visible = false end
	end
	cameraController.setNavigation(view.shop and shopPanel or (view.results and recordSummary or nil),
		view.shop and upgradeCards[upgradeOrder[1]].card or (view.continue and recordContinue or nil), ui.layout.inputKind)
	inputState:setBlocked(view.shop or view.picker)
end

local function updateRecordUI()
	local run = state.recordRun or { status = "idle", score = 0, combo = 0, multiplier = 1, personalBest = 0 }
	local status = run.status or "idle"
	local session = status ~= "idle"
	recordScore.Text = string.format("SCORE\n%d", run.score or 0)
	recordCombo.Text = string.format("COMBO %d\nx%.2f", run.combo or 0, run.multiplier or 1)
	recordBest.Text = string.format("PERSONAL BEST  %d", run.personalBest or 0)
	recordCombo.TextColor3 = (run.combo or 0) >= 4 and COLORS.yellow or COLORS.green

	if session then
		if onboarding.onboardingCompleted then
			tutorial.Visible = false
		end
	end
	if status == "saving" then

		recordSummaryTitle.Text = "TIME!"
		recordSummaryDetail.Text = string.format("FINAL SCORE  %d\nSaving your best score...", run.score or 0)
		recordSummaryHint.Text = "YOUR RESULT IS READY — CHOOSE ANOTHER MODE NEXT"
	elseif status == "finished" then

		if run.madeTopTen and run.rank then
			recordSummaryTitle.Text = string.format("LEGEND!  #%d", run.rank)
		else
			recordSummaryTitle.Text = run.isNewBest and "NEW PERSONAL BEST!" or "RUN COMPLETE!"
		end
		local rankLine = run.madeTopTen and string.format("GLOBAL TOP 10  -  RANK #%d", run.rank) or "GLOBAL TOP 10  -  NOT THIS TIME"
		if not run.globalBoardAvailable then
			rankLine = "GLOBAL RECORDS UNAVAILABLE RIGHT NOW"
		end
		recordSummaryDetail.Text = string.format("FINAL SCORE  %d\nPERSONAL BEST  %d\n%s", run.score or 0, run.personalBest or 0, rankLine)
			recordSummaryHint.Text = run.globalBoardAvailable and "CHOOSE MODE TO PLAY AGAIN" or "Best kept for this session • Choose a mode to play again"
	end
	if not session then
		countdownLabel.Visible = false
	end
	applyPresentation()
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
							descendant.Enabled = isActive and tableModel:GetAttribute("Occupied") ~= false and not descendant:GetAttribute("CustomerProxyFace")
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

local effects = Feedback.new({ Workspace = Workspace, UserInputService = UserInputService, TweenService = TweenService, TextService = TextService, COLORS = COLORS, ui = ui, getState = function() return state end,
	isCovered = function() return shopPanel.Visible or modeSelection.Visible or recordSummary.Visible end })
activityHud = ActivityHUD.new({
	gui = ui.safeRoot, player = player, Workspace = Workspace, UserInputService = UserInputService, GuiService = GuiService,
	getLayout = function() return ui.layout end,
	activityRemote = activityRemote, takeoutRemote = takeoutRemote, queueRemote = queueRemote, exitButton = exitButton,
	onChanged = applyPresentation,
	onEconomy = function(coins, upgrades)
		-- Activity snapshots can refresh this player's wallet and shop. They do
		-- not enter the launcher state handler or rebuild competitive visuals.
		if type(coins) == "number" then state.coins = coins; coinsLabel.Text = string.format("COINS  %d", coins) end
		if type(upgrades) == "table" then state.upgrades = upgrades end
		updateShop(state.upgrades)
	end,
})
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

-- UI epochs invalidate delayed feedback on each lease/policy boundary.
local function resetLauncherInput()
	inputState:reset()
	uiEpoch += 1
	cancelUITweens()
	effects.reset()
	shakeUntil = 0
	shakeStrength = 0
	screenTint.BackgroundTransparency = 1
end

local function applyMode()
	operating = state.mode == "launcher"
	shopPanel.Visible = false
	activityHud.setContext(operating, false)
	cameraController.setMounted(operating)
	local selectingMode = operating and state.launcherMode == "select"
	cameraController.setPicker(modeSelection, freePlayChoice, selectingMode)
	if operating then
		effects.hideCustomerDialogue(true)
		onboarding.onboardingReachedLauncher = true
		onboarding.setPizzaTrailVisible(false, false)
		if onboarding.onboardingHighlight then onboarding.onboardingHighlight.Enabled = false end
		if inputState.aimable and not onboarding.onboardingCompleted then onboarding.showFirstPizzaHint() else tutorial.Visible = false end
	else
		tutorial.Visible = false
		if not onboarding.onboardingCompleted then onboarding.beginPizzaTrail() else onboarding.setPizzaTrailVisible(false, true) end
		if activityHud.hasObjective() then onboarding.setPizzaTrailVisible(false, true) end
		for _, dot in trajectoryParts do dot.Transparency = 1 end
		landingRing.Transparency = 1
		landingLight.Enabled = false
	end
	updateRecordUI()
	updateTargetVisuals()
end

local function releaseLocalPresentation(reason)
	if operating or state.mode == "launcher" then
		invalidLeaseEpoch = math.max(invalidLeaseEpoch, state.cleanupEpoch or 0)
		modeRemote:FireServer("walk", state.cleanupEpoch or 0)
	end
	activityHud.resetLocal(reason == "replacement")
	resetLauncherInput()
	state = table.clone(state)
	state.mode = "walk"
	state.launcherMode = "none"
	state.recordRun = { status = "idle", personalBest = state.recordRun and state.recordRun.personalBest or 0 }
	inputState:receive(state, os.clock())
	applyMode()
end

local inputController = ClientInput.bind({
	inputState = inputState, ui = ui, UserInputService = UserInputService, COLORS = COLORS,
	launchRemote = launchRemote, modeRemote = modeRemote, currentDirection = currentDirection,
	getCamera = cameraController.getCamera, isOperating = function() return operating end,
})

shopToggle.Activated:Connect(function()
	shopPanel.Visible = not shopPanel.Visible
	applyPresentation()
end)
recordContinue.Activated:Connect(function()
	modeRemote:FireServer("chooseMode", state.cleanupEpoch or 0)
end)
freePlayChoice.Activated:Connect(function()
	modeRemote:FireServer("freePlay", state.cleanupEpoch or 0)
end)
recordRunChoice.Activated:Connect(function()
	modeRemote:FireServer("recordRun", state.cleanupEpoch or 0)
end)
modeSelectionExit.Activated:Connect(function()
	modeRemote:FireServer("walk", state.cleanupEpoch or 0)
end)
changeModeButton.Activated:Connect(function()
	modeRemote:FireServer("chooseMode", state.cleanupEpoch or 0)
end)
exitButton.Activated:Connect(function()
	if operating then
		modeRemote:FireServer("walk", state.cleanupEpoch or 0)
	end
end)
stateRemote.OnClientEvent:Connect(function(newState)
	if (newState.cleanupEpoch or 0) < (state.cleanupEpoch or 0) then return end
	if newState.mode == "launcher" and ((newState.cleanupEpoch or 0) <= invalidLeaseEpoch or not cameraController.isAlive()) then
		newState = table.clone(newState)
		newState.mode = "walk"
		newState.launcherMode = "none"
		newState.recordRun = { status = "idle", personalBest = newState.recordRun and newState.recordRun.personalBest or 0 }
	end
	local previousLauncherMode = state.launcherMode
	local changedMode = (newState.mode == "launcher") ~= operating
	state = newState
	local inputChanged = inputState:receive(state, os.clock())
	if inputChanged then
		uiEpoch += 1
		cancelUITweens()
		effects.reset()
		shakeUntil = 0
		shakeStrength = 0
		screenTint.BackgroundTransparency = 1
	end
	state.upgrades = state.upgrades or { tips = 0, assist = 0, reload = 0, power = 0 }
	state.recordRun = state.recordRun or { status = "idle", personalBest = 0, score = 0, combo = 0, multiplier = 1 }
	state.launcherMode = state.launcherMode or (state.mode == "launcher" and "freePlay" or "none")
	local changedLauncherMode = state.launcherMode ~= previousLauncherMode
	coinsLabel.Text = string.format("COINS  %d", state.coins or 0)
	comboLabel.Text = string.format("COMBO  x%d", state.combo or 0)
	roundTitle.Text = "FREE PLAY • NO TIMER"
	targetLabel.Text = string.format("Round %d • Serve hungry customers", state.round or 1)
	progressFill.Size = UDim2.fromScale(math.clamp((state.roundProgress or 0) / math.max(state.roundGoal or 1, 1), 0, 1), 1)
	roundCard.BackgroundColor3 = COLORS.cream
	updateShop(state.upgrades)
	if changedMode or changedLauncherMode or inputChanged then
		applyMode()
	else
		updateRecordUI()
		updateTargetVisuals()
	end
	if newState.event == "launcherReset" then
		applyMode()
	end

	if state.event == "launched" and operating and state.payload and state.payload.requestEpoch == inputState.epoch then
		local reloadTime = state.payload and state.payload.reloadTime or Config.RELOAD_TIME
		effects.playLauncherFire(reloadTime)
		-- Anticipation/flour/recoil lives on the machine; ordinary launches do
		-- not shake or flash the whole camera.
		if not onboarding.onboardingCompleted then
			onboarding.onboardingCompleted = true
			onboarding.onboardingReachedLauncher = false
			onboarding.setPizzaTrailVisible(false, true)
			if onboarding.onboardingHighlight then onboarding.onboardingHighlight.Enabled = false end
			tweenUI(tutorial, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
			for _, descendant in tutorial:GetDescendants() do
				if descendant:IsA("TextLabel") then
					tweenUI(descendant, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
				elseif descendant:IsA("UIStroke") then
					tweenUI(descendant, TweenInfo.new(0.2), { Transparency = 1 }):Play()
				end
			end
			delayUI(0.26, function() tutorial.Visible = false end)
			effects.showEventBanner({ title = "YOU'RE COOKING!", icon = "OK", detail = "Serve hungry customers for coins." })
		end
	elseif state.event == "shotResult" and state.payload then
		local payload = state.payload
		local detail
		if payload.recordRun then
			if payload.recordPoints and payload.recordPoints > 0 then
				detail = string.format("+%d POINTS • COMBO %d", payload.recordPoints, payload.recordCombo or 0)
				shakeStrength = payload.result == "PERFECT!" and 0.18 or 0
			else
				detail = "COMBO RESET - NEXT PIZZA!"
				shakeStrength = 0
			end
			shakeUntil = os.clock() + 0.18
		elseif payload.coinsEarned and payload.coinsEarned > 0 then
			detail = string.format("+%d COINS", payload.coinsEarned)
			if payload.comboBonus and payload.comboBonus > 0 then
				detail ..= string.format(" • COMBO +%d", payload.comboBonus)
			end
			shakeStrength = payload.result == "PERFECT!" and 0.18 or 0
			if payload.comboMilestone then
				shakeStrength = 0.28
			end
			shakeUntil = os.clock() + 0.18
		else
			detail = payload.comboSaved and "COMBO SAVED - the critic only skips the bonus!" or "Quick reload — give it another whirl!"
			shakeStrength = 0
		end
		if not payload.recordRun or recordStatus() == "running" then
			effects.showFeedback(payload.result or "PIZZA!", payload.color or COLORS.yellow, detail)
		end
		if payload.roundComplete then
			delayUI(0.45, function()
				effects.showRoundComplete(payload)
			end)
		end
		if payload.shiftEventStarted then
			effects.showEventBanner(payload.shiftEventStarted)
		elseif payload.shiftEventEnded and payload.eventMessage then
			effects.showEventBanner({ title = payload.shiftEventEnded.title or "SHIFT EVENT", icon = "OK", detail = payload.eventMessage })
		end
	elseif state.event == "recordCountdown" then
		inputState:cancelCharge()
	elseif state.event == "recordStarted" then
		effects.showFeedback("LAUNCH!", COLORS.green, "60 seconds - hit the glowing order")
	elseif state.event == "recordEnding" or state.event == "recordFinished" then
		inputState:cancelCharge()
	elseif state.event == "launchRejected" then
		-- receive() has reconciled the matching acknowledgement and server
		-- reload/shot state. A rejection cannot complete onboarding or effects.
		inputController.render()
	elseif state.event == "modeSelected" and state.payload then
		-- The new mode HUD is the acknowledgement; keep the first aim clear.
	elseif state.event == "purchaseResult" and state.payload then
		if state.payload.success then
			effects.showEventBanner({ title = state.payload.result, icon = "UP", detail = state.payload.changeMessage or state.payload.effect or "Upgrade applied now!" })
		else
			effects.showFeedback(state.payload.result, COLORS.orange, "Deliver more pizzas!")
		end
	elseif state.event == "customerDialogue" and state.payload then
		effects.showCustomerDialogue(state.payload)
	elseif state.event == "shiftEventStarted" and state.payload then
		effects.showEventBanner(state.payload)
	elseif state.event == "shiftEventEnded" and state.payload then
		effects.showEventBanner({ title = state.payload.title or "SHIFT EVENT", icon = "OK", detail = state.payload.detail })
	elseif state.event == "modeChanged" and state.payload then
		if onboarding.onboardingCompleted then
			effects.showFeedback(state.payload.result or (operating and "READY!" or "LET'S WALK!"), operating and COLORS.green or COLORS.yellow,
				operating and "Aim for the glowing delivery plate" or "Explore, greet customers, or check the register")
		end
	elseif state.event == "notice" and state.payload then
		effects.showFeedback(state.payload.result or "PIZZA PLACE", state.payload.color or COLORS.yellow, state.payload.detail)
	elseif state.event == "welcome" then
		onboarding.beginPizzaTrail()
	end
end)

RunService:BindToRenderStep("PizzaLaunchRender", Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
	if responsiveUI.refresh() then
		onboarding.updateOnboardingWalkHint()
		if tutorial.Visible then onboarding.showFirstPizzaHint() end
		cameraController.setPicker(modeSelection, freePlayChoice, modeSelection.Visible)
		applyPresentation()
	end
	onboarding.updatePizzaTrail()
	activityHud.render()
	inputController.render()
	if operating and not cameraController.isAlive() then releaseLocalPresentation() end
	if not operating then
		return
	end
	local run = state.recordRun or { status = "idle" }
	local status = run.status or "idle"
	if status == "countdown" then
		local remaining = math.max(1, math.ceil((run.countdownEndsAt or 0) - Workspace:GetServerTimeNow()))
		countdownLabel.Text = tostring(remaining)
		countdownLabel.Visible = not shopPanel.Visible
		recordTimer.Text = "1:00"
		recordTimer.TextColor3 = COLORS.ink
	elseif status == "running" then
		local remaining = math.max(0, (run.endsAt or 0) - Workspace:GetServerTimeNow())
		local wholeSeconds = math.ceil(remaining)
		recordTimer.Text = wholeSeconds >= 60 and "1:00" or string.format("0:%02d", wholeSeconds)
		recordTimer.TextColor3 = remaining <= 10 and COLORS.red or COLORS.ink
		countdownLabel.Visible = false
	elseif status == "saving" or status == "finished" then
		recordTimer.Text = "0:00"
		countdownLabel.Visible = false
	else
		countdownLabel.Visible = false
	end
	if status ~= "idle" then
		recordTitle.Text = "1-MINUTE RECORD RUN"
	end
	inputState:step(deltaTime, os.clock())
	local ready = inputState:isReady(os.clock())

	local cameraFrame = ClientCamera.frameForViewport(Config.CAMERA_POSITION, Config.CAMERA_FOCUS, ui.layout.height)
	if os.clock() < shakeUntil then
		local fade = (shakeUntil - os.clock()) / 0.35
		cameraFrame *= CFrame.new((math.random() - 0.5) * shakeStrength * fade, (math.random() - 0.5) * shakeStrength * fade, 0)
	end
	cameraController.render(cameraFrame)

	powerFill.Size = UDim2.fromScale(math.max(inputState.charge, 0.02), 1)
	local powerLevel = status ~= "idle" and 0 or (state.upgrades and state.upgrades.power or 0)
	powerText.Text = string.format("POWER  %d%%", math.floor(inputState.charge * 100 + 0.5))
	local pitchDegrees = math.deg(Config.MIN_PITCH + inputState.aimPitch * (Config.MAX_PITCH - Config.MIN_PITCH))
	local arcName = pitchDegrees < 37 and "LOW" or (pitchDegrees < 49 and "MEDIUM" or "HIGH")
	arcText.Text = powerLevel > 0 and string.format("%s ARC • +%d%% RANGE", arcName, powerLevel * 4) or "ARC  " .. arcName

	local direction = currentDirection()
	local speed = Config.speedFromCharge(inputState.charge, powerLevel)
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
		-- Only the local cosmetic rig recoils. Physics and trajectory calculations
		-- above continue to use the unchanged authoritative launch origin.
		rig:PivotTo(CFrame.lookAt(Config.LAUNCH_ORIGIN, Config.LAUNCH_ORIGIN + direction) * CFrame.new(0, 0, effects.recoilOffset(os.clock())))
	end
	if station then
		local crankRig = station:FindFirstChild("CosmeticCrankRig")
		local crankBase = crankRig and crankRig:GetAttribute("BasePivot")
		if crankRig and crankRig:IsA("Model") and typeof(crankBase) == "CFrame" then
			local motion = math.rad(inputState.charge * 58 + (inputState.charging and math.sin(os.clock() * 12) * 3 or 0))
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
			gaugeLabel.Text = string.format("POWER\n%d%%", math.floor(inputState.charge * 100 + 0.5))
			gaugeLabel.TextColor3 = inputState.charge >= 0.8 and COLORS.red or COLORS.ink
		end
	end
end)

task.defer(function()
	local world = Workspace:WaitForChild("PizzaLaunchWorld", 10)
	if world then
		onboarding.ensurePizzaTrailWorld()
		if not onboarding.onboardingCompleted then
			onboarding.beginPizzaTrail()
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

cameraController.watchCharacter(function(reason)
	releaseLocalPresentation(reason)
end, function(character)
	if player.Character ~= character then return end
	if not operating then cameraController.setMounted(false) end
	if not onboarding.onboardingCompleted then onboarding.beginPizzaTrail() end
end)
