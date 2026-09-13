local loadModule = require("./support/LoadModule")
local roblox = require("@lune/roblox")
local CFrame, Vector3 = roblox.CFrame, roblox.Vector3

local owner, nextOwner, walker = {}, {}, {}
local currentOwner = owner
local delayed, tweens = {}, {}
local tweenService = {}
function tweenService:Create(part, info, target)
	local effect = { cancelled = false, part = part, info = info, target = target }
	function effect:finish()
		if not self.cancelled then for key, value in self.target do self.part[key] = value end end
	end
	function effect:Play() self:finish() end
	function effect:Cancel() self.cancelled = true end
	table.insert(tweens, effect)
	return effect
end

local world = roblox.Instance.new("Folder")
local tableModel = roblox.Instance.new("Model")
tableModel.Parent = world
local customer = roblox.Instance.new("Model")
customer.Name, customer.Parent = "Customer", tableModel
customer:SetAttribute("CustomerState", "SeatedWaiting")
customer:SetAttribute("DeliveryAvailable", true)
local parts = {}
for index, name in { "Head", "Torso", "LeftArm", "RightArm" } do
	local part = roblox.Instance.new("Part")
	part.Name, part.Parent = name, customer
	part.CFrame = CFrame.new(index, index + 4, 0)
	part.Position = part.CFrame.Position
	part:SetAttribute("ResetCFrame", part.CFrame)
	parts[name] = part
end
local marker = roblox.Instance.new("BillboardGui")
marker.Name, marker.Parent = "WaitingMarker", customer
local label = roblox.Instance.new("TextLabel")
label.Name, label.Parent = "Label", marker
local face = roblox.Instance.new("SurfaceGui")
face.Name, face.Parent = "Face", parts.Head
local faceLabel = roblox.Instance.new("TextLabel")
faceLabel.Name, faceLabel.Parent = "Label", face

local marks, bursts = 0, 0
local Feedback = loadModule("src/server/CustomerFeedback.luau", {
	game = { GetService = function(_, name) assert(name == "TweenService"); return tweenService end },
	TweenInfo = { new = function(duration) return { duration = duration } end },
	task = { delay = function(duration, callback)
		assert(duration == 1.25)
		table.insert(delayed, callback)
	end },
})
local feedback = Feedback.new({
	getOwner = function() return currentOwner end,
	worldTable = function(id) assert(id == 1); return tableModel end,
	tableDefinition = function(id) assert(id == 1); return { color = roblox.Color3.new(1, 1, 0) } end,
	customerService = { markReacting = function(model, duration)
		assert(model == customer and duration == 1.7)
		marks += 1
	end },
	coinBurst = function() bursts += 1 end,
})
local function assertSeated()
	for _, part in parts do assert(part.CFrame == part:GetAttribute("ResetCFrame")) end
end
local function restoreFixture()
	customer:SetAttribute("CustomerState", "SeatedWaiting")
	for _, part in parts do part.CFrame = part:GetAttribute("ResetCFrame") end
end

assert(feedback:react(1, "wrong"))
local outgoingCallback = delayed[#delayed]
local outgoingTweens = table.clone(tweens)
local displaced = parts.Head.CFrame
assert(displaced ~= parts.Head:GetAttribute("ResetCFrame"))
assert(not feedback:clear(walker), "bystander cleanup must not alter current operator's reaction")
assert(parts.Head.CFrame == displaced)
for _, effect in outgoingTweens do assert(not effect.cancelled) end
assert(feedback:clear(owner))
assertSeated()
for _, effect in outgoingTweens do assert(effect.cancelled) end
assert(feedback:clear(owner), "repeated cleanup is harmless")
currentOwner = nextOwner
assert(feedback:react(1, "crowd"))
local nextPose, nextToken, tweenCount = parts.Head.CFrame, customer:GetAttribute("ReactionToken"), #tweens
outgoingCallback()
for _, effect in outgoingTweens do effect:finish() end
assert(parts.Head.CFrame == nextPose and customer:GetAttribute("ReactionToken") == nextToken and #tweens == tweenCount,
	"outgoing lease callback/tweens cannot change the next operator's customer")
assert(not feedback:clear(owner) and parts.Head.CFrame == nextPose, "old owner cannot clear new feedback")
assert(customer:GetAttribute("CustomerState") == "SeatedWaiting" and customer:GetAttribute("DeliveryAvailable"),
	"feedback must not own lifecycle or availability")

-- A mode change under the same owner invalidates old callbacks as well.
local previousPolicyCallback = delayed[#delayed]
assert(feedback:clear(nextOwner))
assertSeated()
assert(feedback:react(1, "success") and bursts == 1)
local successPose, successToken = parts.Head.CFrame, customer:GetAttribute("ReactionToken")
previousPolicyCallback()
assert(parts.Head.CFrame == successPose and customer:GetAttribute("ReactionToken") == successToken)
assert(label.Text == "★")
delayed[#delayed]()
assertSeated()
assert(tweens[#tweens].info.duration == 0.28, "normal reaction restore duration preserved")
assert(feedback:clear(nextOwner))

for _, state in { "Entering", "WalkingToSeat", "Leaving", "Despawn", "Empty" } do
	restoreFixture()
	assert(feedback:react(1, "crowd"))
	local callback = delayed[#delayed]
	customer:SetAttribute("CustomerState", state)
	local movingPose = CFrame.new(52, 5, 70)
	parts.Head.CFrame = movingPose
	faceLabel.Text = "LIFECYCLE FACE"
	local beforeMarks, beforeTweens = marks, #tweens
	assert(not feedback:react(1, "crowd"), "crowd effects cannot interrupt " .. state)
	assert(marks == beforeMarks and #tweens == beforeTweens)
	callback()
	assert(feedback:clear(nextOwner))
	assert(parts.Head.CFrame == movingPose and faceLabel.Text == "LIFECYCLE FACE",
		"reaction cleanup must not snap a " .. state .. " customer to its seat")
	assert(customer:GetAttribute("CustomerState") == state and customer:GetAttribute("DeliveryAvailable"),
		"lifecycle state/delivery ownership must remain unchanged")
end

-- Immediate cleanup has the same protection before the reset callback fires.
restoreFixture()
assert(feedback:react(1, "wrong"))
customer:SetAttribute("CustomerState", "Leaving")
local leavingPose = CFrame.new(52, 6, 25)
parts.Head.CFrame = leavingPose
assert(feedback:clear(nextOwner) and parts.Head.CFrame == leavingPose)
delayed[#delayed]()
assert(parts.Head.CFrame == leavingPose)
currentOwner = nil
assert(not feedback:clear(nextOwner) and not feedback:react(1, "crowd"))
print("PASS: actual CustomerFeedback owner isolation, exit/policy stale callbacks, tween cancellation, unchanged reaction timing and lifecycle movement protection")
