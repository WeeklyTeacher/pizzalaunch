-- Shift-only inventory mutation; this module never writes shared world instances.
local PlayerProgression = {}

function PlayerProgression.purchase(config, state, upgradeId, recordSession)
	local definition = typeof(upgradeId) == "string" and config.UPGRADES[upgradeId] or nil
	if not state or not definition then return nil, nil end
	if recordSession then return nil, "FINISH THE 1-MINUTE RECORD RUN FIRST" end
	local level = state.upgrades[upgradeId]
	local cost = definition.costs[level + 1]
	if not cost then return nil, "MAX LEVEL!" end
	if state.coins < cost then return nil, "NEED MORE COINS", cost end
	state.coins -= cost
	state.upgrades[upgradeId] = level + 1
	return { definition = definition, oldLevel = level, newLevel = level + 1 }, nil
end

return PlayerProgression
