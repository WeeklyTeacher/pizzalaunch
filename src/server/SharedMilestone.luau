-- Session-only restaurant progress. No timers, AFK rewards or Record Run input.
local SharedMilestone = {}
SharedMilestone.__index = SharedMilestone

function SharedMilestone.new(dependencies)
	return setmetatable({ dependencies = dependencies, progress = 0, cycle = 1, contributors = {} }, SharedMilestone)
end

function SharedMilestone:snapshot()
	return { progress = self.progress, target = self.dependencies.target, cycle = self.cycle, reward = self.dependencies.reward }
end

function SharedMilestone:removePlayer(player)
	self.contributors[player] = nil
end

function SharedMilestone:contribute(player, source): boolean
	if (source ~= "freePlay" and source ~= "takeout") or not self.dependencies.isPresent(player) then return false end
	self.contributors[player] = true
	self.progress += 1
	if self.progress < self.dependencies.target then
		self.dependencies.notify(self:snapshot(), false)
		return true
	end
	-- Consume the cycle before callbacks: repeated/reentrant completion cannot
	-- award this contributor set twice. The caller owns successful service facts.
	local contributors, cycle = self.contributors, self.cycle
	self.contributors = {}
	self.progress = 0
	self.cycle += 1
	for contributor in contributors do
		if self.dependencies.isPresent(contributor) then
			self.dependencies.award(contributor, self.dependencies.reward, cycle)
		end
	end
	self.dependencies.notify(self:snapshot(), true)
	return true
end

return SharedMilestone
