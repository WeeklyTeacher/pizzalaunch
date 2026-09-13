-- Independent walking orders. This module never reads or writes launcher,
-- customer, projectile, upgrade, competitive scoring or persistence services.
local TakeoutRunner = {}
TakeoutRunner.__index = TakeoutRunner

local function finite(value): boolean
	return typeof(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function validPosition(position): boolean
	return typeof(position) == "Vector3" and finite(position.X) and finite(position.Y) and finite(position.Z)
end

local function horizontalDistance(a, b): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

function TakeoutRunner.new(dependencies)
	assert(dependencies.config and #dependencies.config.destinations == 2, "Takeout starts with two destinations")
	return setmetatable({ dependencies = dependencies, players = {} }, TakeoutRunner)
end

function TakeoutRunner:addPlayer(player)
	if self.players[player] then return end
	self.players[player] = {
		generation = 0, completedCount = 0, lastActionAt = -math.huge, nextNoticeAt = 0,
		nextDestination = math.abs(player.UserId) % #self.dependencies.config.destinations + 1,
	}
end

function TakeoutRunner:_notify(player, eventName, payload)
	if self.dependencies.notify and player.Parent then self.dependencies.notify(player, eventName, payload) end
end

function TakeoutRunner:_reject(player, reason)
	local record = self.players[player]
	local now = self.dependencies.now()
	if record and reason ~= "rateLimited" and now >= record.nextNoticeAt then
		record.nextNoticeAt = now + 0.75
		self:_notify(player, "runnerRejected", { reason = reason })
	end
	return false, reason
end

function TakeoutRunner:_actor(player)
	local state = self.dependencies.getState(player)
	if not state or state.mode ~= "walk" or not player.Parent then return nil end
	local character = player.Character
	if not character or not character.Parent then return nil end
	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not root.Parent or not root:IsA("BasePart") or root.Anchored
		or not humanoid or not humanoid.Parent or not finite(humanoid.Health) or humanoid.Health <= 0
		or not validPosition(root.Position) then return nil end
	return { character = character, root = root, humanoid = humanoid, position = root.Position }
end

function TakeoutRunner:_request(player)
	local record = self.players[player]
	if not record then return nil, "unavailable" end
	local now = self.dependencies.now()
	if now - record.lastActionAt < self.dependencies.config.requestInterval then return nil, "rateLimited" end
	record.lastActionAt = now
	return record, nil
end

function TakeoutRunner:getSnapshot(player)
	local config = self.dependencies.config
	local record = self.players[player]
	local order = record and record.order
	local snapshot = {
		status = order and "carrying" or "idle",
		normalReward = config.normalReward, quickBonus = config.quickBonus,
		pickupPosition = config.pickupPosition,
		routePositions = { config.pickupPosition },
		completedCount = record and record.completedCount or 0,
	}
	if order then
		snapshot.orderId = order.id
		snapshot.destinationId = order.destination.id
		snapshot.destinationName = order.destination.name
		snapshot.destinationPosition = order.destination.position
		snapshot.startedAt = order.startedAt
		snapshot.quickBonusEndsAt = order.startedAt + config.quickBonusSeconds
		snapshot.routePositions = table.clone(config.routePositions)
		for _, position in order.destination.approachPositions do table.insert(snapshot.routePositions, position) end
		table.insert(snapshot.routePositions, order.destination.position)
	else
		local actor = self:_actor(player)
		if actor and actor.position.Z >= 110 then
			-- Returning runners retrace the sidewalk/crosswalk route instead of
			-- taking a direct diagonal through the parked van or sidewalk props.
			local destination = record and record.lastDestination
			if not destination then
				local nearestDistance = math.huge
				for _, candidate in config.destinations do
					local distance = horizontalDistance(actor.position, candidate.position)
					if distance < nearestDistance then destination, nearestDistance = candidate, distance end
				end
			end
			snapshot.routePositions = {}
			for index = #destination.approachPositions, 1, -1 do
				table.insert(snapshot.routePositions, destination.approachPositions[index])
			end
			for index = #config.routePositions, 1, -1 do table.insert(snapshot.routePositions, config.routePositions[index]) end
			table.insert(snapshot.routePositions, config.pickupPosition)
		end
	end
	return snapshot
end

function TakeoutRunner:pickup(player)
	local record, reason = self:_request(player)
	if not record then return self:_reject(player, reason) end
	if record.order then return self:_reject(player, "alreadyCarrying") end
	local actor = self:_actor(player)
	if not actor then return self:_reject(player, "walkingCharacterRequired") end
	local config = self.dependencies.config
	if (actor.position - config.pickupPosition).Magnitude > config.promptDistance then
		return self:_reject(player, "approachPickup")
	end
	local now = self.dependencies.now()
	record.generation += 1
	record.order = {
		id = string.format("%d:%d", player.UserId, record.generation),
		generation = record.generation,
		destination = config.destinations[record.nextDestination],
		character = actor.character, root = actor.root, humanoid = actor.humanoid,
		startedAt = now, lastSampleAt = now, lastPosition = actor.position, distanceTravelled = 0,
	}
	self:_notify(player, "runnerStarted", { orderId = record.order.id })
	return true, self:getSnapshot(player)
end

function TakeoutRunner:cancel(player, reason, expectedOrderId)
	local record = self.players[player]
	local order = record and record.order
	if not order then return false, "noOrder" end
	if expectedOrderId ~= nil and expectedOrderId ~= order.id then return self:_reject(player, "staleOrder") end
	-- Advance only activity state. Launcher epochs and queue membership are separate.
	record.generation += 1
	record.order = nil
	self:_notify(player, "runnerCancelled", { reason = reason or "cancelled", orderId = order.id })
	return true, nil
end

function TakeoutRunner:_sample(player, record, order, now)
	if record.order ~= order or record.generation ~= order.generation then return nil, "staleOrder" end
	local actor = self:_actor(player)
	if not actor or actor.character ~= order.character or actor.root ~= order.root or actor.humanoid ~= order.humanoid then
		self:cancel(player, "characterChanged")
		return nil, "characterChanged"
	end
	local config = self.dependencies.config
	local delta = horizontalDistance(actor.position, order.lastPosition)
	local elapsed = math.max(0, now - order.startedAt)
	local sampleElapsed = math.max(0, now - order.lastSampleAt)
	local totalDistance = order.distanceTravelled + delta
	if delta > config.maxHorizontalSpeed * sampleElapsed + config.positionSlack
		or totalDistance > config.maxHorizontalSpeed * elapsed + config.positionSlack then
		self:cancel(player, "travelInterrupted")
		return nil, "travelInterrupted"
	end
	order.distanceTravelled = totalDistance
	order.lastPosition, order.lastSampleAt = actor.position, now
	return actor, nil
end

function TakeoutRunner:deliver(player, expectedOrderId)
	local record, reason = self:_request(player)
	if not record then return self:_reject(player, reason) end
	local order = record.order
	if not order then return self:_reject(player, "noOrder") end
	if typeof(expectedOrderId) ~= "string" or expectedOrderId ~= order.id then return self:_reject(player, "staleOrder") end
	local now = self.dependencies.now()
	local actor, sampleReason = self:_sample(player, record, order, now)
	if not actor then return false, sampleReason end
	local config = self.dependencies.config
	if (actor.position - order.destination.position).Magnitude > config.promptDistance then
		return self:_reject(player, "approachDestination")
	end
	local elapsed = now - order.startedAt
	local bonus = elapsed <= config.quickBonusSeconds and config.quickBonus or 0
	local receipt = table.freeze({
		orderId = order.id, userId = player.UserId,
		destinationId = order.destination.id, destinationName = order.destination.name,
		coinsEarned = config.normalReward + bonus, bonusEarned = bonus,
		elapsed = elapsed, startedAt = order.startedAt, completedAt = now,
	})
	-- No yields occur before consumption. A duplicate or reentrant callback can
	-- never claim this order again. The award hook adds only session coins.
	record.order = nil
	record.generation += 1
	record.completedCount += 1
	record.lastDestination = order.destination
	record.nextDestination = record.nextDestination % #config.destinations + 1
	self.dependencies.award(player, receipt)
	self:_notify(player, "runnerCompleted", receipt)
	return true, receipt
end

function TakeoutRunner:step()
	local now = self.dependencies.now()
	for player, record in self.players do
		local order = record.order
		if order then self:_sample(player, record, order, now) end
	end
end

function TakeoutRunner:removePlayer(player)
	local record = self.players[player]
	if record then record.order = nil; record.generation += 1 end
	self.players[player] = nil
end

return TakeoutRunner
