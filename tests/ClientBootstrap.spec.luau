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
camera.CameraSubject = humanoid
local replicated = instance("ReplicatedStorage")
local shared = child(replicated, "Folder", "Shared")
local configObject = child(shared, "ModuleScript", "Config")
local remotes = child(replicated, "Folder", "PizzaLaunchRemotes")
local launch = child(remotes, "RemoteEvent", "LaunchPizza")
local stateRemote = child(remotes, "RemoteEvent", "GameState")
local purchase = child(remotes, "RemoteEvent", "PurchaseUpgrade")
local mode = child(remotes, "RemoteEvent", "LauncherMode")
local sent = {}
for _, remote in { launch, purchase, mode } do function remote:FireServer(...) table.insert(sent, { remote = self.Name, arguments = table.pack(...) }) end end
local inputService = { TouchEnabled = true, GamepadEnabled = false, InputBegan = signal(), InputEnded = signal(), InputChanged = signal(), WindowFocusReleased = signal(), TextBoxFocused = signal() }
function inputService:GetFocusedTextBox() return nil end
local selectedBefore = child(playerGui, "TextButton", "PreviouslySelected")
local guiService = { SelectedObject = selectedBefore }
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
for _, name in { "UITheme", "UIConstruction", "UIPresentation", "Onboarding", "Feedback", "LauncherInputState", "ClientInput", "ClientCamera" } do
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
local function send(modeName, phase, epoch)
	stateRemote.OnClientEvent:fire({ mode = modeName == "none" and "walk" or "launcher", launcherMode = modeName,
		cleanupEpoch = epoch, recordRun = { status = phase, score = 12, personalBest = 15 }, upgrades = {}, coins = 10,
		shotActive = false, reloadDelay = 0, event = "state" })
end
send("select", "idle", 1)
assert(find("LauncherModeSelection").Visible and not find("Controls").Visible and not touchGui.Enabled)
assert(boundActions.BlockMovement)
find("FreePlay").Activated:fire()
assert(sent[#sent].remote == "LauncherMode" and sent[#sent].arguments[1] == "freePlay")
send("freePlay", "idle", 2)
assert(find("Controls").Visible and not find("LauncherModeSelection").Visible and find("ShopToggle").Visible)
find("ShopToggle").Activated:fire()
assert(not find("Controls").Visible and find("ExitLauncher").Visible)
find("ShopToggle").Activated:fire()
assert(find("Controls").Visible)
render(0.016)
assert(camera.CameraType == roblox.Enum.CameraType.Scriptable and camera.FieldOfView == 57)
send("recordRun", "finished", 3)
assert(find("RecordSummary").Visible and not find("Controls").Visible)
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
local replacement = child(world, "Model", "ReplacementCharacter")
local replacementHumanoid = child(replacement, "Humanoid", "Humanoid")
replacementHumanoid.Health = 100
child(replacement, "Part", "HumanoidRootPart")
player.Character = replacement
player.CharacterAdded:fire(replacement)
for _, callback in table.clone(timers) do callback() end
table.clear(timers)
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
