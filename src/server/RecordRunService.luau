local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local RecordRunService = {}

local orderedStore
local storeChecked = false
local runs = {}
local notifyChanged
local legendsLabel: TextLabel?
local nameCache = {}
local refreshBusy = false
local lastBoardRefreshAt = 0
local lastBoardEntries = nil

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
	return "Global leaderboard is available in the published game.\nStudio API access is currently off.\n\nFor Studio testing: File > Experience Settings > Security >\nEnable Studio Access to API Services."
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
	if not storeChecked then
		storeChecked = true
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

local function playerKey(player: Player): string
	return string.format("u_%d", player.UserId)
end

local function notify(player: Player, eventName: string)
	if notifyChanged and player.Parent then
		notifyChanged(player, eventName)
	end
end

local function setBoardText(text: string)
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
	local entries = readTopTen()
	refreshBusy = false
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
		while world.Parent do
			task.wait(90)
			refreshBoard()
		end
	end)
end

function RecordRunService.addPlayer(player: Player)
	runs[player] = {
		status = "idle",
		score = 0,
		combo = 0,
		multiplier = 1,
		personalBest = 0,
		countdownEndsAt = 0,
		endsAt = 0,
		lastPoints = 0,
		rank = nil,
		madeTopTen = false,
		isNewBest = false,
		persistenceAvailable = true,
		persistenceMessage = "",
		token = 0,
		globalBoardAvailable = true,
		globalBoardMessage = "",
		lastSubmittedToken = -1,
	}
	task.spawn(function()
		local store = getOrderedStore()
		if not store then
			local run = runs[player]
			if run then
				run.persistenceAvailable = false
				run.persistenceMessage = RunService:IsStudio() and studioFallbackMessage() or "Personal best is temporarily unavailable."
				run.globalBoardAvailable = false
				run.globalBoardMessage = run.persistenceMessage
				notify(player, "recordBestLoaded")
			end
			return
		end
		local success, value = retryStore("GetAsync personal best", function()
			return store:GetAsync(playerKey(player))
		end)
		local run = runs[player]
		if not run then
			return
		end
		if success and typeof(value) == "number" then
			run.personalBest = math.max(0, math.floor(value))
		elseif not success then
			run.persistenceAvailable = false
			run.persistenceMessage = RunService:IsStudio() and studioFallbackMessage() or "Personal best is temporarily unavailable."
		end
		notify(player, "recordBestLoaded")
	end)
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
		personalBest = run.personalBest,
		countdownEndsAt = run.countdownEndsAt,
		endsAt = run.endsAt,
		lastPoints = run.lastPoints,
		rank = run.rank,
		madeTopTen = run.madeTopTen,
		isNewBest = run.isNewBest,
		persistenceAvailable = run.persistenceAvailable,
		persistenceMessage = run.persistenceMessage,
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
		return false, "A record run is already active."
	end
	run.token += 1
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
		run.endsAt = now() + Config.RECORD_RUN_DURATION
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
	if not run or run.status ~= "running" then
		return
	end
	if run.lastSubmittedToken == run.token then
		return
	end
	run.lastSubmittedToken = run.token
	run.status = "saving"
	run.combo = 0
	run.multiplier = 1
	local previousBest = run.personalBest
	run.isNewBest = run.score > previousBest
	if run.isNewBest then
		run.personalBest = run.score
	end
	notify(player, "recordEnding")

	local completedToken = run.token
	task.spawn(function()
		local key = playerKey(player)
		local store = getOrderedStore()
		local personalSaveSucceeded = true
		if run.score > previousBest then
			if not store then
				personalSaveSucceeded = false
			else
				local success, storedValue = retryStore("UpdateAsync completed Record Run", function()
				return store:UpdateAsync(key, function(oldValue)
					return math.max(typeof(oldValue) == "number" and oldValue or 0, run.score)
				end)
			end)
				personalSaveSucceeded = success
				if success and typeof(storedValue) == "number" then
					run.personalBest = math.floor(storedValue)
				end
			end
		end

		if not personalSaveSucceeded then
			run.persistenceAvailable = false
			run.persistenceMessage = "Score shown for this session; personal best could not be saved."
		end
		-- Board fetch is deliberately independent from the personal-best write.
		-- A read outage must not turn a successfully saved score into a failure.
		local entries = refreshBoard()
		if not entries then
			run.globalBoardAvailable = false
			run.globalBoardMessage = RunService:IsStudio() and studioFallbackMessage() or "The live board is reconnecting; your score may still be saved."
		end
		if runs[player] ~= run or run.status ~= "saving" or run.token ~= completedToken then
			return
		end
		run.rank = rankForKey(entries, key)
		run.madeTopTen = run.rank ~= nil and run.score >= run.personalBest
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
	RecordRunService.cancel(player)
	runs[player] = nil
end

return RecordRunService
