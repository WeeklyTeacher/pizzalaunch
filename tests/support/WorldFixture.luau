local loadModule = require("./LoadModule")
local roblox = require("@lune/roblox")

return function(services, config)
	local shared = services.ReplicatedStorage:FindFirstChild("Shared")
	if not shared then
		shared = roblox.Instance.new("Folder")
		shared.Name, shared.Parent = "Shared", services.ReplicatedStorage
	end
	local function module(name)
		local item = shared:FindFirstChild(name) or roblox.Instance.new("ModuleScript")
		item.Name, item.Parent = name, shared
		return item
	end
	local configModule, pizzaModule = module("Config"), module("PizzaVisual")
	local engine = {
		ColorSequence = roblox.ColorSequence, ColorSequenceKeypoint = roblox.ColorSequenceKeypoint,
		NumberSequence = roblox.NumberSequence, NumberSequenceKeypoint = roblox.NumberSequenceKeypoint,
		NumberRange = roblox.NumberRange,
	}
	local pizza = loadModule("src/shared/PizzaVisual.luau", engine)
	local art = loadModule("src/server/LauncherArt.luau", engine)
	local artToken = {}
	local dependencies = { [configModule] = config, [pizzaModule] = pizza, [artToken] = art }
	engine.game = { GetService = function(_, name) return assert(services[name], name) end }
	engine.script = { Parent = { LauncherArt = artToken } }
	engine.require = function(dependency) return assert(dependencies[dependency], "Unwired WorldBuilder dependency") end
	return loadModule("src/server/WorldBuilder.luau", engine)
end
