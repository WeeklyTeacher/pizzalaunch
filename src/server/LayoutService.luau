local LayoutService = {}

local obstacles = {}

function LayoutService.start(world: Instance)
	table.clear(obstacles)
	for _, descendant in world:GetDescendants() do
		if descendant:IsA("BasePart") and typeof(descendant:GetAttribute("MinRound")) == "number" then
			descendant:SetAttribute("LayoutTransparency", descendant.Transparency)
			descendant:SetAttribute("LayoutCanCollide", descendant.CanCollide)
			descendant:SetAttribute("LayoutCanTouch", descendant.CanTouch)
			table.insert(obstacles, descendant)
		end
	end
	LayoutService.setRound(1)
end

function LayoutService.setRound(roundNumber: number)
	for _, obstacle in obstacles do
		if obstacle.Parent then
			local active = roundNumber >= obstacle:GetAttribute("MinRound")
			obstacle.Transparency = active and (obstacle:GetAttribute("LayoutTransparency") or 0) or 1
			obstacle.CanCollide = active and obstacle:GetAttribute("LayoutCanCollide") == true
			obstacle.CanTouch = active and obstacle:GetAttribute("LayoutCanTouch") == true
			for _, child in obstacle:GetChildren() do
				if child:IsA("SurfaceGui") then
					child.Enabled = active
				end
			end
		end
	end
end

return LayoutService
