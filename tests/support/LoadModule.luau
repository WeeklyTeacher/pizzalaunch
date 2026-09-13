local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")

-- Execute the unchanged production source with explicit boundary doubles.
-- This is a Luau behavior test; it is not Roblox physics/replication validation.
return function(path: string, overrides: { [string]: any }?)
	local environment = {
		Vector3 = roblox.Vector3,
		Vector2 = roblox.Vector2,
		CFrame = roblox.CFrame,
		Color3 = roblox.Color3,
		UDim = roblox.UDim,
		UDim2 = roblox.UDim2,
		Enum = roblox.Enum,
		Instance = roblox.Instance,
	}
	for key, value in overrides or {} do
		environment[key] = value
	end
	return luau.load(fs.readFile(path), {
		debugName = path,
		environment = environment,
		injectGlobals = true,
	})()
end
