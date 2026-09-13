-- Resolves one authenticated shot and sequences its score, customer feedback,
-- round transition and visual cleanup. Launcher lease/input/physics and durable
-- profiles stay with their existing owners; all cross-domain hooks are explicit.
local DeliveryService = {}

function DeliveryService.new(context)
	local Config = context.config
	local getState, now, delay = context.getState, context.now, context.delay or task.delay
	local launcherLease = context.lease
	local RecordRunService, ProjectileService = context.recordRun, context.projectiles
	local CustomerService, ShiftEventService = context.customers, context.shiftEvents
	local DeliveryScoring, LayoutService, PropService = context.scoring, context.layout, context.props
	local tableDefinition, roundDefinition, nextTarget = context.tableDefinition, context.roundDefinition, context.nextTarget
	local customerReaction, reactionText, worldTable = context.customerReaction, context.reactionText, context.worldTable
	local playSound, confettiBurst, SOUND = context.playSound, context.confettiBurst, context.sounds
	local beginShiftEvent, endShiftEvent = context.beginShiftEvent, context.endShiftEvent
	local setLeaderstats, sendState = context.setLeaderstats, context.sendState

	local function resolve(player: Player, pizza: BasePart, result: string, hitPosition: Vector3?, tableId: number?)
		local state = getState(player)
		if not state or pizza:GetAttribute("Resolved") or not launcherLease:isValid(player) or not RecordRunService.canLaunch(player)
			or not ProjectileService.resolve(player, pizza, state.cleanupEpoch) then
			return false
		end
		pizza:SetAttribute("Resolved", true)
		state.shotActive = false
		local recordSession = RecordRunService.isSession(player)
		local effectiveReload = recordSession and Config.RELOAD_TIME or Config.RELOAD_TIME * (1 - state.upgrades.reload * 0.12)
		local payload = {
			result = result,
			position = hitPosition,
			tableId = tableId,
			coinsEarned = 0,
			comboBonus = 0,
			reloadDelay = math.max(0.05, state.lastLaunch + effectiveReload - now()),
			recordRun = recordSession,
		}
		local eligibleTables = ShiftEventService.extendTablePool(roundDefinition(state.round).tables)
		local tableEligible = tableId ~= nil and (recordSession or table.find(eligibleTables, tableId) ~= nil)
		local acceptedDelivery = result == "delivery" and tableEligible and hitPosition ~= nil and CustomerService.claimDelivery(tableId)
		local shiftOutcome = nil

		if acceptedDelivery and tableId and hitPosition then
			local definition = tableDefinition(tableId)
			local round = roundDefinition(state.round)
			local accuracy, distance = DeliveryScoring.accuracy(Config, definition.position, hitPosition, state, recordSession)
			payload.result = accuracy.name
			payload.color = accuracy.color
			payload.accuracy = distance
			local scoredDelivery = not recordSession

			if recordSession then
				local recordResult = RecordRunService.recordSuccess(player, tableId, accuracy.name)
				if recordResult then
					scoredDelivery = true
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
				local deliveryReward, comboBonus, unmultipliedReward = DeliveryScoring.freePlayReward(accuracy, state.combo, state.upgrades.tips)
				local serviceTime = now() - (state.targetSetAt or now())
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
				context.contributeShared(player)
			end
			if scoredDelivery then
				local customer = CustomerService.getInfo(tableId)
				context.recordDelivery(player, state, tableId, accuracy.name, customer and customer.name or nil, recordSession)
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
			local completedEpoch = state.cleanupEpoch
			delay(0.62, function()
				if not pizza.Parent or getState(player) ~= state or state.cleanupEpoch ~= completedEpoch or launcherLease.owner ~= player then
					return
				end
				local tableModel = worldTable(tableId)
				local customer = tableModel and tableModel:FindFirstChild("Customer")
				if customer and customer:IsA("Model") then
					reactionText(customer, "NOM NOM NOM!\nDELICIOUS!")
				end
				ProjectileService.consumeVisual(pizza)
			end)

			if not recordSession then
				if state.roundProgress >= round.goal then
					state.coins += round.reward
					payload.roundComplete = true
					payload.roundReward = round.reward
					payload.completedRound = state.round
					payload.completedRoundName = round.name
					if state.round == 1 then context.roundOneCompleted(player) end
					state.roundProgress = 0
					if state.round < #Config.ROUNDS then
						state.round += 1
					end
					LayoutService.setRound(state.round)
					PropService.resetAll()
				end
				state.targetId = nextTarget(state.targetId, state.round)
				state.targetSetAt = now()
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
		delay(1.45, function()
			ProjectileService.removeVisual(player, pizza)
		end)
		return true
	end

	return table.freeze({ resolve = resolve })
end

return DeliveryService
