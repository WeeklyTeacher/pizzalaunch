local loadModule = require("./support/LoadModule")
local roblox = require("@lune/roblox")
local Vector3, CFrame = roblox.Vector3, roblox.CFrame
local config = loadModule("src/shared/Config.luau")
local policy = loadModule("src/server/ShotPolicy.luau")
local progression = loadModule("src/server/PlayerProgression.luau")
local scoring = loadModule("src/server/DeliveryScoring.luau")
local Lease = loadModule("src/server/LauncherLease.luau")

local function state()
	return { mode = "launcher", launcherMode = "freePlay", cleanupEpoch = 3, lastLaunch = -100,
		shotActive = false, round = 1, coins = 1000, upgrades = { assist = 0, tips = 0, reload = 0, power = 0 } }
end
local operator, walker = {}, {}
local current = state()
local aim = config.directionFromAim(0, 0.4)
local function validate(overrides)
	local data = { owns = true, playable = true, record = false, direction = aim, charge = 0.5, id = 1, epoch = 3, now = 10 }
	for key, value in overrides or {} do data[key] = value end
	return policy.validate(config, current, data.owns, data.playable, data.record, data.direction, data.charge, data.id, data.epoch, data.now)
end
local accepted = validate()
assert(accepted and accepted.charge == 0.5 and accepted.reloadTime == 0.85)
assert(not validate({ owns = false }), "non-owner launch rejected")
assert(not validate({ epoch = 2 }), "request from previous policy rejected")
assert(not validate({ id = 0 }) and not validate({ id = 0.5 }) and not validate({ id = math.huge }))
assert(not validate({ direction = Vector3.new(0, 0, 0) }) and not validate({ direction = Vector3.new(0, 1, 0) }))
assert(not validate({ direction = Vector3.new(0/0, 0.5, -1) }) and not validate({ charge = 0/0 }))
assert(validate({ charge = 2 }).charge == 1 and validate({ charge = -1 }).charge == 0)
current.launcherMode = "select"
assert(not validate() and not current.shotActive and current.lastLaunch == -100, "picker rejection has no readiness side effects")
current.launcherMode = "recordRun"
assert(not validate() and not validate({ record = true, playable = false }), "idle/countdown/results cannot shoot")
current.upgrades.reload = 3
assert(validate({ record = true }).reloadTime == 0.85, "record reload ignores inventory")
current.launcherMode = "freePlay"
assert(math.abs(validate().reloadTime - 0.544) < 0.0001)
current.lastLaunch = 9.9
assert(not validate(), "reload cadence enforced")
current.lastLaunch = -100
current.lastRequestId = 1
assert(not validate() and validate({ id = 2 }), "duplicate accepted request cannot spawn again")
current.shotActive = true
assert(not validate({ id = 2 }), "only one active shot")

-- A walking purchase succeeds in its own inventory but cannot drive station policy.
local inventory = state()
inventory.mode, inventory.launcherMode = "walk", "none"
local purchase = progression.purchase(config, inventory, "assist", false)
assert(purchase and inventory.upgrades.assist == 1 and inventory.coins == 955)
assert(not policy.canPresent(walker, operator, inventory))
assert(not policy.canPresent(operator, operator, { mode = "launcher", launcherMode = "recordRun" }))
assert(policy.canPresent(operator, operator, { mode = "launcher", launcherMode = "freePlay" }))
assert(not progression.purchase(config, inventory, "assist", true) and inventory.coins == 955)
assert(not progression.purchase(config, inventory, "madeUpUpgrade", false))
inventory.coins = 0
assert(not progression.purchase(config, inventory, "assist", false) and inventory.upgrades.assist == 1)

-- Extracted accuracy retains near/edge/far tiers and record fixed assistance.
local scoreState = state()
assert(scoring.accuracy(config, Vector3.zero, Vector3.new(3.8, 30, 0), scoreState, false).name == "PERFECT!")
assert(scoring.accuracy(config, Vector3.zero, Vector3.new(3.8, 30, 0), scoreState, true).name == "GREAT!")
scoreState.upgrades.assist = 3
assert(scoring.accuracy(config, Vector3.zero, Vector3.new(3.8, 30, 0), scoreState, true).name == "GREAT!")
assert(scoring.accuracy(config, Vector3.zero, Vector3.new(20, 0, 0), scoreState, false).name == "DELIVERED!")
local reward, combo, base = scoring.freePlayReward(config.ACCURACY[1], 8, 3)
assert(reward == 56 and combo == 12 and base == 32)

local function avatar()
	local root = { Parent = true, Position = config.LAUNCHER_OPERATOR_CFRAME.Position, Anchored = false, CFrame = CFrame.new() }
	function root:IsA(name) return name == "BasePart" end
	local humanoid = { Parent = true, Health = 100, WalkSpeed = 19, JumpPower = 46, JumpHeight = 8, AutoRotate = true }
	local character = { Parent = true, root = root, humanoid = humanoid }
	function character:FindFirstChild(name) return name == "HumanoidRootPart" and self.root or nil end
	function character:FindFirstChildOfClass(name) return name == "Humanoid" and self.humanoid or nil end
	return character, root, humanoid
end
local character, root, humanoid = avatar()
operator.Parent, operator.Character = true, character
local lease = Lease.new()
assert(lease:acquire(operator, character, config.LAUNCHER_OPERATOR_CFRAME))
assert(lease:isValid(operator) and root.Anchored and humanoid.WalkSpeed == 0 and humanoid.JumpHeight == 0)
assert(not lease:release(walker) and lease.owner == operator)
assert(not lease:acquire(walker, character, config.LAUNCHER_OPERATOR_CFRAME))
humanoid.Health = 0
assert(not lease:isValid(operator))
assert(lease:release(operator, config.LAUNCHER_EXIT_CFRAME))
assert(not root.Anchored and humanoid.WalkSpeed == 19 and humanoid.JumpHeight == 8 and humanoid.JumpPower == 46 and humanoid.AutoRotate)
assert(not lease:release(operator), "cleanup is idempotent")
humanoid.Health = 100
local replacement, newRoot = avatar()
operator.Character = replacement
assert(lease:acquire(operator, replacement, config.LAUNCHER_OPERATOR_CFRAME))
assert(not lease:release(operator, nil, character) and lease:isValid(operator), "old character cannot release new lease")
replacement.root = nil
assert(not lease:isValid(operator), "removed root invalidates mount immediately")
replacement.root = newRoot
newRoot.Anchored = false
assert(not lease:isValid(operator), "unanchored mount rejected")
newRoot.Anchored = true
newRoot.Position = Vector3.new(900, 0, 0)
assert(not lease:isValid(operator), "displaced mount rejected")
lease:release(operator)

local function signal()
	local event = { listeners = {} }
	function event:Connect(callback)
		local connection = { Connected = true }
		function connection:Disconnect() self.Connected = false end
		table.insert(self.listeners, { callback = callback, connection = connection })
		return connection
	end
	function event:Fire(value)
		for _, item in self.listeners do if item.connection.Connected then item.callback(value) end end
	end
	return event
end
local function part(reactive)
	local result = { Parent = true }
	function result:IsA(name) return name == "BasePart" end
	function result:GetAttribute(name) return name == "ReactiveProp" and reactive end
	function result:Destroy() self.Parent = nil end
	return result
end
local groups, relationships = {}, {}
local physics = {}
function physics:IsCollisionGroupRegistered(name) return groups[name] == true end
function physics:RegisterCollisionGroup(name) assert(not groups[name]); groups[name] = true end
function physics:CollisionGroupSetCollidable(a, b, value) relationships[a .. "/" .. b] = value end
local body, accessory, prop = part(false), part(false), part(true)
local characterEvent = signal()
local playerCharacter = { DescendantAdded = characterEvent, GetDescendants = function() return { body } end }
local otherPlayer = { Character = playerCharacter }
local createdParts, delayed = {}, {}
local testInstance = { new = function(className)
		local item = part(false)
		item.attributes, item.className = {}, className
		function item:SetAttribute(key, value) self.attributes[key] = value end
		function item:SetNetworkOwner(value) assert(value == nil); self.serverOwned = true end
		table.insert(createdParts, item)
		return item
	end }
local pizzaVisual = loadModule("src/shared/PizzaVisual.luau", { Instance = testInstance })
local projectiles = loadModule("src/server/ProjectileService.luau", {
	game = { GetService = function(_, name)
		if name == "PhysicsService" then return physics end
		if name == "ReplicatedStorage" then return { Shared = { PizzaVisual = "PizzaVisual" } } end
		return { GetPlayers = function() return { otherPlayer } end }
	end },
	Instance = testInstance,
	require = function(name) assert(name == "PizzaVisual"); return pizzaVisual end,
	PhysicalProperties = { new = function(...) return { ... } end },
	task = { delay = function(_, callback) table.insert(delayed, callback) end },
})
projectiles.start({ GetDescendants = function() return { prop } end })
projectiles.start({ GetDescendants = function() return { prop } end })
projectiles.bindCharacter(otherPlayer, playerCharacter)
characterEvent:Fire(accessory)
assert(body.CollisionGroup == "PizzaLaunchCharacters" and accessory.CollisionGroup == body.CollisionGroup)
assert(prop.CollisionGroup == "PizzaLaunchProps")
assert(relationships["PizzaLaunchCharacters/PizzaLaunchProjectiles"] == false)
assert(relationships["PizzaLaunchCharacters/PizzaLaunchProps"] == false, "bystanders cannot deflect loose props")
function body:IsDescendantOf(model) return model == playerCharacter end
assert(projectiles.isCharacterPart(body), "defensive contact ignores another avatar")
local pizza, laterPizza = part(false), part(false)
projectiles.prepare(pizza)
assert(pizza.CollisionGroup == "PizzaLaunchProjectiles")
local tracked = projectiles.track(operator, pizza, 3)
tracked.connection = signal():Connect(function() end)
assert(not projectiles.resolve(operator, pizza, 2), "old epoch cannot score")
projectiles.clear(operator)
projectiles.clear(operator)
assert(not tracked.connection.Connected and pizza.Parent == nil)
projectiles.track(operator, laterPizza, 4)
assert(not projectiles.resolve(operator, pizza, 3) and projectiles.isCurrent(operator, laterPizza, 4), "old callback cannot resolve later shot")
assert(projectiles.resolve(operator, laterPizza, 4) and not projectiles.resolve(operator, laterPizza, 4), "resolution is exactly once")
assert(laterPizza.CanCollide == false and laterPizza.CanTouch == false and laterPizza.CanQuery == false,
	"lingering result visuals cannot obstruct a later competitive shot")
projectiles.clear(operator)
assert(laterPizza.Parent == nil, "mode/lease cleanup removes resolved feedback visuals")
local nextVisual = part(false)
projectiles.track(operator, nextVisual, 5)
projectiles.resolve(operator, nextVisual, 5)
projectiles.removeVisual(operator, laterPizza)
assert(nextVisual.Parent ~= nil, "old delayed visual cleanup cannot delete a new result")
projectiles.removeVisual(operator, nextVisual)
assert(nextVisual.Parent == nil)
projectiles.unbindCharacter(otherPlayer)
local detached = part(false)
characterEvent:Fire(detached)
assert(detached.CollisionGroup == nil)
local soundCalls = 0
local builtPizza = projectiles.create(config, { Name = "Chef", UserId = 123 }, aim, 0.5, 0,
	function() soundCalls += 1 end, { launch = "existing-launch", whoosh = "existing-whoosh" })
assert(builtPizza.Size == Vector3.new(0.65, 6, 6) and builtPizza.serverOwned)
assert(builtPizza.CFrame.Position == config.LAUNCH_ORIGIN + aim * 1.8)
assert((builtPizza.AssemblyLinearVelocity - aim * config.speedFromCharge(0.5, 0)).Magnitude < 0.001)
assert(builtPizza.AssemblyAngularVelocity == Vector3.new(aim.Z * 17, 5, -aim.X * 17))
assert(builtPizza.CustomPhysicalProperties[1] == 0.65 and builtPizza.CustomPhysicalProperties[3] == 0.62)
assert(builtPizza.CollisionGroup == "PizzaLaunchProjectiles" and builtPizza.attributes.OwnerUserId == 123)
local toppings = 0
for _, item in createdParts do
	if item.Name and string.find(item.Name, "Pepperoni") then
		toppings += 1
		assert(item.CanCollide == false and item.CanTouch == false and item.CanQuery == false and item.Massless)
	end
end
assert(toppings == 6 and soundCalls == 1, "hero pizza uses six cosmetic pepperoni with unchanged launch sound")
builtPizza:Destroy()
delayed[#delayed]()
assert(soundCalls == 1, "cleared projectile cannot play delayed whoosh")
print("PASS: actual authority modules: lease lifecycle, request rejection/epoch/cadence, inventory isolation, scoring preservation, collision policy and stale shot ownership")
