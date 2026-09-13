local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local overlay = require("./lib/RecoveryOverlay")

-- Run from the repository root. Normal source builds still use `rojo build`.
-- This optional tool only updates a COPY of the frozen recovery DataModel.
local canonicalPath = "recovery/PizzaLaunchTransfer.rbxl"
local canonicalHash = "73b3d5df3b72f9b13350790759b715bc0e510bb7a41fed3c895f58bd17f11088"
local inputPath = process.args[1] or canonicalPath
local outputPath = process.args[2] or string.format(
	".qa-artifacts/PizzaLaunchMerged-%s-%06d.rbxl", os.date("!%Y%m%d-%H%M%S"), math.random(0, 999999)
)
assert(inputPath == canonicalPath, "Only the reviewed, read-only Transfer input is supported")
assert(outputPath:match("^%.qa%-artifacts/[A-Za-z0-9][A-Za-z0-9_.%-]*%.rbxl$")
	and not outputPath:find("..", 1, true), "Output must be a new .qa-artifacts/<name>.rbxl file")

local safety = process.exec("powershell", { "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "scripts/Test-RecoverySafety.ps1" })
assert(safety.ok, safety.stderr .. safety.stdout)
local pathCheck = process.exec("powershell", {
	"-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "scripts/Test-RecoveryOutputPath.ps1", "-OutputPath", outputPath,
})
assert(pathCheck.ok, pathCheck.stderr .. pathCheck.stdout)
local inputBytes = fs.readFile(inputPath)
assert(serde.hash("sha256", inputBytes) == canonicalHash, "Canonical Transfer hash mismatch")
local mapping = process.exec("rojo", { "sourcemap", "default.project.json" })
assert(mapping.ok, mapping.stderr)
local sourceMap = serde.decode("json", mapping.stdout)
local dataModel = roblox.deserializePlace(inputBytes)
local workspaceBefore = roblox.serializeModel({ dataModel:GetService("Workspace") }, true)

local scriptCount = overlay(dataModel, sourceMap, fs.readFile, fs.readDir, fs.isDir)
assert(roblox.serializeModel({ dataModel:GetService("Workspace") }, true) == workspaceBefore,
	"Recovery overlay changed Workspace")
local outputBytes = roblox.serializePlace(dataModel)
local roundTrip = roblox.deserializePlace(outputBytes)
assert(roblox.serializeModel({ roundTrip:GetService("Workspace") }, true) == workspaceBefore,
	"Recovery serialization changed Workspace")
-- A second overlay verifies all current scripts survive binary serialization.
overlay(roundTrip, sourceMap, fs.readFile, fs.readDir, fs.isDir, true)
assert(serde.hash("sha256", fs.readFile(inputPath)) == canonicalHash, "Transfer changed during generation")
assert(not fs.isFile(outputPath) and not fs.isDir(outputPath), "Refusing to overwrite an existing artifact")
-- Keep the verified payload ignored. File-based transfer avoids Windows stdin races.
local payloadPath = outputPath .. ".payload"
assert(not fs.isFile(payloadPath) and not fs.isDir(payloadPath), "Refusing to overwrite an existing payload")
fs.writeFile(payloadPath, outputBytes)
assert(fs.readFile(payloadPath) == outputBytes, "Recovery payload verification failed")
local write = process.exec("powershell", {
	"-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File", "scripts/Write-RecoveryOutput.ps1",
	"-OutputPath", outputPath, "-PayloadPath", payloadPath,
})
assert(write.ok, write.stderr .. write.stdout)
assert(fs.readFile(outputPath) == outputBytes, "Recovery output verification failed")
assert(serde.hash("sha256", fs.readFile(inputPath)) == canonicalHash, "Transfer changed after generation")
print(string.format("PASS: created %s with %d current scripts; canonical input and Workspace preserved", outputPath, scriptCount))
