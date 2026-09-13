local loadModule = require("./support/LoadModule")
local roblox = require("@lune/roblox")
local Analytics = loadModule("src/server/JourneyAnalytics.luau")
local now, calls = 0, {}
local analytics = Analytics.new({clock=function()return now end,emit=function(player,event,fields)
	table.insert(calls,{player=player,event=event,fields=fields})
	assert(not pcall(function()fields.CustomField01="tampered"end))
end})
local direct,blocked={},{ }
assert(analytics:addPlayer(direct) and not analytics:addPlayer(direct))
analytics:addPlayer(blocked)
analytics:occupied(blocked)
analytics:mounted(direct)
analytics:mounted(blocked)
assert(analytics:snapshot(direct).cohort=="direct" and analytics:snapshot(blocked).cohort=="blocked")
analytics:occupied(direct)
assert(analytics:snapshot(direct).cohort=="direct", "Later occupancy cannot rewrite initial cohort")
assert(not analytics:emit(direct,"InventedEvent","freePlay","started"))
assert(not analytics:emit(direct,"ModeSelected","user_123456","selected"))
assert(not analytics:emit(direct,"ModeSelected","freePlay","raw error token"))
assert(analytics:emit(direct,"FirstLaunch","freePlay","accepted"))
now=20
assert(not analytics:emit(direct,"FirstLaunch","recordRun","accepted"))
analytics:recordStarted(direct)
analytics:recordStarted(direct)
now+=1
analytics:recordStarted(direct)
assert(analytics:snapshot(direct).counts.RecordRunStarted==2 and analytics:snapshot(direct).counts.AnotherRecordRunStarted==1)
analytics:takeoutCompleted(blocked)
now+=12
analytics:takeoutStarted(blocked)
now+=1
analytics:takeoutStarted(blocked)
assert(analytics:snapshot(blocked).counts.ImmediateRunnerReplay==1)
analytics:takeoutCompleted(blocked)
now+=21
analytics:takeoutStarted(blocked)
assert(analytics:snapshot(blocked).counts.ImmediateRunnerReplay==1)
for _=1,50 do analytics:occupied(blocked) end
assert(analytics:snapshot(blocked).counts.OccupiedRejection==2, "Repeated interaction must be bounded")
local character=roblox.Instance.new("Model")
character.Parent=roblox.Instance.new("Folder")
local humanoid=roblox.Instance.new("Humanoid")
humanoid.Health=100;humanoid.Parent=character
local root=roblox.Instance.new("Part")
root.Name="HumanoidRootPart";root.Anchored=false;root.Position=roblox.Vector3.zero;root.Parent=character
direct.Character=character
local context={state={mode="walk",cleanupEpoch=4},spawnPosition=roblox.Vector3.zero,launcherPosition=roblox.Vector3.new(40,0,0)}
assert(not analytics:uiAction(direct,"routeStarted",3,character,context))
assert(not analytics:uiAction(direct,"routeStarted",4,roblox.Instance.new("Model"),context))
assert(not analytics:uiAction(direct,"score",4,character,context))
assert(not analytics:uiAction(direct,"launcherReached",4,character,context))
assert(analytics:uiAction(direct,"routeStarted",4,character,context))
assert(not analytics:uiAction(direct,"routeStarted",4,character,context))
root.Position=context.launcherPosition
humanoid.Health=0
assert(not analytics:uiAction(direct,"launcherReached",4,character,context))
humanoid.Health=100;root.Anchored=true
assert(not analytics:uiAction(direct,"launcherReached",4,character,context))
root.Anchored=false;context.state.mode="launcher"
assert(not analytics:uiAction(direct,"launcherReached",4,character,context))
context.state.mode="walk"
for _,invalid in {0/0, math.huge, -math.huge} do
	root.Position=roblox.Vector3.new(invalid,0,0)
	assert(not analytics:uiAction(direct,"launcherReached",4,character,context))
end
root.Position=context.launcherPosition
for _,invalid in {0/0, math.huge, -math.huge} do
	humanoid.Health=invalid
	assert(not analytics:uiAction(direct,"launcherReached",4,character,context))
end
humanoid.Health=100
assert(analytics:uiAction(direct,"launcherReached",4,character,context))
local snapshot=analytics:snapshot(direct)
snapshot.counts.Joined=100
assert(analytics:snapshot(direct).counts.Joined==1)
analytics:removePlayer(blocked);analytics:removePlayer(blocked)
assert(not analytics:snapshot(blocked))
local failing=Analytics.new({clock=function()return now end,emit=function()error("SDK unavailable")end})
assert(failing:addPlayer(direct) and failing:emit(direct,"ProfileLoadFailure","profile","failed"))
assert(not failing:emit(direct,"ProfileLoadFailure","profile","failed"))
for _=1,120 do now+=.21;analytics:emit(direct,"ModeSelected","freePlay","selected") end
assert(#analytics:snapshot(direct).recent<=24)
for _,call in calls do
	local count=0;for key,value in call.fields do count+=1;assert(key=="CustomField01" or key=="CustomField02" or key=="CustomField03");assert(typeof(value)=="string")end
	assert(count==3)
end
print("PASS: journey cohorts, once/replay counters, bounded fields/diagnostics/rates, failing sink, detached snapshots and validated UI route requests")

-- Execute the actual default SDK adapter through engine boundaries. Studio and
-- unpublished servers must never obtain AnalyticsService or schedule sends.
local function adapter(studio, placeId, shouldFail)
	local deferred, sdkCalls, serviceReads = {}, 0, 0
	local Module = loadModule("src/server/JourneyAnalytics.luau", {
		game = { PlaceId=placeId, GetService=function(_,name)
			if name=="RunService" then return {IsStudio=function()return studio end} end
			assert(name=="AnalyticsService"); serviceReads+=1
			return {LogCustomEvent=function(_,player,event,value,fields)
				sdkCalls+=1; assert(value==1 and fields.CustomField01=="unmounted")
				if shouldFail then error("backend failed") end
			end}
		end },
		task = {defer=function(callback)table.insert(deferred,callback)end},
	})
	return Module.new(), deferred, function()return sdkCalls,serviceReads end
end
for _,environment in {{true,123},{false,0}} do
	local isolated, deferred, counts=adapter(environment[1],environment[2],false)
	isolated:addPlayer({})
	assert(#deferred==0 and counts()==0)
end
local production,deferred,counts=adapter(false,123,true)
for _=1,100 do production:addPlayer({}) end
assert(#deferred==64 and counts()==0, "Default telemetry must defer and bound pending SDK work")
for _,callback in deferred do assert(pcall(callback)) end
assert(counts()==64)
production:addPlayer({})
assert(#deferred==65, "SDK failures must release the pending budget")
print("PASS: actual analytics adapter gates Studio/unpublished, bounds/defer calls and survives SDK failures")
