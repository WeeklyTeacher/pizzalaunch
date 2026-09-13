-- Execute the actual service with a deterministic clock/scheduler and an
-- in-memory store. This never contacts Roblox, Studio, or production APIs.
local loadModule = require("./support/LoadModule")
local RecordPersistence = require("../src/server/RecordPersistence")
local Config = loadModule("src/shared/Config.luau")

local function harness()
	local fake = { time = 1000, jobs = {}, values = {}, writes = {}, writeDelay = 0, writeFailures = 0, events = {} }
	local scheduler = {}
	local function resume(thread, ...)
		local ok, delay = coroutine.resume(thread, ...)
		assert(ok, tostring(delay))
		if coroutine.status(thread) ~= "dead" then
			table.insert(fake.jobs, { thread = thread, at = fake.time + (delay or 0) })
		end
	end
	function scheduler.spawn(callback, ...)
		local thread = coroutine.create(callback)
		resume(thread, ...)
		return thread
	end
	function scheduler.wait(delay)
		return coroutine.yield(delay or 0)
	end
	function fake.advance(seconds)
		local untilTime = fake.time + seconds
		local iterations = 0
		while true do
			table.sort(fake.jobs, function(a, b) return a.at < b.at end)
			local job = fake.jobs[1]
			if not job or job.at > untilTime then break end
			table.remove(fake.jobs, 1)
			fake.time = job.at
			resume(job.thread)
			iterations += 1
			assert(iterations < 100000, "Fake scheduler did not make progress")
		end
		fake.time = untilTime
	end
	local store = {}
	function store:GetAsync(key) return fake.values[key] end
	function store:UpdateAsync(key, transform)
		if fake.writeDelay > 0 then scheduler.wait(fake.writeDelay) end
		if fake.writeFailures > 0 then
			fake.writeFailures -= 1
			error("Injected temporary write outage")
		end
		local value = transform(fake.values[key])
		table.insert(fake.writes, { key = key, value = value })
		if value ~= nil then fake.values[key] = value end
		return value
	end
	function store:GetSortedAsync()
		return { GetCurrentPage = function() return {} end }
	end
	local services = {
		DataStoreService = { GetOrderedDataStore = function(_, name)
			assert(name == "PizzaLaunch_RecordRun_AllTime_v1", "Historical store name changed")
			return store
		end },
		Players = { GetNameFromUserIdAsync = function() return "Chef" end },
		Workspace = { GetServerTimeNow = function() return fake.time end },
		RunService = { IsStudio = function() return true end },
		HttpService = { GenerateGUID = function()
			fake.guid = (fake.guid or 0) + 1
			return "test-run-" .. fake.guid
		end },
		ReplicatedStorage = { Shared = { Config = "Config" } },
	}
	local game = {
		GetService = function(_, name) return assert(services[name], name) end,
		BindToClose = function(_, callback) fake.close = callback end,
	}
	fake.service = loadModule("src/server/RecordRunService.luau", {
			game = game,
			script = { Parent = { RecordPersistence = "RecordPersistence" } },
			task = scheduler,
			os = { clock = function() return fake.time end },
			warn = function() end,
			require = function(name)
				if name == "Config" then return Config end
				assert(name == "RecordPersistence")
				return RecordPersistence
			end,
	})
	fake.service.start({ Parent = true, FindFirstChild = function() return nil end }, function(player, event)
		table.insert(fake.events, { player = player, event = event })
		if fake.onEvent then fake.onEvent(player, event) end
	end)
	fake.player = { UserId = 42, Parent = true }
	fake.service.addPlayer(fake.player)
	function fake.startRun()
		assert(fake.service.begin(fake.player))
		fake.advance(Config.RECORD_RUN_COUNTDOWN + 0.1)
		assert(fake.service.getSnapshot(fake.player).status == "running")
	end
	return fake
end

do
	local fake = harness()
	fake.startRun()
	local completed = fake.service.recordSuccess(fake.player, 6, "PERFECT!").score
	assert(completed == 240)
	fake.writeDelay = 1
	fake.service.finish(fake.player)
	assert(fake.service.getSnapshot(fake.player).status == "saving")
	fake.service.cancel(fake.player)
	assert(fake.service.begin(fake.player))
	fake.advance(1.1)
	assert(fake.values.u_42 == completed, "Suspended write read a cancelled/replayed run score")
	assert(fake.writes[1].key == "u_42")
	local replay = fake.service.getSnapshot(fake.player)
	assert(replay.status == "countdown" and replay.score == 0, "Old result callback mutated replay")
	assert(replay.savedBest == completed and replay.sessionBest == completed and replay.pendingBest == nil)
	for _, event in fake.events do
		assert(event.event ~= "recordFinished", "Old callback finished the new run")
	end
	print("PASS: suspended actual RecordRunService write preserves completed score and cannot finish replay")
end

do
	local fake = harness()
	fake.startRun()
	local completed = fake.service.recordSuccess(fake.player, 6, "PERFECT!").score
	fake.onEvent = function(player, event)
		if event == "recordEnding" then fake.service.cancel(player) end
	end
	fake.service.finish(fake.player)
	assert(fake.values.u_42 == completed, "Completion was not frozen before notification")
	assert(fake.service.getSnapshot(fake.player).status == "idle")
	print("PASS: completed submission is captured before recordEnding notification can cancel")
end

do
	local fake = harness()
	fake.startRun()
	local completed = fake.service.recordSuccess(fake.player, 6, "PERFECT!").score
	fake.writeFailures = 3
	fake.service.finish(fake.player)
	fake.advance(2)
	local failed = fake.service.getSnapshot(fake.player)
	assert(failed.savedBest == 0 and failed.pendingBest == completed and not failed.persistenceAvailable)
	fake.service.removePlayer(fake.player)
	assert(fake.values.u_42 == completed, "Departure discarded the failed completed submission")
	assert(fake.service.getSnapshot(fake.player).status == "idle")
	print("PASS: removal retries a failed completed submission without saving partial gameplay")
end
