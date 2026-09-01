local Workspace = game:GetService("Workspace")

local ShiftEventService = {}

local EVENT_ORDER = { "DinnerRush", "BirthdayTable", "FoodCritic" }
local activeEvent = nil
local successfulDeliveries = 0
local nextEventAt = 3
local eventIndex = 0

local function copyEvent()
	if not activeEvent then
		return nil
	end
	local snapshot = table.clone(activeEvent)
	snapshot.timeRemaining = math.max(0, activeEvent.endsAt - Workspace:GetServerTimeNow())
	return snapshot
end

function ShiftEventService.reset()
	activeEvent = nil
	successfulDeliveries = 0
	nextEventAt = 3
	eventIndex = 0
end

function ShiftEventService.getSnapshot()
	return copyEvent()
end

function ShiftEventService.expire()
	if activeEvent and Workspace:GetServerTimeNow() >= activeEvent.endsAt then
		local ended = activeEvent
		activeEvent = nil
		return ended
	end
	return nil
end

function ShiftEventService.extendTablePool(roundTables: { number }): { number }
	local result = table.clone(roundTables)
	if activeEvent then
		local extra = activeEvent.extraTableId or activeEvent.specialTableId
		if extra and not table.find(result, extra) then
			table.insert(result, extra)
		end
	end
	return result
end

function ShiftEventService.recordDelivery(tableId: number, accuracyName: string, serviceTime: number)
	successfulDeliveries += 1
	local outcome = { bonus = 0 }
	if not activeEvent then
		return outcome
	end

	if activeEvent.kind == "DinnerRush" then
		activeEvent.remaining -= 1
		if serviceTime <= 10 then
			outcome.bonus = 4
			outcome.fastService = true
			outcome.message = "FAST SERVICE  +4 COINS"
		end
		if activeEvent.remaining <= 0 then
			outcome.ended = activeEvent
			activeEvent = nil
		end
	elseif activeEvent.kind == "BirthdayTable" and tableId == activeEvent.specialTableId then
		outcome.bonus = 24
		outcome.confetti = true
		outcome.message = "BIRTHDAY DELIVERY  +24 COINS"
		outcome.ended = activeEvent
		activeEvent = nil
	elseif activeEvent.kind == "FoodCritic" and tableId == activeEvent.specialTableId then
		if accuracyName == "PERFECT!" then
			outcome.bonus = 32
			outcome.message = "CRITIC'S PERFECT SCORE  +32 COINS"
		elseif accuracyName == "GREAT!" then
			outcome.bonus = 20
			outcome.message = "CRITIC APPROVED  +20 COINS"
		else
			outcome.message = "GOOD DELIVERY  -  CRITIC BONUS MISSED"
		end
		outcome.ended = activeEvent
		activeEvent = nil
	end
	return outcome
end

function ShiftEventService.recordMiss()
	if activeEvent and activeEvent.kind == "FoodCritic" then
		local ended = activeEvent
		activeEvent = nil
		return {
			comboSaved = true,
			ended = ended,
			message = "CRITIC BONUS MISSED  -  COMBO SAVED",
		}
	end
	return nil
end

function ShiftEventService.maybeStart(roundTables: { number }, preferredTableId: number?)
	if activeEvent or successfulDeliveries < nextEventAt then
		return nil
	end
	eventIndex += 1
	nextEventAt += 4
	local kind = EVENT_ORDER[(eventIndex - 1) % #EVENT_ORDER + 1]
	local now = Workspace:GetServerTimeNow()

	if kind == "DinnerRush" then
		local extraTableId = nil
		for tableId = 1, 6 do
			if not table.find(roundTables, tableId) then
				extraTableId = tableId
				break
			end
		end
		activeEvent = {
			kind = kind,
			title = "DINNER RUSH",
			icon = ">>",
			description = "Serve 3 orders quickly for +4 coins each.",
			extraTableId = extraTableId,
			remaining = 3,
			endsAt = now + 40,
		}
	elseif kind == "BirthdayTable" then
		local specialTableId = preferredTableId and preferredTableId >= 3 and preferredTableId or nil
		for _, tableId in roundTables do
			if tableId >= 3 then
				specialTableId = tableId
				break
			end
		end
		specialTableId = specialTableId or 3
		activeEvent = {
			kind = kind,
			title = "BIRTHDAY TABLE",
			icon = "B-DAY",
			description = "Land the birthday pizza for a +24 coin celebration.",
			specialTableId = specialTableId,
			endsAt = now + 38,
		}
	else
		local specialTableId = preferredTableId or roundTables[math.random(1, #roundTables)]
		activeEvent = {
			kind = kind,
			title = "FOOD CRITIC",
			icon = "STAR",
			description = "A clean landing earns up to +32 coins.",
			specialTableId = specialTableId,
			endsAt = now + 38,
		}
	end
	return copyEvent()
end

return ShiftEventService
