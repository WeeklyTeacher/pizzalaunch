-- Walking activities never infer or update authoritative launcher state.
local ActivityPresentation = {}

function ActivityPresentation.stationText(station, now: number): string
	if not station or not station.occupied then return "LAUNCHER AVAILABLE" end
	if station.launcherMode == "freePlay" then return "FREE PLAY • NO TIME LIMIT" end
	if station.launcherMode == "recordRun" then
		if station.recordStatus == "running" then
			local seconds = math.ceil(math.max(0, (station.endsAt or now) - now))
			return string.format("1-MINUTE RECORD RUN • %d:%02d • SCORE %d", math.floor(seconds / 60), seconds % 60, station.score or 0)
		elseif station.recordStatus == "countdown" then
			return "1-MINUTE RECORD RUN • STARTING"
		end
		return "1-MINUTE RECORD RUN • RESULTS"
	end
	return "CHOOSING A MODE"
end

function ActivityPresentation.select(snapshot, now: number, mounted: boolean, routeRequested: boolean)
	local runner, queue, station = snapshot.runner or {}, snapshot.queue or {}, snapshot.station or {}
	local reserved = queue.status == "reserved"
	local waiting = queue.status == "waiting"
	local carrying = runner.status == "carrying"
	local normalReward = runner.normalReward or 8
	local view = {
		visible = not mounted and (reserved or waiting or carrying or routeRequested),
		carrying = not mounted and carrying,
		standaloneCarry = not mounted and carrying and not waiting and not reserved,
		reserved = reserved,
		waiting = waiting,
		stationText = ActivityPresentation.stationText(station, now),
		chefText = station.occupied and (station.operatorName or "Another chef") or "Pizza Launcher",
		passTurn = mounted and (station.waitingCount or queue.waitingCount or 0) > 0,
		queueText = "",
		canLeaveLine = waiting or reserved,
		canDoTakeout = not carrying and not routeRequested and not reserved,
	}
	if reserved then
		local remaining = math.ceil(math.max(0, (queue.reservationEndsAt or now) - now))
		view.title = "YOUR TURN • USE THE LAUNCHER"
		view.detail = remaining > 0 and string.format("Approach the pizza pad and use its prompt.\nReserved for you: %ds", remaining)
			or "Approach the pizza pad. Checking the line..."
	elseif carrying then
		view.title = "DELIVER TO " .. (runner.destinationName or "YOUR DESTINATION")
		local bonusActive = (runner.quickBonusEndsAt or 0) > now
		view.compactDetail = bonusActive and string.format("%d COINS ON DELIVERY • QUICK BONUS +%d", normalReward, runner.quickBonus or 0)
			or string.format("%d COINS ON DELIVERY", normalReward)
		view.detail = bonusActive and string.format("%d COINS ON DELIVERY • QUICK BONUS +%d\nFollow the takeout marker.", normalReward, runner.quickBonus or 0)
			or string.format("%d COINS ON DELIVERY\nYour normal reward is still waiting.", normalReward)
	elseif routeRequested then
		view.title = "PICK UP A READY PIZZA BOX"
		view.detail = string.format("Follow the TAKEOUT marker.\nEarn %d coins for each delivery.", normalReward)
	elseif waiting then
		view.title = string.format("YOU'RE IN LINE #%d", queue.position or 1)
		view.detail = view.chefText .. "\n" .. view.stationText
	else
		view.title = "TAKEOUT RUNNER"
		view.detail = "Pick up a pizza box for a short neighborhood delivery."
	end
	if waiting and (carrying or routeRequested) then
		view.queueText = string.format("LINE #%d • %s", queue.position or 1, view.stationText)
	elseif reserved and carrying then
		view.queueText = "You can finish takeout or approach for your turn."
	end
	return view
end

return ActivityPresentation
