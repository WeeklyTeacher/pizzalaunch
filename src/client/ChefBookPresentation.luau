local Presentation = {}

function Presentation.status(snapshot)
	local status = snapshot.status or "loading"
	if status == "memory" then return "LOCAL TEST • Not saved outside this test server." end
	if status == "ready" then
		if snapshot.durable ~= true or snapshot.persistenceAvailable ~= true then return "BOOK CONNECTION PENDING • Latest progress may not be saved." end
		if snapshot.dirty then return "SAVE PENDING • Latest progress is waiting to save." end
		return snapshot.isNew == true and "NEW CHEF BOOK • Progress saved." or "CHEF BOOK SAVED"
	end
	if status == "saveFailed" then return "SAVE DELAYED • Retrying. Latest progress is not confirmed saved." end
	if status == "loading" then return "LOADING CHEF BOOK • Saved totals are not available yet." end
	if status == "locked" then return "BOOK IN USE • Retrying. Saved totals are not available yet." end
	if status == "loadFailed" then return "LOAD FAILED • Retrying. Showing only this visit's progress." end
	if status == "leaseLost" then return "BOOK CONNECTION LOST • Latest progress may not be saved." end
	if status == "unsupported" then return "NEWER BOOK VERSION • Your saved data was kept." end
	if status == "malformed" then return "BOOK UNAVAILABLE • Your saved data was kept." end
	return "CHEF BOOK UNAVAILABLE • Normal play is still available."
end

function Presentation.canEquip(snapshot, id)
	local status = snapshot.status
	return (status == "ready" or status == "memory") and snapshot.persistenceAvailable == true
		and (status == "memory" or snapshot.durable == true)
		and snapshot.earnedCosmetics ~= nil and snapshot.earnedCosmetics[id] == true
end

function Presentation.goal(snapshot, definition)
	local current = snapshot.mastery and snapshot.mastery[definition.counter] or 0
	return string.format("%d / %d%s", math.min(current, definition.goal), definition.goal, current >= definition.goal and " • COMPLETE" or ""), current >= definition.goal
end

function Presentation.cosmetic(snapshot, id, definition)
	local earned = snapshot.earnedCosmetics and snapshot.earnedCosmetics[id] == true
	if not earned then return definition.requirement, "LOCKED", false end
	if snapshot.equipped == id then return "Earned nameplate", "EQUIPPED", false end
	if not Presentation.canEquip(snapshot, id) then return "Earned • waiting for your book", "WAITING", false end
	return "Earned nameplate", "EQUIP", true
end

return Presentation
