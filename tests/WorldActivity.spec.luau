local loadModule = require("./support/LoadModule")
local roblox = require("@lune/roblox")
local config = loadModule("src/shared/Config.luau")
local services = {}
for _, name in { "Workspace", "Lighting", "StarterGui", "ReplicatedStorage" } do services[name] = roblox.Instance.new(name) end
local world = require("./support/WorldFixture")(services, config).build()
local fan = world:FindFirstChild("KitchenVentFan", true)
assert(fan and fan:GetAttribute("SourceOwnedAmbient"))
assert(not world:FindFirstChild("AmbientStreetPedestrian", true), "Sideways street glider was not retired")
local windows, blades, authored = {}, {}, {}
for _, item in world:GetDescendants() do
	if item:IsA("BasePart") and item.Name == "RestaurantWindow" then windows[item] = item.Transparency end
end
for _, item in fan:GetDescendants() do
	if item:IsA("BasePart") then
		assert(not item.CanCollide and not item.CanTouch and not item.CanQuery)
		if item:GetAttribute("FanBlade") then
			table.insert(blades, item)
			authored[item] = item.CFrame
		end
	end
end
assert(#blades == 3)
local heartbeat = { connections = {} }
function heartbeat:Connect(callback)
	local connection = { connected = true, callback = callback }
	function connection:Disconnect() self.connected = false end
	table.insert(self.connections, connection)
	return connection
end
function heartbeat:fire(dt)
	for _, connection in self.connections do
		if connection.connected then connection.callback(dt) end
	end
end
local function countConnections()
	local count = 0
	for _, item in heartbeat.connections do if item.connected then count += 1 end end
	return count
end
local activity = loadModule("src/server/WorldActivityService.luau", {
	game = { GetService = function(_, name)
		assert(name == "RunService", "Ambient motion must not create unowned TweenService work")
		return { Heartbeat = heartbeat }
	end },
	task = setmetatable({}, { __index = function() error("Ambient motion must not leave delayed or yielded tasks") end }),
})
local function restored()
	for _, blade in blades do
		if blade.Parent then assert(blade.CFrame == authored[blade], "Stop/restart must restore authored blade poses") end
	end
end
activity.start(world)
assert(countConnections() == 1)
local oldCallback = heartbeat.connections[1].callback
heartbeat:fire(0.04)
restored()
heartbeat:fire(0.09)
assert(blades[1].CFrame ~= authored[blades[1]], "Fan never rotates")
for _ = 1, 240 do
	heartbeat:fire(0.125)
	for _, blade in blades do
		local radius = (blade.CFrame.Position - fan.FanHub.CFrame.Position).Magnitude
		assert(math.abs(radius - 1.25) < 0.0001, "Ambient blade drifted out of its housing")
		assert(math.abs(blade.CFrame.Position.Z - fan.FanHub.CFrame.Position.Z) < 0.0001)
	end
end
for window, alpha in windows do assert(window.Transparency == alpha, "Glass must not pulse without a physical cause") end
activity.start(world)
assert(countConnections() == 1)
restored()
oldCallback(0.25)
restored()
heartbeat:fire(0.125)
assert(blades[1].CFrame ~= authored[blades[1]])
activity.stop()
activity.stop()
assert(countConnections() == 0)
restored()
heartbeat.connections[2].callback(0.25)
restored()
activity.start(world)
world.Parent = nil
heartbeat:fire(0.125)
assert(countConnections() == 0, "Detached world retains an update connection")
restored()
world.Parent = services.Workspace
fan:SetAttribute("SourceOwnedAmbient", false)
activity.start(world)
assert(countConnections() == 0, "Unowned fan must not be animated")
fan:SetAttribute("SourceOwnedAmbient", true)
activity.start(world)
local orphan = blades[1]
orphan.Parent = nil
heartbeat:fire(0.125)
assert(countConnections() == 0, "Removed blade leaves partial animation running")
restored()
orphan.Parent = fan
orphan:SetAttribute("FanAuthoredCFrame", nil)
activity.start(world)
assert(countConnections() == 0, "Incomplete authored fixture must not animate")
activity.stop()
print("PASS: actual source fan rotates in bounds at capped cadence; windows/proxies untouched; restart/stop/orphan/missing fixture and queued old callbacks clean up without tasks or tweens")
