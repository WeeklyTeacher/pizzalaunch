-- Executes the production module with explicit engine/service
-- boundaries. It does not simulate Roblox contact generation or replication.
local loadModule = require("./support/LoadModule")
local roblox = require("@lune/roblox")
local Config = loadModule("src/shared/Config.luau")
local Scoring = loadModule("src/server/DeliveryScoring.luau")
local DeliveryService = loadModule("src/server/DeliveryService.luau")

local function harness()
	local h = { now = 100, player = { UserId = 42 }, events = {}, timers = {}, receipts = {}, public = {},
		leaseValid = true, recordSession = false, cutoff = 1000, claimable = true, claims = 0,
		resolved = 0, served = 0, shared = 0, roundOne = 0, propResets = 0, consumed = 0, removed = 0,
		misses = 0, wrong = 0, feedbackText = 0 }
	h.owner = h.player
	h.state = { coins = 0, combo = 0, bestCombo = 0, round = 1, roundProgress = 0,
		targetId = 1, targetSetAt = 95, lastLaunch = 99.5, cleanupEpoch = 7, shotActive = true,
		upgrades = { tips = 0, assist = 0, reload = 0, power = 0 } }
	local function event(name) table.insert(h.events, name) end
	local lease = { isValid = function(_, player) return h.leaseValid and h.owner == player end }
	setmetatable(lease, { __index = function(_, key) if key == "owner" then return h.owner end end })
	local customers = {
		claimDelivery = function(_)
			h.claims += 1
			if not h.claimable then return false end
			h.claimable = false
			event("claim")
			return true
		end,
		getInfo = function() return { name = "Mia" } end,
		served = function() h.served += 1; event("served") end,
		wrongPizza = function() h.wrong += 1 end,
	}
	local projectiles = {
		resolve = function(_, pizza, epoch)
			if h.activePizza ~= pizza or h.activeEpoch ~= epoch or not pizza.Parent then return false end
			h.activePizza = nil
			h.resolved += 1
			event("resolve")
			return true
		end,
		consumeVisual = function() h.consumed += 1 end,
		removeVisual = function(_, pizza) h.removed += 1; pizza.Parent = nil end,
	}
	local record = {
		isSession = function() return h.recordSession end,
		canLaunch = function() return not h.recordSession or h.now < h.cutoff end,
		recordSuccess = function(_, tableId, accuracy)
			event("recordSuccess")
			h.lastRecordTable, h.lastRecordAccuracy = tableId, accuracy
			if h.scoreRejected then return nil end
			return { lastPoints = 240, score = 1240, combo = 4, multiplier = 2 }
		end,
		recordMiss = function() h.misses += 1 end,
	}
	local context = {
		config = Config, scoring = Scoring, lease = lease, customers = customers, projectiles = projectiles, recordRun = record,
		getState = function(player) return player == h.player and h.state or nil end,
		now = function() return h.now end,
		delay = function(seconds, callback) table.insert(h.timers, { seconds = seconds, callback = callback }) end,
		layout = { setRound = function(round) h.layoutRound = round; event("layout") end },
		props = { resetAll = function() h.propResets += 1; event("props") end },
		shiftEvents = {
			extendTablePool = function(pool) return table.clone(pool) end,
			recordDelivery = function(_, _, elapsed) h.serviceTime = elapsed; return h.shiftOutcome or { bonus = 0 } end,
			maybeStart = function(tables, target) h.eventPool, h.eventTarget = tables, target; return h.startedEvent end,
			recordMiss = function() return h.eventMiss end,
		},
		tableDefinition = function(id) return Config.TABLES[id] end,
		roundDefinition = function(round) return Config.ROUNDS[math.clamp(round, 1, #Config.ROUNDS)] end,
		nextTarget = function(id, round) h.nextTargetRound = round; return id == 1 and 2 or 1 end,
		worldTable = function() return h.tableModel end,
		customerReaction = function(_, reaction) event(reaction) end,
		reactionText = function() h.feedbackText += 1 end,
		playSound = function(_, sound) event(sound) end,
		confettiBurst = function() event("confetti") end,
		sounds = { perfect = "perfectSound", success = "successSound", miss = "missSound", splat = "splatSound" },
		beginShiftEvent = function(value) h.beganEvent = value; event("eventStart") end,
		endShiftEvent = function(value, message) h.endedEvent, h.endedMessage = value, message; event("eventEnd") end,
		setLeaderstats = function() event("leaderstats") end,
		sendState = function(player, eventName, payload)
			assert(player == h.player and eventName == "shotResult")
			table.insert(h.public, payload); event("shotResult")
		end,
		contributeShared = function() h.shared += 1; event("shared") end,
		recordDelivery = function(player, state, tableId, accuracy, customerName, isRecord)
			assert(player == h.player and state == h.state)
			table.insert(h.receipts, { tableId = tableId, accuracy = accuracy, customerName = customerName, record = isRecord })
			event("mastery")
		end,
		roundOneCompleted = function() h.roundOne += 1 end,
	}
	h.service = DeliveryService.new(context)
	function h.shot(epoch)
		local pizza = { Parent = true, attributes = {} }
		function pizza:GetAttribute(key) return self.attributes[key] end
		function pizza:SetAttribute(key, value) self.attributes[key] = value end
		h.activePizza, h.activeEpoch = pizza, epoch or h.state.cleanupEpoch
		h.state.shotActive = true
		return pizza
	end
	function h.deliver(tableId, position, pizza)
		return h.service.resolve(h.player, pizza or h.shot(), "delivery", position or Config.TABLES[tableId or 1].position, tableId or 1)
	end
	return h
end

do
	for _, denial in { "nonowner", "invalidCharacter", "oldEpoch", "cutoff", "missingState" } do
		local h = harness()
		local pizza = h.shot(denial == "oldEpoch" and 6 or 7)
		local state = h.state
		if denial == "nonowner" then h.owner = {} end
		if denial == "invalidCharacter" then h.leaseValid = false end
		if denial == "cutoff" then h.recordSession, h.cutoff = true, h.now end
		if denial == "missingState" then h.state = nil end
		assert(not h.service.resolve(h.player, pizza, "delivery", Config.TABLES[1].position, 1))
		assert(h.claims == 0 and h.resolved == 0 and h.served == 0 and #h.receipts == 0 and #h.public == 0 and state.coins == 0,
			denial .. " must be rejected before any customer, score, profile or feedback mutation")
	end
	print("PASS: delivery admission rejects another owner, invalid character, stale epoch, missing state and exact Record Run cutoff before mutation")
end

do
	local h = harness()
	local pizza = h.shot()
	assert(h.deliver(1, nil, pizza))
	assert(not h.deliver(1, nil, pizza))
	assert(h.claims == 1 and h.resolved == 1 and h.served == 1 and h.shared == 1 and #h.receipts == 1 and #h.public == 1)
	assert(h.state.coins == 20 and h.state.combo == 1 and h.state.roundProgress == 1 and not h.state.shotActive)
	assert(h.receipts[1].customerName == "Mia" and h.receipts[1].accuracy == "PERFECT!" and not h.receipts[1].record)
	assert(h.public[1].result == "PERFECT!" and math.abs(h.public[1].reloadDelay - 0.35) < 1e-6)
	assert(h.events[1] == "resolve" and h.events[2] == "claim" and table.find(h.events, "mastery") < table.find(h.events, "served"))
	assert(h.events[#h.events] == "shotResult" and h.events[#h.events - 1] == "leaderstats")
	assert(h.timers[1].seconds == 0.62 and h.timers[2].seconds == 1.45)
	print("PASS: one resolved contact yields one authoritative reward/mastery/customer claim and preserves feedback ordering and delays")
end

do
	local h = harness()
	h.state.roundProgress, h.state.combo, h.state.bestCombo, h.state.coins, h.state.upgrades.tips = 2, 2, 2, 7, 2
	h.shiftOutcome = { bonus = 5, fastService = true, message = "Fast!", ended = { kind = "DinnerRush" } }
	h.startedEvent = { kind = "BirthdayTable" }
	assert(h.deliver())
	local payload = h.public[1]
	assert(payload.coinsEarned == 41 and payload.comboBonus == 4 and payload.tipBonus == 12 and payload.eventBonus == 5,
		"20 base +4 combo, x1.5 tips =36, +5 shift; extra tips must stay visible as12")
	assert(payload.roundReward == 25 and payload.roundComplete and payload.completedRound == 1)
	assert(h.state.coins == 73 and h.state.round == 2 and h.state.roundProgress == 0 and h.state.combo == 3)
	assert(h.layoutRound == 2 and h.propResets == 1 and h.roundOne == 1 and h.nextTargetRound == 2)
	assert(h.eventPool == Config.ROUNDS[2].tables and h.eventTarget == 2 and h.state.targetSetAt == h.now and h.serviceTime == 5)
	assert(h.endedEvent == h.shiftOutcome.ended and h.beganEvent == h.startedEvent)
	assert(table.find(h.events, "layout") < table.find(h.events, "props") and table.find(h.events, "eventEnd") < table.find(h.events, "eventStart"))
	print("PASS: Bigger Tips feedback, combo/shift/round rewards and next-round layout/prop/target/event routing preserve their order")
end

do
	for round = 2, 4 do
		local h = harness()
		h.state.round, h.state.roundProgress = round, Config.ROUNDS[round].goal - 1
		local id = Config.ROUNDS[round].tables[1]
		assert(h.deliver(id))
		assert(h.state.round == math.min(round + 1, 4) and h.layoutRound == h.state.round and h.propResets == 1)
		assert(h.public[1].roundReward == Config.ROUNDS[round].reward and h.state.coins == 20 + Config.ROUNDS[round].reward)
		assert(h.roundOne == 0, "later rounds cannot repeat the first-round milestone")
	end
	print("PASS: round2-to3, round3-to4 and final-round replay keep current authored progression and rewards")
end

do
	local h = harness()
	h.recordSession = true
	h.state.coins, h.state.combo, h.state.roundProgress = 17, 8, 2
	h.state.upgrades.tips, h.state.upgrades.assist, h.state.upgrades.reload = 3, 3, 3
	assert(h.deliver(6, Config.TABLES[6].position + roblox.Vector3.new(4, 0, 0)))
	local payload = h.public[1]
	assert(payload.result == "GREAT!" and payload.recordPoints == 240 and payload.recordScore == 1240 and payload.recordComboMilestone)
	assert(h.lastRecordTable == 6 and h.lastRecordAccuracy == "GREAT!", "competitive accuracy ignores walking assist and early-round scale")
	assert(h.state.coins == 17 and h.state.combo == 8 and h.state.roundProgress == 2 and h.state.round == 1)
	assert(h.shared == 0 and h.propResets == 0 and h.nextTargetRound == nil and h.serviceTime == nil)
	assert(#h.receipts == 1 and h.receipts[1].record and payload.coinsEarned == 0 and math.abs(payload.reloadDelay - 0.35) < 1e-6)
	print("PASS: Record Run accepts far tables with fixed accuracy/reload and record scoring, without session economy/shared/round/shift mutation")
end

do
	local h = harness()
	h.claimable = false
	h.state.combo = 4
	assert(h.deliver())
	assert(h.state.combo == 0 and h.state.coins == 0 and h.served == 0 and #h.receipts == 0 and h.shared == 0)
	assert(h.wrong == 1 and h.public[1].result == "TABLE IS CLEARING!")
	local record = harness()
	record.recordSession, record.claimable = true, false
	assert(record.deliver())
	assert(record.misses == 1 and #record.receipts == 0 and record.state.coins == 0)
	local expiredAtScoring = harness()
	expiredAtScoring.recordSession, expiredAtScoring.scoreRejected = true, true
	assert(expiredAtScoring.deliver())
	assert(#expiredAtScoring.receipts == 0 and expiredAtScoring.shared == 0 and expiredAtScoring.public[1].result == "TIME!")
	print("PASS: unavailable customers and a rejected record score grant no reward or mastery")
end

do
	local h = harness()
	h.state.combo = 6
	h.eventMiss = { comboSaved = true, ended = { kind = "FoodCritic" }, message = "Bonus ended" }
	assert(h.service.resolve(h.player, h.shot(), "FLOOR PIZZA!", roblox.Vector3.zero, nil))
	assert(h.state.combo == 6 and h.public[1].comboSaved and h.endedEvent == h.eventMiss.ended)
	assert(#h.receipts == 0 and h.state.coins == 0)
	print("PASS: existing Food Critic miss preserves combo while ending only its shift event")
end

do
	for _, change in { "none", "epoch", "owner", "replacement", "removedPizza" } do
		local h = harness()
		local customer = { IsA = function(_, name) return name == "Model" end }
		h.tableModel = { FindFirstChild = function() return customer end }
		local pizza = h.shot()
		assert(h.deliver(1, nil, pizza))
		if change == "epoch" then h.state.cleanupEpoch += 1 end
		if change == "owner" then h.owner = {} end
		if change == "replacement" then h.state = table.clone(h.state) end
		if change == "removedPizza" then pizza.Parent = nil end
		h.timers[1].callback()
		assert(h.feedbackText == (change == "none" and 1 or 0) and h.consumed == h.feedbackText)
		h.timers[2].callback()
		assert(h.removed == 1 and pizza.Parent == nil)
	end
	print("PASS: delayed eating feedback fences old epochs, owners, player states and removed visuals while still cleaning its own pizza")
end
