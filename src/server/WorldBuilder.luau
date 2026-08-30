local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local WorldBuilder = {}

local function part(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3, material: Enum.Material?): Part
	local item = Instance.new("Part")
	item.Name = name
	item.Size = size
	item.Position = position
	item.Anchored = true
	item.Color = color
	item.Material = material or Enum.Material.SmoothPlastic
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	item.Parent = parent
	return item
end

local function rounded(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3): Part
	local item = part(parent, name, size, position, color)
	item.Shape = Enum.PartType.Cylinder
	item.Orientation = Vector3.new(0, 0, 90)
	return item
end

local function textLabel(adornee: BasePart, name: string, face: Enum.NormalId, displayText: string, color: Color3): SurfaceGui
	local gui = Instance.new("SurfaceGui")
	gui.Name = name
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 32
	gui.Adornee = adornee
	gui.Parent = adornee

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = displayText
	label.TextColor3 = color
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextStrokeTransparency = 0.7
	label.Parent = gui
	return gui
end

local function buildTable(world: Folder, definition)
	local model = Instance.new("Model")
	model.Name = string.format("Table_%d_%s", definition.id, definition.customer)
	model:SetAttribute("TableId", definition.id)
	model:SetAttribute("CustomerName", definition.customer)
	model.Parent = world

	local p = definition.position
	local top = rounded(model, "TableTop", Vector3.new(1.1, 18, 18), p + Vector3.new(0, 4.1, 0), Color3.fromRGB(250, 236, 203))
	top:SetAttribute("TableId", definition.id)
	top:SetAttribute("DeliverySurface", true)
	part(model, "Pedestal", Vector3.new(3, 4.2, 3), p + Vector3.new(0, 1.5, 0), Color3.fromRGB(116, 83, 62), Enum.Material.Wood)
	part(model, "Base", Vector3.new(9, 0.8, 9), p + Vector3.new(0, -0.55, 0), Color3.fromRGB(95, 67, 52), Enum.Material.Wood)

	local target = rounded(model, "TargetRing", Vector3.new(0.22, 6.6, 6.6), p + Vector3.new(0, 4.72, 0), definition.color)
	target.Material = Enum.Material.Neon
	target.CanCollide = false
	target.CanTouch = false
	target.Transparency = 0.12
	target:SetAttribute("TableId", definition.id)

	local plate = rounded(model, "Plate", Vector3.new(0.3, 5.2, 5.2), p + Vector3.new(0, 4.85, 0), Color3.fromRGB(255, 255, 255))
	plate.CanCollide = false
	plate:SetAttribute("TableId", definition.id)
	plate:SetAttribute("DeliverySurface", true)

	local chairPosition = p + Vector3.new(0, 0, -9.8)
	part(model, "ChairSeat", Vector3.new(7, 1, 6), chairPosition + Vector3.new(0, 2.2, 0), definition.color, Enum.Material.Wood)
	part(model, "ChairBack", Vector3.new(7, 8, 1), chairPosition + Vector3.new(0, 5.5, -2.5), definition.color, Enum.Material.Wood)

	rounded(model, "CustomerBody", Vector3.new(4.5, 5.5, 5.5), chairPosition + Vector3.new(0, 6.6, 0), definition.color)
	local head = Instance.new("Part")
	head.Name = "CustomerHead"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(4.5, 4.5, 4.5)
	head.Position = chairPosition + Vector3.new(0, 11.1, 0)
	head.Anchored = true
	head.Color = Color3.fromRGB(255, 213, 167)
	head.Parent = model
	textLabel(head, "Face", Enum.NormalId.Back, ":D", Color3.fromRGB(70, 45, 35))

	local sign = part(model, "OrderSign", Vector3.new(8, 5.5, 0.5), p + Vector3.new(0, 10.5, -4.9), definition.color)
	sign.CanCollide = false
	textLabel(sign, "OrderDisplay", Enum.NormalId.Back, string.format("%s\nTABLE %d", string.upper(definition.customer), definition.id), Color3.fromRGB(35, 30, 40))
	return model
end

local function buildCannon(world: Folder)
	local model = Instance.new("Model")
	model.Name = "PizzaCannon"
	model.Parent = world

	local base = rounded(model, "Base", Vector3.new(4, 13, 13), Vector3.new(0, 3.2, 62), Color3.fromRGB(210, 42, 49))
	base.Material = Enum.Material.Metal
	local launchDirection = Vector3.new(0, math.sin(Config.LAUNCH_ANGLE), -math.cos(Config.LAUNCH_ANGLE))
	local barrelCenter = Config.LAUNCH_ORIGIN - launchDirection * 8.2
	local barrel = rounded(model, "Barrel", Vector3.new(18, 5.8, 5.8), barrelCenter, Color3.fromRGB(238, 57, 49))
	barrel.CFrame = CFrame.lookAt(barrelCenter, barrelCenter + launchDirection) * CFrame.Angles(0, math.pi / 2, 0)
	barrel.Material = Enum.Material.Metal
	local trim = rounded(model, "Muzzle", Vector3.new(2.2, 7.4, 7.4), Config.LAUNCH_ORIGIN, Color3.fromRGB(255, 202, 57))
	trim.CFrame = CFrame.lookAt(Config.LAUNCH_ORIGIN, Config.LAUNCH_ORIGIN + launchDirection) * CFrame.Angles(0, math.pi / 2, 0)
	trim.Material = Enum.Material.Neon
	local leftWheel = part(model, "LeftWheel", Vector3.new(1.8, 12, 12), Vector3.new(-7, 3.5, 62), Color3.fromRGB(55, 58, 65), Enum.Material.Metal)
	leftWheel.Shape = Enum.PartType.Cylinder
	local rightWheel = part(model, "RightWheel", Vector3.new(1.8, 12, 12), Vector3.new(7, 3.5, 62), Color3.fromRGB(55, 58, 65), Enum.Material.Metal)
	rightWheel.Shape = Enum.PartType.Cylinder
	local sign = part(model, "CannonSign", Vector3.new(18, 5, 1), Vector3.new(0, 4.8, 70), Color3.fromRGB(255, 226, 84))
	textLabel(sign, "Title", Enum.NormalId.Back, "PIZZA\nLAUNCH!", Color3.fromRGB(181, 35, 41))
end

function WorldBuilder.build()
	local old = Workspace:FindFirstChild("PizzaLaunchWorld")
	if old then
		old:Destroy()
	end

	local world = Instance.new("Folder")
	world.Name = "PizzaLaunchWorld"
	world.Parent = Workspace

	Workspace.Gravity = Config.GRAVITY
	Lighting.ClockTime = 14.5
	Lighting.Brightness = 2.6
	Lighting.Ambient = Color3.fromRGB(125, 110, 105)
	Lighting.OutdoorAmbient = Color3.fromRGB(145, 135, 130)
	Lighting.EnvironmentDiffuseScale = 0.35
	Lighting.EnvironmentSpecularScale = 0.5

	local oldAtmosphere = Lighting:FindFirstChild("RestaurantAtmosphere")
	if oldAtmosphere then
		oldAtmosphere:Destroy()
	end
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "RestaurantAtmosphere"
	atmosphere.Density = 0.18
	atmosphere.Color = Color3.fromRGB(255, 235, 210)
	atmosphere.Decay = Color3.fromRGB(255, 200, 160)
	atmosphere.Glare = 0.05
	atmosphere.Parent = Lighting

	local floor = part(world, "RestaurantFloor", Vector3.new(150, 1, 160), Vector3.new(0, -1, -15), Color3.fromRGB(244, 218, 176), Enum.Material.Slate)
	floor:SetAttribute("MissSurface", true)
	part(world, "BackWall", Vector3.new(150, 34, 2), Vector3.new(0, 16, -94), Color3.fromRGB(255, 239, 211), Enum.Material.Brick)
	part(world, "LeftWall", Vector3.new(2, 34, 160), Vector3.new(-75, 16, -15), Color3.fromRGB(236, 92, 78), Enum.Material.Brick)
	part(world, "RightWall", Vector3.new(2, 34, 160), Vector3.new(75, 16, -15), Color3.fromRGB(236, 92, 78), Enum.Material.Brick)

	for x = -68, 68, 8 do
		for z = -90, 61, 8 do
			if ((x + z) / 8) % 2 == 0 then
				local tile = part(world, "FloorTile", Vector3.new(7.8, 0.05, 7.8), Vector3.new(x, -0.47, z), Color3.fromRGB(255, 239, 205))
				tile.CanCollide = false
			end
		end
	end

	local banner = part(world, "BackBanner", Vector3.new(58, 15, 0.5), Vector3.new(0, 20, -92.8), Color3.fromRGB(255, 202, 57))
	textLabel(banner, "Welcome", Enum.NormalId.Back, "FEED THE HUNGRY TABLE!", Color3.fromRGB(185, 39, 43))

	buildCannon(world)
	for _, definition in Config.TABLES do
		buildTable(world, definition)
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "PlayerSpawn"
	spawn.Size = Vector3.new(12, 1, 8)
	spawn.Position = Vector3.new(0, 0, 75)
	spawn.Anchored = true
	spawn.Transparency = 1
	spawn.CanCollide = true
	spawn.Neutral = true
	spawn.Parent = world

	return world
end

return WorldBuilder
