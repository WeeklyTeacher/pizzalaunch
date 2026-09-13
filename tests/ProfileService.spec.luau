-- Actual service execution with deterministic scheduling and a shared fake
-- backend. No Roblox APIs, Studio settings, or live stores are contacted.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local Model = require("../src/server/ProfileModel")
local Config = require("../src/shared/MasteryConfig")
local serviceSource = fs.readFile("src/server/ProfileService.luau")
local function harness()
	local fake = { time = 1000, jobs = {}, values = {}, calls = 0, storeCalls = 0, events = {}, snapshots = {}, serial = 0,
		delay = 0, failBefore = 0, failAfter = 0, callbackRuns = 1 }
	local function resume(thread, ...)
		local ok, delay = coroutine.resume(thread, ...)
		assert(ok, tostring(delay))
		if coroutine.status(thread) ~= "dead" then table.insert(fake.jobs, { thread = thread, at = fake.time + (delay or 0) }) end
	end
	function fake.spawn(callback, ...)
		local thread = coroutine.create(callback)
		resume(thread, ...)
		return thread
	end
	function fake.wait(delay) return coroutine.yield(delay or 0) end
	function fake.advance(seconds)
		local target, iterations = fake.time + seconds, 0
		while true do
			table.sort(fake.jobs, function(a, b) return a.at < b.at end)
			local job = fake.jobs[1]
			if not job or job.at > target then break end
			table.remove(fake.jobs, 1)
			fake.time = job.at
			resume(job.thread)
			iterations += 1
			assert(iterations < 100000, "Scheduler did not advance")
		end
		fake.time = target
	end
	fake.store = { UpdateAsync = function(_, key, transform)
		fake.calls += 1
		if fake.delay > 0 then fake.wait(fake.delay) end
		if fake.failBefore > 0 then fake.failBefore -= 1; error("Injected pre-write outage") end
		local value
		for _ = 1, fake.callbackRuns do value = transform(Model.copy(fake.values[key])) end
		if value ~= nil then fake.values[key] = Model.copy(value) end
		if fake.failAfter > 0 then fake.failAfter -= 1; error("Injected lost success response") end
		return Model.copy(value)
	end }
	function fake.newService(options)
		local opts = options or {}
		local fakeGame = {
			PlaceId = opts.placeId or 100,
			GetService = function(_, name)
				if name == "ReplicatedStorage" then return { Shared = { MasteryConfig = "MasteryConfig" } } end
				if name == "RunService" then return { IsStudio = function() return opts.studio == true end } end
				error("Unexpected Roblox service: " .. name)
			end,
			BindToClose = function() end,
		}
		local Service = luau.load(serviceSource, { environment = {
			game = fakeGame, script = { Parent = { ProfileModel = "ProfileModel" } }, warn = function() end,
			require = function(name)
				if name == "ProfileModel" then return Model end
				assert(name == "MasteryConfig")
				return Config
			end,
		} })()
		local service = Service.new({
			now = function() return math.floor(fake.time) end, clock = function() return fake.time end,
			spawn = fake.spawn, wait = fake.wait, random = function() return 0.5 end,
			token = function() fake.serial += 1; return "session-" .. fake.serial end,
			storeProvider = function() fake.storeCalls += 1; return fake.store end,
			onChanged = function(player, snapshot) table.insert(fake.snapshots, { player = player, snapshot = snapshot }) end,
			onEvent = function(player, event, reason) table.insert(fake.events, { player = player, event = event, reason = reason }) end,
		})
		service:start()
		return service
	end
	return fake
end
local passed = 0
local function test(name, fn) fn(); passed += 1; print("PASS: " .. name) end
local function player() return { UserId = 42, Parent = true } end
local function deliver(service, who, sequence)
	return service:recordDelivery(who, { sequence = sequence, tableId = 6, accuracy = "PERFECT!", customerName = "Mia" })
end

test("Studio and unpublished sessions cannot invoke even an injected real-store provider", function()
	for _, options in { { studio = true }, { placeId = 0 } } do
		local fake, who = harness(), player()
		local service = fake.newService(options)
		service:addPlayer(who)
		deliver(service, who, 1)
		fake.advance(35)
		local snapshot = service:snapshot(who)
		assert(snapshot.status == "memory" and snapshot.isNew == nil and not snapshot.durable)
		assert(snapshot.mastery.deliveries == 1 and not snapshot.dirty)
		service:removePlayer(who)
		local rejoin = player()
		service:addPlayer(rejoin)
		assert(service:snapshot(rejoin).mastery.deliveries == 1)
		assert(fake.storeCalls == 0 and fake.calls == 0 and next(fake.values) == nil)
	end
end)
test("new profile is confirmed atomically and normal heartbeat renews its lease", function()
	local fake, who = harness(), player()
	local service = fake.newService()
	service:addPlayer(who)
	local snapshot = service:snapshot(who)
	assert(snapshot.status == "ready" and snapshot.isNew and snapshot.durable and snapshot.persistenceAvailable)
	assert(fake.values.u_42.lease.expiresAt == 1120)
	fake.advance(31)
	assert(fake.values.u_42.lease.expiresAt == 1150)
	assert(fake.events[1].event == "ProfileLoaded" and fake.events[1].reason == "new")
end)
test("failed load retains server session progress and never writes zero over existing history", function()
	local fake, who = harness(), player()
	fake.values.u_42 = Model.acquire(Config, nil, "previous", 800)
	fake.values.u_42.lease = nil
	fake.values.u_42.data.mastery.deliveries = 50
	fake.failBefore = 2
	local service = fake.newService()
	service:addPlayer(who)
	deliver(service, who, 1)
	local failed = service:snapshot(who)
	assert(failed.status == "loadFailed" and failed.isNew == nil and not failed.durable)
	assert(fake.values.u_42.data.mastery.deliveries == 50)
	fake.advance(7)
	local loaded = service:snapshot(who)
	assert(loaded.status == "ready" and loaded.isNew == false and loaded.mastery.deliveries == 51)
	fake.advance(31)
	assert(fake.values.u_42.data.mastery.deliveries == 51)
end)
test("locked malformed and unsupported data remain distinct without default replacement", function()
	for _, kind in { "locked", "malformed", "unsupported" } do
		local fake, who = harness(), player()
		if kind == "locked" then fake.values.u_42 = Model.acquire(Config, nil, "other-owner", 1000)
		elseif kind == "unsupported" then fake.values.u_42 = { schemaVersion = 2, keep = "safe" }
		else fake.values.u_42 = { schemaVersion = 1, keep = "safe" } end
		local original = Model.copy(fake.values.u_42)
		local service = fake.newService()
		service:addPlayer(who)
		deliver(service, who, 1)
		fake.advance(10)
		local snapshot = service:snapshot(who)
		assert(snapshot.status == kind and snapshot.isNew == nil and not snapshot.durable)
		if kind == "locked" then assert(fake.values.u_42.lease.token == original.lease.token)
		else assert(fake.values.u_42.keep == "safe" and fake.values.u_42.data == nil) end
	end
end)
test("failed save retries its frozen revision before saving newer mutations", function()
	local fake, who = harness(), player()
	local service = fake.newService()
	service:addPlayer(who)
	deliver(service, who, 1)
	fake.failBefore = 1
	fake.advance(30)
	assert(service:snapshot(who).status == "saveFailed")
	deliver(service, who, 2)
	fake.advance(2)
	assert(fake.values.u_42.data.mastery.deliveries == 1)
	assert(service:snapshot(who).dirty)
	fake.advance(1)
	assert(fake.values.u_42.data.mastery.deliveries == 2 and not service:snapshot(who).dirty)
end)
test("uncertain write response and repeated transform callbacks cannot duplicate mastery", function()
	local fake, who = harness(), player()
	local service = fake.newService()
	service:addPlayer(who)
	deliver(service, who, 1)
	fake.failAfter, fake.callbackRuns = 1, 2
	fake.advance(30)
	assert(fake.values.u_42.data.mastery.deliveries == 1 and service:snapshot(who).dirty)
	fake.advance(2)
	assert(fake.values.u_42.data.mastery.deliveries == 1 and not service:snapshot(who).dirty)
end)
test("departure final save and rapid next server preserve equipped cosmetics and mastery", function()
	local fake, who = harness(), player()
	local first = fake.newService()
	first:addPlayer(who)
	for sequence = 1, 15 do deliver(first, who, sequence) end
	assert(first:equip(who, "gold"))
	assert(first:completeTutorial(who))
	first:removePlayer(who)
	assert(fake.values.u_42.lease == nil)
	local rejoin, second = player(), fake.newService()
	second:addPlayer(rejoin)
	local snapshot = second:snapshot(rejoin)
	assert(snapshot.status == "ready" and snapshot.isNew == false and snapshot.mastery.deliveries == 15)
	assert(snapshot.equipped == "gold" and snapshot.tutorialCompleted and snapshot.earnedCosmetics.gold)
	assert(deliver(second, rejoin, 1), "Receipt sequence must reset for the new player session")
	assert(snapshot.coins == nil and snapshot.upgrades == nil)
end)
test("lost release response cannot overwrite the newly acquired server", function()
	local fake, who = harness(), player()
	local first = fake.newService()
	first:addPlayer(who)
	deliver(first, who, 1)
	fake.failAfter = 1
	first:removePlayer(who)
	assert(fake.values.u_42.lease == nil and fake.values.u_42.data.mastery.deliveries == 1)
	local second, rejoin = fake.newService(), player()
	second:addPlayer(rejoin)
	local currentToken = fake.values.u_42.lease.token
	second:recordTakeout(rejoin, { sequence = 1 })
	fake.advance(4)
	assert(fake.values.u_42.lease.token == currentToken)
	assert(next(first.sessions) == nil)
	second:removePlayer(rejoin)
	assert(fake.values.u_42.data.mastery.takeout == 1 and fake.values.u_42.data.mastery.deliveries == 1)
end)
test("expired suspended old-server write cannot overwrite a takeover", function()
	local fake, who = harness(), player()
	local first = fake.newService()
	first:addPlayer(who)
	deliver(first, who, 1)
	fake.delay = 130
	fake.advance(30)
	fake.delay = 0
	fake.advance(91)
	local second, rejoin = fake.newService(), player()
	second:addPlayer(rejoin)
	assert(second:snapshot(rejoin).status == "ready")
	second:recordTakeout(rejoin, { sequence = 1 })
	fake.advance(40)
	assert(first:snapshot(who).status == "leaseLost" and not first:snapshot(who).durable)
	assert(fake.values.u_42.data.mastery.deliveries == 0 and fake.values.u_42.data.mastery.takeout == 1)
end)
test("removal during acquisition serializes final release before same-server rejoin", function()
	local fake, who = harness(), player()
	local service = fake.newService()
	fake.delay = 2
	service:addPlayer(who)
	deliver(service, who, 1)
	service:removePlayer(who)
	local rejoin = player()
	service:addPlayer(rejoin)
	service:recordTakeout(rejoin, { sequence = 1 })
	fake.advance(8)
	local snapshot = service:snapshot(rejoin)
	assert(snapshot.status == "ready" and snapshot.mastery.deliveries == 1 and snapshot.mastery.takeout == 1)
	assert(service:snapshot(who).status == "unavailable")
end)
test("shutdown final release succeeds or returns within its bounded deadline", function()
	for _, failing in { false, true } do
		local fake, who = harness(), player()
		local service = fake.newService()
		service:addPlayer(who)
		deliver(service, who, 1)
		if failing then fake.failBefore = math.huge end
		local close = fake.spawn(function() service:shutdown() end)
		fake.advance(25.2)
		assert(coroutine.status(close) == "dead")
		assert(not service:addPlayer(player()))
		if not failing then assert(fake.values.u_42.lease == nil and fake.values.u_42.data.mastery.deliveries == 1)
		else assert(fake.values.u_42.data.mastery.deliveries == 0 and fake.calls < 20) end
	end
end)
test("duplicate receipts and client snapshot edits cannot affect another player", function()
	local fake, who, other = harness(), player(), { UserId = 43, Parent = true }
	local service = fake.newService()
	service:addPlayer(who)
	service:addPlayer(other)
	assert(deliver(service, who, 1) and not deliver(service, who, 1))
	local snapshot = service:snapshot(who)
	snapshot.mastery.deliveries, snapshot.earnedCosmetics.gold = 99999, true
	assert(not service:equip(who, "gold"))
	assert(service:snapshot(who).mastery.deliveries == 1 and service:snapshot(other).mastery.deliveries == 0)
end)
test("acquisition returning after departure or shutdown deadline cannot leave a fresh orphan lease", function()
	for _, shutdown in { false, true } do
		local fake, who = harness(), player()
		local service = fake.newService()
		fake.delay = 30
		service:addPlayer(who)
		deliver(service, who, 1)
		if shutdown then fake.spawn(function() service:shutdown() end) else service:removePlayer(who) end
		fake.advance(30)
		assert(fake.values.u_42 == nil, "Late departed acquisition created an orphan profile lease")
		assert(next(service.sessions) == nil)
		fake.delay = 0
		local nextServer, rejoin = fake.newService(), player()
		nextServer:addPlayer(rejoin)
		assert(nextServer:snapshot(rejoin).status == "ready")
	end
end)
test("lost renewal success can recover after the last locally confirmed lease deadline", function()
	local fake, who = harness(), player()
	local service = fake.newService()
	service:addPlayer(who)
	deliver(service, who, 1)
	fake.failAfter = 1
	fake.advance(30)
	assert(fake.values.u_42.lease.expiresAt == 1150)
	deliver(service, who, 2)
	fake.failBefore = 5
	fake.advance(91)
	assert(not service:snapshot(who).durable, "Locally expired ownership is not confirmed")
	fake.advance(4)
	assert(service:snapshot(who).status == "ready" and service:snapshot(who).durable)
	assert(fake.values.u_42.data.mastery.deliveries == 2, "Local expiry incorrectly blocked a valid frozen retry")
end)
print(string.format("ProfileService: %d behavioral tests passed", passed))
