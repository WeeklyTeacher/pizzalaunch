local loadModule = require("./support/LoadModule")
local roblox = require("@lune/roblox")
-- Lune enum userdata compares by value but is not interned as table keys.
-- Stable boundary values reproduce Roblox's interned EnumItem identity.
local Enum = { KeyCode = {}, UserInputType = {} }
for _, name in { "A", "Left", "D", "Right", "W", "Up", "S", "Down", "Q", "ButtonB", "Space", "ButtonR2", "Thumbstick1", "Unknown", "ButtonA" } do
	Enum.KeyCode[name] = roblox.Enum.KeyCode[name]
end
for _, name in { "Keyboard", "Touch", "MouseButton1", "MouseMovement", "Gamepad1" } do Enum.UserInputType[name] = roblox.Enum.UserInputType[name] end
local function signal()
	local result = { handlers = {} }
	function result:Connect(callback)
		self.handlers[callback] = true
		return { Disconnect = function() self.handlers[callback] = nil end }
	end
	function result:fire(...) for callback in self.handlers do callback(...) end end
	return result
end
local function button() return { InputBegan = signal(), InputEnded = signal() } end
local service = { InputBegan = signal(), InputEnded = signal(), InputChanged = signal(), WindowFocusReleased = signal(), TextBoxFocused = signal(), TouchEnabled = true }
local focused
function service:GetFocusedTextBox() return focused end
local Input = loadModule("src/client/LauncherInputState.luau")
local bindings = loadModule("src/client/ClientInput.luau", { Enum = Enum })
local input = Input.new(0.25, 1.25)
local now = os.clock()
local function state(mode)
	input:receive({ mode = "launcher", launcherMode = mode, cleanupEpoch = (input.epoch or 0) + 1, recordRun = { status = "idle" } }, now)
end
state("freePlay")
local ui = { fireButton = button(), aimButtons = { left = button(), right = button(), up = button(), down = button() } }
local requests = {}
local context = { inputState = input, ui = ui, UserInputService = service,
	COLORS = { orange = roblox.Color3.new(1, 0.5, 0), red = roblox.Color3.new(1, 0, 0), yellow = roblox.Color3.new(1, 1, 0) },
	launchRemote = { FireServer = function(_, ...) table.insert(requests, table.pack(...)) end },
	modeRemote = { FireServer = function() end }, currentDirection = function() return roblox.Vector3.new(0, 1, -1).Unit end,
	getCamera = function() return { ViewportSize = roblox.Vector2.new(667, 375) } end,
	isOperating = function() return true end,
}
local controller = bindings.bind(context)
local space = { KeyCode = Enum.KeyCode.Space, UserInputType = Enum.UserInputType.Keyboard }
local w = { KeyCode = Enum.KeyCode.W, UserInputType = Enum.UserInputType.Keyboard }
service.InputBegan:fire(w, true)
service.InputBegan:fire(space, true)
assert(input.keyboardHeld.up and input.charging, "CAS processed movement keys still control mounted aim/charge")
service.InputEnded:fire(space, true)
assert(#requests == 1 and requests[1][3] == 1, "Global release sends exactly one correlated request")
state("select")
service.InputBegan:fire(space, true)
assert(not input.charging and #requests == 1)
state("freePlay")
focused = {}
service.InputBegan:fire(space, false)
assert(not input.charging, "Typing cannot launch")
focused = nil
input:setBlocked(true)
service.InputBegan:fire(space, true)
assert(not input.charging, "Shop prevents charging")
input:setBlocked(false)
local fireFinger = { KeyCode = Enum.KeyCode.Unknown, UserInputType = Enum.UserInputType.Touch }
local aimFinger = { KeyCode = Enum.KeyCode.Unknown, UserInputType = Enum.UserInputType.Touch }
ui.fireButton.InputBegan:fire(fireFinger)
ui.aimButtons.right.InputBegan:fire(aimFinger)
assert(input.charging and input.touchHeld.right)
service.InputEnded:fire(aimFinger, true)
assert(input.charging and not input.touchHeld.right, "Release outside arrow clears its identity")
service.InputEnded:fire(fireFinger, true)
ui.fireButton.InputEnded:fire(fireFinger)
assert(#requests == 2 and not input.charging, "Outside fire release + button release cannot duplicate a shot")
state("freePlay")
ui.fireButton.InputBegan:fire(fireFinger)
service.WindowFocusReleased:fire()
service.InputEnded:fire(fireFinger, true)
assert(not input.charging and #requests == 2, "Focus loss cancels charge without firing")
local buttonA = { KeyCode = Enum.KeyCode.ButtonA, UserInputType = Enum.UserInputType.Gamepad1 }
service.InputBegan:fire(buttonA, false)
assert(not input.charging, "Picker ButtonA is not a launch binding")
controller.render()
controller.destroy()
print("PASS: actual client bindings honor movement-sink keys, picker/text/shop gating, independent fingers and global cancellation")
