local loadModule = require("./support/LoadModule")
local roblox = require("@lune/roblox")
local Vector3 = roblox.Vector3
local Config = loadModule("src/shared/TakeoutConfig.luau")
local Runner = loadModule("src/server/TakeoutRunner.luau")

local function harness()
	local fake = { now = 100, states = {}, rewards = {}, events = {} }
	fake.runner = Runner.new({
		config = Config,
		now = function() return fake.now end,
		getState = function(player) return fake.states[player] end,
		award = function(player, receipt)
			assert(fake.runner:getSnapshot(player).status == "idle", "order must be consumed before reward")
			assert(not pcall(function() receipt.coinsEarned = 9999 end), "receipt must be immutable")
			fake.states[player].coins += receipt.coinsEarned
			table.insert(fake.rewards, { player = player, receipt = receipt })
			if fake.onAward then fake.onAward(player, receipt) end
		end,
		notify = function(player, event, payload)
			table.insert(fake.events, { player = player, event = event, payload = payload })
		end,
	})
	function fake:addPlayer(userId)
		local humanoid = { Parent = true, Health = 100, WalkSpeed = 16, JumpPower = 50, AutoRotate = true }
		local root = { Parent = true, Position = Config.pickupPosition, Anchored = false }
		function root:IsA(className) return className == "BasePart" end
		local character = { Parent = true, root = root, humanoid = humanoid }
		function character:FindFirstChild(name) return name == "HumanoidRootPart" and self.root or nil end
		function character:FindFirstChildOfClass(name) return name == "Humanoid" and self.humanoid or nil end
		local player = { Parent = true, UserId = userId, Character = character }
		fake.states[player] = { mode = "walk", coins = 0, cleanupEpoch = 1, combo = 7, round = 3, targetId = 4 }
		fake.runner:addPlayer(player)
		return player
	end
	function fake:wait(seconds)
		fake.now += seconds
		fake.runner:step()
	end
	function fake:walkTo(player, target, duration, jump)
		local start = player.Character.root.Position
		local count = math.ceil(duration / 0.25)
		for index = 1, count do
			local alpha = index / count
			player.Character.root.Position = start:Lerp(target, alpha) + Vector3.new(0, jump and math.sin(alpha * math.pi) * 6 or 0, 0)
			fake:wait(duration / count)
		end
	end
	return fake
end

do
	local fake = harness()
	local first, second = fake:addPlayer(42), fake:addPlayer(43)
	assert(fake.runner:pickup(first) and fake.runner:pickup(second), "one shelf serves independent players")
	local firstOrder, secondOrder = fake.runner:getSnapshot(first), fake.runner:getSnapshot(second)
	assert(firstOrder.status == "carrying" and firstOrder.destinationId ~= secondOrder.destinationId)
	assert(firstOrder.orderId ~= secondOrder.orderId and #firstOrder.routePositions == 5 and #secondOrder.routePositions == 4)
	assert(firstOrder.normalReward == 8 and firstOrder.quickBonus == 2)
	assert(firstOrder.quickBonusEndsAt == firstOrder.startedAt + 16)
	local originalId = firstOrder.orderId
	firstOrder.orderId, firstOrder.destinationName = "client-fake", "WRONG"
	firstOrder.routePositions[1] = Vector3.zero
	assert(fake.runner:getSnapshot(first).orderId == originalId)
	assert(fake.runner:getSnapshot(first).routePositions[1] == Config.routePositions[1], "snapshot mutation cannot change route policy")
	local beforeState = table.clone(fake.states[first])
	fake:walkTo(first, fake.runner:getSnapshot(first).destinationPosition, 12, true)
	fake.onAward = function(player, receipt)
		local ok = fake.runner:deliver(player, receipt.orderId)
		assert(not ok, "reentrant reward callback cannot consume an order twice")
	end
	local completed, receipt = fake.runner:deliver(first, originalId)
	assert(completed and receipt.coinsEarned == 10 and receipt.bonusEarned == 2 and receipt.elapsed == 12)
	assert(fake.states[first].coins == 10 and fake.states[second].coins == 0 and #fake.rewards == 1)
	local returnRoute = fake.runner:getSnapshot(first).routePositions
	assert(#returnRoute == 5 and returnRoute[1] == Config.destinations[1].approachPositions[2])
	assert(returnRoute[#returnRoute] == Config.pickupPosition, "far-side replay retraces the safe sidewalk/crosswalk route")
	assert(fake.runner:getSnapshot(second).orderId == secondOrder.orderId, "delivery must not touch another player's order")
	for key, value in beforeState do if key ~= "coins" then assert(fake.states[first][key] == value) end end
	local character = first.Character
	assert(character.humanoid.WalkSpeed == 16 and character.humanoid.JumpPower == 50 and character.humanoid.AutoRotate and not character.root.Anchored)
	fake:wait(0.3)
	assert(not fake.runner:deliver(first, originalId) and #fake.rewards == 1)
	fake:walkTo(first, Config.pickupPosition, 12)
	assert(#fake.runner:getSnapshot(first).routePositions == 1, "nearby pickup guidance stays direct")
	assert(fake.runner:pickup(first))
	local replay = fake.runner:getSnapshot(first)
	assert(replay.destinationId == secondOrder.destinationId and replay.orderId ~= originalId and replay.completedCount == 1)
	assert(not fake.runner:cancel(first, "cancelled", originalId) and fake.runner:getSnapshot(first).orderId == replay.orderId,
		"delayed cancel from prior order cannot cancel replay")
	fake:walkTo(first, replay.destinationPosition, 20)
	local finished, normal = fake.runner:deliver(first, replay.orderId)
	assert(finished and normal.coinsEarned == 8 and normal.bonusEarned == 0, "late service retains full normal reward")
	assert(fake.states[first].coins == 18)
	print("PASS: independent pickup/reward/replay, immutable receipts, normal jump/movement and no bonus deadline punishment")
end

do
	local fake = harness()
	local player = fake:addPlayer(42)
	player.Character.root.Position = Vector3.zero
	assert(not fake.runner:pickup(player))
	player.Character.root.Position = Config.pickupPosition
	fake:wait(0.3)
	assert(fake.runner:pickup(player))
	local order = fake.runner:getSnapshot(player)
	local eventCount = #fake.events
	for _ = 1, 40 do assert(not fake.runner:pickup(player)) end
	assert(#fake.events == eventCount and fake.runner:getSnapshot(player).orderId == order.orderId, "spam remains bounded and cannot reroll")
	fake:wait(0.3)
	assert(not fake.runner:deliver(player, "stale-id"))
	fake:wait(0.3)
	assert(not fake.runner:deliver(player, order.orderId), "pickup is not destination")
	fake:walkTo(player, Config.destinations[2].position, 12)
	assert(not fake.runner:deliver(player, order.orderId) and #fake.rewards == 0, "wrong desk cannot claim current order")
	assert(fake.runner:getSnapshot(player).status == "carrying")
	fake:walkTo(player, Config.destinations[1].position, 3)
	assert(fake.runner:deliver(player, order.orderId))
	assert(fake.states[player].coins == 10 and #fake.rewards == 1)
	print("PASS: distance, wrong destination, stale delivery and duplicate request validation")
end

for _, invalidation in { "death", "character", "root", "humanoid", "mounted", "anchor", "removed", "invalidPosition" } do
	local fake = harness()
	local player = fake:addPlayer(42)
	assert(fake.runner:pickup(player))
	local oldOrder = fake.runner:getSnapshot(player)
	if invalidation == "death" then player.Character.humanoid.Health = 0
	elseif invalidation == "character" then player.Character = fake:addPlayer(99).Character
	elseif invalidation == "root" then player.Character.root = nil
	elseif invalidation == "humanoid" then player.Character.humanoid = nil
	elseif invalidation == "mounted" then fake.states[player].mode = "launcher"
	elseif invalidation == "anchor" then player.Character.root.Anchored = true
	elseif invalidation == "removed" then player.Parent = nil
	elseif invalidation == "invalidPosition" then player.Character.root.Position = Vector3.new(0/0, 3, 98) end
	fake:wait(0.3)
	assert(fake.runner:getSnapshot(player).status == "idle" and #fake.rewards == 0, invalidation .. " must invalidate the order")
	assert(not fake.runner:deliver(player, oldOrder.orderId))
end
print("PASS: death/replacement/root/humanoid/mount/anchor/removal/invalid position cancellation")

do
	local fake = harness()
	local player = fake:addPlayer(42)
	assert(fake.runner:pickup(player))
	local order = fake.runner:getSnapshot(player)
	player.Character.root.Position = order.destinationPosition
	fake:wait(0.3)
	assert(fake.runner:getSnapshot(player).status == "idle" and #fake.rewards == 0, "instant teleport must cancel without reward")
	player.Character.root.Position = Config.pickupPosition
	fake:wait(0.3)
	assert(fake.runner:pickup(player))
	for _ = 1, 4 do
		player.Character.root.Position += Vector3.new(10, 0, 0)
		fake:wait(0.25)
	end
	assert(fake.runner:getSnapshot(player).status == "idle", "small repeated displacements cannot bypass aggregate speed budget")
	assert(#fake.rewards == 0)
	print("PASS: teleport and sustained implausible horizontal movement rejected")
end

do
	local fake = harness()
	local player = fake:addPlayer(42)
	assert(fake.runner:pickup(player))
	local order = fake.runner:getSnapshot(player)
	fake.states[player].cleanupEpoch += 1
	fake:wait(0.3)
	assert(fake.runner:getSnapshot(player).orderId == order.orderId, "walking launcher epoch changes cannot erase activity")
	assert(fake.runner:cancel(player, "mounted") and not fake.runner:cancel(player, "mounted"))
	assert(#fake.rewards == 0 and fake.states[player].coins == 0)
	fake:wait(0.3)
	assert(fake.runner:pickup(player))
	fake.runner:removePlayer(player)
	fake.runner:removePlayer(player)
	assert(fake.runner:getSnapshot(player).status == "idle" and not fake.runner:pickup(player))
	assert(#fake.rewards == 0)
	for _, state in { "launcher", "missing" } do
		local blocked = fake:addPlayer(state == "launcher" and 80 or 81)
		fake.states[blocked] = state == "launcher" and { mode = "launcher" } or nil
		assert(not fake.runner:pickup(blocked), "runner requires an independent walking state")
	end
	print("PASS: runner generation independent from launcher epoch, idempotent cancel/remove and walking-only entry")
end

for _, position in Config.routePositions do assert(position.Z >= 94) end
for _, destination in Config.destinations do assert(destination.position.Z >= 94) end
assert(Config.pickupPosition.Z >= 94 and #Config.destinations == 2)
print("PASS: authored takeout guidance stays outside restaurant forward projectile/customer lanes")

-- Execute the actual authored world and check both directions against its
-- raised street colliders. This conservative 1.25-stud horizontal envelope is
-- source geometry evidence, not an engine pathfinding/character walking test.
do
	local services = {}
	for _, name in { "Workspace", "Lighting", "StarterGui", "ReplicatedStorage" } do services[name] = roblox.Instance.new(name) end
	local shared = roblox.Instance.new("Folder")
	shared.Name, shared.Parent = "Shared", services.ReplicatedStorage
	local configModule = roblox.Instance.new("ModuleScript")
	configModule.Name, configModule.Parent = "Config", shared
	local gameConfig = loadModule("src/shared/Config.luau")
	local builder = require("./support/WorldFixture")(services, gameConfig)
	local world = builder.build()
	local obstacles = {}
	for _, part in world.NeighborhoodStreet:GetDescendants() do
		if not part:IsA("BasePart") or not part.CanCollide then continue end
		local frame = part.CFrame
		-- Lune stores explicitly assigned Orientation independently of CFrame.
		local hasOrientation, orientation = pcall(function() return part.Orientation end)
		if hasOrientation and orientation ~= Vector3.zero then
			frame = roblox.CFrame.new(frame.Position) * roblox.CFrame.Angles(math.rad(orientation.X), math.rad(orientation.Y), math.rad(orientation.Z))
		end
		local half = part.Size * 0.5
		local low, high = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
		for _, x in { -1, 1 } do for _, y in { -1, 1 } do for _, z in { -1, 1 } do
			local corner = frame:PointToWorldSpace(Vector3.new(x * half.X, y * half.Y, z * half.Z))
			low = Vector3.new(math.min(low.X, corner.X), math.min(low.Y, corner.Y), math.min(low.Z, corner.Z))
			high = Vector3.new(math.max(high.X, corner.X), math.max(high.Y, corner.Y), math.max(high.Z, corner.Z))
		end end end
		-- Walkable surfaces/low curbs and overhead decoration are not blockers.
		if high.Y > 1 and low.Y < 7 then table.insert(obstacles, { name = part.Name, low = low, high = high }) end
	end
	local function intersects(from, to, obstacle)
		local first, last = 0, 1
		for _, axis in { "X", "Z" } do
			local lower, upper = obstacle.low[axis] - 1.25, obstacle.high[axis] + 1.25
			local delta = to[axis] - from[axis]
			if math.abs(delta) < 0.0001 then
				if from[axis] < lower or from[axis] > upper then return false end
			else
				local enter, leave = (lower - from[axis]) / delta, (upper - from[axis]) / delta
				first = math.max(first, math.min(enter, leave))
				last = math.min(last, math.max(enter, leave))
				if first > last then return false end
			end
		end
		return true
	end
	local function checkPath(start, route)
		for _, finish in route do
			for _, obstacle in obstacles do
				assert(not intersects(start, finish, obstacle), string.format("Takeout route crosses %s from %s to %s", obstacle.name, tostring(start), tostring(finish)))
			end
			start = finish
		end
	end
	local reproducedOldBlock = false
	for _, obstacle in obstacles do
		if intersects(Vector3.new(-16, 3, 147), Config.destinations[2].position, obstacle) then reproducedOldBlock = true end
	end
	assert(reproducedOldBlock, "geometry fixture must reproduce the observed original route obstruction")
	for _, id in { 42, 43 } do
		local fake = harness()
		local player = fake:addPlayer(id)
		assert(fake.runner:pickup(player))
		local outbound = fake.runner:getSnapshot(player)
		checkPath(Config.pickupPosition, outbound.routePositions)
		fake:walkTo(player, outbound.destinationPosition, 12)
		assert(fake.runner:deliver(player, outbound.orderId))
		checkPath(outbound.destinationPosition, fake.runner:getSnapshot(player).routePositions)
	end
	print("PASS: actual street collider geometry reproduces old blockage; both destinations and replay routes clear raised obstacles with 1.25-stud envelope")
end
