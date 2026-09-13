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
local created, snapshots, activities, stateCounts = {}, {}, {}, {}
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
	function self:FireClient(player, snapshot)
		if self.Name == "RestaurantActivity" then activities[player] = snapshot
		else snapshots[player] = snapshot; stateCounts[player] = (stateCounts[player] or 0) + 1 end
	end
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
local now = 10
function workspace:GetServerTimeNow() return now end
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
	player.UserId = #players.children + 100
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
local third, thirdRoot = addPlayer("Third")
local fourth, fourthRoot = addPlayer("Fourth")
function players:GetPlayers() return { owner, walker, third, fourth } end
local replicated = instance("ReplicatedStorage")
local shared = child(replicated, "Folder", "Shared")
local configObject = child(shared, "ModuleScript", "Config")
local takeoutObject = child(shared, "ModuleScript", "TakeoutConfig")
local takeoutConfig = loadModule("src/shared/TakeoutConfig.luau")
local groups = {}
local physics = {}
function physics:IsCollisionGroupRegistered(name) return groups[name] end
function physics:RegisterCollisionGroup(name) groups[name] = true end
function physics:CollisionGroupSetCollidable(_, _, _) end
local services = { Players = players, Workspace = workspace, ReplicatedStorage = replicated, PhysicsService = physics, TweenService = {} }
local timers = {}
local modules = { [configObject] = config, [takeoutObject] = takeoutConfig }
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
local pickupPrompt, deliveryPrompts = nil, {}
modules.TakeoutWorld = { start = function()
	local pickup = child(world, "Part", "TakeoutPickup")
	pickup.CFrame = roblox.CFrame.new(takeoutConfig.pickupPosition)
	pickupPrompt = child(pickup, "ProximityPrompt", "TakeoutPickupPrompt")
	for _, destination in takeoutConfig.destinations do
		local point = child(world, "Part", destination.id)
		point.CFrame = roblox.CFrame.new(destination.position)
		local delivery = child(point, "ProximityPrompt", "TakeoutDeliveryPrompt")
		delivery:SetAttribute("DestinationId", destination.id)
		deliveryPrompts[destination.id] = delivery
	end
end, update = noop }
modules.ShiftEventService = { reset = noop, getSnapshot = function() return nil end, extendTablePool = function(pool) return table.clone(pool) end }
modules.ServerEffects = { playSound = noop, coinBurst = noop, confettiBurst = noop, createSplat = noop, impactRing = noop }
local runStates = {}
local recordChanged
modules.RecordRunService = {
	start = function(_, callback) recordChanged = callback end, addPlayer = function(player) runStates[player] = "idle" end,
	getSnapshot = function(player) return { status = runStates[player], personalBest = 1000, score = 500, combo = 3, endsAt = 1000 } end,
	begin = function(player) runStates[player] = "running"; recordChanged(player, "recordStarted"); return true end,
	isSession = function(player) return runStates[player] ~= "idle" end,
	canLaunch = function() return true end,
	cancel = function(player) runStates[player] = "idle" end,
	removePlayer = function(player) runStates[player] = nil end,
}
for _, name in { "TakeoutRunner", "LauncherQueue", "SharedMilestone", "LayoutService", "PropService", "LauncherLease", "ShotPolicy", "ProjectileService", "DeliveryScoring", "PlayerProgression", "CustomerFeedback", "InteractionService" } do
	modules[name] = loadModule("src/server/" .. name .. ".luau", overrides)
end
local gameService = loadModule("src/server/GameService.luau", overrides)
gameService.start()
local remote = replicated:FindFirstChild(config.REMOTES_FOLDER):FindFirstChild(config.MODE_REMOTE)
local function mode(player, action, epoch)
	remote.OnServerEvent:fire(player, action, epoch or snapshots[player].cleanupEpoch)
end
prompt.Triggered:fire(owner)
assert(ownerRoot.Anchored and snapshots[owner].launcherMode == "select")
mode(owner, "freePlay")
assert(snapshots[owner].launcherMode == "freePlay")
assert(modules.PropService.knock(prop, roblox.Vector3.new(0, 2, -1)))
local reset = timers[#timers]
local token = prop:GetAttribute("ResetToken")
prompt.Triggered:fire(walker)
assert(activities[walker].payload.result == "LAUNCHER OCCUPIED" and not walkerRoot.Anchored)
mode(walker, "walk")
assert(not prop.Anchored and modules.PropService.getActiveCount() == 1 and prop:GetAttribute("ResetToken") == token,
	"walking exit cannot alter operator props or delayed reset ownership")
mode(owner, "walk")
assert(prop.Anchored and modules.PropService.getActiveCount() == 0 and prop:GetAttribute("ResetToken") ~= token,
	"lease release restores props and invalidates the old callback before transfer")
assert(not ownerRoot.Anchored and prompt.Enabled)
prompt.Triggered:fire(walker)
assert(walkerRoot.Anchored and snapshots[walker].launcherMode == "select")
mode(walker, "freePlay")
assert(modules.PropService.knock(prop, roblox.Vector3.new(0, 2, -1)))
reset()
assert(not prop.Anchored and modules.PropService.getActiveCount() == 1,
	"former operator callback cannot restore a later operator's active prop")
mode(owner, "walk")
assert(not prop.Anchored and walkerRoot.Anchored, "former operator cannot clear the new lease")
mode(walker, "walk")
mode(walker, "walk")
assert(prop.Anchored and modules.PropService.getActiveCount() == 0 and not walkerRoot.Anchored)
print("PASS: actual GameService prompt/remote integration preserves nonowner isolation and resets props only on owner lease release")

-- Four clients share the station, while an independent walker completes and buys upgrades.
local folder = replicated:FindFirstChild(config.REMOTES_FOLDER)
local queueRemote = folder:FindFirstChild(config.QUEUE_REMOTE)
local takeoutRemote = folder:FindFirstChild(config.TAKEOUT_REMOTE)
local purchaseRemote = folder:FindFirstChild(config.PURCHASE_REMOTE)
local queueIds = {}
local function queueAction(player, action, epoch)
	now += 0.3
	queueIds[player] = (queueIds[player] or 0) + 1
	queueRemote.OnServerEvent:fire(player, action, epoch or activities[player].activityEpoch, queueIds[player])
end
prompt.Triggered:fire(owner)
local oldModeEpoch = snapshots[owner].cleanupEpoch
mode(owner, "recordRun")
assert(snapshots[owner].launcherMode == "recordRun")
local ownerState = snapshots[owner]
local ownerCount = stateCounts[owner]
queueAction(walker, "join")
queueAction(third, "join")
queueAction(fourth, "join")
assert(activities[walker].queue.position == 1 and activities[third].queue.position == 2 and activities[fourth].queue.position == 3)
assert(activities[owner].station.launcherMode == "recordRun" and activities[owner].station.score == 500)
local queueEpoch = activities[walker].activityEpoch
queueAction(walker, "leave", queueEpoch - 1)
assert(activities[walker].queue.position == 1, "stale activity request cannot cancel a new queue session")
queueRemote.OnServerEvent:fire(walker, "join", queueEpoch, queueIds[walker])
assert(activities[walker].queue.waitingCount == 3, "duplicate activity request cannot duplicate a queue entry")
for _ = 1, 6 do
	now += 0.3
	walkerRoot.CFrame = roblox.CFrame.new(takeoutConfig.pickupPosition)
	pickupPrompt.Triggered:fire(walker)
	assert(activities[walker].runner.status == "carrying")
	local order = activities[walker].runner
	now += 17
	walkerRoot.CFrame = roblox.CFrame.new(order.destinationPosition)
	deliveryPrompts[order.destinationId].Triggered:fire(walker)
	assert(activities[walker].runner.status == "idle")
end
assert(activities[walker].coins == 48 and activities[walker].queue.position == 1,
	"runner pays independent session coins while retaining queue position")
purchaseRemote.OnServerEvent:fire(walker, "assist")
assert(snapshots[walker].upgrades.assist == 1 and snapshots[walker].coins == 3)
assert(snapshots[owner] == ownerState and stateCounts[owner] == ownerCount and ownerRoot.Anchored,
	"runner/queue/walker purchase do not dispatch GameState or mutate competitive state for operator")
assert(snapshots[owner].recordRun.score == 500 and snapshots[owner].recordRun.combo == 3)
for _ = 1, 6 do
	now += 0.3
	thirdRoot.CFrame = roblox.CFrame.new(takeoutConfig.pickupPosition)
	pickupPrompt.Triggered:fire(third)
	local order = activities[third].runner
	assert(order.status == "carrying")
	now += 17
	thirdRoot.CFrame = roblox.CFrame.new(order.destinationPosition)
	deliveryPrompts[order.destinationId].Triggered:fire(third)
end
assert(activities[walker].coins == 13 and activities[third].coins == 58,
	"shared milestone rewards only the two actual runner contributors")
assert(activities[owner].coins == 0 and activities[fourth].coins == 0,
	"Record Run and waiting/AFK presence alone cannot earn the shared milestone")
assert(activities[owner].shared.cycle == 2 and activities[owner].shared.progress == 0)
assert(snapshots[owner] == ownerState and stateCounts[owner] == ownerCount,
	"shared milestone during Record Run has a separate presentation channel")
mode(owner, "walk", oldModeEpoch)
assert(ownerRoot.Anchored, "old mode request cannot exit a later policy epoch")
mode(owner, "walk")
assert(activities[walker].queue.status == "reserved" and not walkerRoot.Anchored)
prompt.Triggered:fire(third)
assert(not thirdRoot.Anchored and activities[third].event == "launcherOccupied", "waiting player cannot steal reservation")
prompt.Triggered:fire(walker)
assert(not walkerRoot.Anchored, "reserved player still must approach the launcher")
walkerRoot.CFrame = config.WALK_SPAWN_CFRAME
prompt.Triggered:fire(walker)
assert(walkerRoot.Anchored and activities[walker].queue.status == "none")
mode(walker, "freePlay")
assert(activities[third].station.launcherMode == "freePlay" and activities[third].station.waitingCount == 2)
assert(activities[third].station.endsAt == nil, "Free Play public snapshot must not imply a deadline")
print("PASS: four actual GameService client boundaries isolate runner/queue/purchases from records; reservations retain approach validation; stale mode/activity requests ignored")
