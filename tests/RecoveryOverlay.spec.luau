local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local overlay = require("../scripts/lib/RecoveryOverlay")

local inputPath = "recovery/PizzaLaunchTransfer.rbxl"
local inputBytes = fs.readFile(inputPath)
local expectedHash = "73b3d5df3b72f9b13350790759b715bc0e510bb7a41fed3c895f58bd17f11088"
assert(serde.hash("sha256", inputBytes) == expectedHash, "Canonical fixture hash changed")
local result = process.exec("rojo", { "sourcemap", "default.project.json" })
assert(result.ok, result.stderr)
local mapping = serde.decode("json", result.stdout)

local function apply(dataModel, suppliedMapping, verifyOnly)
	return overlay(dataModel, suppliedMapping or mapping, fs.readFile, fs.readDir, fs.isDir, verifyOnly)
end
local function rejects(callback, expected)
	local ok, message = pcall(callback)
	assert(not ok and tostring(message):find(expected, 1, true), tostring(message))
end

local dataModel = roblox.deserializePlace(inputBytes)
local workspace = dataModel:GetService("Workspace")
local sentinel = roblox.Instance.new("Model")
sentinel.Name = "UnmappedRecoveryFixture"
sentinel:SetAttribute("PreserveMe", "authored geometry")
sentinel.Parent = workspace
local part = roblox.Instance.new("Part")
part.CFrame = roblox.CFrame.new(3, 4, 5)
part.Size = roblox.Vector3.new(6, 7, 8)
part.Parent = sentinel
-- Repeated names are normal for unmapped art and must never cause its deletion.
local repeatedPart = part:Clone()
repeatedPart.Parent = sentinel
-- Normalize serializer-populated default properties just as a saved place has.
dataModel = roblox.deserializePlace(roblox.serializePlace(dataModel))
workspace = dataModel:GetService("Workspace")
local workspaceBefore = roblox.serializeModel({ workspace }, true)
local originalInstances = dataModel:GetDescendants()
local parents = {}
for _, instance in originalInstances do parents[instance] = instance.Parent end
local count = apply(dataModel)
assert(count > 0, "No current modules were recovered")
for _, instance in originalInstances do
	assert(instance.Parent == parents[instance], "An original recovery instance was moved or removed")
end
assert(roblox.serializeModel({ workspace }, true) == workspaceBefore, "Workspace geometry changed")
for _, name in { "CustomerDialogue", "ShiftEventService", "WorldActivityService" } do
	local module = dataModel:GetService("ServerScriptService").Server:FindFirstChild(name)
	assert(module and module.Source == fs.readFile("src/server/" .. name .. ".luau"), "Required module missing: " .. name)
end
local serialized = roblox.serializePlace(dataModel)
local restored = roblox.deserializePlace(serialized)
assert(apply(restored, nil, true) == count, "Recovery round trip lost current source")
local workspaceAfter = roblox.serializeModel({ restored:GetService("Workspace") }, true)
assert(workspaceAfter == workspaceBefore)
print("PASS: recovery adds every current module and preserves unmapped geometry through binary round trip")

local unreviewed = roblox.deserializePlace(inputBytes)
local unknownScript = roblox.Instance.new("Script")
unknownScript.Name = "UnreviewedFixture"
unknownScript.Parent = unreviewed:GetService("Workspace")
rejects(function() apply(unreviewed) end, "Unreviewed script")
print("PASS: unreviewed embedded scripts are rejected")

local incomplete = serde.decode("json", result.stdout)
local function childNamed(node, name)
	for _, child in node.children or {} do
		if child.name == name then return child end
	end
	error("Missing mapped fixture node: " .. name)
end
local server = childNamed(childNamed(incomplete, "ServerScriptService"), "Server")
table.remove(server.children, 1)
rejects(function() apply(roblox.deserializePlace(inputBytes), incomplete) end, "missing from Rojo recovery mapping")
print("PASS: source omitted from the generated mapping is rejected")

local changed = roblox.deserializePlace(serialized)
changed:GetService("ServerScriptService").Server.CustomerDialogue.Source = "return {}"
rejects(function() apply(changed, nil, true) end, "source differs from current source")
print("PASS: recovery verification detects changed module contents")

local ambiguous = roblox.deserializePlace(inputBytes)
local duplicate = ambiguous:GetService("ServerScriptService").Server:Clone()
duplicate.Parent = ambiguous:GetService("ServerScriptService")
rejects(function() apply(ambiguous) end, "Ambiguous mapped instance path")
print("PASS: ambiguous script paths are rejected while repeated unmapped art names are preserved")

for _, path in { "recovery/PizzaLaunchTransfer.rbxl", ".qa-artifacts/../escaped.rbxl", "E:/outside.rbxl" } do
	local guard = process.exec("powershell", {
		"-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "scripts/Test-RecoveryOutputPath.ps1", "-OutputPath", path,
	})
	assert(not guard.ok, "Unsafe recovery output was accepted: " .. path)
end
local occupiedPath = string.format(".qa-artifacts/recovery-overwrite-test-%s-%06d.rbxl", os.time(), math.random(0, 999999))
local payloadPath = occupiedPath .. ".payload"
assert(not fs.isFile(payloadPath), "Fixture name collision")
fs.writeFile(payloadPath, "preserve this fixture")
local fixtureWrite = process.exec("powershell", {
	"-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File", "scripts/Write-RecoveryOutput.ps1",
	"-OutputPath", occupiedPath, "-PayloadPath", payloadPath,
})
assert(fixtureWrite.ok, fixtureWrite.stderr)
assert(fs.readFile(occupiedPath) == "preserve this fixture", "Fixture payload did not survive atomic writer")
local guard = process.exec("powershell", {
	"-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File", "scripts/Write-RecoveryOutput.ps1",
	"-OutputPath", occupiedPath, "-PayloadPath", payloadPath,
})
assert(not guard.ok, "Writer accepted an existing output: " .. guard.stdout .. guard.stderr)
assert(fs.readFile(occupiedPath) == "preserve this fixture", "Existing recovery fixture content changed: " .. fs.readFile(occupiedPath))
assert(serde.hash("sha256", fs.readFile(inputPath)) == expectedHash, "Canonical recovery fixture changed")
print("PASS: canonical/external/traversal/existing output paths are rejected and canonical input is unchanged")
