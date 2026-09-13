local ProfileModel = require(script.Parent.ProfileModel)
local MasteryConfig = require(game:GetService("ReplicatedStorage").Shared.MasteryConfig)

local ProfileService = {}
ProfileService.__index = ProfileService

function ProfileService.new(dependencies)
	local deps = dependencies or {}
	local self = setmetatable({}, ProfileService)
	self.config = MasteryConfig
	self.now = deps.now or os.time
	self.clock = deps.clock or os.clock
	self.spawn = deps.spawn or task.spawn
	self.wait = deps.wait or task.wait
	self.random = deps.random or math.random
	self.token = deps.token or function() return game:GetService("HttpService"):GenerateGUID(false) end
	self.onChanged, self.onEvent = deps.onChanged, deps.onEvent
	self.storeProvider = deps.storeProvider or function()
		return game:GetService("DataStoreService"):GetDataStore(self.config.storeName)
	end
	-- This decision cannot be overridden by callers. Test Studio never reaches
	-- the real store even when API access has been enabled outside this code.
	self.memoryOnly = game:GetService("RunService"):IsStudio() or game.PlaceId <= 0
	self.players, self.sessions, self.busyUsers, self.memoryData = {}, {}, {}, {}
	self.started, self.closing = false, false
	return self
end

function ProfileService:_store()
	if self.store then return self.store end
	if self.memoryOnly then
		local values = self.memoryData
		self.store = { UpdateAsync = function(_, key, transform)
			local value = transform(ProfileModel.copy(values[key]))
			if value ~= nil then values[key] = ProfileModel.copy(value) end
			return ProfileModel.copy(value)
		end }
	else
		self.store = self.storeProvider()
	end
	return self.store
end

function ProfileService:_event(record, name, reason)
	if self.onEvent and record.player then
		local ok, err = pcall(self.onEvent, record.player, name, reason)
		if not ok then warn("[PizzaLaunch][Profile] Event observer failed: " .. tostring(err)) end
	end
end

function ProfileService:snapshot(player)
	local record = self.players[player]
	if not record then return { status = "unavailable", durable = false, dirty = false } end
	local snapshot = record.model:snapshot()
	snapshot.status = record.phase == "ready" and (record.saveError and "saveFailed" or (self.memoryOnly and "memory" or "ready")) or record.phase
	snapshot.isNew = record.isNew
	local leaseConfirmed = record.model.loaded and self.now() < record.leaseExpiresAt
	snapshot.durable = not self.memoryOnly and leaseConfirmed and record.phase == "ready"
	snapshot.persistenceAvailable = record.phase == "ready" and leaseConfirmed and record.saveError == nil
	return snapshot
end

function ProfileService:_notify(record)
	if self.onChanged and record.player then
		local ok, err = pcall(self.onChanged, record.player, self:snapshot(record.player))
		if not ok then warn("[PizzaLaunch][Profile] Snapshot observer failed: " .. tostring(err)) end
	end
end

function ProfileService:_dispose(record)
	if record.player and self.players[record.player] == record then self.players[record.player] = nil end
	record.player = nil
	record.phase = "closed"
	self.sessions[record.token] = nil
end

function ProfileService:_failure(record, operation, reason)
	record.failures += 1
	local terminal = reason == "malformed" or reason == "unsupported" or reason == "leaseLost" or reason == "staleRevision"
	if operation == "load" or terminal then record.phase = reason == "staleRevision" and "leaseLost" or reason end
	if operation == "save" then record.saveError = reason end
	local delay = math.min(60, 2 ^ math.min(record.failures, 5)) * (0.8 + self.random() * 0.4)
	record.nextAttempt = self.clock() + (record.detached and math.min(2, delay) or delay)
	self:_event(record, operation == "load" and "ProfileLoadFailure" or "ProfileSaveFailure", reason)
	self:_notify(record)
end

function ProfileService:_work(record)
	if self.sessions[record.token] ~= record or self.busyUsers[record.userId] then return end
	if record.phase == "leaseLost" or record.phase == "malformed" or record.phase == "unsupported" then
		if record.detached then self:_dispose(record) end
		return
	end
	if record.detached and self.clock() >= record.closeDeadline then self:_dispose(record); return end
	local operation = record.model.loaded and "save" or "load"
	self.busyUsers[record.userId] = true
	local request
	if operation == "save" then
		request = record.request or record.model:request(record.token, record.detached)
		record.request = request
	else
		record.attemptedAcquire = true
	end
	local rejectedReason
	local success, result = pcall(function()
		return self:_store():UpdateAsync("u_" .. tostring(record.userId), function(old, keyInfo)
			-- A backend may rerun the callback after contention. Read time on every
			-- invocation; an expired owner cannot renew using a stale request time.
			local document, reason
			if operation == "load" then
				if record.detached and self.clock() >= record.closeDeadline then
					document, reason = ProfileModel.abandonAcquire(self.config, old, record.token), "closed"
				else
					document, reason = ProfileModel.acquire(self.config, old, record.token, self.now())
				end
			else
				document, reason = ProfileModel.save(self.config, old, request, self.now())
			end
			rejectedReason = reason
			return document, keyInfo and keyInfo:GetUserIds() or nil, keyInfo and keyInfo:GetMetadata() or nil
		end)
	end)
	self.busyUsers[record.userId] = nil
	if self.sessions[record.token] ~= record then return end
	if rejectedReason == "closed" then self:_dispose(record); return end
	if not success or result == nil then
		self:_failure(record, operation, success and (rejectedReason or (operation == "load" and "loadFailed" or "saveFailed"))
			or (operation == "load" and "loadFailed" or "saveFailed"))
		return
	end
	local valid, invalidReason = ProfileModel.validate(self.config, result)
	if not valid then self:_failure(record, operation, invalidReason); return end
	if operation == "save" and request.release then
		record.model:acknowledge(request)
		self:_dispose(record)
		return
	end
	if not result.lease or result.lease.token ~= record.token or result.lease.expiresAt <= self.now() then
		self:_failure(record, operation, "leaseLost")
		return
	end
	record.leaseExpiresAt = result.lease.expiresAt
	if operation == "load" then
		record.model:adopt(result)
		record.isNew = not self.memoryOnly and result.createdBy == record.token or nil
		if not self.memoryOnly and result.createdBy ~= record.token then record.isNew = false end
		self:_event(record, "ProfileLoaded", self.memoryOnly and "memory" or (record.isNew and "new" or "existing"))
	else
		record.model:acknowledge(request)
	end
	record.phase, record.request, record.saveError, record.failures = "ready", nil, nil, 0
	local dirty = record.model.revision > record.model.savedRevision
	local interval = self.config.autosaveSeconds * (0.85 + self.random() * 0.3)
	record.nextAttempt = self.clock() + (record.detached and 0 or (operation == "save" and dirty and 1 or interval))
	self:_notify(record)
	if record.detached then self.spawn(function() self:_work(record) end) end
end

function ProfileService:start()
	if self.started then return end
	self.started = true
	game:BindToClose(function() self:shutdown() end)
	self.spawn(function()
		while not self.closing do
			self.wait(1)
			self:step()
		end
	end)
end

function ProfileService:step()
	for _, record in self.sessions do
		if self.clock() >= record.nextAttempt then self.spawn(function() self:_work(record) end) end
	end
end

function ProfileService:addPlayer(player)
	if self.closing then return false end
	if self.players[player] then return true end
	local token = self.token()
	assert(type(token) == "string" and #token > 0 and #token <= 128 and not self.sessions[token], "Profile session token must be unique")
	local record = { player = player, userId = player.UserId, token = token, model = ProfileModel.new(self.config),
		phase = "loading", nextAttempt = 0, failures = 0, detached = false, leaseExpiresAt = 0 }
	self.players[player], self.sessions[token] = record, record
	self:_notify(record)
	self.spawn(function() self:_work(record) end)
	return true
end

function ProfileService:_mutate(player, method, value)
	local record = self.players[player]
	if not record or record.detached or self.closing then return false end
	if record.model.loaded and record.phase == "ready" and self.now() >= record.leaseExpiresAt then
		-- A lost successful renewal response may leave the backend lease newer
		-- than our local deadline. Only the atomic transform can fence ownership.
		record.saveError = "saveFailed"
		record.nextAttempt = math.min(record.nextAttempt, self.clock())
		if method == "equip" then return false end
	end
	-- These server-only receipts may continue to describe this session during an
	-- outage; saving stays gated on successful load and current lease ownership.
	local changed = record.model[method](record.model, value)
	if changed then self:_notify(record) end
	return changed
end

function ProfileService:recordDelivery(player, receipt) return self:_mutate(player, "delivery", receipt) end
function ProfileService:recordTakeout(player, receipt) return self:_mutate(player, "takeout", receipt) end
function ProfileService:recordCompletedRun(player, receipt) return self:_mutate(player, "record", receipt) end
function ProfileService:completeTutorial(player) return self:_mutate(player, "completeTutorial") end

function ProfileService:equip(player, cosmeticId)
	local record = self.players[player]
	if not record or not record.model.loaded or record.phase ~= "ready" then return false end
	return self:_mutate(player, "equip", cosmeticId)
end

function ProfileService:removePlayer(player)
	local record = self.players[player]
	if not record then return end
	self.players[player] = nil
	record.player, record.detached = nil, true
	record.closeDeadline, record.nextAttempt = self.clock() + 25, 0
	if not record.attemptedAcquire then self:_dispose(record); return end
	self.spawn(function() self:_work(record) end)
end

function ProfileService:shutdown()
	if self.closing then return end
	self.closing = true
	local deadline = self.clock() + 25
	for _, record in self.sessions do
		record.detached, record.closeDeadline, record.nextAttempt = true, deadline, 0
	end
	while next(self.sessions) and self.clock() < deadline do
		self:step()
		self.wait(0.1)
	end
end

return ProfileService
