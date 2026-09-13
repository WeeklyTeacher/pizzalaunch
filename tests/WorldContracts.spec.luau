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
end
assert(config.LAUNCH_ORIGIN == roblox.Vector3.new(0, 12, 50))
assert(config.RECORD_RUN_DURATION == 60 and config.RECORD_RUN_COUNTDOWN == 3)
assert(config.RECORD_RUN_STORE == "PizzaLaunch_RecordRun_AllTime_v1")
builder.build()
assert(protected.Parent == services.Workspace and ownedPart.Parent == protected)
print("PASS: actual WorldBuilder preserves owner model, six ballistic anchors, one launcher prompt and competitive constants")
