local loadModule = require("./support/LoadModule")
local worldFixture = require("./support/WorldFixture")
local roblox = require("@lune/roblox")
local clock, jobs, heartbeatListeners = 100, {}, {}
local heartbeat = {}
function heartbeat:Connect(callback)
	local connection = { Connected = true }
	function connection:Disconnect() self.Connected = false end
	table.insert(heartbeatListeners, { callback = callback, connection = connection })
	return connection
end
local scheduler = {}
local function resume(thread, ...)
	local success, delay = coroutine.resume(thread, ...)
	assert(success, tostring(delay))
	if coroutine.status(thread) ~= "dead" then table.insert(jobs, { thread = thread, at = clock + (delay or 0) }) end
end
function scheduler.spawn(callback, ...)
	local thread = coroutine.create(callback)
	resume(thread, ...)
end
function scheduler.wait(duration) return coroutine.yield(duration or 0) end
function scheduler.delay(duration, callback) table.insert(jobs, { thread = coroutine.create(callback), at = clock + duration }) end
local function advance(duration)
	local finish = clock + duration
	while clock < finish - 0.00001 do
		local nextTime = math.min(finish, clock + 0.05)
		table.sort(jobs, function(a, b) return a.at < b.at end)
		local job = jobs[1]
		if job and job.at <= nextTime then
			clock = job.at
			table.remove(jobs, 1)
			resume(job.thread)
		else clock = nextTime end
		for _, listener in heartbeatListeners do if listener.connection.Connected then listener.callback(0.1) end end
	end
end
local tweens, proxyTweens = {}, 0
local tweenService = {}
function tweenService:Create(object, _, target)
	if target.CFrame and object.Name == "Head" and object:GetAttribute("CustomerRenderProxy") then proxyTweens += 1 end
	local tween = { cancelled = false }
	function tween:Play()
		if self.cancelled then return end
		for key, value in target do
			object[key] = value
			if key == "CFrame" then object.Position = value.Position end
		end
	end
	function tween:Cancel() self.cancelled = true end
	table.insert(tweens, tween)
	return tween
end
local services = {}
for _, name in { "Workspace", "Lighting", "StarterGui", "ReplicatedStorage" } do services[name] = roblox.Instance.new(name) end
local config = loadModule("src/shared/Config.luau")
local world = worldFixture(services, config).build()
for _, item in world:GetDescendants() do if item:IsA("BasePart") then item.Position = item.CFrame.Position end end
local originals, customers = {}, {}
local customer = world.Table_1_Mia.Customer
for _, definition in config.TABLES do
	local model = world:FindFirstChild(string.format("Table_%d_%s", definition.id, definition.customer))
	customers[definition.id] = model.Customer
	for _, part in model.Customer:GetDescendants() do
		if part:IsA("BasePart") then originals[part] = { frame = part.CFrame, size = part.Size, collide = part.CanCollide, touch = part.CanTouch, query = part.CanQuery } end
	end
end
local boundary = {
	game = { GetService = function(_, name)
		if name == "RunService" then return { Heartbeat = heartbeat } end
		if name == "TweenService" then return tweenService end
		assert(name == "Workspace")
		return { GetServerTimeNow = function() return clock end }
	end },
	task = scheduler, TweenInfo = { new = function(...) return { ... } end },
}
local Rig = loadModule("src/server/CustomerRig.luau", boundary)
local dialogue = loadModule("src/server/CustomerDialogue.luau")
boundary.script = { Parent = { CustomerRig = "CustomerRig", CustomerDialogue = "CustomerDialogue" } }
boundary.require = function(name) return name == "CustomerRig" and Rig or dialogue end
local service = loadModule("src/server/CustomerService.luau", boundary)
service.start(world)
local visual = customer:FindFirstChild("ArticulatedCustomer")
local function connectedCount()
	local count = 0
	for _, item in heartbeatListeners do if item.connection.Connected then count += 1 end end
	return count
end
assert(connectedCount() == 6, "one bounded render loop for each current table")
for part, saved in originals do
	assert(part.CFrame == saved.frame and part.Size == saved.size)
	assert(part.CanCollide == saved.collide and part.CanTouch == saved.touch and part.CanQuery == saved.query,
		"art must preserve every original contact proxy")
	assert(part.Transparency == 1 and part:GetAttribute("CustomerRenderProxy"))
end
local function inspectBudget()
	local totalParts, totalJoints = 0, 0
	for _, actor in customers do
		local parts, joints = 0, 0
		local rig = assert(actor:FindFirstChild("ArticulatedCustomer"))
		for _, item in rig:GetDescendants() do
			if item:IsA("BasePart") then
				parts += 1
				assert(item.Massless and not item.CanCollide and not item.CanTouch and not item.CanQuery and item:GetAttribute("CustomerVisual"))
				assert(item:GetAttribute("CustomerPart") == nil and item:GetAttribute("DeliverySurface") == nil)
				assert(item:GetAttribute("CustomerAuthoredCFrame") == nil and item:GetAttribute("ResetCFrame") == nil,
					"legacy lifecycle loops must exclude rig art")
			elseif item:IsA("Motor6D") then joints += 1; assert(item.Part0 and item.Part1) end
		end
		assert(parts <= 32 and joints == 10, "bounded articulated rig budget")
		totalParts += parts
		totalJoints += joints
	end
	assert(totalParts <= 192 and totalJoints == 60)
	return totalParts
end
local initialParts = inspectBudget()
local repeated = assert(Rig.install(customer))
assert(Rig.install(customer) == repeated and connectedCount() == 6, "repeat install cannot duplicate rigs/connections")
local duplicate = customer:Clone()
duplicate.Parent = world
assert(Rig.install(duplicate) == nil, "only one active rig per table")
duplicate:SetAttribute("TableId", 7)
assert(Rig.install(duplicate) == nil, "no seventh active rig")
duplicate:Destroy()
local stepCalls, step = 0, Rig.step
Rig.step = function(self, time) stepCalls += 1; return step(self, time) end
for _ = 1, 9 do
	for _, listener in heartbeatListeners do if listener.connection.Connected then listener.callback(0.01) end end
end
assert(stepCalls == 0, "render loop does no pose work before its tenth-second budget")
for _, listener in heartbeatListeners do if listener.connection.Connected then listener.callback(0.02) end end
assert(stepCalls == 6, "all six rigs update once, without per-frame pose work")
Rig.step = step

local layout = loadModule("src/server/LayoutService.luau")
layout.start(world)
for _, round in { 1, 3, 4, 1 } do
	layout.setRound(round)
	for _, actor in customers do
		assert(actor.Head.Transparency == 1 and actor.Head.Face.Enabled == false)
		assert(actor.ArticulatedCustomer.Head.Transparency == 0, "round props cannot hide/reveal customer art or its proxies")
	end
end
assert(customer.Head.Face.Enabled == false and service.isDeliverable(1))
advance(0.1)
assert(visual:GetAttribute("VisualPose") == "Sit")
advance(0.5)
assert(visual:GetAttribute("VisualPose") == "Idle")
advance(9.1)
assert(visual:GetAttribute("VisualPose") == "Wait")
assert(service.claimDelivery(1) and not service.claimDelivery(1))
service.served(1)
advance(0.1)
assert(visual:GetAttribute("VisualPose") == "Cheer" and not service.isDeliverable(1))
advance(1.59)
assert(customer:GetAttribute("CustomerState") == "HappyReaction", "service reaction lasts original 1.7 seconds")
advance(0.02)
assert(customer:GetAttribute("CustomerState") == "Eating" and visual:GetAttribute("VisualPose") == "Eat")
advance(1.05)
assert(customer:GetAttribute("CustomerState") == "Leaving" and visual:GetAttribute("VisualPose") == "Leave")
local departing = customer.PrimaryPart.CFrame
service.clearFeedback(customer)
assert(customer.PrimaryPart.CFrame == departing and not service.isDeliverable(1), "feedback cleanup cannot snap lifecycle root")
advance(4.5)
assert(customer:GetAttribute("CustomerState") == "Entering" and visual:GetAttribute("VisualPose") == "Walk")
advance(2.6)
assert(service.isDeliverable(1) and customer:GetAttribute("CustomerState") == "SeatedWaiting")
for part in originals do assert(part.Transparency == 1, "arrival fade must not expose proxy body") end
assert(customer.Head.Face.Enabled == false)
service.hit(1)
advance(0.1)
assert(visual:GetAttribute("VisualPose") == "Startled")
advance(1.5)
assert(service.isDeliverable(1), "hit reaction preserves original 1.55-second availability")
customer:SetAttribute("ReactionToken", 90)
service.feedbackReaction(customer, "crowd", 90)
advance(0.1)
assert(visual:GetAttribute("VisualPose") == "Cheer")
service.clearFeedback(customer)
assert(visual:GetAttribute("VisualPose") ~= "Cheer")

-- Actual lease-owned feedback reaches all six render rigs and keeps bystanders
-- from clearing another operator's poses or invalidating their pending work.
local owner, walker = {}, {}
local Feedback = loadModule("src/server/CustomerFeedback.luau", boundary)
local feedback = Feedback.new({
	getOwner = function() return owner end,
	worldTable = function(id) return customers[id].Parent end,
	customerService = service,
})
for id in customers do assert(feedback:react(id, "crowd")) end
advance(0.1)
local tokens = {}
for id, actor in customers do
	tokens[id] = actor:GetAttribute("ReactionToken")
	assert(actor.ArticulatedCustomer:GetAttribute("VisualPose") == "Cheer")
end
assert(not feedback:clear(walker))
for id, actor in customers do
	assert(actor:GetAttribute("ReactionToken") == tokens[id] and actor.ArticulatedCustomer:GetAttribute("VisualPose") == "Cheer")
end
assert(feedback:clear(owner))
for _, actor in customers do
	assert(actor.ArticulatedCustomer:GetAttribute("VisualPose") ~= "Cheer")
	assert(actor.Head.CFrame == actor.Head:GetAttribute("ResetCFrame"), "owner exit restores proxy seat without changing lifecycle")
end
advance(0.9)
for id in customers do assert(feedback:react(id, "crowd")) end
advance(0.4)
for _, actor in customers do assert(actor.ArticulatedCustomer:GetAttribute("VisualPose") == "Cheer", "former lease callback cannot end new reactions") end
feedback:clear(owner)

for id in customers do assert(service.claimDelivery(id)); service.served(id) end
advance(6.3)
for _, round in { 4, 1 } do
	layout.setRound(round)
	for id, actor in customers do
		assert(actor:GetAttribute("CustomerState") == "Despawn" and not service.isDeliverable(id))
		assert(actor.ArticulatedCustomer.Head.Transparency == 1 and actor.Head.Transparency == 1,
			"round changes cannot reveal despawned guests or legacy proxies")
	end
end
advance(5)
for id, actor in customers do
	assert(service.isDeliverable(id) and actor.ArticulatedCustomer.Head.Transparency == 0 and actor.Head.Transparency == 1)
end
local identities, accessories = {}, {}
for _ = 1, 12 do
	identities[service.getInfo(1).name] = true
	accessories[customer.ArticulatedCustomer:GetAttribute("AccessoryStyle")] = true
	assert(service.claimDelivery(1))
	service.served(1)
	advance(11)
	assert(service.isDeliverable(1))
	identities[service.getInfo(1).name] = true
	accessories[customer.ArticulatedCustomer:GetAttribute("AccessoryStyle")] = true
	inspectBudget()
end
local identityCount, accessoryCount = 0, 0
for _ in identities do identityCount += 1 end
for _ in accessories do accessoryCount += 1 end
assert(identityCount == 12 and accessoryCount == 3,
	string.format("all original identities and source accessories survive turnover (got %d identities/%d accessories)", identityCount, accessoryCount))

local previous, oldConnections = {}, {}
for id, actor in customers do previous[id] = actor.ArticulatedCustomer end
for _, listener in heartbeatListeners do if listener.connection.Connected then table.insert(oldConnections, listener.connection) end end
assert(service.claimDelivery(1))
service.served(1)
service.start(world)
for id, old in previous do assert(old.Parent == nil and service.isDeliverable(id)) end
for _, connection in oldConnections do assert(not connection.Connected) end
assert(connectedCount() == 6, "restart releases every old rig before creating its replacement")
advance(1.8)
assert(service.isDeliverable(1), "old lifecycle callback must not change restarted rig/availability")
-- Restart while the former idle coroutine is suspended in its initial wait.
-- Its next wake occurs before the replacement idle loop's first pose update.
service.start(world)
local proxyTweensBefore = proxyTweens
advance(1.3)
assert(proxyTweens == proxyTweensBefore, "old idle coroutine must revalidate identity after yielding")
local current = customer:FindFirstChild("ArticulatedCustomer")
for _, actor in customers do actor.Parent = nil end
advance(0.1)
assert(current.Parent == nil and connectedCount() == 0, "all removed rigs release animation listeners")
print(string.format("PASS: six actual customer rigs (%d initial render parts/60 joints), 10Hz cap, 12 identities/eight poses, lifecycle/proxy/round isolation, owner cleanup and restart/removal", initialParts))
