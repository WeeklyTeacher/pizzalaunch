local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local RecordRunService = {}

local orderedStore
local storeChecked = false
local runs = {}
local notifyChanged
local legendsLabel: TextLabel?
local nameCache = {}
local refreshBusy = false

local TARGET_SEQUENCE = { 1, 2, 3, 4, 2, 5, 3, 6, 1, 4, 5, 6 }

local function getOrderedStore()
	if not storeChecked then
		storeChecked = true
		local success, store = pcall(function()
			return DataStoreService:GetOrderedDataStore(Config.RECORD_RUN_STORE)
		end)
		if success then
			orderedStore = store
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
		setBoardText("PIZZA LAUNCH LEGENDS\n\nRecords are warming up!\n\nPublish this place to test\nsaved scores in Studio.")
		return nil
	end
	local success, pageOrError = pcall(function()
		return store:GetSortedAsync(false, 10)
	end)
	if not success then
		setBoardText("PIZZA LAUNCH LEGENDS\n\nRecords are warming up!\n\nStudio: enable API Services\nto test saved scores.")
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
		return nil
	end
	refreshBusy = true
	local entries = readTopTen()
	refreshBusy = false
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

local function nextTarget(run): number
	run.targetStep += 1
	return TARGET_SEQUENCE[(run.targetStep - 1) % #TARGET_SEQUENCE + 1]
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
		targetId = nil,
		targetStep = 0,
		countdownEndsAt = 0,
		endsAt = 0,
		lastPoints = 0,
		rank = nil,
		madeTopTen = false,
		isNewBest = false,
		persistenceAvailable = true,
		persistenceMessage = "",
		token = 0,
	}
	task.spawn(function()
		local store = getOrderedStore()
		if not store then
			local run = runs[player]
			if run then
				run.persistenceAvailable = false
				run.persistenceMessage = "Publish this place to test saved records in Studio."
				notify(player, "recordBestLoaded")
			end
			return
		end
		local success, value = pcall(function()
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
			run.persistenceMessage = "Records are unavailable in this Studio session."
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
		targetId = run.targetId,
		countdownEndsAt = run.countdownEndsAt,
		endsAt = run.endsAt,
		lastPoints = run.lastPoints,
		rank = run.rank,
		madeTopTen = run.madeTopTen,
		isNewBest = run.isNewBest,
		persistenceAvailable = run.persistenceAvailable,
		persistenceMessage = run.persistenceMessage,
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
	run.targetStep = 0
	run.targetId = nextTarget(run)
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
	if not run or run.status ~= "running" or now() >= run.endsAt or tableId ~= run.targetId then
		return nil
	end
	run.combo += 1
	run.multiplier = multiplierForCombo(run.combo)
	local basePoints = Config.RECORD_RUN_TABLE_POINTS[tableId] or 100
	local accuracyBonus = Config.RECORD_RUN_ACCURACY_BONUS[accuracyName] or 0
	run.lastPoints = math.floor((basePoints + accuracyBonus) * run.multiplier + 0.5)
	run.score += run.lastPoints
	run.targetId = nextTarget(run)
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
	run.status = "saving"
	run.combo = 0
	run.multiplier = 1
	local previousBest = run.personalBest
	run.isNewBest = run.score > previousBest
	if run.isNewBest then
		run.personalBest = run.score
	end
	notify(player, "recordEnding")

	task.spawn(function()
		local key = playerKey(player)
		local store = getOrderedStore()
		local saveSucceeded = store ~= nil
		if run.score >= previousBest then
			local success, storedValue = pcall(function()
				if not store then
					error("record store unavailable")
				end
				return store:UpdateAsync(key, function(oldValue)
					return math.max(typeof(oldValue) == "number" and oldValue or 0, run.score)
				end)
			end)
			saveSucceeded = success
			if success and typeof(storedValue) == "number" then
				run.personalBest = math.floor(storedValue)
			end
		end

		local entries
		if saveSucceeded then
			entries = refreshBoard()
		else
			run.persistenceAvailable = false
			run.persistenceMessage = "Score shown for this session; saved records are unavailable."
		end
		if runs[player] ~= run or run.status ~= "saving" then
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
	run.targetId = nil
	run.countdownEndsAt = 0
	run.endsAt = 0
end

function RecordRunService.removePlayer(player: Player)
	RecordRunService.cancel(player)
	runs[player] = nil
end

return RecordRunService
