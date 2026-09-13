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
local expectedFrame = {0,-10,0,1,0,0,0,1,0,0,0,1}
for index, value in expectedFrame do assert(props.CFrame[index] == value, "Unreviewed ground transform") end
assert(#props.CFrame == 12)
-- Everything else stays exactly equivalent to the protected project mapping.
local normalized = serde.decode("json", fs.readFile("default.project.json"))
normalized.tree.Workspace.Baseplate["$properties"].CFrame = nil
normalized.tree.Workspace.Baseplate["$properties"].Position = {0,-10,0}
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
assert(baseplate.CFrame.Position == roblox.Vector3.new(0,-10,0), "Fresh build ground diverges from live sync")
assert(baseplate.Size == roblox.Vector3.new(512,20,512))
print("PASS: protected mapping differs only by reviewed CFrame serialization repair; real Rojo binary preserves mapped ground height")
