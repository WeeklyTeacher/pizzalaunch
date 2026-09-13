local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local RecordPersistence = require(script.Parent.RecordPersistence)

local RecordRunService = {}

local orderedStore
local nextStoreRetryAt = 0
local persistenceSessions = {}
local closing = false
local runs = {}
local notifyChanged
local legendsLabel: TextLabel?
local nameCache = {}
local refreshBusy = false
local lastBoardRefreshAt = 0
local lastBoardEntries = nil
local setBoardText: (string) -> ()

local SAMPLE_BOARD = {
	{ name = "Chef Pepper", score = 1280 },
	{ name = "Mia's Dad", score = 1040 },
	{ name = "Pizza Pal", score = 860 },
	{ name = "Oven Ace", score = 720 },
	{ name = "You?", score = 600 },
}

local function warnStore(operation: string, err: any)
	warn(string.format("[PizzaLaunch][RecordRun] %s failed: %s", operation, tostring(err)))
end

local function studioFallbackMessage(): string
	return "GLOBAL RECORDS ARE UNAVAILABLE IN THIS TEST SESSION.\nYOUR BEST STILL COUNTS UNTIL YOU LEAVE."
end

local function setSampleBoard(message: string)
	local lines = { "PIZZA LAUNCH LEGENDS", "STUDIO SAMPLE BOARD", "", message, "" }
	for rank, entry in SAMPLE_BOARD do
		table.insert(lines, string.format("%2d.  %-18s  %d", rank, entry.name, entry.score))
	end
	setBoardText(table.concat(lines, "\n"))
end

local function retryStore(operation: string, callback): (boolean, any)
	local lastError
	for attempt = 1, 3 do
		local success, value = pcall(callback)
		if success then
			return true, value
		end
		lastError = value
		warnStore(string.format("%s (attempt %d/3)", operation, attempt), value)
		if attempt < 3 then
			task.wait(attempt * 0.35)
		end
	end
	return false, lastError
end

local function getOrderedStore()
	if not orderedStore and os.clock() >= nextStoreRetryAt then
		nextStoreRetryAt = os.clock() + 15
		local success, store = pcall(function()
			return DataStoreService:GetOrderedDataStore(Config.RECORD_RUN_STORE)
		end)
		if success then
			orderedStore = store
		else
			warnStore("GetOrderedDataStore", store)
		end
	end
	return orderedStore
end

local function now(): number
	return Workspace:GetServerTimeNow()
end

local function notify(player: Player, eventName: string)
	if notifyChanged and player.Parent then
		notifyChanged(player, eventName)
	end
end

local function persistenceMessage(model): string
	if model.saveStatus == "failed" then
		return "Your session best is safe here. Saving will retry automatically."
	elseif model.loadStatus == "failed" or model.loadStatus == "invalid" then
		return RunService:IsStudio() and studioFallbackMessage() or "Personal best is reconnecting. Your session best still counts."
	end
	return ""
end

local function releaseSavedSession(session)
	if not session.player and not session.model.pending and not session.model.inFlight
		and persistenceSessions[session.model.userId] == session then
		persistenceSessions[session.model.userId] = nil
	end
end

local function savePending(session, attempts: number): boolean
	local model = session.model
	local submission = model:beginWrite()
	if not submission then return model.pending == nil and model.inFlight == nil end
	local success, value = false, nil
	for attempt = 1, attempts do
		local store = getOrderedStore()
		if store then
			success, value = pcall(function()
				return store:UpdateAsync(string.format("u_%d", submission.userId), function(oldValue)
					return RecordPersistence.transform(submission, oldValue)
				end)
			end)
		else
			success, value = false, "Store unavailable"
		end
		-- A cancelled transform returns nil: this is not a confirmed saved best.
		if success and typeof(value) == "number" then break end
		warnStore(string.format("UpdateAsync completed Record Run (attempt %d/%d)", attempt, attempts), value)
		if attempt < attempts then task.wait(attempt * 0.35) end
	end
	local saved = model:resolve(submission, success, value)
	session.nextRetryAt = now() + (saved and 0 or math.min(60, 5 * 2 ^ math.min(model.failedWrites, 4)))
	if session.player then notify(session.player, "recordBestLoaded") end
	releaseSavedSession(session)
	return saved
end

local function loadPersonalBest(session)
	if session.loadBusy then return end
	session.loadBusy = true
	local store = getOrderedStore()
	local success, value = false, nil
	if store then
		success, value = retryStore("GetAsync personal best", function()
			return store:GetAsync(string.format("u_%d", session.model.userId))
		end)
	end
	session.model:loaded(success, value)
	session.loadBusy = false
	session.nextLoadAt = now() + 60
	if session.player then notify(session.player, "recordBestLoaded") end
	releaseSavedSession(session)
end

setBoardText = function(text: string)
	if legendsLabel and legendsLabel.Parent then
		legendsLabel.Text = text
	end
end

local function resolveName(key: string): string
	if nameCache[key] then
		return nameCache[key]
	end
	local userId = tonumber(string.match(key, "^u_(%d+)$"))
	if not userId then
		return "Mystery Chef"
	end
	local success, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	local displayName = success and string.format("@%s", name) or string.format("Chef %d", userId)
	nameCache[key] = displayName
	return displayName
end

local function readTopTen()
	local store = getOrderedStore()
	if not store then
		setSampleBoard(studioFallbackMessage())
		return nil
	end
	local success, pageOrError = retryStore("GetSortedAsync", function()
		return store:GetSortedAsync(false, 10)
	end)
	if not success then
		if RunService:IsStudio() then
			setSampleBoard(studioFallbackMessage())
		else
			setBoardText("PIZZA LAUNCH LEGENDS\n\nThe live board is reconnecting.\nPlease check back in a moment.")
		end
		return nil
	end

	local entries = pageOrError:GetCurrentPage()
	local lines = { "PIZZA LAUNCH LEGENDS", "ALL-TIME TOP 10", "" }
	for rank, entry in entries do
		table.insert(lines, string.format("%2d.  %-18s  %d", rank, resolveName(entry.key), math.floor(entry.value)))
	end
	if #entries == 0 then
		table.insert(lines, "No records yet - be the first!")
	end
	setBoardText(table.concat(lines, "\n"))
	return entries
end

local function refreshBoard()
	if refreshBusy then
		return lastBoardEntries
	end
	if lastBoardEntries and now() - lastBoardRefreshAt < 20 then
		return lastBoardEntries
	end
	refreshBusy = true
	local success, entries = pcall(readTopTen)
	refreshBusy = false
	if not success then
		warnStore("Refresh board", entries)
		return nil
	end
	if entries then
		lastBoardEntries = entries
		lastBoardRefreshAt = now()
	end
	return entries
end

local function rankForKey(entries, key: string): number?
	if not entries then
		return nil
	end
	for rank, entry in entries do
		if entry.key == key then
			return rank
		end
	end
	return nil
end

local function multiplierForCombo(combo: number): number
	return math.min(2, 1 + math.floor(math.max(0, combo - 1) / 3) * 0.25)
end

function RecordRunService.start(world: Instance, onChanged)
	notifyChanged = onChanged
	local board = world:FindFirstChild("LegendsBoard", true)
	local gui = board and board:FindFirstChild("LegendsGui")
	local label = gui and gui:FindFirstChild("Label")
	if label and label:IsA("TextLabel") then
		legendsLabel = label
	end
	task.spawn(refreshBoard)
	task.spawn(function()
		local nextBoardRefreshAt = now() + 90
		while world.Parent and not closing do
			task.wait(5)
			for _, session in persistenceSessions do
				if session.model.pending and not session.model.inFlight and now() >= session.nextRetryAt then
					task.spawn(savePending, session, 3)
				end
				if session.player and session.model.loadStatus ~= "loaded" and not session.loadBusy and now() >= session.nextLoadAt then
					task.spawn(loadPersonalBest, session)
				end
			end
			if now() >= nextBoardRefreshAt then
				nextBoardRefreshAt = now() + 90
				task.spawn(refreshBoard)
			end
		end
	end)
	game:BindToClose(function()
		closing = true
		local deadline = os.clock() + 25
		for _, session in persistenceSessions do session.nextRetryAt = 0 end
		-- Parallel across users, serialized within each max-score key. Never
		-- submit a partial active run or a default profile during shutdown.
		while os.clock() < deadline do
			local outstanding = false
			for _, session in persistenceSessions do
				if session.model.pending or session.model.inFlight then
					outstanding = true
					if not session.model.inFlight and now() >= session.nextRetryAt then
						task.spawn(savePending, session, 1)
					end
				end
			end
			if not outstanding then break end
			task.wait(0.1)
		end
	end)
end

function RecordRunService.addPlayer(player: Player)
	local session = persistenceSessions[player.UserId]
	if not session then
		session = { model = RecordPersistence.new(player.UserId), nextRetryAt = 0, nextLoadAt = 0 }
		persistenceSessions[player.UserId] = session
	end
	session.player = player
	local run = {
		status = "idle",
		score = 0,
		combo = 0,
		multiplier = 1,
		persistence = session,
		countdownEndsAt = 0,
		startedAt = 0,
		endsAt = 0,
		lastPoints = 0,
		rank = nil,
		madeTopTen = false,
		isNewBest = false,
		token = 0,
		globalBoardAvailable = true,
		globalBoardMessage = "",
		lastSubmittedToken = -1,
	}
	runs[player] = run
	task.spawn(loadPersonalBest, session)
end

function RecordRunService.getSnapshot(player: Player)
	local run = runs[player]
	if not run then
		return {
			status = "idle",
			personalBest = 0,
		}
	end
	return {
		status = run.status,
		score = run.score,
		combo = run.combo,
		multiplier = run.multiplier,
		personalBest = run.persistence.model:best(),
		sessionBest = run.persistence.model.sessionBest,
		savedBest = run.persistence.model.savedBest,
		pendingBest = run.persistence.model.pending and run.persistence.model.pending.score or nil,
		countdownEndsAt = run.countdownEndsAt,
		endsAt = run.endsAt,
		lastPoints = run.lastPoints,
		rank = run.rank,
		madeTopTen = run.madeTopTen,
		isNewBest = run.isNewBest,
		persistenceAvailable = run.persistence.model:available(),
		persistenceMessage = persistenceMessage(run.persistence.model),
		globalBoardAvailable = run.globalBoardAvailable,
		globalBoardMessage = run.globalBoardMessage,
	}
end

function RecordRunService.isSession(player: Player): boolean
	local run = runs[player]
	return run ~= nil and run.status ~= "idle"
end

function RecordRunService.canLaunch(player: Player): boolean
	local run = runs[player]
	return run == nil or run.status == "idle" or (run.status == "running" and now() < run.endsAt)
end

function RecordRunService.begin(player: Player): (boolean, string?)
	local run = runs[player]
	if not run or run.status == "countdown" or run.status == "running" or run.status == "saving" then
		return false, "A 1-Minute Record Run is already active."
	end
	run.token += 1
	run.runId = HttpService:GenerateGUID(false)
	local token = run.token
	run.status = "countdown"
	run.score = 0
	run.combo = 0
	run.multiplier = 1
	run.lastPoints = 0
	run.rank = nil
	run.madeTopTen = false
	run.isNewBest = false
	run.globalBoardAvailable = true
	run.globalBoardMessage = ""
	run.countdownEndsAt = now() + Config.RECORD_RUN_COUNTDOWN
	run.endsAt = run.countdownEndsAt + Config.RECORD_RUN_DURATION
	notify(player, "recordCountdown")

	task.spawn(function()
		while runs[player] == run and run.token == token and now() < run.countdownEndsAt do
			task.wait(0.05)
		end
		if runs[player] ~= run or run.token ~= token or run.status ~= "countdown" then
			return
		end
		run.status = "running"
		run.startedAt = now()
		run.endsAt = run.startedAt + Config.RECORD_RUN_DURATION
		notify(player, "recordStarted")
		while runs[player] == run and run.token == token and run.status == "running" and now() < run.endsAt do
			task.wait(0.1)
		end
		if runs[player] == run and run.token == token and run.status == "running" then
			RecordRunService.finish(player)
		end
	end)
	return true, nil
end

function RecordRunService.recordSuccess(player: Player, tableId: number, accuracyName: string)
	local run = runs[player]
	if not run or run.status ~= "running" or now() >= run.endsAt then
		return nil
	end
	run.combo += 1
	run.multiplier = multiplierForCombo(run.combo)
	local basePoints = Config.RECORD_RUN_TABLE_POINTS[tableId] or 100
	local accuracyBonus = Config.RECORD_RUN_ACCURACY_BONUS[accuracyName] or 0
	run.lastPoints = math.floor((basePoints + accuracyBonus) * run.multiplier + 0.5)
	run.score += run.lastPoints
	return RecordRunService.getSnapshot(player)
end

function RecordRunService.recordMiss(player: Player)
	local run = runs[player]
	if not run or run.status ~= "running" then
		return nil
	end
	run.combo = 0
	run.multiplier = 1
	run.lastPoints = 0
	return RecordRunService.getSnapshot(player)
end

function RecordRunService.finish(player: Player)
	local run = runs[player]
	if not run or run.status ~= "running" or run.lastSubmittedToken == run.token then return end
	run.lastSubmittedToken = run.token
	local completedToken = run.token
	-- Capture every submitted fact before notify/task.spawn/DataStore can yield.
	-- cancel(), another run, disconnect, or late reads cannot change this score.
	local submission, isNewBest = run.persistence.model:complete(run.score, run.runId, run.startedAt, now())
	run.status = "saving"
	run.combo = 0
	run.multiplier = 1
	run.isNewBest = isNewBest
	notify(player, "recordEnding")

	task.spawn(function()
		savePending(run.persistence, 3)
		-- Board fetch is independent from the write and cannot revoke its success.
		local entries = refreshBoard()
		if runs[player] ~= run or run.status ~= "saving" or run.token ~= completedToken then return end
		run.globalBoardAvailable = entries ~= nil
		run.globalBoardMessage = entries and "" or (RunService:IsStudio() and studioFallbackMessage() or "The live board is reconnecting; your score may still be saved.")
		run.rank = rankForKey(entries, string.format("u_%d", submission.userId))
		run.madeTopTen = run.rank ~= nil and submission.score >= run.persistence.model:best()
		run.status = "finished"
		notify(player, "recordFinished")
	end)
end

function RecordRunService.cancel(player: Player)
	local run = runs[player]
	if not run then
		return
	end
	run.token += 1
	run.status = "idle"
	run.score = 0
	run.combo = 0
	run.multiplier = 1
	run.countdownEndsAt = 0
	run.endsAt = 0
end

function RecordRunService.removePlayer(player: Player)
	local run = runs[player]
	RecordRunService.cancel(player)
	runs[player] = nil
	if run then
		local session = run.persistence
		if session.player == player then session.player = nil end
		-- Retain failed completed submissions after departure until confirmed or
		-- server shutdown; the queued score never references the removed run.
		if session.model.pending then task.spawn(savePending, session, 3) end
		releaseSavedSession(session)
	end
end

return RecordRunService
