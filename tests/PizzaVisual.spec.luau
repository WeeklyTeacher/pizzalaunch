local loadModule = require("./support/LoadModule")
local roblox = require("@lune/roblox")
local PizzaVisual = loadModule("src/shared/PizzaVisual.luau")
local anchor = roblox.Instance.new("Part")
anchor.Name, anchor.Parent = "Collider", roblox.Instance.new("Folder")
anchor.Size = roblox.Vector3.new(0.65, 6, 6)
anchor.CFrame = roblox.CFrame.new(0, 12, 50) * roblox.CFrame.Angles(0, 0, math.pi / 2)
anchor.Transparency = 1
anchor.Massless = false
local frame, size = anchor.CFrame, anchor.Size
local model = PizzaVisual.attach(anchor)
local counts, baseCount = {}, 0
for _, part in model:GetChildren() do
	assert(part:IsA("BasePart"))
	baseCount += 1
	counts[part.Name] = (counts[part.Name] or 0) + 1
	assert(part.Massless and not part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery)
	assert(part:GetAttribute("PizzaCosmetic") and not part:GetAttribute("CosmeticLoadedPizza"))
	local weld = part:FindFirstChildOfClass("WeldConstraint")
	assert(weld and weld.Part0 == anchor and weld.Part1 == part, "every cosmetic must remain massless in the collider's assembly")
end
assert(baseCount == 27 and counts.RaisedCrust == 12 and counts.MeltedCheese == 1 and counts.TomatoSauce == 1)
assert(anchor.CFrame == frame and anchor.Size == size and not anchor.Massless and anchor.Transparency == 1)
assert(anchor.CanCollide and anchor.CanTouch and anchor.CanQuery, "prefab cannot rewrite collider interaction policy")
local loaded = roblox.Instance.new("Part")
loaded.Parent, loaded.CFrame, loaded.Anchored = anchor.Parent, roblox.CFrame.new(), true
local display = PizzaVisual.attach(loaded, { diameter = 5.8, name = "LoadedPizzaVisual", loaded = true })
assert(display.Name == "LoadedPizzaVisual" and display:GetAttribute("CosmeticLoadedPizza"))
for _, part in display:GetChildren() do assert(part:GetAttribute("CosmeticLoadedPizza")) end
assert(math.abs(display.BakedBase.Size.Y - 5.8) < 0.0001 and loaded.Anchored)

local fades = 0
local service = loadModule("src/server/ProjectileService.luau", {
	game = { GetService = function(_, name)
		if name == "ReplicatedStorage" then return { Shared = { PizzaVisual = "PizzaVisual" } } end
		if name == "TweenService" then return { Create = function(_, part, info, goal)
			assert(info.duration == 0.42 and goal.Transparency == 1 and goal.Size == nil)
			return { Play = function() fades += 1; part.Transparency = 1 end }
		end } end
		return {}
	end },
	require = function(name) assert(name == "PizzaVisual"); return PizzaVisual end,
	TweenInfo = { new = function(duration) return { duration = duration } end },
})
assert(not service.consumeVisual(anchor), "active pizza cannot be consumed")
anchor:SetAttribute("Resolved", true)
assert(service.consumeVisual(anchor) and fades == 27)
assert(anchor.CFrame == frame and anchor.Size == size and anchor.Transparency == 1 and not anchor.Massless,
	"landing treatment cannot resize/reveal/change the authoritative collider")
anchor:Destroy()
assert(not service.consumeVisual(anchor))
local binary = roblox.serializeModel({ loaded.Parent })
local restored = roblox.deserializeModel(binary)
assert(#restored > 0, "source-native welded pizza also survives binary build serialization")
print("PASS: pizza prefab normal/loaded variants, 27-part budget, baked geometry, massless welds, collider preservation and bounded landing fade")
