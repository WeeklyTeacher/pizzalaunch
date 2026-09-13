-- Presentation/input state only. Readiness always follows the server snapshot;
-- a sent request is pending, never evidence that a shot was accepted.
local LauncherInputState = {}
LauncherInputState.__index = LauncherInputState

function LauncherInputState.new(defaultPitch: number, chargeTime: number)
	local self = setmetatable({ defaultPitch = defaultPitch, chargeTime = chargeTime, nextRequestId = 0 }, LauncherInputState)
	self.epoch = -1
	self.mode = "none"
	self.playable = false
	self.aimable = false
	self.blocked = false
	self:reset()
	return self
end

function LauncherInputState:cancelCharge()
	self.charging = false
	self.activeFireInput = nil
	self.keyboardHeld = {}
	self.touchHeld = {}
	self.touchOwners = {}
	self.gamepadAim = Vector2.zero
end

function LauncherInputState:reset()
	self:cancelCharge()
	self.pendingRequestId = nil
	self.shotActive = false
	self.reloadReadyAt = 0
	self.charge = 0.34
	self.aimYaw = 0
	self.aimPitch = self.defaultPitch
end

function LauncherInputState:receive(snapshot, now: number)
	local epoch = snapshot.cleanupEpoch or 0
	local mode = snapshot.launcherMode or "none"
	local changed = epoch ~= self.epoch or mode ~= self.mode
	if changed then self:reset() end
	self.epoch = epoch
	self.mode = mode
	local status = snapshot.recordRun and snapshot.recordRun.status or "idle"
	self.playable = snapshot.mode == "launcher" and (mode == "freePlay" or (mode == "recordRun" and status == "running"))
	self.aimable = snapshot.mode == "launcher" and (mode == "freePlay" or (mode == "recordRun" and (status == "countdown" or status == "running")))
	if not self.playable then self:cancelCharge() end
	self.shotActive = snapshot.shotActive == true
	local payload = snapshot.payload
	local resultDelay = snapshot.event == "shotResult" and payload and payload.reloadDelay or 0
	self.reloadReadyAt = now + math.max(0, snapshot.reloadDelay or 0, resultDelay)
	if (snapshot.event == "launched" or snapshot.event == "launchRejected") and payload
		and payload.requestEpoch == self.epoch and payload.requestId == self.pendingRequestId then
		self.pendingRequestId = nil
	end
	return changed
end

function LauncherInputState:setBlocked(blocked: boolean)
	self.blocked = blocked
	if blocked then self:cancelCharge() end
end

function LauncherInputState:isReady(now: number): boolean
	return self.playable and not self.blocked and self.pendingRequestId == nil and not self.shotActive and now >= self.reloadReadyAt
end

function LauncherInputState:begin(input, now: number): boolean
	if not self:isReady(now) or self.charging then return false end
	self.charging = true
	self.activeFireInput = input
	self.chargeStarted = now
	self.charge = 0
	return true
end

function LauncherInputState:release(input, now: number)
	if not self.charging or input ~= self.activeFireInput then return nil end
	self.charging = false
	self.activeFireInput = nil
	if not self:isReady(now) then return nil end
	self.charge = math.clamp((now - self.chargeStarted) / self.chargeTime, 0, 1)
	self.nextRequestId += 1
	self.pendingRequestId = self.nextRequestId
	return { requestId = self.nextRequestId, cleanupEpoch = self.epoch, charge = self.charge }
end

function LauncherInputState:setTouch(direction: string, input, held: boolean)
	if held then
		if not self.aimable or self.blocked then return end
		self.touchOwners[input] = direction
	else
		self.touchOwners[input] = nil
	end
	self.touchHeld = {}
	for _, value in self.touchOwners do self.touchHeld[value] = true end
end

function LauncherInputState:step(deltaTime: number, now: number)
	if not self.aimable or self.blocked then return end
	local horizontal = ((self.keyboardHeld.right or self.touchHeld.right) and 1 or 0) - ((self.keyboardHeld.left or self.touchHeld.left) and 1 or 0) + self.gamepadAim.X
	local vertical = ((self.keyboardHeld.up or self.touchHeld.up) and 1 or 0) - ((self.keyboardHeld.down or self.touchHeld.down) and 1 or 0) + self.gamepadAim.Y
	self.aimYaw = math.clamp(self.aimYaw + horizontal * deltaTime * 0.72, -1, 1)
	self.aimPitch = math.clamp(self.aimPitch + vertical * deltaTime * 0.72, 0, 1)
	if self.charging then self.charge = math.clamp((now - self.chargeStarted) / self.chargeTime, 0, 1) end
end

return LauncherInputState
