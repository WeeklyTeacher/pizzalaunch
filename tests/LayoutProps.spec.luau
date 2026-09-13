local loadModule = require("./support/LoadModule")
local roblox = require("@lune/roblox")

local function object(className, children)
	local item = { Parent = true, attributes = {}, children = children or {} }
	function item:IsA(name) return name == className or (className == "Part" and name == "BasePart") end
	function item:GetAttribute(name) return self.attributes[name] end
	function item:SetAttribute(name, value) self.attributes[name] = value end
	function item:GetChildren() return self.children end
	return item
end

local function prop(minRound)
	local sign = object("SurfaceGui")
	sign.Enabled = true
	local item = object("Part", { sign })
	item.Transparency = 0.25
	item.CanCollide, item.CanTouch, item.CanQuery = true, true, true
	item.Anchored = true
	item.Size = roblox.Vector3.new(3, 3, 3)
	item.CFrame = roblox.CFrame.new(1, 2, 3)
	item.AssemblyMass = 1
	item:SetAttribute("MinRound", minRound)
	item:SetAttribute("ReactiveProp", true)
	function item:SetNetworkOwner(owner) assert(owner == nil) end
	function item:ApplyImpulse(_) end
	function item:ApplyAngularImpulse(_) end
	return item
end

local sign, boxes = prop(3), prop(4)
local world = { GetDescendants = function() return { sign, boxes } end }
local layout = loadModule("src/server/LayoutService.luau")
local delayed = {}
local props = loadModule("src/server/PropService.luau", {
	game = { GetService = function() return { FindFirstChild = function() return nil end } end },
	script = { Parent = { LayoutService = "layout" } },
	require = function(name) assert(name == "layout"); return layout end,
	task = { delay = function(_, callback) table.insert(delayed, callback) end },
})

layout.start(world)
props.start(world)
assert(sign.Transparency == 1 and not sign.CanTouch and not sign.CanQuery)
assert(not props.knock(sign, roblox.Vector3.new(0, 1, -1)), "inactive props cannot be knocked")
layout.setRound(3)
props.resetAll()
assert(sign.Transparency == 0.25 and sign.CanCollide and sign.CanTouch and sign.children[1].Enabled)
assert(boxes.Transparency == 1 and not boxes.CanCollide)
layout.setRound(4)
props.resetAll()
assert(boxes.Transparency == 0.25 and boxes.CanTouch)
assert(props.knock(sign, roblox.Vector3.new(0, 1, -1)))
assert(props.getActiveCount() == 1 and not sign.Anchored)
props.resetAll()
assert(sign.Anchored and props.getActiveCount() == 0)
assert(props.knock(sign, roblox.Vector3.new(0, 1, -1)))
delayed[1]()
assert(not sign.Anchored and props.getActiveCount() == 1, "stale reset cannot reset a later knock")
layout.setRound(1)
delayed[2]()
assert(sign.Anchored and sign.Transparency == 1 and not sign.CanCollide)
layout.start(world)
props.start(world)
layout.setRound(4)
props.resetAll()
props.resetAll()
assert(sign.Transparency == 0.25 and boxes.Transparency == 0.25, "repeated startup preserves authored defaults")
assert(sign.CFrame == sign:GetAttribute("ResetCFrame") and props.getActiveCount() == 0)
print("PASS: actual LayoutService/PropService round activation, downward transition, repeat startup and stale reset behavior")
