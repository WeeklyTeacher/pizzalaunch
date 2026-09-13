local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local CustomerService = require(script.Parent.CustomerService)
local InteractionService = require(script.Parent.InteractionService)
local LayoutService = require(script.Parent.LayoutService)
local PropService = require(script.Parent.PropService)
local RecordRunService = require(script.Parent.RecordRunService)
local ShiftEventService = require(script.Parent.ShiftEventService)
local WorldActivityService = require(script.Parent.WorldActivityService)

local LauncherLease = require(script.Parent.LauncherLease)
local ShotPolicy = require(script.Parent.ShotPolicy)
local ProjectileService = require(script.Parent.ProjectileService)
local DeliveryScoring = require(script.Parent.DeliveryScoring)
local DeliveryService = require(script.Parent.DeliveryService)
local PlayerProgression = require(script.Parent.PlayerProgression)
local LauncherQueue = require(script.Parent.LauncherQueue)
local TakeoutRunner = require(script.Parent.TakeoutRunner)
local TakeoutConfig = require(ReplicatedStorage.Shared.TakeoutConfig)
local TakeoutWorld = require(script.Parent.TakeoutWorld)
local SharedMilestone = require(script.Parent.SharedMilestone)
local ProfileService = require(script.Parent.ProfileService)
local ProfileCosmetics = require(script.Parent.ProfileCosmetics)
local JourneyAnalytics = require(script.Parent.JourneyAnalytics)

local CustomerFeedback = require(script.Parent.CustomerFeedback)
local Effects = require(script.Parent.ServerEffects)
local playSound, coinBurst, confettiBurst = Effects.playSound, Effects.coinBurst, Effects.confettiBurst
local createSplat, impactRing = Effects.createSplat, Effects.impactRing

local GameService = {}

local SOUND = {
	launch = "rbxassetid://9113263647",
	whoosh = "rbxassetid://9126229255",
	bounce = "rbxassetid://9113974103",
	splat = "rbxassetid://9114615986",
	success = "rbxassetid://4612374036",
	perfect = "rbxassetid://4612374036",
	miss = "rbxassetid://9113974103",
}

local states = {}
local launchRemote: RemoteEvent
local stateRemote: RemoteEvent
local purchaseRemote: RemoteEvent
local modeRemote: RemoteEvent
local activityRemote: RemoteEvent
local takeoutRemote: RemoteEvent
local queueRemote: RemoteEvent
local profileRemote: RemoteEvent
local profileActionRemote: RemoteEvent
local journeyRemote: RemoteEvent
local profiles
local journey
local runner
local launcherQueue
local sharedMilestone
local sendActivity
local broadcastActivity
local launcherLease = LauncherLease.new()
local cleanupLauncherSession
local characterConnections = {}

local function createRemotes()
	local old = ReplicatedStorage:FindFirstChild(Config.REMOTES_FOLDER)
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = Config.REMOTES_FOLDER
	folder.Parent = ReplicatedStorage

	launchRemote = Instance.new("RemoteEvent")
	launchRemote.Name = Config.LAUNCH_REMOTE
	launchRemote.Parent = folder
	stateRemote = Instance.new("RemoteEvent")
	stateRemote.Name = Config.STATE_REMOTE
	stateRemote.Parent = folder
	purchaseRemote = Instance.new("RemoteEvent")
	purchaseRemote.Name = Config.PURCHASE_REMOTE
	purchaseRemote.Parent = folder
	modeRemote = Instance.new("RemoteEvent")
	modeRemote.Name = Config.MODE_REMOTE
	modeRemote.Parent = folder
	activityRemote = Instance.new("RemoteEvent")
	activityRemote.Name = Config.ACTIVITY_REMOTE
	activityRemote.Parent = folder
	takeoutRemote = Instance.new("RemoteEvent")
	takeoutRemote.Name = Config.TAKEOUT_REMOTE
	takeoutRemote.Parent = folder
	queueRemote = Instance.new("RemoteEvent")
	queueRemote.Name = Config.QUEUE_REMOTE
	queueRemote.Parent = folder
	profileRemote = Instance.new("RemoteEvent")
	profileRemote.Name, profileRemote.Parent = "ProfileState", folder
	profileActionRemote = Instance.new("RemoteEvent")
	profileActionRemote.Name, profileActionRemote.Parent = "ProfileAction", folder
	journeyRemote = Instance.new("RemoteEvent")
	journeyRemote.Name, journeyRemote.Parent = "JourneyAction", folder
end

local function sendProfile(player, eventName, payload, snapshot)
	local state = states[player]
	if not state or not player.Parent or not profiles then return end
	snapshot = snapshot or profiles:snapshot(player)
	ProfileCosmetics.apply(player, snapshot, state.mode == "launcher")
	profileRemote:FireClient(player, {
		event = eventName or "profileState", payload = payload,
		cleanupEpoch = state.cleanupEpoch, character = player.Character, profile = snapshot,
	})
end

local function receiptSequence(state, domain)
	state.receiptSequences[domain] += 1
	return state.receiptSequences[domain]
end

local function recordCancellation(player)
	local status = RecordRunService.getSnapshot(player).status
	if status == "countdown" or status == "running" then
		journey:emit(player, "RecordRunCancelled", "recordRun", "cancelled")
	end
end

local function cancelRecordRun(player)
	recordCancellation(player)
	RecordRunService.cancel(player)
end

local function tableDefinition(tableId: number)
	for _, definition in Config.TABLES do
		if definition.id == tableId then
			return definition
		end
	end
	return Config.TABLES[1]
end

local function roundDefinition(roundNumber: number)
	return Config.ROUNDS[math.clamp(roundNumber, 1, #Config.ROUNDS)]
end

local function nextTarget(previousId: number?, roundNumber: number): number
	local pool = ShiftEventService.extendTablePool(roundDefinition(roundNumber).tables)
	local available = CustomerService.getAvailableTables()
	local readyPool = {}
	for _, tableId in pool do
		if table.find(available, tableId) then
			table.insert(readyPool, tableId)
		end
	end
	if #readyPool > 0 then
		pool = readyPool
	end
	if #pool == 1 then
		return pool[1]
	end
	local picked = pool[math.random(1, #pool)]
	while picked == previousId do
		picked = pool[math.random(1, #pool)]
	end
	return picked
end

local function sendState(player: Player, eventName: string?, payload: { [string]: any }?)
	local state = states[player]
	if not state then
		return
	end
	local round = roundDefinition(state.round)
	local target = tableDefinition(state.targetId)
	stateRemote:FireClient(player, {
		event = eventName or "state",
		coins = state.coins,
		combo = state.combo,
		bestCombo = state.bestCombo,
		targetId = state.targetId,
		targetCustomer = target.customer,
		round = state.round,
		roundName = round.name,
		roundProgress = state.roundProgress,
		roundGoal = round.goal,
		roundColor = round.color,
		upgrades = state.upgrades,
		mode = state.mode,
		launcherMode = state.launcherMode,
		cleanupEpoch = state.cleanupEpoch,
		shotActive = state.shotActive,
		reloadDelay = math.max(0, state.lastLaunch + ShotPolicy.reloadTime(Config, state, RecordRunService.isSession(player)) - Workspace:GetServerTimeNow()),
		recordRun = RecordRunService.getSnapshot(player),
		shiftEvent = ShiftEventService.getSnapshot(),
		payload = payload,
	})
end

local function setLeaderstats(player: Player, state)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end
	for name, value in { Coins = state.coins, Combo = state.combo, Round = state.round } do
		local item = leaderstats:FindFirstChild(name)
		if item and item:IsA("IntValue") then
			item.Value = value
		end
	end
end

local function livingRoot(player, expectedCharacter)
	local character = player.Character
	if not states[player] or not player.Parent or not character or not character.Parent
		or (expectedCharacter and character ~= expectedCharacter) then return nil end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not ShotPolicy.isFinite(humanoid.Health) or humanoid.Health <= 0 or not root or not root:IsA("BasePart")
		or not ShotPolicy.isFinite(root.Position.X) or not ShotPolicy.isFinite(root.Position.Y) or not ShotPolicy.isFinite(root.Position.Z) then return nil end
	return root
end

local function onProfileAction(player, action, cosmeticId, epoch, requestId)
	local state = states[player]
	local root = livingRoot(player)
	if not state or state.mode ~= "walk" or not root or root.Anchored or epoch ~= state.cleanupEpoch
		or (action ~= "request" and action ~= "equip")
		or not ShotPolicy.isFinite(requestId) or requestId % 1 ~= 0 or requestId < 1 or requestId > 2147483647
		or requestId <= state.profileRequestId then return end
	local now = Workspace:GetServerTimeNow()
	-- Opening the book requests a fresh snapshot; it must not consume the
	-- separate rate allowance for the chef's first appearance selection.
	if now - state.profileRequestTimes[action] < 0.5 then return end
	state.profileRequestId, state.profileRequestTimes[action] = requestId, now
	if action == "request" then
		sendProfile(player)
	elseif typeof(cosmeticId) == "string" and #cosmeticId <= 24 and profiles:equip(player, cosmeticId) then
		sendProfile(player, "profileEquipped")
	else
		sendProfile(player, "profileRejected", { reason = "styleUnavailable" })
	end
end

local function stationSnapshot()
	local owner = launcherLease.owner
	local state = owner and states[owner]
	local record = owner and RecordRunService.getSnapshot(owner) or {}
	local isRecord = state ~= nil and state.launcherMode == "recordRun"
	local world = Workspace:FindFirstChild("PizzaLaunchWorld")
	local anchor = world and world:FindFirstChild("LauncherInteractionAnchor", true)
	return {
		occupied = owner ~= nil, operatorUserId = owner and owner.UserId or nil,
		operatorName = owner and (owner.DisplayName or owner.Name) or nil,
		launcherMode = state and state.launcherMode or "none", recordStatus = isRecord and record.status or nil,
		score = isRecord and record.score or nil,
		endsAt = isRecord and record.endsAt or nil, countdownEndsAt = isRecord and record.countdownEndsAt or nil,
		interactionPosition = anchor and anchor:IsA("BasePart") and anchor.Position or nil,
		waitingCount = launcherQueue and launcherQueue:snapshot(owner).waitingCount or 0,
	}
end

sendActivity = function(player, eventName, payload)
	local state = states[player]
	if not state or not player.Parent or not runner or not launcherQueue then return end
	activityRemote:FireClient(player, {
		event = eventName or "activity", payload = payload, activityEpoch = state.activityEpoch, character = player.Character,
		runner = runner:getSnapshot(player), queue = launcherQueue:snapshot(player), station = stationSnapshot(),
		shared = sharedMilestone and sharedMilestone:snapshot() or nil,
		coins = state.coins, upgrades = table.clone(state.upgrades),
	})
end

broadcastActivity = function(eventName, payload)
	if not launcherQueue then return end
	for player in states do sendActivity(player, eventName, payload) end
	TakeoutWorld.update(stationSnapshot(), sharedMilestone and sharedMilestone:snapshot() or nil)
	local reserved = launcherQueue.reservation
	InteractionService.setLauncherAvailable(launcherLease.owner == nil, reserved and (reserved.player.DisplayName or reserved.player.Name) or nil)
end

local function invalidateActivity(player, reason)
	local state = states[player]
	if not state then return end
	state.activityEpoch += 1
	state.activityRequests = { queue = 0, takeout = 0 }
	if runner then runner:cancel(player, reason) end
	if launcherQueue then launcherQueue:cancel(player, reason) end
end

local function activityRequest(player, scope, epoch, requestId): boolean
	local state = states[player]
	if not state or state.mode ~= "walk" or not livingRoot(player) or epoch ~= state.activityEpoch
		or not ShotPolicy.isFinite(requestId) or requestId % 1 ~= 0 or requestId < 1 or requestId > 2147483647
		or requestId <= state.activityRequests[scope] then return false end
	local now = Workspace:GetServerTimeNow()
	if now - (state.activityRequestTimes[scope] or -100) < 0.2 then return false end
	state.activityRequests[scope] = requestId
	state.activityRequestTimes[scope] = now
	return true
end

local function worldTable(tableId: number): Model?
	local world = Workspace:FindFirstChild("PizzaLaunchWorld")
	if not world then
		return nil
	end
	for _, child in world:GetChildren() do
		if child:IsA("Model") and child:GetAttribute("TableId") == tableId then
			return child
		end
	end
	return nil
end

local function updateDeliveryZones(assistLevel: number, recordSession: boolean)
	local world = Workspace:FindFirstChild("PizzaLaunchWorld")
	if not world then return end
	local scale = recordSession and 1.12 or (1 + assistLevel * 0.12)
	for _, tableData in Config.TABLES do
		local tableModel = worldTable(tableData.id)
		local ring = tableModel and tableModel:FindFirstChild("TargetRing")
		if ring and ring:IsA("BasePart") then
			local diameter = (Config.DELIVERY_ZONE_DIAMETER or 8) * scale
			ring.Size = Vector3.new(0.15, diameter, diameter)
			ring:SetAttribute("DeliveryZoneScale", scale)
		end
	end
end

local function applyProgressionVisuals(state)
	local world = Workspace:FindFirstChild("PizzaLaunchWorld")
	if not world then return end
	local totalLevels = 0
	for _, level in state.upgrades do
		totalLevels += level
	end
	local progression = world:FindFirstChild("ProgressionDecor", true)
	if progression then
		for _, descendant in progression:GetDescendants() do
			local milestone = descendant:GetAttribute("ProgressionMilestone")
			if typeof(milestone) == "number" then
				local visible = totalLevels >= milestone
				if descendant:IsA("BasePart") then
					descendant.Transparency = visible and (descendant:GetAttribute("VisibleTransparency") or 0) or 1
				elseif descendant:IsA("SurfaceGui") or descendant:IsA("Light") then
					descendant.Enabled = visible
				end
			end
		end
	end
	local station = world:FindFirstChild("LauncherStation")
	local ovenGlow = station and station:FindFirstChild("OvenGlow")
	local ovenLight = ovenGlow and ovenGlow:FindFirstChildOfClass("PointLight")
	if ovenLight then
		ovenLight.Brightness = 2.3 + state.upgrades.power * 0.6
	end
end

local function eventRoleTable(eventData)
	if not eventData then return nil end
	return eventData.specialTableId or eventData.extraTableId
end

local function clearShiftEventVisual(eventData)
	local tableId = eventRoleTable(eventData)
	if tableId then
		CustomerService.setSpecialRole(tableId, nil)
	end
end

local function beginShiftEvent(eventData)
	local tableId = eventRoleTable(eventData)
	if tableId then
		CustomerService.setSpecialRole(tableId, eventData.kind)
	end
	for player, state in states do
		if not RecordRunService.isSession(player) then
			if eventData.specialTableId then
				state.targetId = eventData.specialTableId
				state.targetSetAt = Workspace:GetServerTimeNow()
			end
			sendState(player, "shiftEventStarted", eventData)
		end
	end
end

local function endShiftEvent(eventData, message: string?)
	clearShiftEventVisual(eventData)
	for player, state in states do
		if not RecordRunService.isSession(player) then
			local roundTables = roundDefinition(state.round).tables
			if not table.find(roundTables, state.targetId) then
				state.targetId = nextTarget(nil, state.round)
				state.targetSetAt = Workspace:GetServerTimeNow()
			end
			sendState(player, "shiftEventEnded", {
				title = eventData and eventData.title or "SHIFT EVENT",
				detail = message or "The restaurant is back to its usual rhythm.",
			})
		end
	end
end

local customerFeedback = CustomerFeedback.new({
	getOwner = function() return launcherLease.owner end,
	worldTable = worldTable,
	tableDefinition = tableDefinition,
	customerService = CustomerService,
	coinBurst = coinBurst,
})

local function reactionText(customer, text)
	customerFeedback:text(customer, text)
end

local function customerReaction(tableId, reaction)
	customerFeedback:react(tableId, reaction)
end

local deliveryService = DeliveryService.new({
	config = Config, getState = function(player) return states[player] end,
	now = function() return Workspace:GetServerTimeNow() end, lease = launcherLease,
	recordRun = RecordRunService, projectiles = ProjectileService, customers = CustomerService,
	shiftEvents = ShiftEventService, scoring = DeliveryScoring, layout = LayoutService, props = PropService,
	tableDefinition = tableDefinition, roundDefinition = roundDefinition, nextTarget = nextTarget,
	customerReaction = customerReaction, reactionText = reactionText, worldTable = worldTable,
	playSound = playSound, confettiBurst = confettiBurst, sounds = SOUND,
	beginShiftEvent = beginShiftEvent, endShiftEvent = endShiftEvent,
	setLeaderstats = setLeaderstats, sendState = sendState,
	contributeShared = function(player)
		if sharedMilestone then sharedMilestone:contribute(player, "freePlay") end
	end,
	recordDelivery = function(player, state, tableId, accuracy, customerName, recordSession)
		profiles:recordDelivery(player, table.freeze({
			sequence = receiptSequence(state, "delivery"), tableId = tableId,
			accuracy = accuracy, customerName = customerName,
		}))
		journey:emit(player, "FirstSuccessfulDelivery", recordSession and "recordRun" or "freePlay", "completed")
	end,
	roundOneCompleted = function(player) journey:emit(player, "RoundOneCompleted", "freePlay", "completed") end,
})

local function finishShot(player: Player, pizza: BasePart, result: string, hitPosition: Vector3?, tableId: number?)
	return deliveryService.resolve(player, pizza, result, hitPosition, tableId)
end

local function onLaunch(player: Player, directionValue: any, chargeValue: any, requestId: any, requestEpoch: any)
	local state = states[player]
	if not state then return end
	if launcherLease.owner == player and not launcherLease:isValid(player) then
		cleanupLauncherSession(player, "invalidMountedCharacter", { cancelRun = true, notifyClient = true })
	end
	local now = Workspace:GetServerTimeNow()
	local recordSession = RecordRunService.isSession(player)
	local accepted, reason = ShotPolicy.validate(Config, state, launcherLease:isValid(player),
		RecordRunService.canLaunch(player), recordSession, directionValue, chargeValue, requestId, requestEpoch, now)
	if not accepted then
		local reloadTime = ShotPolicy.reloadTime(Config, state, recordSession)
		sendState(player, "launchRejected", {
			requestId = ShotPolicy.isFinite(requestId) and requestId or nil,
			requestEpoch = requestEpoch == state.cleanupEpoch and requestEpoch or -1,
			shotActive = state.shotActive, reason = reason,
			reloadDelay = math.max(0, state.lastLaunch + reloadTime - now), reloadTime = reloadTime,
		})
		return
	end
	state.lastRequestId = requestId
	state.lastLaunch = now
	state.shotActive = true
	local epoch = state.cleanupEpoch
	local powerLevel = RecordRunService.isSession(player) and 0 or state.upgrades.power
	local pizza = ProjectileService.create(Config, player, accepted.direction, accepted.charge, powerLevel, playSound, SOUND)
	local shot = ProjectileService.track(player, pizza, epoch)
	profiles:completeTutorial(player)
	journey:emit(player, "FirstLaunch", recordSession and "recordRun" or "freePlay", "accepted")
	sendState(player, "launched", {
		requestId = requestId, requestEpoch = epoch, shotActive = true,
		reloadTime = accepted.reloadTime, reloadDelay = accepted.reloadTime,
	})
	local bornAt = now
	local connection: RBXScriptConnection
	connection = pizza.Touched:Connect(function(hit)
		if not ProjectileService.isCurrent(player, pizza, epoch) or states[player] ~= state
			or state.cleanupEpoch ~= epoch or not launcherLease:isValid(player) or not RecordRunService.canLaunch(player)
			or pizza:GetAttribute("Resolved") or hit:IsDescendantOf(pizza) or Workspace:GetServerTimeNow() - bornAt < 0.13 then
			return
		end
		if ProjectileService.isCharacterPart(hit) then
			return
		end

		if hit:GetAttribute("ReactiveProp") and PropService.knock(hit, pizza.AssemblyLinearVelocity) then
			createSplat(hit, pizza.Position, Color3.fromRGB(255, 190, 57))
			playSound(hit, SOUND.bounce, 0.6, math.random(85, 125) / 100)
			connection:Disconnect()
			finishShot(player, pizza, "PIZZA CHAOS!", pizza.Position, nil)
		elseif hit:GetAttribute("CustomerPart") then
			local tableId = hit:GetAttribute("TableId")
			createSplat(hit, pizza.Position, Color3.fromRGB(255, 187, 58))
			impactRing(pizza.Position, Color3.fromRGB(255, 132, 76))
			CustomerService.hit(tableId)
			customerReaction(tableId, "dodge")
			connection:Disconnect()
			finishShot(player, pizza, "TOO HUNGRY!", pizza.Position, tableId)
		elseif hit:GetAttribute("DeliverySurface") then
			connection:Disconnect()
			impactRing(pizza.Position, Color3.fromRGB(255, 221, 74))
			finishShot(player, pizza, "delivery", pizza.Position, hit:GetAttribute("TableId"))
		elseif hit:GetAttribute("MissSurface") or hit:GetAttribute("SplatSurface") then
			connection:Disconnect()
			createSplat(hit, pizza.Position, Color3.fromRGB(255, 187, 58))
			impactRing(pizza.Position, Color3.fromRGB(255, 126, 83))
			finishShot(player, pizza, hit.Name == "RestaurantFloor" and "FLOOR PIZZA!" or "SAUCY SPLAT!", pizza.Position, nil)
		end
	end)
	shot.connection = connection

	task.delay(Config.PROJECTILE_LIFETIME, function()
		if ProjectileService.isCurrent(player, pizza, epoch) and states[player] == state
			and state.cleanupEpoch == epoch and not pizza:GetAttribute("Resolved") then
			if connection.Connected then
				connection:Disconnect()
			end
			finishShot(player, pizza, "LOST IN THE SAUCE!", pizza.Position, nil)
		end
	end)
end

local function upgradeChangeMessage(upgradeId: string, oldLevel: number, newLevel: number): string
	if upgradeId == "tips" then
		return string.format("Delivery rewards x%.2f -> x%.2f", 1 + oldLevel * 0.25, 1 + newLevel * 0.25)
	elseif upgradeId == "assist" then
		return string.format("Landing zone +%d%% -> +%d%%", oldLevel * 12, newLevel * 12)
	elseif upgradeId == "reload" then
		return string.format("Oven reload %.2fs -> %.2fs", Config.RELOAD_TIME * (1 - oldLevel * 0.12), Config.RELOAD_TIME * (1 - newLevel * 0.12))
	elseif upgradeId == "power" then
		return string.format("Max launch power %d -> %d", math.floor(Config.MAX_SPEED * (1 + oldLevel * 0.04) + 0.5), math.floor(Config.MAX_SPEED * (1 + newLevel * 0.04) + 0.5))
	end
	return "Upgrade applied immediately"
end

local function onPurchase(player: Player, upgradeId: any)
	local state = states[player]
	local purchase, reason, cost = PlayerProgression.purchase(Config, state, upgradeId, RecordRunService.isSession(player))
	if not purchase then
		if reason then sendState(player, "purchaseResult", { result = reason, success = false, cost = cost }) end
		return
	end
	local definition, oldLevel, newLevel = purchase.definition, purchase.oldLevel, purchase.newLevel
	journey:emit(player, "FirstEarnedUpgrade", state.mode == "walk" and "lobby" or "freePlay", "earned")
	if ShotPolicy.canPresent(player, launcherLease.owner, state) then
		if upgradeId == "assist" then updateDeliveryZones(newLevel, false) end
		applyProgressionVisuals(state)
	end
	local world = Workspace:FindFirstChild("PizzaLaunchWorld")
	local console = world and world:FindFirstChild("OperatorConsole", true)
	if ShotPolicy.canPresent(player, launcherLease.owner, state) and console and console:IsA("BasePart") then
		coinBurst(console.Position + Vector3.new(0, 4, 0), Color3.fromRGB(75, 200, 116))
		playSound(console, SOUND.success, 0.28, 1.25)
	end
	setLeaderstats(player, state)
	sendState(player, "purchaseResult", {
		result = string.format("%s LEVEL %d!", definition.name, newLevel),
		success = true,
		upgradeId = upgradeId,
		effect = definition.effect,
		changeMessage = upgradeChangeMessage(upgradeId, oldLevel, newLevel),
		oldLevel = oldLevel,
		newLevel = newLevel,
	})
end

local function clearActiveShot(player: Player)
	local state = states[player]
	if state then
		state.shotActive = false
		state.lastLaunch = -100
	end
	ProjectileService.clear(player)
end

-- This is deliberately the one route out of a launcher session.  It is safe to
-- call more than once because every mutable launcher resource is cleared before
-- the player and prompt are restored.
cleanupLauncherSession = function(player: Player, reason: string, options: { cancelRun: boolean?, moveToExit: boolean?, notifyClient: boolean? }?)
	local state = states[player]
	if not state then
		return
	end
	options = options or {}
	-- Departure removes the run just after cleanup; count its cancellation here
	-- while the authenticated player session and original status still exist.
	if not options.cancelRun and reason == "playerLeaving" then recordCancellation(player) end
	local wasOwner = launcherLease.owner == player
	if wasOwner then
		customerFeedback:clear(player)
		-- Release the lane in a stable pose; old prop callbacks cannot affect the next chef.
		PropService.resetAll()
	end
	state.cleanupEpoch = (state.cleanupEpoch or 0) + 1
	clearActiveShot(player)
	if options.cancelRun then
		cancelRecordRun(player)
	end
	if state.resumeTargetId then
		state.targetId = state.resumeTargetId
		state.resumeTargetId = nil
	end
	state.mode = "walk"
	state.launcherMode = "none"
	sendProfile(player)
	if launcherLease:release(player, options.moveToExit and Config.LAUNCHER_EXIT_CFRAME or nil) then
		launcherQueue:step()
	end
	broadcastActivity()
	if options.notifyClient then
		sendState(player, "launcherReset", { result = "BACK ON THE FLOOR", reason = reason })
	end
end

local function setPlayerMode(player: Player, requestedMode: string)
	local state = states[player]
	if not state then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if requestedMode == "launcher" then
		if launcherLease.owner == player and state.mode == "launcher" then
			sendState(player, "notice", { result = "LAUNCHER IN USE", detail = "Choose a mode or keep playing." })
			return
		end
		-- A finished/saving run must never make the next free-play launcher session
		-- use Record Run restrictions or fixed physics. Route stale state through
		-- the same cleanup path rather than only changing the Record Run flag.
		if RecordRunService.isSession(player) then
			cleanupLauncherSession(player, "reenterLauncher", { cancelRun = true, moveToExit = false, notifyClient = false })
		end
		if launcherLease.owner and launcherLease.owner ~= player then
			journey:occupied(player)
			sendActivity(player, "launcherOccupied", { result = "LAUNCHER OCCUPIED" })
			return
		end
		if not livingRoot(player) then return end
		if not launcherQueue:canMount(player) then
			journey:occupied(player)
			sendActivity(player, "launcherOccupied", { result = "TURN RESERVED", detail = "The next chef has a short chance to approach." })
			return
		end
		local world = Workspace:FindFirstChild("PizzaLaunchWorld")
		local interactionAnchor = world and world:FindFirstChild("LauncherInteractionAnchor", true)
		if not interactionAnchor or not interactionAnchor:IsA("BasePart") or not ((root.Position - interactionAnchor.Position).Magnitude <= 17) then
			return
		end
		if not launcherLease:acquire(player, character, Config.LAUNCHER_OPERATOR_CFRAME) then return end
		state.cleanupEpoch += 1
		state.lastRequestId = 0
		state.mode = "launcher"
		state.launcherMode = "select"
		journey:mounted(player)
		sendProfile(player)
		launcherQueue:accepted(player)
		invalidateActivity(player, "mounted")
		InteractionService.setLauncherAvailable(false)
		LayoutService.setRound(state.round)
		updateDeliveryZones(state.upgrades.assist, false)
		applyProgressionVisuals(state)
		sendState(player, "modeChanged", { result = "CHOOSE HOW TO PLAY", mode = "launcher" })
		broadcastActivity()
	elseif requestedMode == "walk" then
		cleanupLauncherSession(player, "playerExit", { cancelRun = true, moveToExit = state.mode == "launcher", notifyClient = false })
		sendState(player, "modeChanged", { result = "BACK ON THE FLOOR", mode = "walk" })
	end
end

local function selectLauncherMode(player: Player, requestedMode: string)
	local state = states[player]
	if not state or state.mode ~= "launcher" or launcherLease.owner ~= player or state.shotActive then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") or not root.Anchored
		or not launcherLease:isValid(player) then
		cleanupLauncherSession(player, "invalidMountedCharacter", { cancelRun = true, notifyClient = true })
		return
	end
	local runStatus = RecordRunService.getSnapshot(player).status
	if requestedMode == "chooseMode" then
		if runStatus == "countdown" or runStatus == "running" or runStatus == "saving" then
			sendState(player, "notice", { result = "RUN IN PROGRESS", detail = "Finish the run or use Exit Launcher." })
			return
		end
		if RecordRunService.isSession(player) then
			cancelRecordRun(player)
		end
		if state.resumeTargetId then
			state.targetId = state.resumeTargetId
			state.resumeTargetId = nil
		end
		customerFeedback:clear(player)
		ProjectileService.clear(player)
		state.cleanupEpoch += 1
		state.lastRequestId = 0
		state.launcherMode = "select"
		sendProfile(player)
		updateDeliveryZones(state.upgrades.assist, false)
		sendState(player, "modeSelection", { result = "CHOOSE HOW TO PLAY" })
		broadcastActivity()
		return
	end
	if state.launcherMode ~= "select" then
		return
	end
	if requestedMode == "freePlay" then
		if RecordRunService.isSession(player) then
			cancelRecordRun(player)
		end
		customerFeedback:clear(player)
		ProjectileService.clear(player)
		state.cleanupEpoch += 1
		state.lastRequestId = 0
		state.launcherMode = "freePlay"
		journey:emit(player, "ModeSelected", "freePlay", "selected")
		sendProfile(player)
		updateDeliveryZones(state.upgrades.assist, false)
		sendState(player, "modeSelected", { result = "FREE PLAY", detail = "Practice launches with no time limit." })
		broadcastActivity()
	elseif requestedMode == "recordRun" then
		if runStatus == "countdown" or runStatus == "running" or runStatus == "saving" then
			return
		end
		if RecordRunService.isSession(player) then
			cancelRecordRun(player)
		end
		state.resumeTargetId = state.resumeTargetId or state.targetId
		customerFeedback:clear(player)
		ProjectileService.clear(player)
		state.cleanupEpoch += 1
		state.lastRequestId = 0
		state.launcherMode = "recordRun"
		PropService.resetAll()
		local started, reason = RecordRunService.begin(player)
		if started then
			journey:emit(player, "ModeSelected", "recordRun", "selected")
			sendProfile(player)
			updateDeliveryZones(0, true)
			local snapshot = RecordRunService.getSnapshot(player)
			state.targetId = snapshot.targetId or state.targetId
		else
			state.launcherMode = "select"
			sendState(player, "notice", { result = "RECORD RUN UNAVAILABLE", detail = reason or "Try again in a moment." })
		end
	end
end

local function disconnectCharacter(player)
	for _, connection in characterConnections[player] or {} do connection:Disconnect() end
	characterConnections[player] = nil
	ProjectileService.unbindCharacter(player)
end

local function initializeCharacter(player: Player, character: Model)
	if player.Character ~= character then return end
	disconnectCharacter(player)
	invalidateActivity(player, "characterRespawn")
	cleanupLauncherSession(player, "characterRespawn", { cancelRun = true, notifyClient = true })
	ProjectileService.bindCharacter(player, character)
	local connections = {}
	characterConnections[player] = connections
	local initialized = false
	local function initializeReadyCharacter()
		if initialized or player.Character ~= character or not states[player] then return end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local root = character:FindFirstChild("HumanoidRootPart")
		if not humanoid or not root or not root:IsA("BasePart") then return end
		initialized = true
		table.insert(connections, humanoid.Died:Connect(function()
			if player.Character == character and character:FindFirstChildOfClass("Humanoid") == humanoid and states[player] then
				invalidateActivity(player, "characterDied")
				cleanupLauncherSession(player, "characterDied", { cancelRun = true, notifyClient = true })
			end
		end))
		if humanoid.Health > 0 and launcherLease.owner ~= player then root.CFrame = Config.WALK_SPAWN_CFRAME end
	end
	table.insert(connections, character.ChildAdded:Connect(function(child)
		initializeReadyCharacter()
		if child.Name == "Head" and player.Character == character then sendProfile(player) end
	end))
	initializeReadyCharacter()
	sendProfile(player)
end

local function addPlayer(player: Player)
	states[player] = {
		coins = 0,
		combo = 0,
		bestCombo = 0,
		round = 1,
		roundProgress = 0,
		targetId = nextTarget(nil, 1),
		targetSetAt = Workspace:GetServerTimeNow(),
		lastLaunch = -100,
		shotActive = false,
		mode = "walk",
		launcherMode = "none",
		upgrades = { tips = 0, assist = 0, reload = 0, power = 0 },
		cleanupEpoch = 0,
		activityEpoch = 0,
		activityRequests = { queue = 0, takeout = 0 },
		activityRequestTimes = {},
		profileRequestId = 0, profileRequestTimes = { request = -100, equip = -100 },
		receiptSequences = { delivery = 0, takeout = 0, record = 0 },
	}
	journey:addPlayer(player)
	profiles:addPlayer(player)
	RecordRunService.addPlayer(player)
	runner:addPlayer(player)

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	for _, name in { "Coins", "Combo", "Round" } do
		local value = Instance.new("IntValue")
		value.Name = name
		value.Value = name == "Round" and 1 or 0
		value.Parent = leaderstats
	end
	player.CharacterAdded:Connect(function(character)
		initializeCharacter(player, character)
	end)
	player.CharacterRemoving:Connect(function(character)
		if player.Character == character or launcherLease.character == character then
			invalidateActivity(player, "characterRemoving")
			cleanupLauncherSession(player, "characterRemoving", { cancelRun = true, notifyClient = true })
			disconnectCharacter(player)
		end
	end)
	if player.Character then
		initializeCharacter(player, player.Character)
	end
	task.delay(0.8, function()
		if player.Parent then
			sendState(player, "welcome", nil)
			sendActivity(player, "activity", nil)
		end
	end)
end

function GameService.start()
	createRemotes()
	journey = JourneyAnalytics.new()
	profiles = ProfileService.new({
		onChanged = function(player, snapshot) sendProfile(player, nil, nil, snapshot) end,
		onEvent = function(player, eventName, reason)
			if eventName == "ProfileLoadFailure" or eventName == "ProfileSaveFailure" then
				journey:emit(player, eventName, "profile", reason == "locked" and "locked" or "failed")
			end
		end,
	})
	profiles:start()
	ShiftEventService.reset()
	launchRemote.OnServerEvent:Connect(onLaunch)
	purchaseRemote.OnServerEvent:Connect(onPurchase)
	profileActionRemote.OnServerEvent:Connect(onProfileAction)
	journeyRemote.OnServerEvent:Connect(function(player, action, epoch, character)
		local world = Workspace:FindFirstChild("PizzaLaunchWorld")
		local anchor = world and world:FindFirstChild("LauncherInteractionAnchor", true)
		if not anchor or not anchor:IsA("BasePart") then return end
		journey:uiAction(player, action, epoch, character, {
			state = states[player], spawnPosition = Config.WALK_SPAWN_CFRAME.Position, launcherPosition = anchor.Position,
		})
	end)
	modeRemote.OnServerEvent:Connect(function(player, requestedMode, requestEpoch)
		local state = states[player]
		if not state or requestEpoch ~= state.cleanupEpoch or typeof(requestedMode) ~= "string" then
			return
		end
		if requestedMode == "walk" then
			setPlayerMode(player, "walk")
		elseif requestedMode == "freePlay" or requestedMode == "recordRun" or requestedMode == "chooseMode" then
			selectLauncherMode(player, requestedMode)
		end
	end)
	local world = Workspace:WaitForChild("PizzaLaunchWorld")
	TakeoutWorld.start(world)
	sharedMilestone = SharedMilestone.new({
		target = 12, reward = 10,
		isPresent = function(player) return states[player] ~= nil and player.Parent ~= nil end,
		award = function(player, coins, cycle)
			local state = states[player]
			if not state or not player.Parent then return end
			state.coins += coins
			setLeaderstats(player, state)
			sendActivity(player, "restaurantReward", { coinsEarned = coins, cycle = cycle })
		end,
		notify = function(_, completed)
			broadcastActivity(completed and "restaurantMilestone" or "restaurantProgress")
		end,
	})
	runner = TakeoutRunner.new({
		config = TakeoutConfig, now = function() return Workspace:GetServerTimeNow() end,
		getState = function(player) return states[player] end,
		award = function(player, receipt)
			local state = states[player]
			if not state or not player.Parent then return end
			state.coins += receipt.coinsEarned
			setLeaderstats(player, state)
			profiles:recordTakeout(player, table.freeze({ sequence = receiptSequence(state, "takeout") }))
			if sharedMilestone then sharedMilestone:contribute(player, "takeout") end
		end,
		notify = function(player, eventName, payload)
			if eventName == "runnerStarted" then journey:takeoutStarted(player)
			elseif eventName == "runnerCompleted" then journey:takeoutCompleted(player) end
			sendActivity(player, eventName, payload)
		end,
	})
	launcherQueue = LauncherQueue.new({
		now = function() return Workspace:GetServerTimeNow() end,
		getOwner = function() return launcherLease.owner end,
		isEligible = function(player, character)
			local state = states[player]
			local root = livingRoot(player, character)
			return state ~= nil and state.mode == "walk" and root ~= nil and not root.Anchored
		end,
		notify = function(player, eventName, payload)
			if eventName == "queueAccepted" then journey:emit(player, "QueueAccepted", "queue", "accepted")
			elseif eventName == "queueLeft" then journey:emit(player, "QueueAbandoned", "queue", "cancelled") end
			sendActivity(player, eventName, payload)
		end,
		reservationSeconds = 15,
	})
	queueRemote.OnServerEvent:Connect(function(player, action, epoch, requestId)
		if not activityRequest(player, "queue", epoch, requestId) then return end
		if action == "join" then
			local root = livingRoot(player)
			local anchor = world:FindFirstChild("LauncherInteractionAnchor", true)
			if not root or not anchor or not ((root.Position - anchor.Position).Magnitude <= 22) then
				sendActivity(player, "queueRejected", { reason = "approachLauncher" }); return
			end
			local accepted, reason = launcherQueue:join(player)
			if accepted and reason == nil then journey:emit(player, "QueueJoined", "queue", "accepted") end
			sendActivity(player, accepted and "queueChanged" or "queueRejected", { reason = reason })
		elseif action == "leave" then launcherQueue:cancel(player, "cancelled") end
		broadcastActivity()
	end)
	takeoutRemote.OnServerEvent:Connect(function(player, action, epoch, requestId, orderId)
		if not activityRequest(player, "takeout", epoch, requestId) then return end
		if action == "route" then sendActivity(player, "takeoutRoute")
		elseif action == "cancel" and typeof(orderId) == "string" then runner:cancel(player, "cancelled", orderId) end
	end)
	CustomerService.start(world, function(lifecycleName)
		if lifecycleName == "entered" then
			local door = world:FindFirstChild("FrontGlassDoor", true)
			if door and door:IsA("BasePart") then
				playSound(door, SOUND.success, 0.1, 1.55)
			end
		end
	end)
	LayoutService.start(world)
	PropService.start(world)
	ProjectileService.start(world)
	WorldActivityService.start(world)
	updateDeliveryZones(0, false)
	RecordRunService.start(world, function(player, eventName, submission)
		local state = states[player]
		if not state then
			return
		end
		local snapshot = RecordRunService.getSnapshot(player)
		if snapshot.targetId then
			state.targetId = snapshot.targetId
		end
		if eventName == "recordEnding" then
			-- The completion comes from RecordRunService's immutable pre-yield
			-- receipt. Never sample the mutable score to construct durable gains.
			if submission and submission.userId == player.UserId and submission.runId ~= state.lastCompletedRunId then
				state.lastCompletedRunId = submission.runId
				profiles:recordCompletedRun(player, table.freeze({
					sequence = receiptSequence(state, "record"), score = submission.score,
				}))
				journey:emit(player, "RecordRunCompleted", "recordRun", "completed")
				if snapshot.isNewBest then journey:emit(player, "NewPersonalBest", "recordRun", "earned") end
			end
			if launcherLease.owner == player then customerFeedback:clear(player) end
			state.cleanupEpoch += 1
			state.lastRequestId = 0
			if launcherLease.owner == player then PropService.resetAll() end
			-- End the competitive shot window immediately. The player keeps the
			-- launcher lease while the compact result card saves, then explicitly
			-- chooses another mode or exits.
			clearActiveShot(player)
			sendProfile(player)
		elseif eventName == "recordStarted" then
			journey:recordStarted(player)
		end
		sendState(player, eventName, nil)
		broadcastActivity()
	end)
	InteractionService.start(world, {
		takeoutPickup = function(player)
			runner:pickup(player)
		end,
		takeoutDelivery = function(player, destinationId)
			local order = runner:getSnapshot(player)
			if order.status == "carrying" and order.destinationId == destinationId then runner:deliver(player, order.orderId) end
		end,
		launcher = function(player)
			setPlayerMode(player, "launcher")
		end,
		recordRun = function(player)
			-- Legacy handler retained for compatibility with recovered Studio places.
			-- Current Rojo worlds do not create a competing RecordRunPrompt.
			setPlayerMode(player, "launcher")
		end,
		register = function(player)
			local state = states[player]
			if state and state.mode == "walk" then
				local round = roundDefinition(state.round)
				sendState(player, "notice", {
					result = string.format("%s SHIFT", round.name),
					detail = string.format("%d of %d orders served • %d coins", state.roundProgress, round.goal, state.coins),
				})
			end
		end,
		customer = function(player, tableId)
			local state = states[player]
			local info = typeof(tableId) == "number" and CustomerService.getInfo(tableId) or nil
			if state and state.mode == "walk" and info then
				sendState(player, "customerDialogue", {
					name = info.name,
					mood = info.mood,
					line = info.state == "SeatedWaiting" and info.line or "I will be ready again in a moment.",
					color = info.color,
					patience = info.patience,
				})
			end
		end,
	})
	task.spawn(function()
		local nextActivityAt = 0
		while world.Parent do
			task.wait(0.25)
			runner:step()
			local queueChanged = launcherQueue:step()
			if queueChanged or Workspace:GetServerTimeNow() >= nextActivityAt then
				nextActivityAt = Workspace:GetServerTimeNow() + 1
				broadcastActivity()
			end
			local owner = launcherLease.owner
			if owner and not launcherLease:isValid(owner) then
				cleanupLauncherSession(owner, "invalidMountedCharacter", { cancelRun = true, notifyClient = true })
			end
			local expired = ShiftEventService.expire()
			if expired then
				endShiftEvent(expired, "Event time ended. No penalty - keep serving!")
			end
		end
	end)
	Players.PlayerAdded:Connect(addPlayer)
	Players.PlayerRemoving:Connect(function(player)
		invalidateActivity(player, "playerLeaving")
		cleanupLauncherSession(player, "playerLeaving", { cancelRun = false, moveToExit = false, notifyClient = false })
		RecordRunService.removePlayer(player)
		runner:removePlayer(player)
		profiles:removePlayer(player)
		ProfileCosmetics.clear(player)
		journey:removePlayer(player)
		if sharedMilestone then sharedMilestone:removePlayer(player) end
		disconnectCharacter(player)
		states[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		addPlayer(player)
	end
end

return GameService
