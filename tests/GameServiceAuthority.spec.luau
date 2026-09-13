local loadModule = require("./support/LoadModule")
local roblox = require("@lune/roblox")
local function signal()
	local result = { listeners = {} }
	function result:Connect(callback)
		local connection = { Connected = true }
		function connection:Disconnect() self.Connected = false end
		table.insert(self.listeners, { callback, connection })
		return connection
	end
	function result:fire(...)
		for _, item in self.listeners do if item[2].Connected then item[1](...) end end
	end
	return result
end
local events = { OnServerEvent = true, Triggered = true, CharacterAdded = true, CharacterRemoving = true,
	ChildAdded = true, DescendantAdded = true, Died = true, PlayerAdded = true, PlayerRemoving = true }
local created, snapshots = {}, {}
local function instance(className)
	local self = { ClassName = className, Name = className, children = {}, attributes = {}, events = {} }
	function self:IsA(name) return name == className or name == "Instance" or (name == "BasePart" and className == "Part") end
	function self:GetChildren() return self.children end
	function self:GetDescendants()
		local result = {}
		for _, child in self.children do
			table.insert(result, child)
			for _, descendant in child:GetDescendants() do table.insert(result, descendant) end
		end
		return result
	end
	function self:FindFirstChild(name, recursive)
		for _, child in (recursive and self:GetDescendants() or self.children) do if child.Name == name then return child end end
		return nil
	end
	function self:WaitForChild(name) return assert(self:FindFirstChild(name), name) end
	function self:FindFirstChildOfClass(name) for _, child in self.children do if child:IsA(name) then return child end end return nil end
	function self:SetAttribute(key, value) self.attributes[key] = value end
	function self:GetAttribute(key) return self.attributes[key] end
	function self:SetNetworkOwner(owner) assert(owner == nil) end
	function self:ApplyImpulse(_) end
	function self:ApplyAngularImpulse(_) end
	function self:Destroy() self.Parent = nil end
	function self:FireClient(player, snapshot) snapshots[player] = snapshot end
	setmetatable(self, {
		__index = function(object, key)
			if key == "Position" and object.CFrame then return object.CFrame.Position end
			if events[key] then object.events[key] = object.events[key] or signal(); return object.events[key] end
			return object:FindFirstChild(key)
		end,
		__newindex = function(object, key, value)
			rawset(object, key, value)
			if key == "Parent" and value then table.insert(value.children, object) end
		end,
	})
	table.insert(created, self)
	return self
end
local function child(parent, className, name)
	local item = instance(className)
	item.Name, item.Parent = name, parent
	return item
end
local config = loadModule("src/shared/Config.luau")
local workspace = instance("Workspace")
function workspace:GetServerTimeNow() return 10 end
local world = child(workspace, "Model", "PizzaLaunchWorld")
local anchor = child(world, "Part", "LauncherInteractionAnchor")
anchor.CFrame = roblox.CFrame.new(0, 2.4, 84)
local prompt = child(anchor, "ProximityPrompt", "LauncherPrompt")
prompt.Enabled = true
local prop = child(world, "Part", "TestCup")
prop.CFrame = roblox.CFrame.new(0, 8, 0)
prop.Size = roblox.Vector3.new(2, 2, 2)
prop.Anchored, prop.CanCollide, prop.CanTouch, prop.CanQuery = true, true, true, true
prop.Transparency, prop.AssemblyMass = 0, 1
prop:SetAttribute("ReactiveProp", true)
local players = instance("Players")
local function addPlayer(name)
	local player = child(players, "Player", name)
	local character = child(workspace, "Model", name .. "Character")
	player.Character = character
	local root = child(character, "Part", "HumanoidRootPart")
	root.CFrame, root.Anchored = config.WALK_SPAWN_CFRAME, false
	local humanoid = child(character, "Humanoid", "Humanoid")
	humanoid.Health, humanoid.WalkSpeed, humanoid.JumpPower, humanoid.JumpHeight, humanoid.AutoRotate = 100, 16, 50, 7.2, true
	return player, root, humanoid
end
local owner, ownerRoot = addPlayer("Owner")
local walker, walkerRoot = addPlayer("Walker")
function players:GetPlayers() return { owner, walker } end
local replicated = instance("ReplicatedStorage")
local shared = child(replicated, "Folder", "Shared")
local configObject = child(shared, "ModuleScript", "Config")
local groups = {}
local physics = {}
function physics:IsCollisionGroupRegistered(name) return groups[name] end
function physics:RegisterCollisionGroup(name) groups[name] = true end
function physics:CollisionGroupSetCollidable(_, _, _) end
local services = { Players = players, Workspace = workspace, ReplicatedStorage = replicated, PhysicsService = physics, TweenService = {} }
local timers = {}
local modules = { [configObject] = config }
local parent = setmetatable({}, { __index = function(_, name) return name end })
local overrides = {
	game = { GetService = function(_, name) return assert(services[name], name) end },
	script = { Parent = parent }, Instance = { new = instance },
	task = { spawn = function() end, delay = function(_, callback) table.insert(timers, callback) end },
	require = function(name) return assert(modules[name], tostring(name)) end,
}
local noop = function() end
modules.CustomerService = { start = noop, getAvailableTables = function() return { 1, 2, 3, 4, 5, 6 } end }
modules.WorldActivityService = { start = noop }
modules.ShiftEventService = { reset = noop, getSnapshot = function() return nil end, extendTablePool = function(pool) return table.clone(pool) end }
modules.ServerEffects = { playSound = noop, coinBurst = noop, confettiBurst = noop, createSplat = noop, impactRing = noop }
local runStates = {}
modules.RecordRunService = {
	start = noop, addPlayer = function(player) runStates[player] = "idle" end,
	getSnapshot = function(player) return { status = runStates[player], personalBest = 0 } end,
	isSession = function(player) return runStates[player] ~= "idle" end,
	canLaunch = function() return true end,
	cancel = function(player) runStates[player] = "idle" end,
	removePlayer = function(player) runStates[player] = nil end,
}
for _, name in { "LayoutService", "PropService", "LauncherLease", "ShotPolicy", "ProjectileService", "DeliveryScoring", "PlayerProgression", "CustomerFeedback", "InteractionService" } do
	modules[name] = loadModule("src/server/" .. name .. ".luau", overrides)
end
local gameService = loadModule("src/server/GameService.luau", overrides)
gameService.start()
local remote = replicated:FindFirstChild(config.REMOTES_FOLDER):FindFirstChild(config.MODE_REMOTE)
prompt.Triggered:fire(owner)
assert(ownerRoot.Anchored and snapshots[owner].launcherMode == "select")
remote.OnServerEvent:fire(owner, "freePlay")
assert(snapshots[owner].launcherMode == "freePlay")
assert(modules.PropService.knock(prop, roblox.Vector3.new(0, 2, -1)))
local reset = timers[#timers]
local token = prop:GetAttribute("ResetToken")
prompt.Triggered:fire(walker)
assert(snapshots[walker].payload.result == "LAUNCHER OCCUPIED" and not walkerRoot.Anchored)
remote.OnServerEvent:fire(walker, "walk")
assert(not prop.Anchored and modules.PropService.getActiveCount() == 1 and prop:GetAttribute("ResetToken") == token,
	"walking exit cannot alter operator props or delayed reset ownership")
remote.OnServerEvent:fire(owner, "walk")
assert(prop.Anchored and modules.PropService.getActiveCount() == 0 and prop:GetAttribute("ResetToken") ~= token,
	"lease release restores props and invalidates the old callback before transfer")
assert(not ownerRoot.Anchored and prompt.Enabled)
prompt.Triggered:fire(walker)
assert(walkerRoot.Anchored and snapshots[walker].launcherMode == "select")
remote.OnServerEvent:fire(walker, "freePlay")
assert(modules.PropService.knock(prop, roblox.Vector3.new(0, 2, -1)))
reset()
assert(not prop.Anchored and modules.PropService.getActiveCount() == 1,
	"former operator callback cannot restore a later operator's active prop")
remote.OnServerEvent:fire(owner, "walk")
assert(not prop.Anchored and walkerRoot.Anchored, "former operator cannot clear the new lease")
remote.OnServerEvent:fire(walker, "walk")
remote.OnServerEvent:fire(walker, "walk")
assert(prop.Anchored and modules.PropService.getActiveCount() == 0 and not walkerRoot.Anchored)
print("PASS: actual GameService prompt/remote integration preserves nonowner isolation and resets props only on owner lease release")
