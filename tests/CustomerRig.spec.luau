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
local originals = {}
local customer = world.Table_1_Mia.Customer
for _, part in customer:GetDescendants() do
	if part:IsA("BasePart") then originals[part] = { frame = part.CFrame, size = part.Size, collide = part.CanCollide, touch = part.CanTouch, query = part.CanQuery } end
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
assert(visual and not world.Table_2_Bo.Customer:FindFirstChild("ArticulatedCustomer"), "first hero only")
for part, saved in originals do
	assert(part.CFrame == saved.frame and part.Size == saved.size)
	assert(part.CanCollide == saved.collide and part.CanTouch == saved.touch and part.CanQuery == saved.query,
		"art must preserve every original contact proxy")
	assert(part.Transparency == 1 and part:GetAttribute("CustomerRenderProxy"))
end
local parts, joints = 0, 0
for _, item in visual:GetDescendants() do
	if item:IsA("BasePart") then
		parts += 1
		assert(item.Massless and not item.CanCollide and not item.CanTouch and not item.CanQuery and item:GetAttribute("CustomerVisual"))
		assert(item:GetAttribute("CustomerPart") == nil and item:GetAttribute("DeliverySurface") == nil)
		assert(item:GetAttribute("CustomerAuthoredCFrame") == nil and item:GetAttribute("ResetCFrame") == nil,
			"legacy lifecycle loops must exclude rig art")
	elseif item:IsA("Motor6D") then joints += 1; assert(item.Part0 and item.Part1) end
end
assert(parts <= 32 and joints == 10, "bounded articulated rig budget")
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
local previous = visual
local oldConnection = heartbeatListeners[1].connection
assert(service.claimDelivery(1))
service.served(1)
service.start(world)
assert(previous.Parent == nil and not oldConnection.Connected and service.isDeliverable(1))
advance(1.8)
assert(service.isDeliverable(1), "old lifecycle callback must not change restarted rig/availability")
-- Restart while the former idle coroutine is suspended in its initial wait.
-- Its next wake occurs before the replacement idle loop's first pose update.
service.start(world)
local proxyTweensBefore = proxyTweens
advance(1.3)
assert(proxyTweens == proxyTweensBefore, "old idle coroutine must revalidate identity after yielding")
local current = customer:FindFirstChild("ArticulatedCustomer")
customer.Parent = nil
advance(0.1)
assert(current.Parent == nil and not heartbeatListeners[#heartbeatListeners].connection.Connected)
print("PASS: actual CustomerService/Rig preserve proxies, service timing and availability; all eight poses, one hero, rig budget, visibility, restart/removal cleanup")
