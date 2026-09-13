-- Original source-native toy pizza prefab. Local +X is the cheese-facing normal,
-- matching Roblox Cylinder colliders. No visual contributes collision or mass.
local PizzaVisual = {}

function PizzaVisual.attach(anchor: BasePart, options)
	options = options or {}
	local scale = (options.diameter or 6) / 6
	local model = Instance.new("Model")
	model.Name = options.name or "PizzaVisual"
	model:SetAttribute("SourcePrefab", "PizzaVisual_v1")
	model:SetAttribute("CosmeticLoadedPizza", options.loaded == true)
	model.Parent = anchor
	local function piece(name, size, frame, color, shape)
		local part = Instance.new("Part")
		part.Name, part.Size = name, size * scale
		part.CFrame = anchor.CFrame * (CFrame.new(frame.Position * scale) * frame.Rotation)
		part.Shape, part.Color, part.Material = shape or Enum.PartType.Cylinder, color, Enum.Material.SmoothPlastic
		part.Anchored, part.Massless = false, true
		part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
		part.CastShadow = true
		part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		part:SetAttribute("PizzaCosmetic", true)
		part:SetAttribute("CosmeticLoadedPizza", options.loaded == true)
		part.Parent = model
		local weld = Instance.new("WeldConstraint")
		weld.Part0, weld.Part1, weld.Parent = anchor, part, part
		return part
	end
	piece("BakedBase", Vector3.new(0.42, 6, 6), CFrame.new(-0.06, 0, 0), Color3.fromRGB(187, 119, 54))
	piece("TomatoSauce", Vector3.new(0.08, 5.4, 5.4), CFrame.new(0.19, 0, 0), Color3.fromRGB(169, 48, 35))
	piece("MeltedCheese", Vector3.new(0.15, 5.17, 5.17), CFrame.new(0.29, 0, 0), Color3.fromRGB(250, 197, 74))
	for index = 1, 12 do
		local angle = index / 12 * math.pi * 2
		local gold = index % 3 == 0 and Color3.fromRGB(211, 144, 66) or Color3.fromRGB(235, 168, 78)
		piece("RaisedCrust", Vector3.new(0.62, 0.7, 1.47),
			CFrame.new(0.2, math.cos(angle) * 2.58, math.sin(angle) * 2.58) * CFrame.Angles(angle, 0, 0), gold, Enum.PartType.Ball)
	end
	for index, offset in {
		Vector3.new(0.42, -1.42, -0.88), Vector3.new(0.42, 1.28, -1.12), Vector3.new(0.42, -0.37, 1.37),
		Vector3.new(0.42, 1.33, 0.87), Vector3.new(0.42, -1.51, 0.82), Vector3.new(0.42, 0.1, -0.16),
	} do
		piece("Pepperoni" .. index, Vector3.new(0.1, 0.87, 0.87), CFrame.new(offset),
			index % 2 == 0 and Color3.fromRGB(157, 46, 33) or Color3.fromRGB(182, 54, 36))
	end
	for index, offset in { Vector3.new(0.377, 0.3, -1.88), Vector3.new(0.377, -0.76, -0.67), Vector3.new(0.377, 1.93, 0.03), Vector3.new(0.377, 0.65, 1.78) } do
		piece("CheeseBakeSpot" .. index, Vector3.new(0.026, 0.27, 0.41), CFrame.new(offset), Color3.fromRGB(222, 152, 57))
	end
	for index, offset in { Vector3.new(0.43, -0.6, -1.6), Vector3.new(0.43, 0.65, 0.45) } do
		piece("BasilLeaf" .. index, Vector3.new(0.05, 0.27, 0.63), CFrame.new(offset) * CFrame.Angles(index * 0.9, 0, 0), Color3.fromRGB(67, 117, 62), Enum.PartType.Ball)
	end
	return model
end

return PizzaVisual
