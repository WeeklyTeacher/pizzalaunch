-- FIFO approach reservations. This service never mounts or moves a character.
local LauncherQueue = {}
LauncherQueue.__index = LauncherQueue

function LauncherQueue.new(dependencies)
	return setmetatable({ dependencies = dependencies, waiting = {}, reservation = nil }, LauncherQueue)
end

function LauncherQueue:_eligible(entry): boolean
	return self.dependencies.isEligible(entry.player, entry.character)
end

function LauncherQueue:_notify(player, event, reason)
	if self.dependencies.notify then self.dependencies.notify(player, event, { reason = reason }) end
end

function LauncherQueue:step(): boolean
	local changed = false
	for index = #self.waiting, 1, -1 do
		local entry = self.waiting[index]
		if not self:_eligible(entry) then
			table.remove(self.waiting, index)
			self:_notify(entry.player, "queueLeft", "unavailable")
			changed = true
		end
	end
	local reserved = self.reservation
	if reserved and (not self:_eligible(reserved) or self.dependencies.now() >= reserved.endsAt) then
		self.reservation = nil
		self:_notify(reserved.player, "queueLeft", "reservationExpired")
		changed = true
	end
	if not self.dependencies.getOwner() and not self.reservation and #self.waiting > 0 then
		local entry = table.remove(self.waiting, 1)
		entry.endsAt = self.dependencies.now() + (self.dependencies.reservationSeconds or 15)
		self.reservation = entry
		self:_notify(entry.player, "queueReserved")
		changed = true
	end
	return changed
end

function LauncherQueue:join(player): (boolean, string?)
	self:step()
	if self.dependencies.getOwner() == player then return false, "operating" end
	if self.reservation and self.reservation.player == player then return true, "alreadyReserved" end
	for _, entry in self.waiting do if entry.player == player then return true, "alreadyWaiting" end end
	local entry = { player = player, character = player.Character }
	if not self:_eligible(entry) then return false, "unavailable" end
	table.insert(self.waiting, entry)
	self:step()
	return true, nil
end

function LauncherQueue:cancel(player, reason): boolean
	local removed = false
	if self.reservation and self.reservation.player == player then self.reservation = nil; removed = true end
	for index = #self.waiting, 1, -1 do
		if self.waiting[index].player == player then table.remove(self.waiting, index); removed = true end
	end
	if removed then self:_notify(player, "queueLeft", reason or "cancelled") end
	self:step()
	return removed
end

function LauncherQueue:canMount(player): boolean
	self:step()
	if self.dependencies.getOwner() then return false end
	return self.reservation == nil or self.reservation.player == player
end

function LauncherQueue:accepted(player): boolean
	-- Called only after GameService has acquired the distance/health-validated lease.
	if self.dependencies.getOwner() ~= player then return false end
	local reserved = self.reservation
	if reserved and reserved.player ~= player then return false end
	self.reservation = nil
	for index = #self.waiting, 1, -1 do
		if self.waiting[index].player == player then table.remove(self.waiting, index) end
	end
	if reserved then self:_notify(player, "queueAccepted") end
	return true
end

function LauncherQueue:snapshot(player)
	local result = { status = "none", waitingCount = #self.waiting + (self.reservation and 1 or 0) }
	if self.reservation and self.reservation.player == player then
		result.status, result.position, result.reservationEndsAt = "reserved", 1, self.reservation.endsAt
	else
		for index, entry in self.waiting do
			if entry.player == player then
				result.status, result.position = "waiting", index + (self.reservation and 1 or 0)
				break
			end
		end
	end
	return result
end

return LauncherQueue
