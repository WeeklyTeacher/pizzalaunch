local loadModule = require("./support/LoadModule")
local roblox = require("@lune/roblox")
local V = roblox.Vector3
local config = loadModule("src/shared/Config.luau")
local services = {}
for _, name in { "Workspace", "Lighting", "StarterGui", "ReplicatedStorage" } do services[name] = roblox.Instance.new(name) end
local world = require("./support/WorldFixture")(services, config).build()
local facade = world.StorefrontExterior
local proxy, visuals, doors = nil, 0, {}
for _, item in facade:GetChildren() do
	if item.Name == "FrontFacade" and item.CFrame.Position.X == 21.5 then proxy = item end
	if item:GetAttribute("HeroFacadeVisual") then
		visuals += 1
		assert(not item.CanCollide and not item.CanTouch and not item.CanQuery)
	end
	if item.Name == "PlayerEntranceDoor" then table.insert(doors, item.CFrame.Position) end
end
assert(proxy and proxy.CanCollide and proxy.Transparency == 1)
assert(proxy.Size == V.new(55, 18, 2) and proxy.CFrame.Position == V.new(21.5, 8, 72))
assert(visuals == 9 and #doors == 2)
assert((doors[1] == V.new(-20, 6, 71) and doors[2] == V.new(-12, 6, 71)) or (doors[2] == V.new(-20, 6, 71) and doors[1] == V.new(-12, 6, 71)))
local function intersects(part, startPoint, finishPoint)
	local a = part.CFrame:PointToObjectSpace(startPoint)
	local direction = part.CFrame:PointToObjectSpace(finishPoint) - a
	local half = part.Size / 2
	local low, high = 0, 1
	for _, axis in { "X", "Y", "Z" } do
		if math.abs(direction[axis]) < 0.00001 then
			if math.abs(a[axis]) > half[axis] then return false end
		else
			local first = (-half[axis] - a[axis]) / direction[axis]
			local last = (half[axis] - a[axis]) / direction[axis]
			low, high = math.max(low, math.min(first, last)), math.min(high, math.max(first, last))
			if low > high then return false end
		end
	end
	return true
end
local station = world.LauncherStation
local targets = { station.PizzaFeedOven.CFrame.Position, station.OvenGlow.CFrame.Position, station.FeedBelt.CFrame.Position, station.PressureGauge.CFrame.Position }
assert(intersects(proxy, V.new(-16, 6.5, 84), station.PizzaFeedOven.CFrame.Position), "Fixture must reproduce the former opaque-wall obstruction")
local visibleRays = 0
for _, eye in { V.new(-16, 6.5, 84), V.new(-16, 8, 92), V.new(0, 6.5, 84) } do
	for _, target in targets do
		for _, item in facade:GetDescendants() do
			if item:IsA("BasePart") and item.Transparency < 0.7 and item.Material ~= roblox.Enum.Material.Glass then
				assert(not intersects(item, eye, target), "Hero view blocked by " .. item.Name .. " from " .. tostring(eye))
			end
		end
		visibleRays += 1
	end
end
local hero = world:FindFirstChild("Table_1_Mia")
assert(hero.BoothSeat.Material == roblox.Enum.Material.Fabric and hero.BoothSeat.Transparency == 1)
assert(hero.BoothBack.Material == roblox.Enum.Material.Fabric and hero.BoothBack.Transparency == 1)
for _, pair in { { hero.BoothSeat, hero.HeroBoothSeat }, { hero.BoothBack, hero.HeroBoothBack } } do
	local physical, visible = pair[1], pair[2]
	assert(physical.Size == visible.Size and physical.CFrame == visible.CFrame)
	assert(physical.CanCollide and not visible.CanCollide and not visible.CanTouch and not visible.CanQuery)
	assert(visible.Material == roblox.Enum.Material.SmoothPlastic)
end
assert(hero.Rug.Material == roblox.Enum.Material.SmoothPlastic and not hero.Rug.CanCollide)
print(string.format("PASS: hero facade keeps original collision/doors, %d sampled oven/tray/gauge view rays are unobstructed; first booth material changes are nonphysical", visibleRays))
