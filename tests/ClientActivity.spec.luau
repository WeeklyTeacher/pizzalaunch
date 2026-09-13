local loadModule = require("./support/LoadModule")
local Presentation = loadModule("src/client/ActivityPresentation.luau")

local snapshot = {
	runner = { status = "idle", normalReward = 8, quickBonus = 2 },
	queue = { status = "waiting", position = 2 },
	station = { occupied = true, launcherMode = "freePlay", operatorName = "Mia", waitingCount = 1 },
}
local view = Presentation.select(snapshot, 10, false, false)
assert(view.visible and view.title == "YOU'RE IN LINE #2")
assert(view.stationText == "FREE PLAY • NO TIME LIMIT", "Free Play must never fabricate an ETA")
assert(view.detail:find("Mia") and view.canLeaveLine and view.canDoTakeout)
snapshot.station.launcherMode = "recordRun"
snapshot.station.recordStatus = "running"
snapshot.station.endsAt = 60
snapshot.station.score = 120
view = Presentation.select(snapshot, 10, false, false)
assert(view.stationText == "1-MINUTE RECORD RUN • 0:50 • SCORE 120")
snapshot.runner = { status = "carrying", destinationName = "SUNNY SCOOPS", normalReward = 8, quickBonus = 2, quickBonusEndsAt = 20 }
view = Presentation.select(snapshot, 10, false, false)
assert(view.title == "DELIVER TO SUNNY SCOOPS" and view.detail:find("QUICK BONUS %+2") and view.queueText:find("LINE #2"))
assert(not view.standaloneCarry, "Runner plus queue keeps its complete queue presentation")
view = Presentation.select(snapshot, 30, false, false)
assert(view.detail:find("8 COINS ON DELIVERY") and not view.detail:find("QUICK BONUS"), "Normal reward survives expired bonus")
snapshot.queue = { status = "reserved", reservationEndsAt = 42 }
view = Presentation.select(snapshot, 35, false, false)
assert(view.title == "YOUR TURN • USE THE LAUNCHER" and view.detail:find("7s") and view.carrying)
view = Presentation.select(snapshot, 43, false, false)
assert(view.detail:find("Checking the line"), "Client waits for server reservation decision at expiry")
view = Presentation.select(snapshot, 35, true, false)
assert(not view.visible and not view.carrying and view.passTurn, "Mounted presentation suppresses independent runner UI while offering pass turn")
snapshot.queue = { status = "none" }
view = Presentation.select(snapshot, 10, false, false)
assert(view.standaloneCarry and view.compactDetail == "8 COINS ON DELIVERY • QUICK BONUS +2")
view = Presentation.select(snapshot, 30, false, false)
assert(view.standaloneCarry and view.compactDetail == "8 COINS ON DELIVERY", "The compact objective keeps the normal reward after the optional bonus expires")
view = Presentation.select(snapshot, 10, true, false)
assert(not view.standaloneCarry, "Mounted play cannot expose a compact runner card")
snapshot.runner = { status = "idle", normalReward = 8 }
snapshot.station = { occupied = false }
view = Presentation.select(snapshot, 35, false, true)
assert(view.title == "PICK UP A READY PIZZA BOX" and view.visible)
view = Presentation.select(snapshot, 35, false, false)
assert(not view.visible)
print("PASS: activity presentation preserves honest unlimited/timed occupancy, contributor-independent runner rewards, queue priority and walking control")
