-- Pure profile validation, progress and atomic store transforms. No services,
-- network, yields, session coins, upgrade tuning or competitive mutations.
local ProfileModel = {}
ProfileModel.__index = ProfileModel

local function integer(value, maximum): boolean
	return type(value) == "number" and value == value and value >= 0 and value <= maximum and value % 1 == 0
end

local function serializable(value, depth, budget): boolean
	if type(value) == "number" then return value == value and math.abs(value) < math.huge end
	if type(value) == "string" then return #value <= 256 end
	if type(value) == "boolean" then return true end
	if type(value) ~= "table" or depth > 6 then return false end
	for key, item in value do
		budget.count += 1
		if budget.count > 512 or (type(key) ~= "string" and type(key) ~= "number")
			or (type(key) == "string" and #key > 128) or not serializable(item, depth + 1, budget) then return false end
	end
	return true
end

function ProfileModel.copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, item in value do result[key] = ProfileModel.copy(item) end
	return result
end

local function freeze(value)
	for _, item in value do if type(item) == "table" then freeze(item) end end
	return table.freeze(value)
end

local function flags(value, allowed): boolean
	if type(value) ~= "table" then return false end
	for key, item in value do
		if type(key) ~= "string" or #key > 64 or item ~= true or (allowed and not allowed[key]) then return false end
	end
	return true
end

function ProfileModel.emptyData(config)
	local mastery = {}
	for _, key in config.counters do mastery[key] = 0 end
	return { mastery = mastery, tableStamps = {}, customerStamps = {}, earnedCosmetics = { plain = true },
		equipped = "plain", tutorialCompleted = false,
		-- Reserved, preserved storage only. No purchase, receipt or fulfillment API.
		pendingFulfillment = {} }
end

function ProfileModel.validate(config, document): (boolean, string?)
	if type(document) ~= "table" then return false, "malformed" end
	if type(document.schemaVersion) == "number" and document.schemaVersion > config.schemaVersion then return false, "unsupported" end
	if document.schemaVersion ~= config.schemaVersion or not serializable(document, 0, { count = 0 })
		or not integer(document.revision, 9007199254740991) then return false, "malformed" end
	local data = document.data
	if type(data) ~= "table" or type(data.mastery) ~= "table" then return false, "malformed" end
	for _, key in config.counters do
		if not integer(data.mastery[key], config.maxCounter) then return false, "malformed" end
	end
	if not flags(data.tableStamps, { ["1"] = true, ["2"] = true, ["3"] = true, ["4"] = true, ["5"] = true, ["6"] = true })
		or not flags(data.customerStamps, config.customers) or not flags(data.earnedCosmetics)
		or type(data.equipped) ~= "string" or #data.equipped > 64 or not data.earnedCosmetics[data.equipped]
		or type(data.tutorialCompleted) ~= "boolean" or type(data.pendingFulfillment) ~= "table" then return false, "malformed" end
	local lease = document.lease
	if lease ~= nil and (type(lease) ~= "table" or type(lease.token) ~= "string" or #lease.token == 0 or #lease.token > 128
		or not integer(lease.expiresAt, 9007199254740991)) then return false, "malformed" end
	local release = document.lastRelease
	if release ~= nil and (type(release) ~= "table" or type(release.token) ~= "string" or #release.token > 128
		or not integer(release.revision, 9007199254740991)) then return false, "malformed" end
	return true, nil
end

local function unlock(config, data)
	data.earnedCosmetics.plain = true
	for id, cosmetic in config.cosmetics do
		if cosmetic.counter and data.mastery[cosmetic.counter] >= cosmetic.goal then data.earnedCosmetics[id] = true end
	end
end

local function mergeProgress(config, current, incoming, additive)
	local result = ProfileModel.copy(current)
	for _, key in config.counters do
		local prior, nextValue = current.mastery[key], incoming.mastery[key]
		result.mastery[key] = math.min(config.maxCounter, additive and key ~= "recordBest" and prior + nextValue or math.max(prior, nextValue))
	end
	for _, category in { "tableStamps", "customerStamps", "earnedCosmetics" } do
		for key in incoming[category] do result[category][key] = true end
	end
	result.tutorialCompleted = current.tutorialCompleted or incoming.tutorialCompleted
	unlock(config, result)
	return result
end

function ProfileModel.acquire(config, old, token: string, now: number)
	local document
	if old == nil then
		document = { schemaVersion = config.schemaVersion, revision = 0, createdAt = now, createdBy = token,
			data = ProfileModel.emptyData(config) }
	else
		local valid, reason = ProfileModel.validate(config, old)
		if not valid then return nil, reason end
		document = ProfileModel.copy(old)
	end
	if document.lease and document.lease.token ~= token and document.lease.expiresAt > now then return nil, "locked" end
	document.lease = { token = token, expiresAt = now + config.leaseSeconds }
	return document, nil
end

function ProfileModel.abandonAcquire(config, old, token: string)
	-- A detached load whose response is too late must not create/renew a lease.
	-- If an earlier lost response already acquired this token, release only its
	-- ownership while preserving every saved fact. Never touch a foreign owner.
	if not ProfileModel.validate(config, old) or not old.lease or old.lease.token ~= token then return nil end
	local document = ProfileModel.copy(old)
	document.lease = nil
	return document
end

function ProfileModel.save(config, old, request, now: number)
	local valid, reason = ProfileModel.validate(config, old)
	if not valid then return nil, reason end
	-- A failed response may hide a successful final release. Recognize that exact
	-- released revision without ever overwriting a later session's acquisition.
	if request.release and old.lease == nil and old.lastRelease
		and old.lastRelease.token == request.token and old.lastRelease.revision == request.revision then return ProfileModel.copy(old), nil end
	if not old.lease or old.lease.token ~= request.token or old.lease.expiresAt <= now then return nil, "leaseLost" end
	if old.revision > request.revision then return nil, "staleRevision" end
	local document = ProfileModel.copy(old)
	document.data = mergeProgress(config, old.data, request.data, false)
	if document.data.earnedCosmetics[request.data.equipped] then document.data.equipped = request.data.equipped end
	document.revision = request.revision
	if request.release then
		document.lease = nil
		document.lastRelease = { token = request.token, revision = request.revision }
	else
		document.lease = { token = request.token, expiresAt = now + config.leaseSeconds }
	end
	return document, nil
end

function ProfileModel.new(config)
	return setmetatable({ config = config, data = ProfileModel.emptyData(config), revision = 0, savedRevision = 0,
		loaded = false, sequences = { delivery = 0, takeout = 0, record = 0 } }, ProfileModel)
end

function ProfileModel:adopt(document): boolean
	if self.loaded then return false end
	assert(ProfileModel.validate(self.config, document))
	self.data = mergeProgress(self.config, document.data, self.data, true)
	self.savedRevision = document.revision
	self.revision += document.revision
	self.loaded = true
	return true
end

function ProfileModel:_sequence(domain, sequence): boolean
	if not integer(sequence, 9007199254740991) or sequence <= self.sequences[domain] then return false end
	self.sequences[domain] = sequence
	return true
end

function ProfileModel:_changed()
	self.revision += 1
	unlock(self.config, self.data)
end

function ProfileModel:delivery(receipt): boolean
	if type(receipt) ~= "table" or not integer(receipt.tableId, 6) or receipt.tableId < 1
		or (receipt.accuracy ~= "PERFECT!" and receipt.accuracy ~= "GREAT!" and receipt.accuracy ~= "DELIVERED!")
		or (receipt.customerName ~= nil and (type(receipt.customerName) ~= "string" or not self.config.customers[receipt.customerName]))
		or not self:_sequence("delivery", receipt.sequence) then return false end
	local counts = self.data.mastery
	counts.deliveries = math.min(self.config.maxCounter, counts.deliveries + 1)
	if receipt.accuracy == "PERFECT!" then counts.perfect = math.min(self.config.maxCounter, counts.perfect + 1) end
	if receipt.accuracy == "GREAT!" then counts.great = math.min(self.config.maxCounter, counts.great + 1) end
	if receipt.tableId >= 5 then counts.farDeliveries = math.min(self.config.maxCounter, counts.farDeliveries + 1) end
	self.data.tableStamps[tostring(receipt.tableId)] = true
	if receipt.customerName then self.data.customerStamps[receipt.customerName] = true end
	self:_changed()
	return true
end

function ProfileModel:takeout(receipt): boolean
	if type(receipt) ~= "table" or not self:_sequence("takeout", receipt.sequence) then return false end
	self.data.mastery.takeout = math.min(self.config.maxCounter, self.data.mastery.takeout + 1)
	self:_changed()
	return true
end

function ProfileModel:record(receipt): boolean
	if type(receipt) ~= "table" or not integer(receipt.score, self.config.maxCounter)
		or not self:_sequence("record", receipt.sequence) then return false end
	self.data.mastery.recordRuns = math.min(self.config.maxCounter, self.data.mastery.recordRuns + 1)
	self.data.mastery.recordBest = math.max(self.data.mastery.recordBest, receipt.score)
	self:_changed()
	return true
end

function ProfileModel:completeTutorial(): boolean
	if self.data.tutorialCompleted then return false end
	self.data.tutorialCompleted = true
	self:_changed()
	return true
end

function ProfileModel:equip(cosmeticId): boolean
	if type(cosmeticId) ~= "string" or not self.config.cosmetics[cosmeticId]
		or not self.data.earnedCosmetics[cosmeticId] or self.data.equipped == cosmeticId then return false end
	self.data.equipped = cosmeticId
	self:_changed()
	return true
end

function ProfileModel:request(token: string, release: boolean)
	assert(self.loaded, "Never write a profile that did not load")
	return freeze({ token = token, revision = self.revision, data = ProfileModel.copy(self.data), release = release })
end

function ProfileModel:acknowledge(request)
	self.savedRevision = math.max(self.savedRevision, request.revision)
end

function ProfileModel:snapshot()
	local data = self.data
	return { mastery = ProfileModel.copy(data.mastery), tableStamps = ProfileModel.copy(data.tableStamps),
		customerStamps = ProfileModel.copy(data.customerStamps), earnedCosmetics = ProfileModel.copy(data.earnedCosmetics),
		equipped = self.config.cosmetics[data.equipped] and data.equipped or "plain", tutorialCompleted = data.tutorialCompleted,
		dirty = self.revision > self.savedRevision }
end

return ProfileModel
