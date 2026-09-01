local TweenService = game:GetService("TweenService")

local WorldActivityService = {}
local generation = 0

function WorldActivityService.start(world: Instance)
	generation += 1
	local token = generation
	local pedestrian = world:FindFirstChild("AmbientStreetPedestrian", true)
	if pedestrian and pedestrian:IsA("Model") then
		for _, part in pedestrian:GetDescendants() do
			if part:IsA("BasePart") then
				part:SetAttribute("AmbientBaseCFrame", part.CFrame)
			end
		end
		task.spawn(function()
			task.wait(7)
			while token == generation and pedestrian.Parent do
				for _, part in pedestrian:GetDescendants() do
					if part:IsA("BasePart") then
						local base = part:GetAttribute("AmbientBaseCFrame")
						if typeof(base) == "CFrame" then
							part.CFrame = base
						end
						if part:GetAttribute("AmbientVisibleTransparency") ~= nil then
							TweenService:Create(part, TweenInfo.new(0.35), { Transparency = part:GetAttribute("AmbientVisibleTransparency") }):Play()
						end
					end
				end
				task.wait(0.4)
				for _, part in pedestrian:GetDescendants() do
					if part:IsA("BasePart") then
						TweenService:Create(part, TweenInfo.new(15, Enum.EasingStyle.Linear), { CFrame = part.CFrame + Vector3.new(168, 0, 0) }):Play()
					end
				end
				task.wait(14.3)
				for _, part in pedestrian:GetDescendants() do
					if part:IsA("BasePart") and part:GetAttribute("AmbientVisibleTransparency") ~= nil then
						TweenService:Create(part, TweenInfo.new(0.45), { Transparency = 1 }):Play()
					end
				end
				task.wait(18 + math.random() * 12)
			end
		end)
	end

	local windows = {}
	for _, descendant in world:GetDescendants() do
		if descendant:IsA("BasePart") and descendant.Name == "RestaurantWindow" then
			table.insert(windows, descendant)
		end
	end
	task.spawn(function()
		local bright = false
		while token == generation and world.Parent do
			task.wait(10)
			bright = not bright
			for _, window in windows do
				if window.Parent then
					TweenService:Create(window, TweenInfo.new(3, Enum.EasingStyle.Sine), { Transparency = bright and 0.2 or 0.34 }):Play()
				end
			end
		end
	end)
end

return WorldActivityService
