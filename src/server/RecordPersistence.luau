-- Pure state for the historical max-score store. No Roblox services or yields.
-- A confirmed remote best, this session's best, and work awaiting confirmation
-- are deliberately separate; an outage never manufactures a default write.
local RecordPersistence = {}
RecordPersistence.__index = RecordPersistence

local function validScore(value): boolean
	return type(value) == "number" and value == value and value >= 0 and value < math.huge and value % 1 == 0
end

function RecordPersistence.new(userId: number)
	return setmetatable({
		userId = userId,
		sessionBest = 0,
		savedBest = nil,
		pending = nil,
		inFlight = nil,
		loadStatus = "loading",
		saveStatus = "idle",
		failedWrites = 0,
	}, RecordPersistence)
end

function RecordPersistence:best(): number
	return math.max(self.sessionBest, self.savedBest or 0)
end

function RecordPersistence:loaded(success: boolean, value): boolean
	if not success then
		-- A stale failed read cannot invalidate an already confirmed write.
		if self.savedBest == nil then self.loadStatus = "failed" end
		return false
	end
	if value ~= nil and not validScore(value) then
		self.loadStatus = "invalid"
		return false
	end
	self.loadStatus = "loaded"
	self.savedBest = math.max(self.savedBest or 0, value or 0)
	if self.pending and self.pending.score <= self.savedBest then
		self.pending = nil
		if not self.inFlight then
			self.saveStatus = "saved"
			self.failedWrites = 0
		end
	end
	return true
end

function RecordPersistence:complete(score: number, runId: string, startedAt: number, completedAt: number)
	assert(validScore(score), "Completed score must be a nonnegative integer")
	assert(type(runId) == "string" and #runId > 0, "Completed run needs an identifier")
	local previousBest = self:best()
	local submission = table.freeze({
		userId = self.userId,
		score = score,
		runId = runId,
		startedAt = startedAt,
		completedAt = completedAt,
	})
	self.sessionBest = math.max(self.sessionBest, score)
	-- Numeric max writes are commutative: the largest pending submission safely
	-- subsumes lower scores, including retries after another run has started.
	if score > 0 and score > (self.savedBest or 0) and (not self.pending or score > self.pending.score) then
		self.pending = submission
	end
	return submission, score > previousBest
end

function RecordPersistence:beginWrite()
	if self.inFlight or not self.pending then return nil end
	self.inFlight = self.pending
	self.saveStatus = "saving"
	return self.inFlight
end

function RecordPersistence.transform(submission, oldValue)
	-- Returning nil cancels UpdateAsync if historical data is malformed. Never
	-- coerce an unknown value into zero and overwrite it.
	if oldValue ~= nil and not validScore(oldValue) then return nil end
	return math.max(oldValue or 0, submission.score)
end

function RecordPersistence:resolve(submission, success: boolean, storedValue): boolean
	if self.inFlight ~= submission then return false end
	self.inFlight = nil
	if not success or not validScore(storedValue) or storedValue < submission.score then
		-- A concurrent successful load may already confirm this score (or a
		-- larger one) even when this particular request failed.
		if self.savedBest and self.savedBest >= submission.score then
			self.saveStatus = "saved"
			self.failedWrites = 0
			return true
		end
		self.saveStatus = "failed"
		self.failedWrites += 1
		return false
	end
	self.savedBest = math.max(self.savedBest or 0, storedValue)
	self.loadStatus = "loaded"
	self.saveStatus = "saved"
	self.failedWrites = 0
	if self.pending and self.pending.score <= self.savedBest then
		self.pending = nil
	end
	return true
end

function RecordPersistence:available(): boolean
	return self.loadStatus ~= "failed" and self.loadStatus ~= "invalid" and self.saveStatus ~= "failed"
end

return RecordPersistence
