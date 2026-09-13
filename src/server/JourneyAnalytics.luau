-- Server-only journey counters. No identifiers, error strings or client fields
-- are sent as custom dimensions. Analytics failures cannot interrupt gameplay.
local JourneyAnalytics = {}
JourneyAnalytics.__index = JourneyAnalytics

local EVENTS = {
	Joined=true, LauncherRouteStarted=true, LauncherReached=true, Mounted=true,
	ModeSelected=true, FirstLaunch=true, FirstSuccessfulDelivery=true,
	RoundOneCompleted=true, FirstEarnedUpgrade=true, OccupiedRejection=true,
	QueueJoined=true, QueueAccepted=true, QueueAbandoned=true,
	TakeoutOrderStarted=true, TakeoutOrderCompleted=true, ImmediateRunnerReplay=true,
	RecordRunStarted=true, RecordRunCompleted=true, RecordRunCancelled=true,
	NewPersonalBest=true, AnotherRecordRunStarted=true,
	ProfileLoadFailure=true, ProfileSaveFailure=true, SessionEnded=true,
}
local ONCE = {
	Joined=true, LauncherRouteStarted=true, LauncherReached=true, FirstLaunch=true,
	FirstSuccessfulDelivery=true, RoundOneCompleted=true, FirstEarnedUpgrade=true,
	SessionEnded=true,
}
local ACTIVITY = { lobby=true, onboarding=true, freePlay=true, recordRun=true, takeout=true, queue=true, profile=true }
local OUTCOME = { started=true, completed=true, cancelled=true, accepted=true, rejected=true, failed=true, locked=true, selected=true, earned=true, left=true }

function JourneyAnalytics.new(dependencies)
	local deps = dependencies or { clock = os.clock }
	if not dependencies then
		local enabled = not game:GetService("RunService"):IsStudio() and game.PlaceId > 0
		local pending = 0
		deps.emit = function(player, event, fields)
			if not enabled or pending >= 64 then return end
			pending += 1
			-- SDK latency never holds a gameplay callback open. Bounded deferred
			-- work may drop telemetry under overload; gameplay is unaffected.
			task.defer(function()
				pcall(function() game:GetService("AnalyticsService"):LogCustomEvent(player, event, 1, fields) end)
				pending -= 1
			end)
		end
	end
	return setmetatable({ dependencies=deps, sessions={} }, JourneyAnalytics)
end

function JourneyAnalytics:emit(player, event, activity, outcome)
	local session = self.sessions[player]
	if not session or not EVENTS[event] or not ACTIVITY[activity] or not OUTCOME[outcome] then return false end
	local now = self.dependencies.clock()
	if ONCE[event] and session.counts[event] then return false end
	-- Rejections/load faults can be retriggered rapidly; bound each named stream.
	local minimum = (event == "OccupiedRejection" or event == "ProfileLoadFailure" or event == "ProfileSaveFailure") and 10 or .2
	if session.last[event] and now-session.last[event] < minimum then return false end
	if now-session.windowStart >= 60 then session.windowStart,session.windowCount=now,0 end
	if session.windowCount >= 90 then return false end
	session.windowCount += 1
	session.last[event] = now
	session.counts[event] = (session.counts[event] or 0)+1
	local fields = table.freeze({ CustomField01=session.cohort, CustomField02=activity, CustomField03=outcome })
	local receipt = table.freeze({ event=event, fields=fields })
	table.insert(session.recent,receipt)
	if #session.recent > 24 then table.remove(session.recent,1) end
	-- Mark before the sink: reentrancy and a failing/yielding SDK call cannot
	-- duplicate once-per-session events or mutate the frozen diagnostic receipt.
	if self.dependencies.emit then pcall(self.dependencies.emit,player,event,fields) end
	return true
end

function JourneyAnalytics:addPlayer(player)
	if self.sessions[player] then return false end
	self.sessions[player] = { cohort="unmounted", counts={}, last={}, recent={}, windowStart=self.dependencies.clock(),windowCount=0, mounted=false, recordRuns=0 }
	return self:emit(player,"Joined","lobby","started")
end

function JourneyAnalytics:occupied(player)
	local s=self.sessions[player]
	if not s then return end
	if not s.mounted then s.cohort="blocked" end
	self:emit(player,"OccupiedRejection","queue","rejected")
end

function JourneyAnalytics:mounted(player)
	local s=self.sessions[player]
	if not s then return end
	if not s.mounted and s.cohort~="blocked" then s.cohort="direct" end
	s.mounted=true
	self:emit(player,"Mounted","lobby","accepted")
end

function JourneyAnalytics:recordStarted(player)
	local s=self.sessions[player]
	if not s then return end
	if self:emit(player,"RecordRunStarted","recordRun","started") then
		s.recordRuns += 1
		if s.recordRuns > 1 then self:emit(player,"AnotherRecordRunStarted","recordRun","started") end
	end
end

function JourneyAnalytics:takeoutCompleted(player)
	local s=self.sessions[player]
	if not s then return end
	if self:emit(player,"TakeoutOrderCompleted","takeout","completed") then s.lastTakeoutCompleted=self.dependencies.clock() end
end

function JourneyAnalytics:takeoutStarted(player)
	local s=self.sessions[player]
	if not s then return end
	if self:emit(player,"TakeoutOrderStarted","takeout","started") then
		local finished=s.lastTakeoutCompleted
		s.lastTakeoutCompleted=nil
		if finished and self.dependencies.clock()-finished <= 20 then self:emit(player,"ImmediateRunnerReplay","takeout","started") end
	end
end

function JourneyAnalytics:uiAction(player, action, epoch, character, context)
	if action~="routeStarted" and action~="launcherReached" then return false end
	if not context or not context.state or context.state.mode~="walk" or epoch~=context.state.cleanupEpoch then return false end
	if character~=player.Character or not character or not character.Parent then return false end
	local humanoid=character:FindFirstChildOfClass("Humanoid")
	local root=character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health~=humanoid.Health or humanoid.Health<=0 or humanoid.Health==math.huge or not root or not root:IsA("BasePart") or root.Anchored then return false end
	local position=root.Position
	if position.X~=position.X or position.Y~=position.Y or position.Z~=position.Z then return false end
	if action=="routeStarted" then
		if (position-context.spawnPosition).Magnitude>30 then return false end
		return self:emit(player,"LauncherRouteStarted","onboarding","started")
	end
	if (position-context.launcherPosition).Magnitude>14 then return false end
	return self:emit(player,"LauncherReached","onboarding","completed")
end

function JourneyAnalytics:snapshot(player)
	local s=self.sessions[player]
	if not s then return nil end
	return { cohort=s.cohort, counts=table.clone(s.counts), recent=table.clone(s.recent) }
end

function JourneyAnalytics:removePlayer(player)
	if not self.sessions[player] then return end
	self:emit(player,"SessionEnded","lobby","left")
	self.sessions[player]=nil
end

return JourneyAnalytics
