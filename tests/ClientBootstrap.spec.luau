local loadModule = require("./support/LoadModule")
local roblox = require("@lune/roblox")
local function signal()
	local result = { handlers = {} }
	function result:Connect(callback)
		self.handlers[callback] = true
		return { Disconnect = function() self.handlers[callback] = nil end }
	end
	function result:Once(callback)
		local connection
		connection = self:Connect(function(...) connection:Disconnect(); callback(...) end)
		return connection
	end
	function result:fire(...) for callback in self.handlers do callback(...) end end
	function result:Wait() end
	return result
end
local events = { Activated = true, InputBegan = true, InputEnded = true, ChildAdded = true, ChildRemoved = true, CharacterAdded = true, CharacterRemoving = true, Died = true, OnClientEvent = true }
local created = {}
local function instance(class)
	local self = { ClassName = class, Name = class, children = {}, attributes = {}, signals = {} }
	function self:IsA(name) return name == class or name == "Instance" or (name == "BasePart" and class == "Part") end
	function self:GetChildren() return self.children end
	function self:GetDescendants()
		local found = {}
		for _, child in self.children do
			table.insert(found, child)
			for _, descendant in child:GetDescendants() do table.insert(found, descendant) end
		end
		return found
	end
	function self:FindFirstChild(name, recursive)
		for _, child in (recursive and self:GetDescendants() or self.children) do if child.Name == name then return child end end
		return nil
	end
	function self:WaitForChild(name) return self:FindFirstChild(name) end
	function self:FindFirstChildOfClass(name) for _, child in self.children do if child:IsA(name) then return child end end return nil end
	function self:GetAttribute(name) return self.attributes[name] end
	function self:SetAttribute(name, value) self.attributes[name] = value end
	function self:GetPropertyChangedSignal(name) self.signals[name] = self.signals[name] or signal(); return self.signals[name] end
	function self:GetAttributeChangedSignal(name) return self:GetPropertyChangedSignal(name) end
	function self:IsAncestorOf(other) while other do if other.Parent == self then return true end; other = other.Parent end return false end
	function self:Destroy() self.Parent = nil end
	setmetatable(self, {
		__index = function(object, key)
			if events[key] then object.signals[key] = object.signals[key] or signal(); return object.signals[key] end
			for _, child in object.children do if child.Name == key then return child end end
			return nil
		end,
		__newindex = function(object, key, value)
			rawset(object, key, value)
			if key == "Parent" and value then table.insert(value.children, object) end
		end,
	})
	table.insert(created, self)
	return self
end
local function child(parent, class, name)
	local object = instance(class)
	object.Name = name
	object.Parent = parent
	return object
end
local world = instance("Workspace")
function world:GetServerTimeNow() return os.clock() end
local camera = child(world, "Camera", "Camera")
camera.CameraType = roblox.Enum.CameraType.Custom
camera.FieldOfView = 70
camera.ViewportSize = roblox.Vector2.new(667, 375)
world.CurrentCamera = camera
local player = instance("Player")
local playerGui = child(player, "PlayerGui", "PlayerGui")
child(player, "PlayerScripts", "PlayerScripts")
local touchGui = child(playerGui, "ScreenGui", "TouchGui")
touchGui.Enabled = true
local character = child(world, "Model", "TestCharacter")
player.Character = character
local humanoid = child(character, "Humanoid", "Humanoid")
humanoid.Health = 100
local root = child(character, "Part", "HumanoidRootPart")
root.Position = roblox.Vector3.zero
root.CFrame = roblox.CFrame.new(root.Position)
camera.CameraSubject = humanoid
local replicated = instance("ReplicatedStorage")
local shared = child(replicated, "Folder", "Shared")
local configObject = child(shared, "ModuleScript", "Config")
local remotes = child(replicated, "Folder", "PizzaLaunchRemotes")
local launch = child(remotes, "RemoteEvent", "LaunchPizza")
local stateRemote = child(remotes, "RemoteEvent", "GameState")
local purchase = child(remotes, "RemoteEvent", "PurchaseUpgrade")
local mode = child(remotes, "RemoteEvent", "LauncherMode")
local activity = child(remotes, "RemoteEvent", "RestaurantActivity")
local takeout = child(remotes, "RemoteEvent", "TakeoutAction")
local queue = child(remotes, "RemoteEvent", "QueueAction")
local sent = {}
for _, remote in { launch, purchase, mode, takeout, queue } do function remote:FireServer(...) table.insert(sent, { remote = self.Name, arguments = table.pack(...) }) end end
local inputService = { TouchEnabled = true, KeyboardEnabled = false, PreferredInput = roblox.Enum.PreferredInput.Touch, GamepadEnabled = false, InputBegan = signal(), InputEnded = signal(), InputChanged = signal(), WindowFocusReleased = signal(), TextBoxFocused = signal() }
function inputService:GetFocusedTextBox() return nil end
local selectedBefore = child(playerGui, "TextButton", "PreviouslySelected")
local guiService = { SelectedObject = selectedBefore }
local guiInset = roblox.Vector2.new(0, 44)
function guiService:GetGuiInset() return guiInset, roblox.Vector2.zero end
local boundActions = {}
local actions = {}
function actions:BindActionAtPriority(name) boundActions[name] = true end
function actions:UnbindAction(name) boundActions[name] = nil end
local render
local run = {}
function run:BindToRenderStep(_, _, callback) render = callback end
local timers = {}
local tasks = { defer = function(callback) table.insert(timers, callback) end, delay = function(_, callback) table.insert(timers, callback) end }
local tweenService = {}
function tweenService:Create(target, _, properties)
	local tween = { Completed = signal() }
	function tween:Play() for key, value in properties do target[key] = value end end
	function tween:Cancel() self.Completed:fire() end
	return tween
end
local services = { Players = { LocalPlayer = player }, ReplicatedStorage = replicated, Workspace = world, GuiService = guiService,
	ContextActionService = actions, RunService = run, UserInputService = inputService, TweenService = tweenService, TextService = {} }
local game = {}
function game:GetService(name) return assert(services[name], name) end
local scriptObject = { Parent = {} }
local modules = {}
local overrides = { Instance = { new = instance }, task = tasks, game = game, script = scriptObject,
	ColorSequence = roblox.ColorSequence, ColorSequenceKeypoint = roblox.ColorSequenceKeypoint,
	TweenInfo = { new = function(...) return table.pack(...) end } }
modules[configObject] = loadModule("src/shared/Config.luau")
overrides.require = function(name) return assert(modules[name], "Unknown module " .. tostring(name)) end
for _, name in { "UITheme", "UIConstruction", "UIPresentation", "Onboarding", "Feedback", "LauncherInputState", "ClientInput", "ClientCamera", "ActivityPresentation", "ActivityHUD", "ResponsiveLayout", "ResponsiveUI" } do
	scriptObject[name] = name
	scriptObject.Parent[name] = name
	modules[name] = loadModule("src/client/" .. name .. ".luau", overrides)
end
loadModule("src/client/init.client.luau", overrides)
-- Resolve startup character/controls tasks before exercising the launcher.
for _, callback in table.clone(timers) do callback() end
table.clear(timers)
local function find(name) for _, item in created do if item.Name == name then return item end end error(name) end
assert(find("ShopToggle").Visible, "Upgrades must exist and be visible before the first remote")
assert(find("ExitLauncher").Text == "EXIT", "Touch must not display keyboard exit labels")
for _, item in created do if item.ClassName == "UIStroke" then assert(item.ApplyStrokeMode == roblox.Enum.ApplyStrokeMode.Border) end end
local safeRoot = find("SafeContent")
assert(find("PizzaLaunchHUD").ScreenInsets == roblox.Enum.ScreenInsets.CoreUISafeInsets)
local function inside(item, width, height)
	local anchor = item.AnchorPoint or roblox.Vector2.zero
	local left = item.Position.X.Scale * width + item.Position.X.Offset - item.Size.X.Offset * anchor.X
	local top = item.Position.Y.Scale * height + item.Position.Y.Offset - item.Size.Y.Offset * anchor.Y
	assert(left >= 0 and top >= 0 and left + item.Size.X.Offset <= width and top + item.Size.Y.Offset <= height,
		string.format("%s escapes safe content %dx%d: %.1f,%.1f %.1fx%.1f", item.Name, width, height, left, top, item.Size.X.Offset, item.Size.Y.Offset))
end
for _, profile in { { 667, 375, 44 }, { 874, 402, 44 }, { 1024, 768, 44 }, { 1366, 841, 44 } } do
	camera.ViewportSize = roblox.Vector2.new(profile[1], profile[2])
	safeRoot.AbsoluteSize = roblox.Vector2.new(profile[1], profile[2] - profile[3])
	for _, kind in { roblox.Enum.PreferredInput.Touch, roblox.Enum.PreferredInput.KeyboardAndMouse, roblox.Enum.PreferredInput.Gamepad } do
		-- A hybrid device keeps touch hardware available while preference changes.
		inputService.KeyboardEnabled, inputService.GamepadEnabled = true, true
		inputService.PreferredInput = kind
		render(0.016)
		for _, name in { "Stats", "ShopToggle", "ExitLauncher", "ChangeMode", "RoundCard", "RecordRunHUD", "LauncherModeSelection", "Controls", "TouchAimPad", "RecordSummary", "ShopPanel", "WalkHint" } do
			inside(find(name), safeRoot.AbsoluteSize.X, safeRoot.AbsoluteSize.Y)
		end
		local exitText = find("ExitLauncher").Text
		if kind == roblox.Enum.PreferredInput.Touch then assert(exitText == "EXIT")
		elseif kind == roblox.Enum.PreferredInput.Gamepad then assert(exitText:find("%[B%]"))
		else assert(exitText:find("%[Q%]")) end
		assert(find("LaunchButton").Size.X.Offset >= 44 and find("LaunchButton").Size.Y.Offset >= 44)
		for _, direction in { "Up", "Down", "Left", "Right" } do assert(find(direction).Size.Y.Offset >= 44) end
		local heading = find("RecordRun"):FindFirstChild("Title")
		assert(heading.Size.Y.Offset >= heading.TextSize * 2.2, "Both public Record Run heading lines must fit")
		assert(find("RecordRun"):FindFirstChild("Description").TextSize >= 16)
		assert(find("ShopPanel"):FindFirstChild("UpgradeCards").CanvasSize.Y.Offset > find("ShopPanel"):FindFirstChild("UpgradeCards").Size.Y.Offset or profile[2] > 700)
	end
end
-- Regression evidence from the native 666x374 Studio landscape run. These
-- observed projections are a specific fixture, not a simulated engine/render
-- pass. GUI local positions must include GetGuiInset before comparison with
-- WorldToViewportPoint coordinates.
camera.ViewportSize = roblox.Vector2.new(666, 374)
safeRoot.AbsoluteSize = roblox.Vector2.new(666, 316)
inputService.PreferredInput = roblox.Enum.PreferredInput.Touch
guiInset = roblox.Vector2.new(0, 58)
render(0.016)
local nativeProjections = { { 210, 217 }, { 447, 211 }, { 229, 191 }, { 431, 187 }, { 263, 176 }, { 400, 174 } }
local inset = guiService:GetGuiInset()
for _, name in { "RecordRunHUD", "RoundCard", "Controls", "TouchAimPad", "ShopToggle", "ExitLauncher", "ChangeMode" } do
	local item = find(name)
	local anchor = item.AnchorPoint or roblox.Vector2.zero
	local left = item.Position.X.Offset - item.Size.X.Offset * anchor.X + inset.X
	local top = item.Position.Y.Offset - item.Size.Y.Offset * anchor.Y + inset.Y
	for index, point in nativeProjections do
		assert(point[1] < left - 14 or point[1] > left + item.Size.X.Offset + 14 or point[2] < top - 14 or point[2] > top + item.Size.Y.Offset + 14,
			string.format("%s overlaps native table %d including 58px GUI inset and14px ring margin", name, index))
	end
end
camera.ViewportSize = roblox.Vector2.new(667, 375)
safeRoot.AbsoluteSize = roblox.Vector2.new(667, 331)
guiInset = roblox.Vector2.new(0, 44)
inputService.PreferredInput = roblox.Enum.PreferredInput.Touch
render(0.016)
local activitySnapshot = {
	activityEpoch = 0, character = character, event = "launcherOccupied", coins = 10, upgrades = {},
	runner = { status = "idle", pickupPosition = roblox.Vector3.new(-50, 3, 98), normalReward = 8, quickBonus = 2 },
	queue = { status = "none" }, station = { occupied = true, operatorName = "Bo", launcherMode = "freePlay", waitingCount = 1 },
}
activity.OnClientEvent:fire(activitySnapshot)
render(0.016)
assert(find("OccupiedLauncherChoices").Visible and camera.CameraType == roblox.Enum.CameraType.Custom and touchGui.Enabled)
assert(find("NowPlaying").Text:find("NO TIME LIMIT"))
find("JoinLine").Activated:fire()
assert(sent[#sent].remote == "QueueAction" and sent[#sent].arguments[1] == "join" and sent[#sent].arguments[2] == 0)
activitySnapshot.event, activitySnapshot.queue = "queueChanged", { status = "waiting", position = 2 }
activity.OnClientEvent:fire(activitySnapshot)
render(0.016)
assert(find("WalkingActivity").Visible and not find("OccupiedLauncherChoices").Visible)
find("DoTakeout").Activated:fire()
assert(sent[#sent].remote == "TakeoutAction" and sent[#sent].arguments[1] == "route")
activitySnapshot.event = "takeoutRoute"
activity.OnClientEvent:fire(activitySnapshot)
render(0.016)
assert(find("LocalTakeoutMarker").CanCollide == false and not find("WalkHint").Visible)
activitySnapshot.event = "activity"
activitySnapshot.runner.routePositions = { roblox.Vector3.new(-16, 3, 145), roblox.Vector3.new(-16, 3, 100), roblox.Vector3.new(-50, 3, 98) }
root.Position = roblox.Vector3.new(-16, 3, 153)
activity.OnClientEvent:fire(activitySnapshot)
render(0.016)
assert(find("LocalTakeoutMarker").Position == roblox.Vector3.new(-16, 7, 145), "Return route retains a clearance corner eight units away")
root.Position = roblox.Vector3.new(-16, 3, 145)
render(0.016)
assert(find("LocalTakeoutMarker").Position == roblox.Vector3.new(-16, 7, 100), "Return route advances only after reaching its corner")
root.Position = roblox.Vector3.zero
activitySnapshot.event = "runnerStarted"
activitySnapshot.runner = { status = "carrying", orderId = "test:1", destinationName = "SUNNY SCOOPS", destinationPosition = roblox.Vector3.new(44, 3, 152), normalReward = 8, quickBonus = 2 }
activity.OnClientEvent:fire(activitySnapshot)
render(0.016)
assert(find("LocalTakeoutBox").CanCollide == false and find("LocalTakeoutBox").CanTouch == false and find("LocalTakeoutBox").CanQuery == false)
assert(touchGui.Enabled and not boundActions.BlockMovement, "Runner snapshots preserve walking controls")
activitySnapshot.event, activitySnapshot.payload = "restaurantMilestone", nil
activity.OnClientEvent:fire(activitySnapshot)
assert(not find("Message").Text:find("earned"), "Shared celebration cannot imply an AFK reward")
activitySnapshot.event, activitySnapshot.payload = "restaurantReward", { coinsEarned = 5 }
activity.OnClientEvent:fire(activitySnapshot)
assert(find("Message").Text:find("earned %+5"), "Contributor reward uses actor-only authoritative receipt")
activitySnapshot.event, activitySnapshot.payload = "restaurantMilestone", nil
activity.OnClientEvent:fire(activitySnapshot)
assert(find("Message").Text:find("earned %+5"), "Generic broadcast cannot replace the contributor's reward receipt")
local function send(modeName, phase, epoch)
	stateRemote.OnClientEvent:fire({ mode = modeName == "none" and "walk" or "launcher", launcherMode = modeName,
		cleanupEpoch = epoch, recordRun = { status = phase, score = 12, personalBest = 15 }, upgrades = {}, coins = 10,
		shotActive = false, reloadDelay = 0, event = "state" })
end
send("select", "idle", 1)
assert(find("LauncherModeSelection").Visible and not find("Controls").Visible and not touchGui.Enabled)
assert(boundActions.BlockMovement)
find("FreePlay").Activated:fire()
assert(sent[#sent].remote == "LauncherMode" and sent[#sent].arguments[1] == "freePlay" and sent[#sent].arguments[2] == 1, "Mode requests carry their lease epoch")
send("freePlay", "idle", 2)
assert(find("Controls").Visible and not find("LauncherModeSelection").Visible and find("ShopToggle").Visible)
assert(find("TouchAimPad").Visible and not find("Tutorial").Visible, "Compact touch keeps aim controls and omits the duplicate tutorial panel")
inputService.PreferredInput = roblox.Enum.PreferredInput.KeyboardAndMouse
render(0.016)
assert(not find("TouchAimPad").Visible and find("Help").Text:find("SPACE"), "Hybrid keyboard switches control labels without relying on TouchEnabled")
inputService.PreferredInput = roblox.Enum.PreferredInput.Gamepad
render(0.016)
assert(not find("TouchAimPad").Visible and find("Help").Text:find("RT"))
local focusBeforeShop = guiService.SelectedObject
find("ShopToggle").Activated:fire()
assert(guiService.SelectedObject == find("tips"), "Controller enters the visible upgrade list")
find("ShopToggle").Activated:fire()
assert(guiService.SelectedObject == focusBeforeShop, "Closing the upgrade list restores prior selection")
inputService.PreferredInput = roblox.Enum.PreferredInput.Touch
render(0.016)
assert(find("TouchAimPad").Visible and not find("Help").Text:find("SPACE"))
stateRemote.OnClientEvent:fire({ mode = "launcher", launcherMode = "freePlay", cleanupEpoch = 2,
	recordRun = { status = "idle" }, upgrades = {}, coins = 10, shotActive = false, reloadDelay = 0,
	event = "shiftEventStarted", payload = { title = "DINNER RUSH", description = "Serve customers for a bonus." } })
assert(find("ShiftEventBanner").Visible)
find("ShopToggle").Activated:fire()
assert(not find("Controls").Visible and find("ExitLauncher").Visible)
assert(not find("ShiftEventBanner").Visible, "Opening upgrades hides an already-visible event without resetting projectile feedback")
find("ShopToggle").Activated:fire()
assert(find("Controls").Visible)
render(0.016)
assert(camera.CameraType == roblox.Enum.CameraType.Scriptable and camera.FieldOfView == 57)
assert(find("ExitLauncher").Text == "EXIT &\nPASS TURN")
assert(not find("WalkingActivity").Visible and find("LocalTakeoutBox").Parent == nil)
local previousRoundText = find("RoundTitle").Text
local previousScoreText = find("Score").Text
activitySnapshot.event, activitySnapshot.payload, activitySnapshot.coins = "restaurantReward", { coinsEarned = 5 }, 15
activity.OnClientEvent:fire(activitySnapshot)
render(0.016)
assert(find("RoundTitle").Text == previousRoundText and find("Score").Text == previousScoreText and find("Controls").Visible)
assert(not find("ActivityNotice").Visible and not find("WalkingActivity").Visible, "Activity rewards remain quiet during mounted play")
send("recordRun", "finished", 3)
assert(find("RecordSummary").Visible and not find("Controls").Visible)
inputService.PreferredInput = roblox.Enum.PreferredInput.Gamepad
render(0.016)
assert(guiService.SelectedObject == find("Continue"), "Controller can choose another mode directly from results")
inputService.PreferredInput = roblox.Enum.PreferredInput.Touch
render(0.016)
find("ShopToggle").Activated:fire()
find("ShopToggle").Activated:fire()
assert(not find("Controls").Visible and find("RecordSummary").Visible)
player.CharacterRemoving:fire(character)
assert(camera.CameraType == roblox.Enum.CameraType.Custom and camera.FieldOfView == 70)
assert(touchGui.Enabled and not boundActions.BlockMovement and guiService.SelectedObject == selectedBefore)
assert(not find("RecordSummary").Visible and not find("LauncherModeSelection").Visible)
send("recordRun", "running", 3)
assert(not find("Controls").Visible, "Late old-lease snapshot cannot remount local presentation after removal")
player.CharacterRemoving:fire(character)
assert(touchGui.Enabled and camera.CameraType == roblox.Enum.CameraType.Custom)
activity.OnClientEvent:fire(activitySnapshot)
render(0.016)
assert(not find("WalkingActivity").Visible, "Old character activity snapshots cannot resurrect an objective after cleanup")
local replacement = child(world, "Model", "ReplacementCharacter")
local replacementHumanoid = child(replacement, "Humanoid", "Humanoid")
replacementHumanoid.Health = 100
local replacementRoot = child(replacement, "Part", "HumanoidRootPart")
replacementRoot.CFrame = roblox.CFrame.new()
replacementRoot.Position = roblox.Vector3.zero
player.Character = replacement
activitySnapshot.activityEpoch, activitySnapshot.character = 1, replacement
activitySnapshot.event = "queueChanged"
activitySnapshot.runner = { status = "idle", pickupPosition = roblox.Vector3.new(-50, 3, 98) }
activitySnapshot.queue = { status = "waiting", position = 1 }
activity.OnClientEvent:fire(activitySnapshot)
player.CharacterAdded:fire(replacement)
for _, callback in table.clone(timers) do callback() end
table.clear(timers)
activity.OnClientEvent:fire(activitySnapshot)
render(0.016)
assert(find("WalkingActivity").Visible, "Repeated same-epoch new-character snapshot recovers when the first packet precedes CharacterAdded")
local oldCharacterPacket = table.clone(activitySnapshot)
oldCharacterPacket.character = character
oldCharacterPacket.runner = { status = "carrying", orderId = "old-character" }
activity.OnClientEvent:fire(oldCharacterPacket)
render(0.016)
assert(find("Objective").Text == "YOU'RE IN LINE #1", "Old character packet cannot replace the new character's objective")
send("freePlay", "idle", 4)
assert(find("Controls").Visible)
humanoid.Died:fire()
player.CharacterRemoving:fire(character)
assert(find("Controls").Visible and boundActions.BlockMovement, "Replaced character callbacks cannot clear a new lease")
local replacementCamera = child(world, "Camera", "ReplacementCamera")
replacementCamera.FieldOfView = 76
replacementCamera.CameraType = roblox.Enum.CameraType.Custom
replacementCamera.CameraSubject = replacementHumanoid
world.CurrentCamera = replacementCamera
render(0.016)
assert(replacementCamera.CameraType == roblox.Enum.CameraType.Scriptable)
replacementHumanoid.Health = 0
replacementHumanoid.Died:fire()
assert(not find("Controls").Visible and touchGui.Enabled and not boundActions.BlockMovement)
assert(replacementCamera.CameraType == roblox.Enum.CameraType.Custom and replacementCamera.FieldOfView == 76)
print("PASS: actual client bootstrap, construction, modal transitions, touch exit labels, border strokes and repeated removal restoration with explicit engine doubles")
