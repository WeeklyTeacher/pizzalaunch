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
local camera = Workspace.CurrentCamera
local remotes = ReplicatedStorage:WaitForChild(Config.REMOTES_FOLDER)
local launchRemote = remotes:WaitForChild(Config.LAUNCH_REMOTE)
local stateRemote = remotes:WaitForChild(Config.STATE_REMOTE)
local purchaseRemote = remotes:WaitForChild(Config.PURCHASE_REMOTE)

local RED = Color3.fromRGB(219, 50, 56)
local CREAM = Color3.fromRGB(255, 245, 217)
local INK = Color3.fromRGB(51, 38, 45)
local YELLOW = Color3.fromRGB(255, 211, 67)
local GREEN = Color3.fromRGB(87, 205, 128)

local targetId = 1
local aimAmount = 0
local charge = 0.35
local charging = false
local chargeStarted = 0
local ready = true
local activeFireInput: InputObject? = nil
local targetHighlight: Highlight? = nil
local orderBillboard: BillboardGui? = nil
local trajectoryParts = {}

local function corner(parent: GuiObject, radius: number)
	local item = Instance.new("UICorner")
	item.CornerRadius = UDim.new(0, radius)
	item.Parent = parent
end

local function stroke(parent: GuiObject, color: Color3, thickness: number)
	local item = Instance.new("UIStroke")
	item.Color = color
	item.Thickness = thickness
	item.Transparency = 0.08
	item.Parent = parent
end

local function label(parent: Instance, name: string, displayText: string, size: UDim2, position: UDim2, textSize: number): TextLabel
	local item = Instance.new("TextLabel")
	item.Name = name
	item.Size = size
	item.Position = position
	item.BackgroundTransparency = 1
	item.Text = displayText
	item.TextColor3 = INK
	item.TextSize = textSize
	item.Font = Enum.Font.GothamBold
	item.TextWrapped = true
	item.Parent = parent
	return item
end

local gui = Instance.new("ScreenGui")
gui.Name = "PizzaLaunchHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 20
gui.Parent = playerGui

local topStats = Instance.new("Frame")
topStats.Name = "Stats"
topStats.Size = UDim2.fromOffset(250, 64)
topStats.Position = UDim2.fromOffset(20, 18)
topStats.BackgroundColor3 = CREAM
topStats.BackgroundTransparency = 0.04
topStats.Parent = gui
corner(topStats, 18)
stroke(topStats, RED, 3)

local coinsLabel = label(topStats, "Coins", "COINS  0", UDim2.fromScale(0.58, 1), UDim2.fromScale(0, 0), 23)
coinsLabel.TextColor3 = RED
local comboLabel = label(topStats, "Combo", "COMBO  x0", UDim2.fromScale(0.42, 1), UDim2.fromScale(0.58, 0), 18)

local targetCard = Instance.new("Frame")
targetCard.Name = "TargetCard"
targetCard.AnchorPoint = Vector2.new(0.5, 0)
targetCard.Size = UDim2.fromOffset(360, 78)
targetCard.Position = UDim2.new(0.5, 0, 0, 18)
targetCard.BackgroundColor3 = RED
targetCard.Parent = gui
corner(targetCard, 20)
stroke(targetCard, Color3.fromRGB(139, 30, 40), 3)

local targetTitle = label(targetCard, "Title", "HUNGRY CUSTOMER", UDim2.new(1, -20, 0, 23), UDim2.fromOffset(10, 7), 14)
targetTitle.TextColor3 = YELLOW
local targetLabel = label(targetCard, "Target", "TABLE 1  •  50 STUDS", UDim2.new(1, -20, 0, 38), UDim2.fromOffset(10, 28), 24)
targetLabel.TextColor3 = Color3.new(1, 1, 1)

local tutorial = Instance.new("Frame")
tutorial.Name = "Tutorial"
tutorial.Size = UDim2.fromOffset(300, 136)
tutorial.Position = UDim2.new(0, 20, 0, 98)
tutorial.BackgroundColor3 = CREAM
tutorial.Parent = gui
corner(tutorial, 18)
stroke(tutorial, Color3.fromRGB(111, 84, 72), 2)
local tutorialTitle = label(tutorial, "Title", "3 STEPS TO DELICIOUS", UDim2.new(1, -24, 0, 30), UDim2.fromOffset(12, 10), 17)
tutorialTitle.TextColor3 = RED
local tutorialText = label(tutorial, "Steps", "1  AIM left and right\n2  HOLD to choose distance\n3  RELEASE to launch!", UDim2.new(1, -28, 0, 82), UDim2.fromOffset(14, 43), 17)
tutorialText.TextXAlignment = Enum.TextXAlignment.Left
tutorialText.TextYAlignment = Enum.TextYAlignment.Top

local feedback = label(gui, "Feedback", "", UDim2.fromOffset(520, 130), UDim2.new(0.5, -260, 0.36, 0), 48)
feedback.TextColor3 = YELLOW
feedback.TextStrokeColor3 = INK
feedback.TextStrokeTransparency = 0.15
feedback.Visible = false
feedback.ZIndex = 10

local controlPanel = Instance.new("Frame")
controlPanel.Name = "Controls"
controlPanel.AnchorPoint = Vector2.new(0.5, 1)
controlPanel.Size = UDim2.new(1, -24, 0, 126)
controlPanel.Position = UDim2.new(0.5, 0, 1, -22)
controlPanel.BackgroundColor3 = CREAM
controlPanel.Parent = gui
corner(controlPanel, 22)
stroke(controlPanel, RED, 3)
local controlConstraint = Instance.new("UISizeConstraint")
controlConstraint.MinSize = Vector2.new(300, 126)
controlConstraint.MaxSize = Vector2.new(500, 126)
controlConstraint.Parent = controlPanel

local powerText = label(controlPanel, "PowerText", "LANDING: 70 STUDS", UDim2.new(1, -170, 0, 28), UDim2.fromOffset(18, 10), 18)
powerText.TextXAlignment = Enum.TextXAlignment.Left

local barBack = Instance.new("Frame")
barBack.Name = "PowerBar"
barBack.Size = UDim2.new(1, -190, 0, 35)
barBack.Position = UDim2.fromOffset(18, 42)
barBack.BackgroundColor3 = Color3.fromRGB(213, 197, 176)
barBack.ClipsDescendants = true
barBack.Parent = controlPanel
corner(barBack, 11)

local barFill = Instance.new("Frame")
barFill.Name = "Fill"
barFill.Size = UDim2.fromScale(charge, 1)
barFill.BackgroundColor3 = GREEN
barFill.Parent = barBack
corner(barFill, 11)
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, GREEN),
	ColorSequenceKeypoint.new(0.65, YELLOW),
	ColorSequenceKeypoint.new(1, RED),
})
gradient.Parent = barFill

local helpText = label(controlPanel, "Help", UserInputService.TouchEnabled and "DRAG SCREEN TO AIM" or "MOVE MOUSE TO AIM  •  SPACE ALSO FIRES", UDim2.new(1, -190, 0, 31), UDim2.fromOffset(18, 84), 13)
helpText.TextXAlignment = Enum.TextXAlignment.Left
helpText.TextColor3 = Color3.fromRGB(100, 82, 76)

local fireButton = Instance.new("TextButton")
fireButton.Name = "LaunchButton"
fireButton.Size = UDim2.fromOffset(145, 96)
fireButton.Position = UDim2.new(1, -158, 0, 15)
fireButton.BackgroundColor3 = RED
fireButton.Text = "HOLD\nLAUNCH"
fireButton.TextColor3 = Color3.new(1, 1, 1)
fireButton.TextSize = 22
fireButton.TextWrapped = true
fireButton.Font = Enum.Font.GothamBlack
fireButton.AutoButtonColor = false
fireButton.Parent = controlPanel
corner(fireButton, 20)
stroke(fireButton, Color3.fromRGB(145, 28, 38), 3)

local shopToggle = Instance.new("TextButton")
shopToggle.Name = "ShopToggle"
shopToggle.AnchorPoint = Vector2.new(1, 0)
shopToggle.Size = UDim2.fromOffset(148, 54)
shopToggle.Position = UDim2.new(1, -20, 0, 18)
shopToggle.BackgroundColor3 = YELLOW
shopToggle.Text = "UPGRADES"
shopToggle.TextColor3 = RED
shopToggle.TextSize = 18
shopToggle.Font = Enum.Font.GothamBlack
shopToggle.Parent = gui
corner(shopToggle, 16)
stroke(shopToggle, RED, 3)

local shopPanel = Instance.new("Frame")
shopPanel.Name = "ShopPanel"
shopPanel.AnchorPoint = Vector2.new(1, 0)
shopPanel.Size = UDim2.fromOffset(292, 275)
shopPanel.Position = UDim2.new(1, -20, 0, 82)
shopPanel.BackgroundColor3 = CREAM
shopPanel.Visible = false
shopPanel.Parent = gui
corner(shopPanel, 18)
stroke(shopPanel, RED, 3)
local shopTitle = label(shopPanel, "Title", "SMARTER LAUNCHES START HERE", UDim2.new(1, -20, 0, 34), UDim2.fromOffset(10, 8), 14)
shopTitle.TextColor3 = RED

local upgradeButtons = {}
local upgradeOrder = { "tips", "assist", "reload" }
for index, upgradeId in upgradeOrder do
	local button = Instance.new("TextButton")
	button.Name = upgradeId
	button.Size = UDim2.new(1, -24, 0, 62)
	button.Position = UDim2.fromOffset(12, 44 + (index - 1) * 72)
	button.BackgroundColor3 = index % 2 == 0 and Color3.fromRGB(238, 226, 205) or Color3.fromRGB(255, 237, 188)
	button.TextColor3 = INK
	button.TextSize = 15
	button.TextWrapped = true
	button.Font = Enum.Font.GothamBold
	button.Parent = shopPanel
	corner(button, 13)
	upgradeButtons[upgradeId] = button
	button.Activated:Connect(function()
		purchaseRemote:FireServer(upgradeId)
	end)
end

shopToggle.Activated:Connect(function()
	shopPanel.Visible = not shopPanel.Visible
	shopToggle.Text = shopPanel.Visible and "CLOSE SHOP" or "UPGRADES"
end)

local markerText = label(gui, "AimMarker", "+", UDim2.fromOffset(60, 60), UDim2.fromOffset(0, 0), 48)
markerText.TextColor3 = RED
markerText.TextStrokeColor3 = Color3.new(1, 1, 1)
markerText.TextStrokeTransparency = 0

if UserInputService.TouchEnabled then
	-- A short landscape HUD leaves the restaurant and target visible on phones.
	tutorial.Visible = false
	topStats.Size = UDim2.fromOffset(170, 54)
	coinsLabel.TextSize = 18
	comboLabel.TextSize = 14
	targetCard.Size = UDim2.fromOffset(280, 64)
	targetCard.Position = UDim2.new(0.5, 0, 0, 8)
	targetLabel.TextSize = 20
	targetLabel.Size = UDim2.new(1, -16, 0, 31)
	targetLabel.Position = UDim2.fromOffset(8, 26)
	shopToggle.Size = UDim2.fromOffset(120, 48)
	shopToggle.Position = UDim2.new(1, -20, 0, 8)
	shopToggle.TextSize = 15
	controlPanel.Size = UDim2.new(1, -24, 0, 110)
	controlPanel.Position = UDim2.new(0.5, 0, 1, -12)
	controlConstraint.MinSize = Vector2.new(300, 110)
	controlConstraint.MaxSize = Vector2.new(440, 110)
	barBack.Size = UDim2.new(1, -165, 0, 30)
	barBack.Position = UDim2.fromOffset(14, 38)
	powerText.Position = UDim2.fromOffset(14, 7)
	powerText.TextSize = 16
	helpText.Position = UDim2.fromOffset(14, 72)
	helpText.Text = "DRAG TO AIM • HOLD + RELEASE TO LAUNCH"
	helpText.TextSize = 11
	fireButton.Size = UDim2.fromOffset(125, 82)
	fireButton.Position = UDim2.new(1, -137, 0, 14)
	fireButton.TextSize = 19

	task.defer(function()
		local touchGui = playerGui:WaitForChild("TouchGui", 8)
		if touchGui and touchGui:IsA("ScreenGui") then
			touchGui.Enabled = false
		end
		local playerModule = player.PlayerScripts:WaitForChild("PlayerModule", 8)
		if playerModule then
			local success, module = pcall(require, playerModule)
			if success and module.GetControls then
				module:GetControls():Disable()
			end
		end
	end)
end

local trajectoryFolder = Instance.new("Folder")
trajectoryFolder.Name = "LocalTrajectory"
trajectoryFolder.Parent = Workspace
for index = 1, 14 do
	local dot = Instance.new("Part")
	dot.Name = "Dot"
	dot.Shape = Enum.PartType.Ball
	dot.Size = Vector3.new(0.75, 0.75, 0.75) * (1 - index * 0.025)
	dot.Anchored = true
	dot.CanCollide = false
	dot.CanTouch = false
	dot.CanQuery = false
	dot.Material = Enum.Material.Neon
	dot.Color = YELLOW
	dot.Transparency = 0.12 + index * 0.035
	dot.Parent = trajectoryFolder
	table.insert(trajectoryParts, dot)
end

local function currentDirection(): Vector3
	local angle = aimAmount * math.rad(31)
	return Vector3.new(math.sin(angle), 0, -math.cos(angle))
end

local function targetDefinition(id: number)
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

local function updateTargetVisuals(distance: number?)
	local definition = targetDefinition(targetId)
	targetLabel.Text = string.format("TABLE %d  •  %d STUDS", targetId, distance or 0)
	targetCard.BackgroundColor3 = definition.color:Lerp(RED, 0.25)
	if targetHighlight then
		targetHighlight:Destroy()
	end
	if orderBillboard then
		orderBillboard:Destroy()
	end
	local model = findTargetModel(targetId)
	if not model then
		return
	end
	targetHighlight = Instance.new("Highlight")
	targetHighlight.Name = "YourOrderHighlight"
	targetHighlight.Adornee = model
	targetHighlight.FillColor = definition.color
	targetHighlight.FillTransparency = 0.72
	targetHighlight.OutlineColor = Color3.new(1, 1, 1)
	targetHighlight.OutlineTransparency = 0
	targetHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	targetHighlight.Parent = model

	local sign = model:FindFirstChild("OrderSign")
	if sign and sign:IsA("BasePart") then
		orderBillboard = Instance.new("BillboardGui")
		orderBillboard.Name = "YourOrder"
		orderBillboard.Adornee = sign
		orderBillboard.Size = UDim2.fromOffset(170, 42)
		orderBillboard.StudsOffset = Vector3.new(0, 4.6, 0)
		orderBillboard.AlwaysOnTop = true
		orderBillboard.Parent = sign
		local yourOrder = label(orderBillboard, "Label", "YOUR ORDER!", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), 21)
		yourOrder.TextColor3 = definition.color
		yourOrder.TextStrokeColor3 = INK
		yourOrder.TextStrokeTransparency = 0.05
	end
end

local function updateShop(upgrades)
	for _, upgradeId in upgradeOrder do
		local definition = Config.UPGRADES[upgradeId]
		local level = upgrades and upgrades[upgradeId] or 0
		local cost = definition.costs[level + 1]
		if cost then
			upgradeButtons[upgradeId].Text = string.format("%s  LV.%d\n%s  •  BUY %d", definition.name, level, definition.description, cost)
		else
			upgradeButtons[upgradeId].Text = string.format("%s  LV.%d\nMAX LEVEL!", definition.name, level)
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
	feedback.Position = UDim2.new(0.5, -260, 0.39, 0)
	feedback.Visible = true
	feedback.Rotation = -3
	TweenService:Create(feedback, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -260, 0.32, 0),
		Rotation = 0,
	}):Play()
	task.delay(1.15, function()
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

local function setAimFromScreenX(screenX: number)
	local viewport = camera.ViewportSize
	if viewport.X > 0 then
		aimAmount = math.clamp((screenX / viewport.X - 0.5) * 2, -1, 1)
	end
end

local function beginCharge(input: InputObject?)
	if not ready or charging then
		return
	end
	charging = true
	chargeStarted = os.clock()
	charge = 0
	activeFireInput = input
	fireButton.Text = "RELEASE!"
	fireButton.BackgroundColor3 = Color3.fromRGB(244, 98, 58)
	local pressedSize = UserInputService.TouchEnabled and UDim2.fromOffset(131, 88) or UDim2.fromOffset(151, 102)
	local pressedPosition = UserInputService.TouchEnabled and UDim2.new(1, -140, 0, 11) or UDim2.new(1, -161, 0, 12)
	TweenService:Create(fireButton, TweenInfo.new(0.12), { Size = pressedSize, Position = pressedPosition }):Play()
end

local function launch()
	if not charging or not ready then
		return
	end
	charging = false
	activeFireInput = nil
	ready = false
	launchRemote:FireServer(currentDirection(), charge)
	fireButton.Text = "RELOADING"
	fireButton.BackgroundColor3 = Color3.fromRGB(145, 135, 130)
	local restSize = UserInputService.TouchEnabled and UDim2.fromOffset(125, 82) or UDim2.fromOffset(145, 96)
	local restPosition = UserInputService.TouchEnabled and UDim2.new(1, -137, 0, 14) or UDim2.new(1, -158, 0, 15)
	TweenService:Create(fireButton, TweenInfo.new(0.1), { Size = restSize, Position = restPosition }):Play()
	TweenService:Create(tutorial, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
	for _, descendant in tutorial:GetDescendants() do
		if descendant:IsA("TextLabel") then
			TweenService:Create(descendant, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
		elseif descendant:IsA("UIStroke") then
			TweenService:Create(descendant, TweenInfo.new(0.35), { Transparency = 1 }):Play()
		end
	end
end

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

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		beginCharge(input)
	elseif input.KeyCode == Enum.KeyCode.Space then
		beginCharge(input)
	elseif input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.Left then
		aimAmount = math.clamp(aimAmount - 0.12, -1, 1)
	elseif input.KeyCode == Enum.KeyCode.D or input.KeyCode == Enum.KeyCode.Right then
		aimAmount = math.clamp(aimAmount + 0.12, -1, 1)
	end
end)

UserInputService.InputEnded:Connect(function(input, _processed)
	if input == activeFireInput or (charging and input.KeyCode == Enum.KeyCode.Space) then
		launch()
	end
end)

UserInputService.InputChanged:Connect(function(input, processed)
	if processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		setAimFromScreenX(input.Position.X)
	elseif input.UserInputType == Enum.UserInputType.Touch and input ~= activeFireInput then
		setAimFromScreenX(input.Position.X)
	end
end)

ContextActionService:BindActionAtPriority("BlockMovement", function()
	return Enum.ContextActionResult.Sink
end, false, Enum.ContextActionPriority.High.Value, Enum.PlayerActions.CharacterForward, Enum.PlayerActions.CharacterBackward, Enum.PlayerActions.CharacterLeft, Enum.PlayerActions.CharacterRight, Enum.PlayerActions.CharacterJump)

stateRemote.OnClientEvent:Connect(function(state)
	coinsLabel.Text = string.format("COINS  %d", state.coins or 0)
	comboLabel.Text = string.format("COMBO  x%d", state.combo or 0)
	updateShop(state.upgrades)
	if state.targetId then
		targetId = state.targetId
		updateTargetVisuals(state.targetDistance)
	end
	if state.event == "shotResult" and state.payload then
		local payload = state.payload
		local detail
		if payload.coinsEarned and payload.coinsEarned > 0 then
			detail = string.format("+%d COINS", payload.coinsEarned)
			if payload.comboBonus and payload.comboBonus > 0 then
				detail ..= string.format("  •  COMBO BONUS +%d", payload.comboBonus)
			end
		else
			detail = "No worries — try again!"
		end
		showFeedback(payload.result or "PIZZA!", payload.color or YELLOW, detail)
		task.delay(payload.reloadDelay or 0.3, function()
			ready = true
			fireButton.Text = "HOLD\nLAUNCH"
			fireButton.BackgroundColor3 = RED
		end)
	elseif state.event == "purchaseResult" and state.payload then
		showFeedback(state.payload.result, state.payload.success and GREEN or Color3.fromRGB(255, 145, 105), state.payload.success and "Upgrade equipped" or "Land more pizzas!")
	elseif state.event == "welcome" then
		showFeedback("PIZZA LAUNCH!", YELLOW, "Feed the glowing table")
	end
end)

RunService:BindToRenderStep("PizzaLaunchCamera", Enum.RenderPriority.Camera.Value + 1, function()
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(Config.CAMERA_POSITION, Config.CAMERA_FOCUS)
	camera.FieldOfView = 58

	if charging then
		charge = math.clamp((os.clock() - chargeStarted) / Config.CHARGE_TIME, 0, 1)
	end
	barFill.Size = UDim2.fromScale(math.max(charge, 0.025), 1)
	local estimatedRange = Config.rangeFromCharge(charge)
	powerText.Text = string.format("LANDING: %d STUDS", math.floor(estimatedRange + 0.5))

	local direction = currentDirection()
	local speed = Config.speedFromCharge(charge)
	local velocity = direction * speed * math.cos(Config.LAUNCH_ANGLE) + Vector3.new(0, speed * math.sin(Config.LAUNCH_ANGLE), 0)
	local flightTime = 2 * speed * math.sin(Config.LAUNCH_ANGLE) / Config.GRAVITY
	for index, dot in trajectoryParts do
		local t = flightTime * index / (#trajectoryParts + 1)
		dot.Position = Config.LAUNCH_ORIGIN + velocity * t + Vector3.new(0, -0.5 * Config.GRAVITY * t * t, 0)
		dot.Transparency = ready and (0.12 + index * 0.035) or 1
	end
	local landing = Config.LAUNCH_ORIGIN + direction * estimatedRange
	local screenPosition, onScreen = camera:WorldToViewportPoint(Vector3.new(landing.X, 0.2, landing.Z))
	markerText.Visible = onScreen and ready
	if markerText.Visible then
		markerText.Position = UDim2.fromOffset(screenPosition.X - 30, screenPosition.Y - 30)
	end
end)

task.defer(function()
	local world = Workspace:WaitForChild("PizzaLaunchWorld", 10)
	if world then
		updateTargetVisuals(0)
	end
end)
