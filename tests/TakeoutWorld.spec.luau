local loadModule = require("./support/LoadModule")
local roblox = require("@lune/roblox")
local I, V = roblox.Instance, roblox.Vector3
local config = loadModule("src/shared/TakeoutConfig.luau")
local replicated = I.new("Folder")
local shared = I.new("Folder"); shared.Name = "Shared"; shared.Parent = replicated
local module = I.new("ModuleScript"); module.Name = "TakeoutConfig"; module.Parent = shared
local world = I.new("Folder")
local builder = loadModule("src/server/TakeoutWorld.luau", {
	game = { GetService = function(_, name) return name == "ReplicatedStorage" and replicated or { GetServerTimeNow = function() return 100 end } end },
	require = function(item) assert(item == module); return config end,
})
local first = builder.start(world)
local counts, ids = {}, {}
for _, item in first:GetDescendants() do
	if item:IsA("BasePart") then
		assert(item.CFrame.Position.Z >= 94, "Activity must remain outside customer and projectile lanes")
		assert(item.Anchored and not item.CanCollide and not item.CanTouch and not item.CanQuery)
	elseif item:IsA("ProximityPrompt") then
		counts[item.Name] = (counts[item.Name] or 0) + 1
		assert(item.HoldDuration == 0 and item.ClickablePrompt and item.GamepadKeyCode == roblox.Enum.KeyCode.ButtonX)
		if item.Name == "TakeoutDeliveryPrompt" then ids[item:GetAttribute("DestinationId")] = true end
	end
end
assert(counts.TakeoutPickupPrompt == 1 and counts.TakeoutDeliveryPrompt == 2 and not counts.LauncherPrompt)
for _, dest in config.destinations do assert(ids[dest.id]) end
builder.update({operatorName="Chef",launcherMode="freePlay"},{progress=2,target=12})
assert(first.NowPlayingStand.NowPlaying.Label.Text:find("NO TIME LIMIT",1,true))
builder.update({operatorName="Chef",launcherMode="recordRun",recordStatus="running",score=350,endsAt=149},nil)
assert(first.NowPlayingStand.NowPlaying.Label.Text:find("350 POINTS",1,true))
assert(first.NowPlayingStand.NowPlaying.Label.Text:find("0:49",1,true))
local sentinel = I.new("Model"); sentinel.Name = "TakeoutActivity"; sentinel.Parent = world
builder.start(world)
assert(sentinel.Parent == world and first.Parent == nil, "Repeated startup must only replace its own reference")
print("PASS: activity world fixtures stay nonphysical outside lanes; two independent delivery prompts and honest station text")
