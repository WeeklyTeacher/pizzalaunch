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
local launcherOccupant: Player?
local activeShots: { [Player]: { pizza: BasePart, connection: RBXScriptConnection? } } = {}

local function playSound(parent: Instance, soundId: string, volume: number, playbackSpeed: number?)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume
	sound.PlaybackSpeed = playbackSpeed or 1
	sound.RollOffMaxDistance = 140
	sound.RollOffMinDistance = 10
	sound.Parent = parent
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	task.delay(5, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
end

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

local function reactionText(customer: Model, text: string)
	local marker = customer:FindFirstChild("WaitingMarker", true)
	local label = marker and marker:FindFirstChild("Label", true)
	if label and label:IsA("TextLabel") then
		if string.find(text, "NOM") then
			label.Text = "YUM"
		elseif string.find(text, "HEY") then
			label.Text = "?"
		elseif string.find(text, "WHOA") or string.find(text, "DUCK") then
			label.Text = "!"
		elseif string.find(text, "YES") or string.find(text, "WOOHOO") or string.find(text, "BEST") then
			label.Text = "★"
		else
			label.Text = "🍕"
		end
	end
end

local function resetCustomer(customer: Model, token: number)
	task.delay(1.25, function()
		if not customer.Parent or customer:GetAttribute("ReactionToken") ~= token then
			return
		end
		for _, descendant in customer:GetDescendants() do
			if descendant:IsA("BasePart") then
				local reset = descendant:GetAttribute("ResetCFrame")
				if typeof(reset) == "CFrame" then
					TweenService:Create(descendant, TweenInfo.new(0.28, Enum.EasingStyle.Quad), { CFrame = reset }):Play()
				end
			end
		end
		local faceGui = customer:FindFirstChild("Face", true)
		local faceLabel = faceGui and faceGui:FindFirstChild("Label")
		if faceLabel and faceLabel:IsA("TextLabel") then
			faceLabel.Text = "^  ^\n\\___/"
		end
		local customerName = customer:GetAttribute("CustomerName") or "CUSTOMER"
		reactionText(customer, string.format("%s IS HUNGRY!\nPIZZA, PLEASE!", string.upper(customerName)))
	end)
end

local function coinBurst(position: Vector3, color: Color3)
	local folder = Instance.new("Folder")
	folder.Name = "CoinBurst"
	folder.Parent = Workspace
	for index = 1, 9 do
		local coin = Instance.new("Part")
		coin.Name = "Coin"
		coin.Shape = Enum.PartType.Cylinder
		coin.Size = Vector3.new(0.25, 1.3, 1.3)
		coin.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2)
		coin.Anchored = true
		coin.CanCollide = false
		coin.CanTouch = false
		coin.CanQuery = false
		coin.Material = Enum.Material.Neon
		coin.Color = index % 3 == 0 and color or Color3.fromRGB(255, 211, 55)
		coin.Parent = folder
		local angle = index / 9 * math.pi * 2
		local target = position + Vector3.new(math.cos(angle) * 7, 5 + (index % 3) * 2, math.sin(angle) * 4)
		TweenService:Create(coin, TweenInfo.new(0.65, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = target,
			Transparency = 1,
			Orientation = Vector3.new(0, index * 70, 90),
		}):Play()
	end
	task.delay(0.8, function()
		folder:Destroy()
	end)
end

local function confettiBurst(position: Vector3)
	local folder = Instance.new("Folder")
	folder.Name = "BirthdayConfetti"
	folder.Parent = Workspace
	local colors = {
		Color3.fromRGB(255, 85, 96), Color3.fromRGB(255, 211, 55),
		Color3.fromRGB(76, 200, 124), Color3.fromRGB(82, 180, 235),
	}
	for index = 1, 18 do
		local piece = Instance.new("Part")
		piece.Name = "Confetti"
		piece.Size = Vector3.new(0.22, 0.65, 0.35)
		piece.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
		piece.Anchored = true
		piece.CanCollide = false
		piece.CanTouch = false
		piece.CanQuery = false
		piece.Material = Enum.Material.Neon
		piece.Color = colors[(index - 1) % #colors + 1]
		piece.Parent = folder
		local angle = index / 18 * math.pi * 2
		local distance = 4 + index % 4
		TweenService:Create(piece, TweenInfo.new(0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = position + Vector3.new(math.cos(angle) * distance, 6 + index % 5, math.sin(angle) * distance),
			Orientation = Vector3.new(index * 43, index * 71, index * 29),
			Transparency = 1,
		}):Play()
	end
	task.delay(1, function()
		folder:Destroy()
	end)
end

local function customerReaction(tableId: number, reaction: string)
	local tableModel = worldTable(tableId)
	local customer = tableModel and tableModel:FindFirstChild("Customer")
	if not customer or not customer:IsA("Model") then
		return
	end
	local token = (customer:GetAttribute("ReactionToken") or 0) + 1
	customer:SetAttribute("ReactionToken", token)
	CustomerService.markReacting(customer, 1.7)
	local head = customer:FindFirstChild("Head")
	local torso = customer:FindFirstChild("Torso")
	local leftArm = customer:FindFirstChild("LeftArm")
	local rightArm = customer:FindFirstChild("RightArm")
	local faceGui = customer:FindFirstChild("Face", true)
	local faceLabel = faceGui and faceGui:FindFirstChild("Label")

	if reaction == "success" then
		reactionText(customer, "YES! PIZZA!\nBEST DAY EVER!")
		if faceLabel and faceLabel:IsA("TextLabel") then
			faceLabel.Text = "*  *\n\\___/"
		end
		if head and head:IsA("BasePart") then
			TweenService:Create(head, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { CFrame = head.CFrame + Vector3.new(0, 1.8, 0) }):Play()
			coinBurst(head.Position + Vector3.new(0, 4, 0), tableDefinition(tableId).color)
		end
		for _, arm in { leftArm, rightArm } do
			if arm and arm:IsA("BasePart") then
				local side = arm.Name == "LeftArm" and -1 or 1
				TweenService:Create(arm, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
					CFrame = arm.CFrame * CFrame.new(side * 0.6, 2, 0) * CFrame.Angles(0, 0, math.rad(side * -115)),
				}):Play()
			end
		end
	elseif reaction == "crowd" then
		reactionText(customer, "PIZZA STREAK!\nWOOHOO!")
		if faceLabel and faceLabel:IsA("TextLabel") then
			faceLabel.Text = "^  ^\n\\___/"
		end
		if head and head:IsA("BasePart") then
			TweenService:Create(head, TweenInfo.new(0.3, Enum.EasingStyle.Back), { CFrame = head.CFrame + Vector3.new(0, 1.25, 0) }):Play()
		end
		if torso and torso:IsA("BasePart") then
			TweenService:Create(torso, TweenInfo.new(0.3, Enum.EasingStyle.Back), { CFrame = torso.CFrame + Vector3.new(0, 0.55, 0) }):Play()
		end
		for _, arm in { leftArm, rightArm } do
			if arm and arm:IsA("BasePart") then
				local side = arm.Name == "LeftArm" and -1 or 1
				TweenService:Create(arm, TweenInfo.new(0.32, Enum.EasingStyle.Back), {
					CFrame = arm.CFrame * CFrame.new(side * 0.45, 1.6, 0) * CFrame.Angles(0, 0, math.rad(side * -105)),
				}):Play()
			end
		end
	elseif reaction == "wrong" then
		reactionText(customer, "HEY! NOT MY ORDER!\n...STILL SMELLS GOOD")
		if faceLabel and faceLabel:IsA("TextLabel") then
			faceLabel.Text = "O  O\n  o"
		end
		for _, bodyPart in { head, torso, leftArm, rightArm } do
			if bodyPart and bodyPart:IsA("BasePart") then
				TweenService:Create(bodyPart, TweenInfo.new(0.22, Enum.EasingStyle.Back), { CFrame = bodyPart.CFrame + Vector3.new(3, 0.5, 0) }):Play()
			end
		end
	else
		reactionText(customer, "WHOA! FLYING PIZZA!\nDUCK!")
		if faceLabel and faceLabel:IsA("TextLabel") then
			faceLabel.Text = ">  <\n  O"
		end
		for _, bodyPart in { head, torso } do
			if bodyPart and bodyPart:IsA("BasePart") then
				TweenService:Create(bodyPart, TweenInfo.new(0.18), { CFrame = bodyPart.CFrame + Vector3.new(0, -2, 0) }):Play()
			end
		end
	end
	resetCustomer(customer, token)
end

local function surfaceNormal(hit: BasePart, point: Vector3): Vector3
	local localPoint = hit.CFrame:PointToObjectSpace(point)
	local half = hit.Size * 0.5
	local normalized = Vector3.new(
		math.abs(localPoint.X) / math.max(half.X, 0.01),
		math.abs(localPoint.Y) / math.max(half.Y, 0.01),
		math.abs(localPoint.Z) / math.max(half.Z, 0.01)
	)
	local localNormal
	if normalized.X >= normalized.Y and normalized.X >= normalized.Z then
		localNormal = Vector3.new(math.sign(localPoint.X), 0, 0)
	elseif normalized.Y >= normalized.Z then
		localNormal = Vector3.new(0, math.sign(localPoint.Y), 0)
	else
		localNormal = Vector3.new(0, 0, math.sign(localPoint.Z))
	end
	return hit.CFrame:VectorToWorldSpace(localNormal)
end

local function splatFolder(): Folder
	local folder = Workspace:FindFirstChild("PizzaMess")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "PizzaMess"
		folder.Parent = Workspace
	end
	while #folder:GetChildren() >= 24 do
		folder:GetChildren()[1]:Destroy()
	end
	return folder :: Folder
end

local function createSplat(hit: BasePart, position: Vector3, color: Color3)
	local normal = surfaceNormal(hit, position)
	local splat = Instance.new("Part")
	splat.Name = "CheesySplat"
	splat.Shape = Enum.PartType.Cylinder
	splat.Size = Vector3.new(0.12, math.random(40, 65) / 10, math.random(40, 65) / 10)
	splat.CFrame = CFrame.lookAt(position + normal * 0.1, position + normal) * CFrame.Angles(0, math.pi / 2, 0)
	splat.Anchored = true
	splat.CanCollide = false
	splat.CanTouch = false
	splat.CanQuery = false
	splat.Material = Enum.Material.SmoothPlastic
	splat.Color = color
	splat.Transparency = 0.08
	splat.Parent = splatFolder()

	for index = 1, 3 do
		local blob = Instance.new("Part")
		blob.Name = "SauceBlob"
		blob.Shape = Enum.PartType.Ball
		local scale = math.random(7, 14) / 10
		blob.Size = Vector3.new(scale, scale, scale)
		blob.Position = position + normal * 0.35 + Vector3.new(math.random(-16, 16) / 10, math.random(-9, 14) / 10, math.random(-16, 16) / 10)
		blob.Anchored = true
		blob.CanCollide = false
		blob.CanTouch = false
		blob.CanQuery = false
		blob.Color = index == 1 and Color3.fromRGB(191, 48, 43) or color
		blob.Parent = splat
	end

	task.delay(7, function()
		if splat.Parent then
			for _, descendant in splat:GetDescendants() do
				if descendant:IsA("BasePart") then
					TweenService:Create(descendant, TweenInfo.new(1), { Transparency = 1 }):Play()
				end
			end
			TweenService:Create(splat, TweenInfo.new(1), { Transparency = 1 }):Play()
			task.delay(1.1, function()
				if splat.Parent then
					splat:Destroy()
				end
			end)
		end
	end)
end

local function impactRing(position: Vector3, color: Color3)
	local ring = Instance.new("Part")
	ring.Name = "PizzaImpact"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.18, 2, 2)
	ring.CFrame = CFrame.new(position + Vector3.new(0, 0.25, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanTouch = false
	ring.CanQuery = false
	ring.Material = Enum.Material.Neon
	ring.Color = color
	ring.Transparency = 0.1
	ring.Parent = Workspace
	TweenService:Create(ring, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.18, 15, 15),
		Transparency = 1,
	}):Play()
	task.delay(0.65, function()
		ring:Destroy()
	end)
end

local function finishShot(player: Player, pizza: BasePart, result: string, hitPosition: Vector3?, tableId: number?)
	local state = states[player]
	if not state or pizza:GetAttribute("Resolved") then
		return
	end
	pizza:SetAttribute("Resolved", true)
	state.shotActive = false
	activeShots[player] = nil
	local recordSession = RecordRunService.isSession(player)
	local effectiveReload = recordSession and Config.RELOAD_TIME or Config.RELOAD_TIME * (1 - state.upgrades.reload * 0.12)
	local payload = {
		result = result,
		position = hitPosition,
		tableId = tableId,
		coinsEarned = 0,
		comboBonus = 0,
		reloadDelay = math.max(0.05, state.lastLaunch + effectiveReload - Workspace:GetServerTimeNow()),
		recordRun = recordSession,
	}
	local eligibleTables = ShiftEventService.extendTablePool(roundDefinition(state.round).tables)
	local tableEligible = tableId ~= nil and (recordSession or table.find(eligibleTables, tableId) ~= nil)
	local acceptedDelivery = result == "delivery" and tableEligible and hitPosition ~= nil and CustomerService.claimDelivery(tableId)
	local shiftOutcome = nil

	if acceptedDelivery and tableId and hitPosition then
		local definition = tableDefinition(tableId)
		local horizontal = Vector3.new(hitPosition.X - definition.position.X, 0, hitPosition.Z - definition.position.Z)
		local round = roundDefinition(state.round)
		local assistScale = recordSession and 1.12 or (1 + state.upgrades.assist * 0.12) * round.accuracyScale
		local accuracy = Config.ACCURACY[#Config.ACCURACY]
		for _, tier in Config.ACCURACY do
			if horizontal.Magnitude <= tier.radius * assistScale then
				accuracy = tier
				break
			end
		end
		payload.result = accuracy.name
		payload.color = accuracy.color
		payload.accuracy = math.floor(horizontal.Magnitude * 10 + 0.5) / 10

		if recordSession then
			local recordResult = RecordRunService.recordSuccess(player, tableId, accuracy.name)
			if recordResult then
				payload.recordPoints = recordResult.lastPoints
				payload.recordScore = recordResult.score
				payload.recordCombo = recordResult.combo
				payload.recordMultiplier = recordResult.multiplier
				if recordResult.combo == 4 or recordResult.combo == 7 or recordResult.combo == 10 then
					payload.recordComboMilestone = true
				end
			else
				payload.result = "TIME!"
				payload.color = Color3.fromRGB(255, 203, 55)
			end
		else
			state.combo += 1
			state.bestCombo = math.max(state.bestCombo, state.combo)
			state.roundProgress += 1
			local comboBonus = math.min((state.combo - 1) * 2, 12)
			local unmultipliedReward = accuracy.coins + comboBonus
			-- The reward multiplier and all event bonuses are calculated only here,
			-- on the server. Record Run never enters this branch.
			local deliveryReward = math.floor(unmultipliedReward * (1 + state.upgrades.tips * 0.25) + 0.5)
			local serviceTime = Workspace:GetServerTimeNow() - (state.targetSetAt or Workspace:GetServerTimeNow())
			shiftOutcome = ShiftEventService.recordDelivery(tableId, accuracy.name, serviceTime)
			local earned = deliveryReward + (shiftOutcome.bonus or 0)
			state.coins += earned
			payload.coinsEarned = earned
			payload.comboBonus = comboBonus
			payload.tipBonus = math.max(0, deliveryReward - unmultipliedReward)
			payload.rewardMultiplier = 1 + state.upgrades.tips * 0.25
			payload.eventBonus = shiftOutcome.bonus or 0
			payload.fastServiceBonus = shiftOutcome.fastService and shiftOutcome.bonus or nil
			payload.eventMessage = shiftOutcome.message
		end

		pizza.Anchored = true
		pizza.CFrame = CFrame.new(definition.position + Vector3.new(0, 4.95, 0)) * CFrame.Angles(0, 0, math.pi / 2)
		customerReaction(tableId, "success")
		CustomerService.served(tableId)
		if shiftOutcome and shiftOutcome.confetti then
			confettiBurst(definition.position + Vector3.new(0, 6, 0))
			for _, tableData in Config.TABLES do
				customerReaction(tableData.id, "crowd")
			end
		end
		local crowdMilestone = (recordSession and payload.recordComboMilestone) or (not recordSession and (state.combo == 3 or state.combo == 5 or state.combo % 10 == 0))
		if crowdMilestone then
			payload.comboMilestone = recordSession and payload.recordCombo or state.combo
			for _, tableData in Config.TABLES do
				if tableData.id ~= tableId then
					customerReaction(tableData.id, "crowd")
				end
			end
		end
		playSound(pizza, accuracy.name == "PERFECT!" and SOUND.perfect or SOUND.success, accuracy.name == "PERFECT!" and 0.75 or 0.65, 1.05)
		task.delay(0.62, function()
			if not pizza.Parent then
				return
			end
			local tableModel = worldTable(tableId)
			local customer = tableModel and tableModel:FindFirstChild("Customer")
			if customer and customer:IsA("Model") then
				reactionText(customer, "NOM NOM NOM!\nDELICIOUS!")
			end
			TweenService:Create(pizza, TweenInfo.new(0.42, Enum.EasingStyle.Quad), { Size = Vector3.new(0.65, 2.8, 2.8), Transparency = 0.25 }):Play()
			for _, topping in pizza:GetChildren() do
				if topping:IsA("BasePart") then
					TweenService:Create(topping, TweenInfo.new(0.35), { Transparency = 1 }):Play()
				end
			end
		end)

		if not recordSession then
			if state.roundProgress >= round.goal then
				state.coins += round.reward
				payload.roundComplete = true
				payload.roundReward = round.reward
				payload.completedRound = state.round
				payload.completedRoundName = round.name
				state.roundProgress = 0
				if state.round < #Config.ROUNDS then
					state.round += 1
				end
				LayoutService.setRound(state.round)
				PropService.resetAll()
			end
			state.targetId = nextTarget(state.targetId, state.round)
			state.targetSetAt = Workspace:GetServerTimeNow()
			if shiftOutcome and shiftOutcome.ended then
				endShiftEvent(shiftOutcome.ended, shiftOutcome.message)
			end
			local startedEvent = ShiftEventService.maybeStart(roundDefinition(state.round).tables, state.targetId)
			if startedEvent then
				beginShiftEvent(startedEvent)
			end
		end
	elseif tableId then
		if recordSession then
			RecordRunService.recordMiss(player)
		else
			local eventMiss = ShiftEventService.recordMiss()
			if eventMiss then
				payload.comboSaved = eventMiss.comboSaved
				payload.eventMessage = eventMiss.message
				endShiftEvent(eventMiss.ended, eventMiss.message)
			else
				state.combo = 0
			end
		end
		payload.result = result == "delivery" and "TABLE IS CLEARING!" or "TOO HUNGRY!"
		payload.color = Color3.fromRGB(255, 139, 95)
		if result == "delivery" then
			CustomerService.wrongPizza(tableId)
			customerReaction(tableId, "wrong")
		else
			customerReaction(tableId, "dodge")
		end
		playSound(pizza, SOUND.miss, 0.38, 1.25)
	else
		if recordSession then
			RecordRunService.recordMiss(player)
		else
			local eventMiss = ShiftEventService.recordMiss()
			if eventMiss then
				payload.comboSaved = eventMiss.comboSaved
				payload.eventMessage = eventMiss.message
				endShiftEvent(eventMiss.ended, eventMiss.message)
			else
				state.combo = 0
			end
		end
		payload.color = Color3.fromRGB(255, 139, 95)
		playSound(pizza, SOUND.splat, 0.5, math.random(85, 115) / 100)
	end

	setLeaderstats(player, state)
	sendState(player, "shotResult", payload)
	task.delay(1.45, function()
		if pizza.Parent then
			pizza:Destroy()
		end
	end)
end

local function makePizza(player: Player, direction: Vector3, charge: number): BasePart
	local state = states[player]
	local pizza = Instance.new("Part")
	pizza.Name = string.format("%s_Pizza", player.Name)
	pizza.Shape = Enum.PartType.Cylinder
	pizza.Size = Vector3.new(0.65, 6, 6)
	pizza.CFrame = CFrame.new(Config.LAUNCH_ORIGIN + direction * 1.8) * CFrame.Angles(0, 0, math.pi / 2)
	pizza.Color = Color3.fromRGB(255, 199, 63)
	pizza.Material = Enum.Material.SmoothPlastic
	pizza.CustomPhysicalProperties = PhysicalProperties.new(0.65, 0.38, 0.62, 1, 1)
	pizza:SetAttribute("OwnerUserId", player.UserId)
	pizza.Parent = Workspace

	for index, offset in {
		Vector3.new(0.42, -1.5, -0.9), Vector3.new(0.42, 1.2, -1.2),
		Vector3.new(0.42, -0.4, 1.35), Vector3.new(0.42, 1.35, 0.8),
	} do
		local topping = Instance.new("Part")
		topping.Name = string.format("Pepperoni%d", index)
		topping.Shape = Enum.PartType.Ball
		topping.Size = Vector3.new(1.05, 0.35, 1.05)
		topping.Color = Color3.fromRGB(190, 46, 45)
		topping.Material = Enum.Material.SmoothPlastic
		topping.CFrame = pizza.CFrame * CFrame.new(offset)
		topping.CanCollide = false
		topping.CanTouch = false
		topping.CanQuery = false
		topping.Massless = true
		topping.Parent = pizza
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = pizza
		weld.Part1 = topping
		weld.Parent = topping
	end

	local powerLevel = RecordRunService.isSession(player) and 0 or state.upgrades.power
	local speed = Config.speedFromCharge(charge, powerLevel)
	pizza.AssemblyLinearVelocity = direction.Unit * speed
	pizza.AssemblyAngularVelocity = Vector3.new(direction.Z * 17, 5, -direction.X * 17)
	pizza:SetNetworkOwner(nil)
	playSound(pizza, SOUND.launch, 0.72, 1.06)
	task.delay(0.16, function()
		if pizza.Parent then
			playSound(pizza, SOUND.whoosh, 0.28, 1.3)
		end
	end)
	return pizza
end

local function isFinite(value: number): boolean
	return value == value and value > -math.huge and value < math.huge
end

local function onLaunch(player: Player, directionValue: any, chargeValue: any)
	local state = states[player]
	if not state or state.shotActive or state.mode ~= "launcher" or launcherOccupant ~= player then
		return
	end
	if not RecordRunService.canLaunch(player) then
		return
	end
	if typeof(directionValue) ~= "Vector3" or typeof(chargeValue) ~= "number" then
		return
	end
	if not isFinite(chargeValue) or not isFinite(directionValue.X) or not isFinite(directionValue.Y) or not isFinite(directionValue.Z) then
		return
	end
	if directionValue.Magnitude < 0.9 then
		return
	end
	local direction = directionValue.Unit
	local pitch = math.asin(math.clamp(direction.Y, -1, 1))
	local yaw = math.atan2(direction.X, -direction.Z)
	if pitch < Config.MIN_PITCH - 0.02 or pitch > Config.MAX_PITCH + 0.02 or math.abs(yaw) > Config.MAX_YAW + 0.02 or direction.Z > -0.3 then
		return
	end
	local now = Workspace:GetServerTimeNow()
	local reloadTime = RecordRunService.isSession(player) and Config.RELOAD_TIME or Config.RELOAD_TIME * (1 - state.upgrades.reload * 0.12)
	if now - state.lastLaunch < reloadTime then
		return
	end
	state.lastLaunch = now
	state.shotActive = true

	local pizza = makePizza(player, direction, math.clamp(chargeValue, 0, 1))
	sendState(player, "launched", { reloadTime = reloadTime })
	local bornAt = now
	local connection: RBXScriptConnection
	connection = pizza.Touched:Connect(function(hit)
		if pizza:GetAttribute("Resolved") or hit:IsDescendantOf(pizza) or Workspace:GetServerTimeNow() - bornAt < 0.13 then
			return
		end
		local character = player.Character
		if character and hit:IsDescendantOf(character) then
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
	activeShots[player] = { pizza = pizza, connection = connection }

	task.delay(Config.PROJECTILE_LIFETIME, function()
		if pizza.Parent and not pizza:GetAttribute("Resolved") then
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
		local diameter = Config.DELIVERY_ZONE_DIAMETER or 8
		return string.format("Landing zone %.1f -> %.1f studs", diameter * (1 + oldLevel * 0.12), diameter * (1 + newLevel * 0.12))
	elseif upgradeId == "reload" then
		return string.format("Oven reload %.2fs -> %.2fs", Config.RELOAD_TIME * (1 - oldLevel * 0.12), Config.RELOAD_TIME * (1 - newLevel * 0.12))
	elseif upgradeId == "power" then
		return string.format("Max launch power %d -> %d", math.floor(Config.MAX_SPEED * (1 + oldLevel * 0.04) + 0.5), math.floor(Config.MAX_SPEED * (1 + newLevel * 0.04) + 0.5))
	end
	return "Upgrade applied immediately"
end

local function onPurchase(player: Player, upgradeId: any)
	local state = states[player]
	local definition = typeof(upgradeId) == "string" and Config.UPGRADES[upgradeId] or nil
	if not state or not definition then
		return
	end
	if RecordRunService.isSession(player) then
		sendState(player, "purchaseResult", { result = "FINISH THE RECORD RUN FIRST", success = false })
		return
	end
	local level = state.upgrades[upgradeId]
	local cost = definition.costs[level + 1]
	if not cost then
		sendState(player, "purchaseResult", { result = "MAX LEVEL!", success = false })
		return
	end
	if state.coins < cost then
		sendState(player, "purchaseResult", { result = "NEED MORE COINS", success = false, cost = cost })
		return
	end
	local oldLevel = level
	state.coins -= cost
	state.upgrades[upgradeId] += 1
	local newLevel = state.upgrades[upgradeId]
	if upgradeId == "assist" then
		updateDeliveryZones(newLevel, false)
	end
	applyProgressionVisuals(state)
	local world = Workspace:FindFirstChild("PizzaLaunchWorld")
	local console = world and world:FindFirstChild("OperatorConsole", true)
	if console and console:IsA("BasePart") then
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

local function restoreMovement(character: Model, moveToExit: boolean)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		root.Anchored = false
		if moveToExit then
			root.CFrame = Config.LAUNCHER_EXIT_CFRAME
		end
	end
	if humanoid then
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
		humanoid.AutoRotate = true
	end
end

-- This is deliberately the one route out of a launcher session.  It is safe to
-- call more than once because every mutable launcher resource is cleared before
-- the player and prompt are restored.
local function cleanupLauncherSession(player: Player, reason: string, options: { cancelRun: boolean?, moveToExit: boolean?, notifyClient: boolean? }?)
	local state = states[player]
	if not state then
		return
	end
	options = options or {}
	state.cleanupEpoch = (state.cleanupEpoch or 0) + 1
	state.shotActive = false
	state.lastLaunch = -100
	local shot = activeShots[player]
	activeShots[player] = nil
	if shot then
		if shot.connection and shot.connection.Connected then
			shot.connection:Disconnect()
		end
		if shot.pizza.Parent then
			shot.pizza:Destroy()
		end
	end
	if options.cancelRun then
		RecordRunService.cancel(player)
	end
	if state.resumeTargetId then
		state.targetId = state.resumeTargetId
		state.resumeTargetId = nil
	end
	state.mode = "walk"
	if launcherOccupant == player then
		launcherOccupant = nil
		InteractionService.setLauncherAvailable(true)
	end
	local character = player.Character
	if character then
		restoreMovement(character, options.moveToExit == true)
	end
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
		-- A finished/saving run must never make the next free-play launcher session
		-- use Record Run restrictions or fixed physics. Route stale state through
		-- the same cleanup path rather than only changing the Record Run flag.
		if RecordRunService.isSession(player) then
			cleanupLauncherSession(player, "reenterLauncher", { cancelRun = true, moveToExit = false, notifyClient = false })
		end
		if launcherOccupant and launcherOccupant ~= player then
			sendState(player, "notice", { result = "LAUNCHER BUSY", detail = "Another chef is serving right now." })
			return
		end
		if not character or not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
			return
		end
		local world = Workspace:FindFirstChild("PizzaLaunchWorld")
		local console = world and world:FindFirstChild("OperatorConsole", true)
		if not console or not console:IsA("BasePart") or (root.Position - console.Position).Magnitude > 17 then
			return
		end
		launcherOccupant = player
		InteractionService.setLauncherAvailable(false)
		LayoutService.setRound(state.round)
		updateDeliveryZones(state.upgrades.assist, false)
		applyProgressionVisuals(state)
		state.mode = "launcher"
		root.CFrame = Config.LAUNCHER_OPERATOR_CFRAME
		root.Anchored = true
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.AutoRotate = false
		sendState(player, "modeChanged", { result = "READY TO LAUNCH!", mode = "launcher" })
	elseif requestedMode == "walk" then
		cleanupLauncherSession(player, "playerExit", { cancelRun = true, moveToExit = state.mode == "launcher", notifyClient = false })
		sendState(player, "modeChanged", { result = "BACK ON THE FLOOR", mode = "walk" })
	end
end

local function initializeCharacter(player: Player, character: Model)
	local state = states[player]
	if state then
		cleanupLauncherSession(player, "characterRespawn", { cancelRun = true, moveToExit = false, notifyClient = false })
	end
	task.defer(function()
		if character.Parent then
			restoreMovement(character, false)
			local root = character:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") then
				root.CFrame = Config.WALK_SPAWN_CFRAME
			end
		end
	end)
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
		upgrades = { tips = 0, assist = 0, reload = 0, power = 0 },
		cleanupEpoch = 0,
	}
	RecordRunService.addPlayer(player)

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
	if player.Character then
		initializeCharacter(player, player.Character)
	end
	task.delay(0.8, function()
		if player.Parent then
			sendState(player, "welcome", nil)
		end
	end)
end

function GameService.start()
	createRemotes()
	ShiftEventService.reset()
	launchRemote.OnServerEvent:Connect(onLaunch)
	purchaseRemote.OnServerEvent:Connect(onPurchase)
	modeRemote.OnServerEvent:Connect(function(player, requestedMode)
		if requestedMode == "walk" then
			setPlayerMode(player, "walk")
		end
	end)
	local world = Workspace:WaitForChild("PizzaLaunchWorld")
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
	WorldActivityService.start(world)
	updateDeliveryZones(0, false)
	RecordRunService.start(world, function(player, eventName)
		local state = states[player]
		if not state then
			return
		end
		local snapshot = RecordRunService.getSnapshot(player)
		if snapshot.targetId then
			state.targetId = snapshot.targetId
		end
		if eventName == "recordEnding" then
			PropService.resetAll()
			-- Timer completion releases the cannon immediately, including a pizza
			-- still in flight, while preserving the server-side result save.
			cleanupLauncherSession(player, "recordCompleted", { cancelRun = false, moveToExit = true, notifyClient = false })
		end
		sendState(player, eventName, nil)
	end)
	InteractionService.start(world, {
		launcher = function(player)
			setPlayerMode(player, "launcher")
		end,
		recordRun = function(player)
			local state = states[player]
			if not state or state.shotActive then
				return
			end
			setPlayerMode(player, "launcher")
			if state.mode ~= "launcher" or launcherOccupant ~= player then
				return
			end
			state.resumeTargetId = state.targetId
			PropService.resetAll()
			local started, reason = RecordRunService.begin(player)
			if started then
				updateDeliveryZones(0, true)
				local snapshot = RecordRunService.getSnapshot(player)
				state.targetId = snapshot.targetId or state.targetId
				sendState(player, "recordCountdown", nil)
			else
				sendState(player, "notice", { result = "RECORD RUN BUSY", detail = reason })
			end
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
		while world.Parent do
			task.wait(1)
			local expired = ShiftEventService.expire()
			if expired then
				endShiftEvent(expired, "Event time ended. No penalty - keep serving!")
			end
		end
	end)
	Players.PlayerAdded:Connect(addPlayer)
	Players.PlayerRemoving:Connect(function(player)
		cleanupLauncherSession(player, "playerLeaving", { cancelRun = false, moveToExit = false, notifyClient = false })
		RecordRunService.removePlayer(player)
		states[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		addPlayer(player)
	end
end

return GameService
