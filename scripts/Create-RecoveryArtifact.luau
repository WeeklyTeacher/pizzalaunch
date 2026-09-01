local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local inputPath = process.args[1] or "recovery/PizzaLaunchTransfer.rbxl"
local outputPath = process.args[2] or "recovery/PizzaLaunchMerged.recovery-20260831.rbxl"

assert(inputPath ~= outputPath, "Input and output must be different paths")
assert(fs.isFile(inputPath), "Transfer input does not exist: " .. inputPath)
assert(not fs.isFile(outputPath), "Refusing to overwrite recovery artifact: " .. outputPath)

local game = roblox.deserializePlace(fs.readFile(inputPath))

local sourceMap = {
	["ReplicatedStorage/Shared/Config"] = "src/shared/Config.luau",
	["ServerScriptService/Server"] = "src/server/init.server.luau",
	["ServerScriptService/Server/CustomerService"] = "src/server/CustomerService.luau",
	["ServerScriptService/Server/GameService"] = "src/server/GameService.luau",
	["ServerScriptService/Server/InteractionService"] = "src/server/InteractionService.luau",
	["ServerScriptService/Server/LayoutService"] = "src/server/LayoutService.luau",
	["ServerScriptService/Server/PropService"] = "src/server/PropService.luau",
	["ServerScriptService/Server/RecordRunService"] = "src/server/RecordRunService.luau",
	["ServerScriptService/Server/WorldBuilder"] = "src/server/WorldBuilder.luau",
	["StarterPlayer/StarterPlayerScripts/Client"] = "src/client/init.client.luau",
}

local function instancePath(instance): string
	local segments = { instance.Name }
	local cursor = instance.Parent
	while cursor and cursor ~= game do
		table.insert(segments, 1, cursor.Name)
		cursor = cursor.Parent
	end
	return table.concat(segments, "/")
end

local updated = 0
for _, instance in game:GetDescendants() do
	if instance:IsA("LuaSourceContainer") then
		local path = instancePath(instance)
		local sourcePath = sourceMap[path]
		assert(sourcePath ~= nil, "Unreviewed script in Transfer place: " .. path)
		assert(fs.isFile(sourcePath), "Mapped source file is missing: " .. sourcePath)
		instance.Source = fs.readFile(sourcePath)
		updated += 1
	end
end

assert(updated == 10, string.format("Expected 10 reviewed scripts, updated %d", updated))
fs.writeFile(outputPath, roblox.serializePlace(game))
print(string.format("Created %s from read-only Transfer base with %d reviewed scripts", outputPath, updated))
