local loadModule = require("./support/LoadModule")
local roblox = require("@lune/roblox")
local Vector3, CFrame, Color3, Enum = roblox.Vector3, roblox.CFrame, roblox.Color3, roblox.Enum

-- Execute the production constructor with real instances/math. Only the engine
-- raycast, clock and tween scheduler are doubles; this does not test rendering.
local raycasters = {}
roblox.implementMethod("Workspace", "Raycast", function(workspace, ...)
	return assert(raycasters[workspace], "Unregistered workspace raycast")(...)
end)
local function near(actual, expected, message)
	assert(math.abs(actual - expected) < 0.0001, message)
end
local function fixture(options)
	options = options or {}
	local self = { clock = 0, operating = false, input = "keyboard", requests = {}, frames = {}, tweens = {}, restored = 0 }
	local function child(parent, class, name, position)
		local item = roblox.Instance.new(class)
		item.Name, item.Parent = name, parent
		if position then item.CFrame, item.Position = CFrame.new(position), position end
		return item
	end
	self.workspace = roblox.Instance.new("Workspace")
	self.world = child(self.workspace, "Folder", "PizzaLaunchWorld")
	local exterior = child(self.world, "Model", "Exterior")
	self.surfaces = {
		child(self.workspace, "Part", "Baseplate"),
		child(self.world, "Part", "RestaurantFloor"),
		child(exterior, "Part", "FrontSidewalk"),
		child(exterior, "Part", "LauncherUsePad"),
	}
	self.blocker = child(self.world, "Part", "UnapprovedCounterTop")
	self.anchor = child(exterior, "Part", "LauncherInteractionAnchor", Vector3.new(23, 2.4, 141))
	if options.missingAnchor then self.anchor.Parent = nil end
	self.guide = child(exterior, "BillboardGui", "InteriorLauncherBillboard")
	self.character = child(self.workspace, "Model", "Character")
	self.root = child(self.character, "Part", "HumanoidRootPart", Vector3.new(23, 2.4, 171))
	self.player = { Character = self.character }
	self.ui = { tutorial = {}, tutorialTitle = {}, tutorialText = {}, walkHint = {} }
	local tweenService = {}
	-- Keep the scheduler's captured list local to this independent player fixture.
	local createdTweens = self.tweens
	function tweenService:Create(part, info, goals)
		local tween = { part = part, duration = info.duration, goals = goals, cancelled = false, played = false }
		function tween:Play() self.played = true end
		function tween:Cancel() self.cancelled = true end
		function tween:complete()
			if not self.cancelled then
				for property, value in self.goals do self.part[property] = value end
			end
		end
		table.insert(createdTweens, tween)
		return tween
	end
	local mathFrames = self.frames
	local cframe = setmetatable({}, { __index = CFrame })
	function cframe.lookAt(position, target)
		table.insert(mathFrames, { position = position, target = target })
		return CFrame.lookAt(position, target)
	end
	self.colors = { yellow = Color3.fromRGB(244, 194, 74), red = Color3.fromRGB(191, 54, 42) }
	raycasters[self.workspace] = function(origin, direction, parameters)
		assert(parameters.FilterType == Enum.RaycastFilterType.Include, "Route casts must include only approved floors")
		assert(#parameters.FilterDescendantsInstances == #self.surfaces)
		for _, surface in self.surfaces do
			assert(table.find(parameters.FilterDescendantsInstances, surface), "An approved floor is omitted")
		end
		assert(not table.find(parameters.FilterDescendantsInstances, self.blocker), "Furniture must not lift route markers")
		near(origin.Y, 12, "Route cast must start above the floor")
		assert(direction == Vector3.new(0, -30, 0), "Route cast must point down through authored floor elevation")
		local index = #self.requests + 1
		-- Uneven positive/negative floor levels catch a hidden constant-Y shortcut.
		local floorY = (index % 4) * 0.7 - 0.5
		table.insert(self.requests, { origin = origin, floorY = floorY })
		if options.miss == index then return nil end
		return { Position = Vector3.new(origin.X, floorY, origin.Z) }
	end
	local module = loadModule("src/client/Onboarding.luau", {
		CFrame = cframe,
		RaycastParams = { new = function() return {} end },
		TweenInfo = { new = function(duration) return { duration = duration } end },
		os = { clock = function() return self.clock end },
	})
	self.onboarding = module.new({
		Workspace = self.workspace, TweenService = tweenService, player = self.player,
		COLORS = self.colors, ui = self.ui,
		getInputKind = function() return self.input end,
		isOperating = function() return self.operating end,
		restoreTutorialAppearance = function() self.restored += 1 end,
	})
	function self:update()
		self.clock += 0.2
		self.onboarding.updatePizzaTrail()
	end
	return self
end

local f = fixture()
local onboarding = f.onboarding
onboarding.beginPizzaTrail()
assert(#f.requests == 12 and #f.frames == 12, "Spawn and interior return routes need six grounded arrows each")
assert(#onboarding.onboardingTrailParts == 36, "Plain arrows must stay within three parts per marker")
assert(onboarding.onboardingTrailFolder:GetAttribute("ClientOnly") == true)
assert(onboarding.onboardingHighlight.Adornee == f.surfaces[4], "The highlight must identify the visible use pad")
assert(not onboarding.onboardingHighlight.Enabled and f.guide.Enabled)
assert(not f.ui.tutorial.Visible and string.find(f.ui.walkHint.Text, "Follow the pizza arrows", 1, true))
for _, index in { 6, 12 } do
	near(f.frames[index].position.X, f.anchor.Position.X, "Both routes must end at the authoritative pad X")
	near(f.frames[index].position.Z, f.anchor.Position.Z, "Both routes must end at the authoritative pad Z")
end
assert(f.frames[7].position.Z < f.anchor.Position.Z - 25, "The interior route must begin inside the restaurant")
for index, frame in f.frames do
	local request = f.requests[index]
	near(frame.position.Y, request.floorY + 0.14, "Each marker must use its own raycast floor height")
	near(frame.position.X, request.origin.X, "Raycast and constructed route X diverged")
	near(frame.position.Z, request.origin.Z, "Raycast and constructed route Z diverged")
	local modelIndex = index <= 6 and index or 100 + index - 6
	local model = assert(onboarding.onboardingTrailFolder:FindFirstChild(string.format("PizzaArrow%02d", modelIndex)))
	local parts = model:GetChildren()
	assert(#parts == 3 and model:FindFirstChild("CheeseShaft"), "A plain arrow needs one shaft and two readable heads")
	for _, part in parts do
		assert(part:IsA("BasePart") and part.Color == f.colors.yellow and part.Material == Enum.Material.SmoothPlastic)
		assert(part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery and not part.CastShadow)
		assert(part.Size.X > 0 and part.Size.Z > 0 and part.Size.Y <= 0.2, "A floor marker must be thin, finite geometry")
		assert(part.CFrame.Position.Y - part.Size.Y / 2 > request.floorY, "Floor marker clips through its supporting surface")
		assert((part.CFrame.Position - frame.position).Magnitude < 3, "A marker exceeds its compact route footprint")
	end
end
local folder = onboarding.onboardingTrailFolder
onboarding.beginPizzaTrail()
onboarding.ensurePizzaTrailWorld()
assert(onboarding.onboardingTrailFolder == folder and #f.requests == 12, "Repeated onboarding must not duplicate the route")

f.root.Position = f.anchor.Position + Vector3.new(0, 0, 10)
f:update()
assert(onboarding.onboardingReachedLauncher and onboarding.onboardingHighlight.Enabled)
assert(string.find(f.ui.walkHint.Text, "Press E", 1, true))
-- Starting takeout while standing by the launcher transfers guidance ownership
-- without mounting or erasing this player's onboarding progress.
onboarding.setPizzaTrailVisible(false, true)
assert(not onboarding.onboardingHighlight.Enabled and not f.guide.Enabled, "Takeout guidance must hide the nearby launcher highlight with its route")
assert(onboarding.onboardingReachedLauncher and not onboarding.onboardingCompleted)
f:update()
assert(not onboarding.onboardingHighlight.Enabled, "Nearby proximity updates cannot resurrect a hidden launcher cue")
onboarding.setPizzaTrailVisible(true, true)
assert(onboarding.onboardingHighlight.Enabled and f.guide.Enabled, "Returning guidance to the launcher restores its nearby cue")
for _, case in { { "touch", "Tap USE LAUNCHER", "HOLD + RELEASE" }, { "gamepad", "Press X", "HOLD RT" }, { "keyboard", "Press E", "HOLD SPACE" } } do
	f.input = case[1]
	onboarding.updateOnboardingWalkHint()
	assert(string.find(f.ui.walkHint.Text, case[2], 1, true), "Approach hint does not match the active input")
	onboarding.showFirstPizzaHint()
	assert(f.ui.tutorial.Visible and string.find(f.ui.tutorialText.Text, case[3], 1, true))
end
assert(f.restored == 3)
f.root.Position = f.anchor.Position + Vector3.new(0, 0, 15)
f:update()
assert(onboarding.onboardingReachedLauncher, "Approach hysteresis should avoid flickering at prompt range")
f.root.Position = f.anchor.Position + Vector3.new(0, 0, 19)
f:update()
assert(not onboarding.onboardingReachedLauncher and not onboarding.onboardingHighlight.Enabled)
for _, part in onboarding.onboardingTrailParts do
	assert(part.Transparency >= 0 and part.Transparency <= 0.1, "Visible route pulse should remain subtle and readable")
end

f.operating = true
onboarding.setPizzaTrailVisible(false, false)
assert(not f.guide.Enabled and not onboarding.onboardingHighlight.Enabled and not onboarding.onboardingTrailActive)
assert(#f.tweens == 36)
for _, tween in f.tweens do
	assert(tween.played and tween.duration > 0 and tween.duration <= 0.5 and tween.goals.Transparency == 1)
	assert(tween.part.Transparency < 1, "Mounting should fade the route instead of snapping it away")
	tween:complete()
end
f:update()
for _, part in onboarding.onboardingTrailParts do assert(part.Transparency == 1, "Hidden route must stay hidden on subsequent updates") end
f.operating = false
onboarding.setPizzaTrailVisible(true, true)
onboarding.setPizzaTrailVisible(false, false)
local interruptedFade = table.clone(f.tweens)
onboarding.setPizzaTrailVisible(true, true)
for _, tween in interruptedFade do
	assert(tween.cancelled, "Showing the route must cancel its pending hide tween")
	tween:complete()
end
for _, part in onboarding.onboardingTrailParts do
	near(part.Transparency, part:GetAttribute("TrailBaseTransparency"), "A stale fade hid the restarted route")
end
onboarding.onboardingCompleted = true
onboarding.setPizzaTrailVisible(false, true)
onboarding.beginPizzaTrail()
assert(not onboarding.onboardingTrailActive and not f.guide.Enabled, "Completed onboarding must not restart itself")
f.player.Character = nil
f:update()
onboarding.onboardingCompleted = false
f:update()
onboarding.beginPizzaTrail()
assert(onboarding.onboardingTrailActive and not onboarding.onboardingReachedLauncher, "Incomplete respawn should restart guidance without stale proximity")

local missing = fixture({ missingAnchor = true })
missing.onboarding.beginPizzaTrail()
assert(not missing.onboarding.onboardingTrailFolder and #missing.requests == 0, "Missing streamed anchor must not create misplaced route art")
missing.anchor.Parent = missing.world
missing:update()
assert(missing.onboarding.onboardingTrailFolder and #missing.requests == 12, "A late anchor must allow route construction to recover")
local miss = fixture({ miss = 2 })
miss.onboarding.beginPizzaTrail()
assert(#miss.requests == 12 and #miss.onboarding.onboardingTrailParts == 33, "A missed floor ray must omit its marker instead of inventing a floor")
print("PASS: actual Onboarding constructs two anchored six-marker routes with approved per-marker floor casts and 36 plain nonphysical parts; proximity/input, fade cancellation, completion, missing root/anchor and missed floor recover safely")
