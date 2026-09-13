local Feedback = {}
function Feedback.new(context)
	local self = {}
	local lifetime = 0
	local tweens = {}
	local engineTask = task
	local task = { delay = function(seconds, callback)
		local epoch = lifetime
		engineTask.delay(seconds, function() if epoch == lifetime then callback() end end)
	end }
	local TweenService = { Create = function(_, target, info, properties)
		local tween = context.TweenService:Create(target, info, properties)
		tweens[tween] = true
		tween.Completed:Once(function() tweens[tween] = nil end)
		return tween
	end }
	local Workspace, UserInputService, TextService, COLORS = context.Workspace, context.UserInputService, context.TextService, context.COLORS
	local feedback = context.ui.feedback
	local dialogueCard = context.ui.dialogueCard
	local dialoguePortrait = context.ui.dialoguePortrait
	local dialogueName = context.ui.dialogueName
	local dialogueMood = context.ui.dialogueMood
	local dialogueText = context.ui.dialogueText
	local dialogueClose = context.ui.dialogueClose
	local eventBanner = context.ui.eventBanner
	local eventIcon = context.ui.eventIcon
	local eventTitle = context.ui.eventTitle
	local eventDetail = context.ui.eventDetail
	local roundOverlay = context.ui.roundOverlay
	local roundOverlayTitle = context.ui.roundOverlayTitle
	local roundOverlayDetail = context.ui.roundOverlayDetail
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
	roundOverlayTitle.Text = string.format("ROUND %d CLEARED!", payload.completedRound or context.getState().round)
	roundOverlayDetail.Text = string.format("%s  -  +%d COINS  -  NEXT: %s", payload.completedRoundName or "GREAT WORK", payload.roundReward or 0, context.getState().roundName or "MORE ORDERS")
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
		local restingBrightness = 2.3 + (context.getState().upgrades and context.getState().upgrades.power or 0) * 0.6
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


function self.reset()
    lifetime += 1
    feedbackToken += 1
    dialogueToken += 1
    eventBannerToken += 1
    roundBannerToken += 1
    launcherEffectToken += 1
    for tween in tweens do tween:Cancel() end
    table.clear(tweens)
    for _, item in { feedback, dialogueCard, eventBanner, roundOverlay } do item.Visible = false end
    local world = Workspace:FindFirstChild("PizzaLaunchWorld")
    local station = world and world:FindFirstChild("LauncherStation")
    if station then
        local glow = station:FindFirstChild("OvenGlow")
        local ovenLight = glow and glow:FindFirstChildOfClass("PointLight")
        if ovenLight then
            local upgrades = context.getState().upgrades
            ovenLight.Brightness = 2.3 + (upgrades and upgrades.power or 0) * 0.6
        end
        for _, item in station:GetDescendants() do
            if item:IsA("BasePart") and (item.Name == "LoadedPizza" or item.Name == "LoadedPepperoni") then item.LocalTransparencyModifier = 0 end
            if item:IsA("BasePart") and item.Name == "CosmeticMuzzleFlash" then item.Transparency = 1 end
            if item:IsA("PointLight") and item.Name == "FireLight" then item.Enabled = false end
            if item:IsA("Smoke") and item.Name == "WarmOvenSteam" then item.Opacity = 0.24 end
        end
    end
end
self.showFeedback = showFeedback
self.hideCustomerDialogue = hideCustomerDialogue
self.showCustomerDialogue = showCustomerDialogue
self.showEventBanner = showEventBanner
self.showRoundComplete = showRoundComplete
self.playLauncherFire = playLauncherFire
return self
end
return Feedback
