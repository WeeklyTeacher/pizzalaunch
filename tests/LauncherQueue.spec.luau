local loadModule = require("./support/LoadModule")
local Queue = loadModule("src/server/LauncherQueue.luau")
local now, owner = 0, nil
local events = {}
local function player(id) return { UserId = id, Character = {}, alive = true, present = true } end
local a, b, c, d = player(1), player(2), player(3), player(4)
local queue = Queue.new({
	now = function() return now end, getOwner = function() return owner end,
	isEligible = function(actor, character) return actor.present and actor.alive and actor.Character == character and actor ~= owner end,
	notify = function(actor, event) table.insert(events, { actor, event }) end,
	reservationSeconds = 15,
})
owner = a
assert(not queue:join(a))
assert(queue:join(b) and queue:join(c) and queue:join(d))
assert(queue:snapshot(b).position == 1 and queue:snapshot(c).position == 2 and queue:snapshot(d).position == 3)
for _ = 1, 20 do assert(queue:join(b)) end
assert(queue:snapshot(a).waitingCount == 3, "duplicate joins never increase capacity")
assert(not queue:canMount(b) and not queue:canMount(c))
owner = nil
queue:step()
assert(queue:snapshot(b).status == "reserved" and queue:snapshot(b).reservationEndsAt == 15)
assert(queue:canMount(b) and not queue:canMount(c) and owner == nil, "reservation never acquires a lease")
assert(not queue:accepted(b), "reservation cannot be consumed before server lease validation")
now = 14.9
assert(queue:canMount(b))
now = 15
queue:step()
assert(queue:snapshot(b).status == "none" and queue:snapshot(c).status == "reserved")
assert(queue:snapshot(c).reservationEndsAt == 30 and queue:snapshot(d).position == 2)
owner = c
assert(queue:accepted(c) and queue:snapshot(c).status == "none")
assert(queue:snapshot(d).position == 1 and queue:snapshot(c).waitingCount == 1)
assert(queue:cancel(d) and not queue:cancel(d), "cancel is idempotent")
assert(queue:join(a) and queue:join(b))
b.Character = {}
queue:step()
assert(queue:snapshot(b).status == "none", "replacement loses the old queue entry")
a.alive = false
owner = nil
queue:step()
assert(queue:snapshot(a).status == "none" and queue:canMount(d), "death cannot retain or block reservations")
a.alive = true
assert(queue:join(a) and queue:snapshot(a).status == "reserved")
assert(queue:join(b))
a.present = false
queue:step()
assert(queue:snapshot(b).status == "reserved", "disconnect immediately advances the queue")
queue:cancel(b)
assert(queue:canMount(c) and queue:snapshot(c).waitingCount == 0)
assert(owner == nil and a.Character and b.Character and c.Character and d.Character, "all four participants retain ordinary characters")
print("PASS: actual LauncherQueue FIFO, four-player positions, duplicate/cancel/death/replacement/disconnect, expired reservations and explicit lease consumption")
