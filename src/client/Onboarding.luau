local Onboarding = {}
function Onboarding.new(context)
	local self = { onboardingCompleted = false, onboardingReachedLauncher = false, onboardingTrailActive = true, onboardingTrailParts = {}, onboardingNextDistanceCheck = 0 }
	local trailTweens = {}
	local Workspace, TweenService = context.Workspace, context.TweenService
	local player, COLORS, tutorial, tutorialTitle, tutorialText, walkHint = context.player, context.COLORS, context.ui.tutorial, context.ui.tutorialTitle, context.ui.tutorialText, context.ui.walkHint
local PIZZA_TRAIL_ANCHOR_OFFSETS = {
	-- Every marker derives from LauncherInteractionAnchor. The route starts in
	-- the player's forward view, curves around the storefront edge, and finishes
	-- at the exact center of the visible use pad.
	Vector3.new(-14.5, 0, -3),
	Vector3.new(-11.5, 0, -5),
	Vector3.new(-8, 0, -5),
	Vector3.new(-5, 0, -4),
	Vector3.new(-2.5, 0, -2),
	Vector3.new(0, 0, 0),
}

-- A player who walks through the entrance before noticing the launcher sees a
-- short return route on the restaurant floor. It terminates at the same
-- authoritative interaction anchor as the spawn-side route and prompt.
local INTERIOR_LAUNCHER_RETURN_OFFSETS = {
	Vector3.new(-14, 0, -40),
	Vector3.new(-14, 0, -28),
	Vector3.new(-14, 0, -18),
	Vector3.new(-11, 0, -11),
	Vector3.new(-6, 0, -5),
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
	table.insert(self.onboardingTrailParts, part)
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
	shaft.Size = Vector3.new(1.05, 0.08, 1.9)
	shaft.CFrame = arrowFrame * CFrame.new(0, 0, 0.35)
	shaft.Color = COLORS.yellow
	shaft.Material = Enum.Material.SmoothPlastic
	shaft.Parent = model
	registerTrailPart(shaft, 0.02)

	for side = -1, 1, 2 do
		local arrowHead = Instance.new("Part")
		arrowHead.Name = "CheeseArrowHead"
		arrowHead.Size = Vector3.new(0.7, 0.08, 1.6)
		arrowHead.CFrame = arrowFrame * CFrame.new(side * 0.55, 0, -0.8) * CFrame.Angles(0, math.rad(side * 40), 0)
		arrowHead.Color = COLORS.yellow
		arrowHead.Material = Enum.Material.SmoothPlastic
		arrowHead.Parent = model
		registerTrailPart(arrowHead, 0.02)
	end

end

local function ensurePizzaTrailWorld()
	if self.onboardingTrailFolder and self.onboardingTrailFolder.Parent then
		return
	end
	local world = Workspace:FindFirstChild("PizzaLaunchWorld")
	local interactionAnchor = world and world:FindFirstChild("LauncherInteractionAnchor", true)
	if not interactionAnchor or not interactionAnchor:IsA("BasePart") then
		return
	end
	self.onboardingInteractionAnchor = interactionAnchor

	self.onboardingTrailParts = {}
	local folder = Instance.new("Folder")
	folder.Name = "LocalPizzaTrail"
	folder:SetAttribute("ClientOnly", true)
	folder.Parent = Workspace
	self.onboardingTrailFolder = folder
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	local floorSurfaces = {}
	for _, surface in {
		Workspace:FindFirstChild("Baseplate"),
		world:FindFirstChild("RestaurantFloor"),
		world:FindFirstChild("FrontSidewalk", true),
		world:FindFirstChild("LauncherUsePad", true),
	} do
		if surface and surface:IsA("BasePart") then
			table.insert(floorSurfaces, surface)
		end
	end
	raycastParams.FilterDescendantsInstances = floorSurfaces
	local trailPoints = {}
	for _, offset in PIZZA_TRAIL_ANCHOR_OFFSETS do
		local horizontalPoint = Vector3.new(interactionAnchor.Position.X + offset.X, 0, interactionAnchor.Position.Z + offset.Z)
		local floorHit = Workspace:Raycast(horizontalPoint + Vector3.new(0, 12, 0), Vector3.new(0, -30, 0), raycastParams)
		if floorHit then
			table.insert(trailPoints, Vector3.new(horizontalPoint.X, floorHit.Position.Y + 0.14, horizontalPoint.Z))
		end
	end
	for index, position in trailPoints do
		local nextPosition = trailPoints[index + 1] or (position + Vector3.new(0, 0, -1))
		makePizzaArrow(folder, position, nextPosition, index)
	end
	local interiorTrailPoints = {}
	for _, offset in INTERIOR_LAUNCHER_RETURN_OFFSETS do
		local horizontalPoint = Vector3.new(interactionAnchor.Position.X + offset.X, 0, interactionAnchor.Position.Z + offset.Z)
		local floorHit = Workspace:Raycast(horizontalPoint + Vector3.new(0, 12, 0), Vector3.new(0, -30, 0), raycastParams)
		if floorHit then
			table.insert(interiorTrailPoints, Vector3.new(horizontalPoint.X, floorHit.Position.Y + 0.14, horizontalPoint.Z))
		end
	end
	for index, position in interiorTrailPoints do
		local nextPosition = interiorTrailPoints[index + 1] or (position + Vector3.new(0, 0, 1))
		makePizzaArrow(folder, position, nextPosition, 100 + index)
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = "PizzaLauncherInteractionHighlight"
	local usePad = world:FindFirstChild("LauncherUsePad", true)
	highlight.Adornee = (usePad and usePad:IsA("BasePart")) and usePad or interactionAnchor
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillColor = COLORS.yellow
	highlight.FillTransparency = 0.82
	highlight.OutlineColor = COLORS.red
	highlight.OutlineTransparency = 0.05
	highlight.Enabled = false
	highlight.Parent = folder
	self.onboardingHighlight = highlight
end

local function updateOnboardingWalkHint()
	if self.onboardingTrailActive and not self.onboardingReachedLauncher then
		walkHint.Text = "Follow the pizza arrows to the Pizza Launcher!"
	elseif context.getInputKind() == "touch" then
		walkHint.Text = "Tap USE LAUNCHER on the pizza pad!"
	elseif context.getInputKind() == "gamepad" then
		walkHint.Text = "Press X to USE LAUNCHER on the pizza pad!"
	else
		walkHint.Text = "Press E to USE LAUNCHER on the pizza pad!"
	end
end

local function setPizzaTrailVisible(visible: boolean, immediate: boolean?)
	ensurePizzaTrailWorld()
	self.onboardingTrailActive = visible
	for _, part in self.onboardingTrailParts do
		if trailTweens[part] then
			trailTweens[part]:Cancel()
			trailTweens[part] = nil
		end
		local target = visible and (part:GetAttribute("TrailBaseTransparency") or 0.1) or 1
		if immediate then
			part.Transparency = target
		else
			local tween = TweenService:Create(part, TweenInfo.new(0.35), { Transparency = target })
			trailTweens[part] = tween
			tween:Play()
		end
	end
	if self.onboardingHighlight then
		self.onboardingHighlight.Enabled = visible and self.onboardingReachedLauncher and not context.isOperating()
	end
	local world = Workspace:FindFirstChild("PizzaLaunchWorld")
	local interiorGuide = world and world:FindFirstChild("InteriorLauncherBillboard", true)
	if interiorGuide and interiorGuide:IsA("BillboardGui") then
		interiorGuide.Enabled = visible
	end
	updateOnboardingWalkHint()
end

local function beginPizzaTrail()
	if self.onboardingCompleted then
		return
	end
	self.onboardingReachedLauncher = false
	tutorial.Visible = false
	setPizzaTrailVisible(true, true)
end

local function showFirstPizzaHint()
	tutorialTitle.Text = "AIM  •  CHARGE  •  LAUNCH!"
	if context.getInputKind() == "touch" then
		tutorialText.Text = "DRAG / ARROWS • AIM\nHOLD + RELEASE"
	elseif context.getInputKind() == "gamepad" then
		tutorialText.Text = "LEFT STICK • AIM\nHOLD RT, THEN RELEASE"
	else
		tutorialText.Text = "MOUSE / W A S D TO AIM\nHOLD SPACE OR CLICK, THEN RELEASE"
	end
	context.restoreTutorialAppearance()
	tutorial.Visible = true
end

local function updatePizzaTrail()
	ensurePizzaTrailWorld()
	if self.onboardingTrailActive then
		local pulse = math.sin(os.clock() * 3.4) * 0.045
		for _, part in self.onboardingTrailParts do
			local baseTransparency = part:GetAttribute("TrailBaseTransparency") or 0.1
			part.Transparency = math.clamp(baseTransparency + pulse, 0, 0.1)
		end
	end
	if context.isOperating() or self.onboardingCompleted then
		return
	end
	if os.clock() < self.onboardingNextDistanceCheck then
		return
	end
	self.onboardingNextDistanceCheck = os.clock() + 0.1
	local interactionAnchor = self.onboardingInteractionAnchor
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not interactionAnchor or not interactionAnchor.Parent or not root or not root:IsA("BasePart") then
		return
	end
	local distance = (root.Position - interactionAnchor.Position).Magnitude
	if self.onboardingTrailActive and not self.onboardingReachedLauncher and distance <= 12 then
		self.onboardingReachedLauncher = true
		if self.onboardingHighlight then self.onboardingHighlight.Enabled = true end
		updateOnboardingWalkHint()
	elseif self.onboardingReachedLauncher and distance > 18 then
		self.onboardingReachedLauncher = false
		if self.onboardingHighlight then self.onboardingHighlight.Enabled = false end
		updateOnboardingWalkHint()
	end
end


self.ensurePizzaTrailWorld = ensurePizzaTrailWorld
self.updateOnboardingWalkHint = updateOnboardingWalkHint
self.setPizzaTrailVisible = setPizzaTrailVisible
self.beginPizzaTrail = beginPizzaTrail
self.showFirstPizzaHint = showFirstPizzaHint
self.updatePizzaTrail = updatePizzaTrail
return self
end
return Onboarding
