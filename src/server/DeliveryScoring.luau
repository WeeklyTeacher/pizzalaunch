local DeliveryScoring = {}

function DeliveryScoring.accuracy(config, tablePosition, hitPosition, state, recordSession)
	local distance = Vector3.new(hitPosition.X - tablePosition.X, 0, hitPosition.Z - tablePosition.Z).Magnitude
	local round = config.ROUNDS[math.clamp(state.round, 1, #config.ROUNDS)]
	local scale = recordSession and 1.12 or (1 + state.upgrades.assist * 0.12) * round.accuracyScale
	local accuracy = config.ACCURACY[#config.ACCURACY]
	for _, tier in config.ACCURACY do
		if distance <= tier.radius * scale then accuracy = tier; break end
	end
	return accuracy, math.floor(distance * 10 + 0.5) / 10
end

function DeliveryScoring.freePlayReward(accuracy, combo, tipsLevel)
	local comboBonus = math.min((combo - 1) * 2, 12)
	local base = accuracy.coins + comboBonus
	return math.floor(base * (1 + tipsLevel * 0.25) + 0.5), comboBonus, base
end

return DeliveryScoring
