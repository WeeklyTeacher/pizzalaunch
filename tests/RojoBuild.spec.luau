local fs = require("@lune/fs")
local serde = require("@lune/serde")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local project = serde.decode("json", fs.readFile("default.project.json"))
local historical = process.exec("git", {"show", "81e3f930b6210359e6ee4c64a90f0b83e9c7dac8:default.project.json"})
assert(historical.ok, "Protected mapping checkpoint must be available")
local baseline = serde.decode("json", historical.stdout)
local workspace = project.tree.Workspace
assert(workspace["$path"] == nil and workspace["$ignoreUnknownInstances"] == true)
local props = workspace.Baseplate["$properties"]
assert(props.Position == nil, "Position alone is lost by fresh place serialization; use CFrame")
local expectedFrame = {0,-12,0,1,0,0,0,1,0,0,0,1}
for index, value in expectedFrame do assert(props.CFrame[index] == value, "Unreviewed ground transform") end
assert(#props.CFrame == 12)
-- Explicit reviewed exceptions: exact mapped ground reveal and supported
-- Lighting controls. All other mappings remain structurally protected.
local lighting = project.tree.Lighting["$properties"]
-- Explicit compatibility seed prevents Studio's missing-Technology migration
-- from overwriting modern properties. See rbx-dom issue #637 and native QA.
assert(lighting.Technology == "Future" and lighting.Outlines == nil)
assert(lighting.LightingStyle == "Realistic" and lighting.PrioritizeLightingQuality == true and lighting.ShadowSoftness == 0.35)
local normalized = serde.decode("json", fs.readFile("default.project.json"))
normalized.tree.Workspace.Baseplate["$properties"].CFrame = nil
normalized.tree.Workspace.Baseplate["$properties"].Position = {0,-10,0}
local normalizedLighting = normalized.tree.Lighting["$properties"]
normalizedLighting.LightingStyle, normalizedLighting.PrioritizeLightingQuality, normalizedLighting.ShadowSoftness = nil, nil, nil
normalizedLighting.Technology, normalizedLighting.Outlines = "Voxel", false
local function equal(a,b,path)
	assert(typeof(a)==typeof(b),path)
	if typeof(a) ~= "table" then assert(a==b,path); return end
	for key,value in a do equal(value,b[key],path.."."..tostring(key)) end
	for key in b do assert(a[key]~=nil,path.." extra "..tostring(key)) end
end
equal(normalized,baseline,"mapping")
local output = string.format(".qa-artifacts/RojoBuild-%s-%06d.rbxl",os.date("!%Y%m%d-%H%M%S"),math.random(0,999999))
assert(not fs.isFile(output))
local result = process.exec("rojo",{"build","default.project.json","-o",output})
assert(result.ok,result.stderr)
local place = roblox.deserializePlace(fs.readFile(output))
local baseplate = place:GetService("Workspace").Baseplate
assert(baseplate.CFrame.Position == roblox.Vector3.new(0,-12,0), "Fresh build ground diverges from live sync")
assert(baseplate.Size == roblox.Vector3.new(512,20,512))
assert(baseplate.CFrame.Position.Y + baseplate.Size.Y/2 == -2, "Mapped ground must reveal authored floors")
local builtLighting = place:GetService("Lighting")
assert(builtLighting.LightingStyle == roblox.Enum.LightingStyle.Realistic and builtLighting.PrioritizeLightingQuality)
assert(builtLighting.Technology == roblox.Enum.Technology.Future)
assert(math.abs(builtLighting.ShadowSoftness - 0.35) < 0.00001)
print("PASS: protected mapping allows only reviewed ground reveal/current lighting; real binary preserves ground and supported lighting controls")
