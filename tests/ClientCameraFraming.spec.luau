local loadModule = require("./support/LoadModule")
local roblox = require("@lune/roblox")
-- Lune 0.10.5 lookAt reverses native Roblox's local-Z convention. Keep an
-- explicit engine boundary using fromMatrix, as in LauncherArt.spec.luau.
local nativeCFrame = {}
function nativeCFrame.lookAt(position, focus)
	local forward = (focus - position).Unit
	local right = forward:Cross(roblox.Vector3.yAxis).Unit
	return roblox.CFrame.fromMatrix(position, right, right:Cross(forward), -forward)
end
local Camera = loadModule("src/client/ClientCamera.luau", { CFrame = nativeCFrame })
local config = loadModule("src/shared/Config.luau")
local originBefore = config.LAUNCH_ORIGIN
for _, safeHeight in { 316, 331, 344, 539 } do
	local frame = Camera.frameForViewport(config.CAMERA_POSITION, config.CAMERA_FOCUS, safeHeight)
	assert(frame.Position == roblox.Vector3.new(0, 26, 67))
	local expectedLook = (roblox.Vector3.new(0, 9, -22) - frame.Position).Unit
	assert((frame.LookVector - expectedLook).Magnitude < 0.0001, string.format("look %s expected %s", tostring(frame.LookVector), tostring(expectedLook)))
end
for _, safeHeight in { 540, 724, 783 } do
	local frame = Camera.frameForViewport(config.CAMERA_POSITION, config.CAMERA_FOCUS, safeHeight)
	assert(frame == nativeCFrame.lookAt(config.CAMERA_POSITION, config.CAMERA_FOCUS), "Larger viewports retain the tested desktop framing")
end
assert(config.LAUNCH_ORIGIN == originBefore)
print("PASS: compact viewing frame follows available safe height while desktop framing and ballistic origin remain independent")
