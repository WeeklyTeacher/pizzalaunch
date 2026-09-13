-- A slow kitchen exhaust fan is presentation only. One capped update connection
-- replaces the old window-opacity pulses and sideways pedestrian tweens.
local RunService = game:GetService("RunService")

local WorldActivityService = {}
local generation = 0
local active = nil
local UPDATE_INTERVAL = 1 / 8
local ANGULAR_SPEED = 1.3

function WorldActivityService.stop()
	generation += 1
	local previous = active
	active = nil
	if not previous then return end
	if previous.connection then previous.connection:Disconnect() end
	for _, entry in previous.blades do
		if entry.part.Parent then entry.part.CFrame = entry.authored end
	end
end

function WorldActivityService.start(world: Instance)
	WorldActivityService.stop()
	local fan = world:FindFirstChild("KitchenVentFan", true)
	if not fan or fan:GetAttribute("SourceOwnedAmbient") ~= true then return end
	local hub = fan:FindFirstChild("FanHub")
	if not hub or not hub:IsA("BasePart") then return end
	local blades = {}
	for _, item in fan:GetChildren() do
		if item:IsA("BasePart") and item:GetAttribute("FanBlade") == true then
			-- Authored values survive repeated starts; do not capture a moving pose.
			local authored = item:GetAttribute("FanAuthoredCFrame")
			if typeof(authored) ~= "CFrame" then return end
			table.insert(blades, { part = item, authored = authored, relative = hub.CFrame:ToObjectSpace(authored) })
		end
	end
	if #blades ~= 3 then return end
	local token = generation
	local state = { blades = blades, elapsed = 0, angle = 0, hubFrame = hub.CFrame }
	active = state
	state.connection = RunService.Heartbeat:Connect(function(deltaTime)
		-- Disconnect plus an epoch check covers already-queued callbacks too.
		if generation ~= token or active ~= state then return end
		if not world.Parent or not fan.Parent or not hub.Parent then
			WorldActivityService.stop()
			return
		end
		state.elapsed += math.clamp(deltaTime, 0, 0.25)
		if state.elapsed < UPDATE_INTERVAL then return end
		state.angle = (state.angle + state.elapsed * ANGULAR_SPEED) % (math.pi * 2)
		state.elapsed = 0
		local frame = state.hubFrame * CFrame.Angles(0, 0, state.angle)
		for _, entry in blades do
			if not entry.part.Parent then WorldActivityService.stop(); return end
			entry.part.CFrame = frame * entry.relative
		end
	end)
end

return WorldActivityService
