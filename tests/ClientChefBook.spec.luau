local loadModule = require("./support/LoadModule")
local config = loadModule("src/shared/MasteryConfig.luau")
local Presentation = loadModule("src/client/ChefBookPresentation.luau")
for _, status in { "loading", "loadFailed", "locked", "leaseLost", "malformed", "unsupported", "unavailable" } do
	local snapshot = { status = status, isNew = nil, earnedCosmetics = { plain = true } }
	assert(not Presentation.canEquip(snapshot, "plain"))
	assert(not Presentation.status(snapshot):find("NEW CHEF"), "Failed/unknown profiles cannot be introduced as new players")
	assert(not Presentation.status(snapshot):find("CHEF BOOK SAVED"))
end
local profile = { status = "memory", isNew = nil, persistenceAvailable = true, mastery = { deliveries = 9, takeout = 1, perfect = 0 },
	earnedCosmetics = { plain = true }, equipped = "plain" }
assert(Presentation.status(profile):find("LOCAL TEST") and not Presentation.status(profile):find("SAVED"))
local progress, complete = Presentation.goal(profile, config.goals[1])
assert(progress == "9 / 10" and not complete)
local _, action, enabled = Presentation.cosmetic(profile, "basil", config.cosmetics.basil)
assert(action == "LOCKED" and not enabled and not Presentation.canEquip(profile, "basil"))
profile.earnedCosmetics.basil, profile.mastery.deliveries = true, 10
progress, complete = Presentation.goal(profile, config.goals[1])
assert(complete and progress:find("COMPLETE"))
_, action, enabled = Presentation.cosmetic(profile, "basil", config.cosmetics.basil)
assert(action == "EQUIP" and enabled)
profile.equipped = "basil"
_, action, enabled = Presentation.cosmetic(profile, "basil", config.cosmetics.basil)
assert(action == "EQUIPPED" and not enabled)
profile.status, profile.dirty, profile.isNew = "ready", true, true
profile.durable = true
assert(Presentation.status(profile):find("PENDING"))
profile.dirty = false
assert(Presentation.status(profile):find("NEW CHEF BOOK"))
profile.isNew = false
assert(Presentation.status(profile) == "CHEF BOOK SAVED")
profile.status = "saveFailed"
profile.persistenceAvailable = false
assert(Presentation.status(profile):find("not confirmed saved"))
assert(not Presentation.canEquip(profile, "plain"), "Unavailable saving disables equip requests until the server confirms readiness")
profile.status, profile.dirty, profile.durable = "ready", false, false
assert(not Presentation.status(profile):find("CHEF BOOK SAVED") and not Presentation.canEquip(profile, "plain"), "Expired ready snapshots must not claim confirmed durability")
print("PASS: Chef Book distinguishes local/new/failed/pending profiles, earned-only choices and counter goals without optimistic ownership")
