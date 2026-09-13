local LayoutService = {}

local obstacles = {}

-- Capture authored presentation once, before any round can hide the part.
-- Repeated startup and prop resets must not replace these defaults.
function LayoutService.capture(part: BasePart)
	if part:GetAttribute("LayoutTransparency") == nil then
		part:SetAttribute("LayoutTransparency", part.Transparency)
		part:SetAttribute("LayoutCanCollide", part.CanCollide)
		part:SetAttribute("LayoutCanTouch", part.CanTouch)
		part:SetAttribute("LayoutCanQuery", part.CanQuery)
	end
	for _, child in part:GetChildren() do
		if child:IsA("SurfaceGui") and child:GetAttribute("LayoutEnabled") == nil then
			child:SetAttribute("LayoutEnabled", child.Enabled)
		end
	end
end

function LayoutService.apply(part: BasePart)
	LayoutService.capture(part)
	local active = part:GetAttribute("LayoutRoundActive") ~= false
	part.Transparency = active and part:GetAttribute("LayoutTransparency") or 1
	part.CanCollide = active and part:GetAttribute("LayoutCanCollide") == true
	part.CanTouch = active and part:GetAttribute("LayoutCanTouch") == true
	part.CanQuery = active and part:GetAttribute("LayoutCanQuery") == true
	for _, child in part:GetChildren() do
		if child:IsA("SurfaceGui") then
			child.Enabled = active and child:GetAttribute("LayoutEnabled") == true
		end
	end
end

function LayoutService.start(world: Instance)
	table.clear(obstacles)
	for _, descendant in world:GetDescendants() do
		if descendant:IsA("BasePart") and typeof(descendant:GetAttribute("MinRound")) == "number" then
			LayoutService.capture(descendant)
			table.insert(obstacles, descendant)
		end
	end
	LayoutService.setRound(1)
end

function LayoutService.setRound(roundNumber: number)
	for _, obstacle in obstacles do
		if obstacle.Parent then
			local active = roundNumber >= obstacle:GetAttribute("MinRound")
			obstacle:SetAttribute("LayoutRoundActive", active)
			LayoutService.apply(obstacle)
		end
	end
end

return LayoutService
