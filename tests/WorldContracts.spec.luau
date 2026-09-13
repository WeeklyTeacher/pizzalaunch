local loadModule = require("./support/LoadModule")
local roblox = require("@lune/roblox")
local config = loadModule("src/shared/Config.luau")
local services = {}
for _, name in { "Workspace", "Lighting", "StarterGui", "ReplicatedStorage" } do
	services[name] = roblox.Instance.new(name)
end
local shared = roblox.Instance.new("Folder")
shared.Name = "Shared"
shared.Parent = services.ReplicatedStorage
local configModule = roblox.Instance.new("ModuleScript")
configModule.Name = "Config"
configModule.Parent = shared
local protected = roblox.Instance.new("Model")
protected.Name = "StudioRestaurant"
protected:SetAttribute("OwnerEvidence", "unchanged")
protected.Parent = services.Workspace
local ownedPart = roblox.Instance.new("Part")
ownedPart.Name = "OwnerWall"
ownedPart.Position = roblox.Vector3.new(200, 10, 0)
ownedPart.Parent = protected
local builder = require("./support/WorldFixture")(services, config)
local world = builder.build()
assert(protected.Parent == services.Workspace and protected:GetAttribute("OwnerEvidence") == "unchanged")
assert(ownedPart.Position == roblox.Vector3.new(200, 10, 0))
local prompts = 0
for _, item in world:GetDescendants() do
	if item:IsA("ProximityPrompt") and item.Name == "LauncherPrompt" then
		prompts += 1
		assert(item.Parent.Name == "LauncherInteractionAnchor")
		assert((item.Parent.CFrame.Position - roblox.Vector3.new(0, 2.4, 84)).Magnitude < 0.00001)
		assert(item.ClickablePrompt and item.GamepadKeyCode == roblox.Enum.KeyCode.ButtonX)
	end
	assert(item.Name ~= "RecordRunPrompt", "Duplicate launcher prompt")
end
assert(prompts == 1)
local station = world.LauncherStation
assert(not station:FindFirstChild("LauncherMountBillboard", true), "Prompt already explains the contextual interaction")
assert(station.Backboard.StationTitle.Label.Text == "PIZZA LAUNCHER", "Destination cue must stay concise")
local returnCue = station:FindFirstChild("InteriorLauncherBillboard", true)
assert(returnCue and returnCue.MaxDistance <= 34, "Interior return cue must not cover spawn")
assert(station.PersonalBestDisplay.CFrame.Position.X <= -55, "Personal records belong off the entrance sightline")
local tileCount, tiles = 0, {}
for _, item in world:GetChildren() do
	if item.Name == "FloorTile" then
		tileCount += 1
		assert(not item.CanCollide and not item.CanTouch)
		local _, saturation = item.Color:ToHSV()
		assert(saturation < .2, "Revealed flooring must remain quiet")
		table.insert(tiles, item)
	end
end
assert(tileCount > 0 and tileCount <= 50, "Large floor panels need a bounded part count")
assert(world.RestaurantFloor.CFrame.Position.Y + world.RestaurantFloor.Size.Y/2 > -2)
local expected = {
	roblox.Vector3.new(-24, 2.5, 2), roblox.Vector3.new(24, 2.5, -3),
	roblox.Vector3.new(-28, 2.5, -24), roblox.Vector3.new(28, 2.5, -30),
	roblox.Vector3.new(-24, 2.5, -49), roblox.Vector3.new(24, 2.5, -55),
}
for index, definition in config.TABLES do
	assert(definition.position == expected[index], "Ballistic table center changed")
	local found
	for _, item in world:GetChildren() do
		if item:GetAttribute("TableId") == definition.id then found = item end
	end
	assert(found and (found.TableTop.CFrame.Position - definition.position - roblox.Vector3.new(0, 4.2, 0)).Magnitude < 0.00001)
	assert(found.TargetRing:GetAttribute("DeliverySurface") and found.TargetRing:GetAttribute("DeliveryZone"))
	local width = index <= 2 and 14 or (index <= 4 and 16 or 18)
	local depth = index <= 2 and 9 or (index <= 4 and 10 or 11)
	local seatOffset = depth * 0.5 + 3.2
	assert((found.BoothSeat.Size - roblox.Vector3.new(width - 2, 1.5, 4.2)).Magnitude < 0.00001)
	assert((found.BoothSeat.CFrame.Position - definition.position - roblox.Vector3.new(0, 2, -seatOffset - 0.5)).Magnitude < 0.00001)
	assert((found.BoothBack.Size - roblox.Vector3.new(width - 1, index <= 2 and 6 or 7, 1.5)).Magnitude < 0.00001)
	assert((found.BoothBack.CFrame.Position - definition.position - roblox.Vector3.new(0, 5, -seatOffset - 2.2)).Magnitude < 0.00001)
	assert((found.TablePost.Size - roblox.Vector3.new(3, 4.2, 3)).Magnitude < 0.00001 and found.TablePost.CanCollide)
	assert((found.TableBase.Size - roblox.Vector3.new(9, 0.8, 7)).Magnitude < 0.00001 and found.TableBase.CanCollide)
	local legs = 0
	for _, item in found:GetChildren() do
		if item.Name == "HeroBoothLeg" then
			legs += 1
			assert(not item.CanCollide and not item.CanTouch and not item.CanQuery)
			assert(item.CFrame.Position.Y - item.Size.Y / 2 < -0.3, "Booth legs must meet the floor")
			assert(item.CFrame.Position.Y + item.Size.Y / 2 >= found.BoothSeat.CFrame.Position.Y - found.BoothSeat.Size.Y / 2)
		end
	end
	assert(legs == 2, "Each booth needs exactly two quiet visual supports")
end
local partCount, lights, shadowLights = 0, 0, 0
for _, item in world:GetDescendants() do
	if item:IsA("BasePart") then partCount += 1 end
	if item:IsA("PointLight") then
		lights += 1
		if item.Shadows then shadowLights += 1 end
	end
end
assert(partCount <= 620, "Authored world exceeded its fixed geometry budget before character/activity runtime additions")
assert(lights <= 13 and shadowLights <= 4, "Restaurant practical-light budget exceeded")
assert(config.LAUNCH_ORIGIN == roblox.Vector3.new(0, 12, 50))
assert(config.RECORD_RUN_DURATION == 60 and config.RECORD_RUN_COUNTDOWN == 3)
assert(config.RECORD_RUN_STORE == "PizzaLaunch_RecordRun_AllTime_v1")
builder.build()
assert(protected.Parent == services.Workspace and ownedPart.Parent == protected)
print(string.format("PASS: actual WorldBuilder preserves owner model, six ballistic/furniture anchors, one launcher prompt and competitive constants; %d fixed parts, %d lights/%d shadow lights", partCount, lights, shadowLights))
