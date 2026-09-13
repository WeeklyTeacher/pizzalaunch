local loadModule = require("./support/LoadModule")
local Milestone = loadModule("src/server/SharedMilestone.luau")
local a, b, afk = {}, {}, {}
local present = { [a] = true, [b] = true, [afk] = true }
local coins, notifications = {}, {}
local milestone = Milestone.new({
	target = 12, reward = 10,
	isPresent = function(player) return present[player] == true end,
	award = function(player, reward, cycle)
		assert(cycle == 1 or cycle == 2)
		coins[player] = (coins[player] or 0) + reward
	end,
	notify = function(snapshot, completed) table.insert(notifications, {snapshot, completed}) end,
})
assert(not milestone:contribute(a, "recordRun"))
assert(not milestone:contribute(a, "unknown"))
assert(milestone:snapshot().progress == 0)
for _ = 1, 10 do assert(milestone:contribute(a, "freePlay")) end
assert(not coins[a] and not coins[b] and not coins[afk])
assert(milestone:contribute(b, "takeout"))
assert(milestone:contribute(a, "takeout"))
assert(coins[a] == 10 and coins[b] == 10 and not coins[afk])
assert(milestone:snapshot().progress == 0 and milestone:snapshot().cycle == 2)
assert(notifications[#notifications][2] == true)
milestone:contribute(b, "takeout")
milestone:removePlayer(b)
present[b] = false
for _ = 1, 11 do milestone:contribute(a, "freePlay") end
assert(coins[a] == 20 and coins[b] == 10)
assert(not milestone:contribute(b, "takeout"))
assert(milestone:snapshot().progress == 0)
print("PASS: shared milestone rewards only present service contributors once per cycle; no Record Run or AFK contribution")
