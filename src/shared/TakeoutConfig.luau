-- Walking service uses session coins and its own destinations. These positions
-- are outside the restaurant's customer paths and forward projectile lanes.
local TakeoutConfig = {
	pickupPosition = Vector3.new(-50, 3, 98),
	destinations = {
		{ id = "sunnyScoops", name = "SUNNY SCOOPS", position = Vector3.new(44, 3, 152),
			approachPositions = { Vector3.new(49, 3, 145), Vector3.new(49, 3, 152) } },
		{ id = "tinySprouts", name = "TINY SPROUTS", position = Vector3.new(82, 3, 152),
			approachPositions = { Vector3.new(82, 3, 145) } },
	},
	-- Crossing at the existing crosswalk avoids the parked pizza van. Guidance
	-- does not require checkpoints or punish a legitimate shorter walking route.
	-- Stay streetward of sidewalk bins/benches, then turn around each obstacle.
	routePositions = { Vector3.new(-16, 3, 100), Vector3.new(-16, 3, 145) },
	normalReward = 8,
	quickBonus = 2,
	quickBonusSeconds = 16,
	promptDistance = 10,
	requestInterval = 0.25,
	-- Tolerate ordinary avatar replication/jumping while rejecting immediate
	-- teleports and sustained implausible horizontal displacement.
	maxHorizontalSpeed = 24,
	positionSlack = 12,
}

return TakeoutConfig
