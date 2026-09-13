local loadModule = require("./support/LoadModule")
local roblox = require("@lune/roblox")
local now, covered = 0, false
local delayed = {}
local function item(name, kind)
	local self = { Name = name, Visible = false, Parent = true, Transparency = 1, LocalTransparencyModifier = 0 }
	function self:IsA(class) return class == kind end
	function self:GetAttribute(attribute) return attribute == "CosmeticLoadedPizza" and name == "Cheese" end
	function self:FindFirstChild() return nil end
	function self:FindFirstChildOfClass() return nil end
	function self:GetDescendants() return {} end
	return self
end
local anchor = item("LoadedPizza", "BasePart")
local cheese = item("Cheese", "BasePart")
local other = item("Barrel", "BasePart")
local rig = item("AimRig", "Model")
function rig:GetDescendants() return { anchor, cheese, other } end
local station = item("LauncherStation", "Model")
function station:FindFirstChild(name) return name == "AimRig" and rig or nil end
function station:GetDescendants() return rig:GetDescendants() end
local world = { FindFirstChild = function(_, name) return name == "LauncherStation" and station or nil end }
local workspace = { FindFirstChild = function(_, name) return name == "PizzaLaunchWorld" and world or nil end }
local ui = {}
for _, name in { "feedback", "dialogueCard", "dialoguePortrait", "dialogueName", "dialogueMood", "dialogueText", "dialogueClose", "eventBanner", "eventIcon", "eventTitle", "eventDetail", "roundOverlay", "roundOverlayTitle", "roundOverlayDetail" } do
	ui[name] = item(name, "TextLabel")
end
ui.dialogueClose.Activated = { Connect = function() end }
ui.feedbackPosition = roblox.UDim2.fromOffset(330, 210)
local theme = loadModule("src/client/UITheme.luau")
local module = loadModule("src/client/Feedback.luau", {
	task = { delay = function(seconds, callback) table.insert(delayed, { seconds = seconds, callback = callback }) end },
	os = { clock = function() return now end },
	TweenInfo = { new = function() return {} end },
})
local tweenService = {}
function tweenService:Create(target, _, properties)
	return { Completed = { Once = function() end, Wait = function() end }, Cancel = function() end,
		Play = function() for key, value in properties do target[key] = value end end }
end
local feedback = module.new({ Workspace = workspace, ui = ui, COLORS = theme.colors, TweenService = tweenService,
	isCovered = function() return covered end, getState = function() return { upgrades = {} } end })
feedback.showFeedback("DELIVERED!", theme.colors.green, "+8 COINS")
assert(ui.feedback.Visible and ui.feedback.Position == ui.feedbackPosition and ui.feedback.Rotation == 0)
feedback.reset()
covered = true
feedback.showFeedback("SHOULD STAY COVERED", theme.colors.red)
assert(not ui.feedback.Visible, "A picker/shop must not receive a competing shot receipt")
covered = false
feedback.playLauncherFire(0.55)
assert(anchor.LocalTransparencyModifier == 1 and cheese.LocalTransparencyModifier == 1 and other.LocalTransparencyModifier == 0)
assert(anchor.Transparency == 1, "The gameplay anchor stays transparent while the separate pizza visual hides")
now = 0.14
assert(feedback.recoilOffset(now) > 0 and feedback.recoilOffset(now) <= 0.7)
assert(feedback.recoilOffset(1) == 0)
local oldCallbacks = table.clone(delayed)
table.clear(delayed)
feedback.reset()
assert(anchor.LocalTransparencyModifier == 0 and cheese.LocalTransparencyModifier == 0 and anchor.Transparency == 1)
assert(feedback.recoilOffset(now) == 0)
feedback.playLauncherFire(0.55)
for _, event in oldCallbacks do event.callback() end
assert(cheese.LocalTransparencyModifier == 1, "Old lease callbacks cannot restore the new shot's loaded pizza")
for _, event in delayed do event.callback() end
assert(cheese.LocalTransparencyModifier == 0)
feedback.reset()
feedback.reset()
assert(anchor.Transparency == 1 and not ui.feedback.Visible)
print("PASS: actual feedback uses responsive receipts, bounded visual-only recoil, attributed pizza visuals and stale-callback-safe reset")
