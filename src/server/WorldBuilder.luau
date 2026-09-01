local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local WorldBuilder = {}

local COLORS = {
	cream = Color3.fromRGB(255, 239, 203),
	red = Color3.fromRGB(199, 48, 49),
	darkRed = Color3.fromRGB(118, 31, 35),
	green = Color3.fromRGB(45, 123, 83),
	dark = Color3.fromRGB(52, 39, 39),
	wood = Color3.fromRGB(139, 83, 50),
	darkWood = Color3.fromRGB(85, 50, 39),
	yellow = Color3.fromRGB(255, 200, 59),
	orange = Color3.fromRGB(255, 126, 54),
	steel = Color3.fromRGB(82, 88, 96),
}

local function makePart(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	local item = Instance.new("Part")
	item.Name = name
	item.Size = size
	item.CFrame = cframe
	item.Anchored = true
	item.Color = color
	item.Material = material or Enum.Material.SmoothPlastic
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	item.Parent = parent
	return item
end

local function surfaceText(part: BasePart, name: string, face: Enum.NormalId, displayText: string, textColor: Color3, backgroundColor: Color3?, textSize: number?): SurfaceGui
	local gui = Instance.new("SurfaceGui")
	gui.Name = name
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 38
	gui.LightInfluence = 0
	gui.Parent = part

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = backgroundColor or Color3.new(1, 1, 1)
	label.BackgroundTransparency = backgroundColor and 0.05 or 1
	label.Text = displayText
	label.TextColor3 = textColor
	label.TextSize = textSize or 28
	label.TextScaled = true
	label.TextWrapped = true
	label.Font = Enum.Font.GothamBlack
	label.TextStrokeTransparency = 0.85
	label.Parent = gui
	return gui
end

local function billboard(adornee: BasePart, name: string, displayText: string, color: Color3, offset: Vector3, size: Vector2): BillboardGui
	local gui = Instance.new("BillboardGui")
	gui.Name = name
	gui.Adornee = adornee
	gui.Size = UDim2.fromOffset(size.X, size.Y)
	gui.StudsOffsetWorldSpace = offset
	gui.AlwaysOnTop = true
	gui.MaxDistance = 180
	gui.Parent = adornee

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(255, 250, 230)
	frame.BackgroundTransparency = 0.04
	frame.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame
	local border = Instance.new("UIStroke")
	border.Color = color
	border.Thickness = 3
	border.Parent = frame

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, -12, 1, -8)
	label.Position = UDim2.fromOffset(6, 4)
	label.BackgroundTransparency = 1
	label.Text = displayText
	label.TextColor3 = COLORS.dark
	label.TextScaled = true
	label.TextWrapped = true
	label.Font = Enum.Font.GothamBold
	label.Parent = frame
	return gui
end

local function prompt(parent: Instance, name: string, actionText: string, objectText: string, distance: number): ProximityPrompt
	local item = Instance.new("ProximityPrompt")
	item.Name = name
	item.ActionText = actionText
	item.ObjectText = objectText
	item.KeyboardKeyCode = Enum.KeyCode.E
	item.GamepadKeyCode = Enum.KeyCode.ButtonX
	item.HoldDuration = 0
	item.MaxActivationDistance = distance
	item.RequiresLineOfSight = false
	item.Style = Enum.ProximityPromptStyle.Default
	item.Parent = parent
	return item
end

local function markSplatSurface(item: BasePart)
	item:SetAttribute("SplatSurface", true)
	return item
end

local function makeReactive(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	local item = makePart(parent, name, size, cframe, color, material)
	item:SetAttribute("ReactiveProp", true)
	item:SetAttribute("ResetCFrame", cframe)
	item:SetAttribute("SplatSurface", true)
	return item
end

local function configureLighting()
	Workspace.Gravity = Config.GRAVITY
	Lighting.ClockTime = 15.2
	Lighting.Brightness = 2.15
	Lighting.Ambient = Color3.fromRGB(101, 85, 78)
	Lighting.OutdoorAmbient = Color3.fromRGB(128, 112, 102)
	Lighting.EnvironmentDiffuseScale = 0.45
	Lighting.EnvironmentSpecularScale = 0.55
	Lighting.ColorShift_Top = Color3.fromRGB(255, 226, 190)

	for _, name in { "RestaurantAtmosphere", "RestaurantColor", "RestaurantBloom" } do
		local existing = Lighting:FindFirstChild(name)
		if existing then
			existing:Destroy()
		end
	end

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "RestaurantAtmosphere"
	atmosphere.Density = 0.12
	atmosphere.Color = Color3.fromRGB(255, 233, 203)
	atmosphere.Decay = Color3.fromRGB(255, 190, 144)
	atmosphere.Glare = 0.08
	atmosphere.Parent = Lighting

	local color = Instance.new("ColorCorrectionEffect")
	color.Name = "RestaurantColor"
	color.Brightness = 0
	color.Contrast = 0.06
	color.Saturation = 0.11
	color.TintColor = Color3.fromRGB(255, 239, 220)
	color.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "RestaurantBloom"
	bloom.Intensity = 0.12
	bloom.Size = 22
	bloom.Threshold = 1.25
	bloom.Parent = Lighting
end

local function buildShell(world: Folder)
	local floor = markSplatSurface(makePart(world, "RestaurantFloor", Vector3.new(132, 1, 168), CFrame.new(0, -1, -12), Color3.fromRGB(91, 56, 42), Enum.Material.WoodPlanks))
	floor:SetAttribute("MissSurface", true)

	for x = -60, 60, 12 do
		for z = -88, 68, 12 do
			local even = ((x + z) / 12) % 2 == 0
			local tileColor = even and Color3.fromRGB(249, 224, 183) or Color3.fromRGB(177, 49, 50)
			local tile = makePart(world, "CheckerTile", Vector3.new(11.7, 0.08, 11.7), CFrame.new(x, -0.46, z), tileColor, Enum.Material.CeramicTiles)
			tile.CanCollide = false
			tile.CanTouch = false
		end
	end

	local back = markSplatSurface(makePart(world, "BackWall", Vector3.new(132, 34, 2), CFrame.new(0, 16, -96), COLORS.cream, Enum.Material.Plaster))
	back:SetAttribute("MissSurface", true)
	local left = markSplatSurface(makePart(world, "LeftWall", Vector3.new(2, 34, 168), CFrame.new(-66, 16, -12), Color3.fromRGB(245, 213, 174), Enum.Material.Brick))
	left:SetAttribute("MissSurface", true)
	local right = markSplatSurface(makePart(world, "RightWall", Vector3.new(2, 34, 168), CFrame.new(66, 16, -12), Color3.fromRGB(245, 213, 174), Enum.Material.Brick))
	right:SetAttribute("MissSurface", true)

	makePart(world, "BackWainscot", Vector3.new(130, 8, 0.6), CFrame.new(0, 4, -94.7), COLORS.darkRed, Enum.Material.WoodPlanks)
	makePart(world, "LeftWainscot", Vector3.new(0.6, 8, 166), CFrame.new(-64.7, 4, -12), COLORS.darkRed, Enum.Material.WoodPlanks)
	makePart(world, "RightWainscot", Vector3.new(0.6, 8, 166), CFrame.new(64.7, 4, -12), COLORS.darkRed, Enum.Material.WoodPlanks)

	for _, z in { 40, 5, -30, -65 } do
		local beam = makePart(world, "CeilingBeam", Vector3.new(126, 1, 1), CFrame.new(0, 31, z), COLORS.darkWood, Enum.Material.Wood)
		beam.CanCollide = false
	end
end

local function buildHangingLight(world: Folder, position: Vector3)
	local cord = makePart(world, "LightCord", Vector3.new(0.18, 7, 0.18), CFrame.new(position + Vector3.new(0, 3.5, 0)), COLORS.dark, Enum.Material.Metal)
	cord.CanCollide = false
	local shade = makePart(world, "LightShade", Vector3.new(5.5, 1.2, 5.5), CFrame.new(position), COLORS.red, Enum.Material.Metal)
	shade.Shape = Enum.PartType.Cylinder
	shade.Orientation = Vector3.new(0, 0, 90)
	shade.CanCollide = false
	local bulb = makePart(world, "WarmBulb", Vector3.new(1.1, 1.1, 1.1), CFrame.new(position - Vector3.new(0, 0.9, 0)), Color3.fromRGB(255, 221, 145), Enum.Material.Neon)
	bulb.Shape = Enum.PartType.Ball
	bulb.CanCollide = false
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 209, 145)
	light.Brightness = 1.15
	light.Range = 34
	light.Shadows = true
	light.Parent = bulb
end

local function buildStorefrontExterior(world: Folder)
	local storefront = Instance.new("Model")
	storefront.Name = "StorefrontExterior"
	storefront:SetAttribute("Ownership", "RuntimeCompatibility")
	storefront.Parent = world

	-- The forecourt extends the walkable route outside without changing any
	-- table, launcher, or camera coordinate from the Transfer game.
	local sidewalk = makePart(storefront, "FrontSidewalk", Vector3.new(132, 1, 34), CFrame.new(0, -1, 88), Color3.fromRGB(202, 197, 187), Enum.Material.Concrete)
	sidewalk:SetAttribute("SplatSurface", true)
	for x = -60, 60, 12 do
		local seam = makePart(storefront, "SidewalkSeam", Vector3.new(0.12, 0.04, 32), CFrame.new(x, -0.47, 88), Color3.fromRGB(158, 153, 146), Enum.Material.Concrete)
		seam.CanCollide = false
		seam.CanTouch = false
	end

	-- Three openings are kept clear: the player's central entrance and the
	-- existing left/right customer doors. Wall segments frame rather than block.
	for _, segment in {
		{ x = -62.5, width = 7 },
		{ x = -37.5, width = 23 },
		{ x = 21.5, width = 55 },
		{ x = 62.5, width = 7 },
	} do
		local wall = makePart(storefront, "FrontFacade", Vector3.new(segment.width, 18, 2), CFrame.new(segment.x, 8, 72), Color3.fromRGB(214, 82, 59), Enum.Material.Brick)
		wall:SetAttribute("SplatSurface", true)
		makePart(storefront, "FacadeWainscot", Vector3.new(segment.width - 0.3, 4.5, 0.35), CFrame.new(segment.x, 1.6, 73.1), COLORS.darkWood, Enum.Material.WoodPlanks)
	end

	local header = makePart(storefront, "StorefrontHeader", Vector3.new(132, 5, 2.4), CFrame.new(0, 19.5, 72), COLORS.cream, Enum.Material.Plaster)
	header:SetAttribute("SplatSurface", true)
	local marquee = makePart(storefront, "MainMarquee", Vector3.new(50, 8, 1), CFrame.new(8, 20, 73.4), COLORS.darkRed, Enum.Material.Wood)
	marquee.CanCollide = false
	surfaceText(marquee, "MainMarqueeText", Enum.NormalId.Back, "PIZZA LAUNCH\nFLYING PIES  -  HAPPY FAMILIES", COLORS.yellow, nil, 24)

	local canopy = makePart(storefront, "StripedCanopy", Vector3.new(126, 1, 9), CFrame.new(0, 15.6, 77), COLORS.red, Enum.Material.Fabric)
	canopy.CanCollide = false
	for x = -56, 56, 16 do
		local stripe = makePart(storefront, "CanopyStripe", Vector3.new(7.5, 0.18, 8.6), CFrame.new(x, 16.15, 77), COLORS.cream, Enum.Material.Fabric)
		stripe.CanCollide = false
	end

	-- The central doors align with the authored walk spawn at X=-16. They are
	-- non-colliding glass so interaction never depends on an animation finishing.
	for _, x in { -20, -12 } do
		local door = makePart(storefront, "PlayerEntranceDoor", Vector3.new(7.5, 13, 0.45), CFrame.new(x, 6, 71), Color3.fromRGB(134, 211, 232), Enum.Material.Glass)
		door.Transparency = 0.38
		door.CanCollide = false
		local handle = makePart(storefront, "DoorHandle", Vector3.new(0.35, 3, 0.35), CFrame.new(x + (x < -16 and 2.4 or -2.4), 6, 70.5), COLORS.steel, Enum.Material.Metal)
		handle.CanCollide = false
	end
	for _, x in { -24.2, -16, -7.8 } do
		makePart(storefront, "PlayerDoorFrame", Vector3.new(0.8, 14, 1), CFrame.new(x, 6, 71), COLORS.darkWood, Enum.Material.Wood)
	end
	local entranceSign = makePart(storefront, "EntranceSign", Vector3.new(17, 2.5, 0.6), CFrame.new(-16, 13.8, 70.6), COLORS.green, Enum.Material.Wood)
	entranceSign.CanCollide = false
	surfaceText(entranceSign, "EntranceSignText", Enum.NormalId.Back, "ENTER  /  EXIT", COLORS.cream, nil, 18)

	for _, x in { -48, 48 } do
		local planter = makePart(storefront, "FrontPlanter", Vector3.new(10, 3, 5), CFrame.new(x, 1, 83), COLORS.darkWood, Enum.Material.WoodPlanks)
		planter.CanCollide = false
		for offset = -3, 3, 3 do
			local plant = makePart(storefront, "PlanterGreenery", Vector3.new(2.4, 3.5, 2.4), CFrame.new(x + offset, 3.7, 83), Color3.fromRGB(68, 143, 75), Enum.Material.Grass)
			plant.Shape = Enum.PartType.Ball
			plant.CanCollide = false
		end
	end
end

local function buildCustomerEntrances(world: Folder)
	local entranceModel = Instance.new("Model")
	entranceModel.Name = "CustomerEntrances"
	entranceModel.Parent = world
	for _, side in { -1, 1 } do
		local x = side * 54
		local glass = makePart(entranceModel, "FrontGlassDoor", Vector3.new(10, 13, 0.45), CFrame.new(x, 6, 71), Color3.fromRGB(134, 211, 232), Enum.Material.Glass)
		glass.Transparency = 0.34
		glass.CanCollide = false
		for _, frameX in { x - 5.4, x + 5.4 } do
			local frame = makePart(entranceModel, "DoorFrame", Vector3.new(0.8, 14, 1), CFrame.new(frameX, 6, 71), COLORS.darkWood, Enum.Material.Wood)
			frame.CanCollide = false
		end
		local sign = makePart(entranceModel, "WelcomeSign", Vector3.new(10, 3, 0.7), CFrame.new(x, 14.2, 70.7), COLORS.green, Enum.Material.Wood)
		sign.CanCollide = false
		surfaceText(sign, "Welcome", Enum.NormalId.Back, "CUSTOMERS\nWELCOME!", COLORS.cream, nil, 18)
		local mat = makePart(entranceModel, "WelcomeMat", Vector3.new(11, 0.14, 6), CFrame.new(x, -0.35, 67.5), COLORS.darkRed, Enum.Material.Fabric)
		mat.CanCollide = false
		mat.CanTouch = false
		-- Customers now materialize on the exterior forecourt, walk through the
		-- visible glass door, then continue along the same safe side aisle.
		local point = makePart(entranceModel, side < 0 and "CustomerEntranceLeft" or "CustomerEntranceRight", Vector3.new(1, 1, 1), CFrame.new(x, 0.2, 83), Color3.new(1, 1, 1))
		point.Transparency = 1
		point.CanCollide = false
		point.CanTouch = false
		point.CanQuery = false
	end
end

local function buildPizzaArt(world: Folder, position: Vector3, accent: Color3)
	local frame = makePart(world, "PizzaArtFrame", Vector3.new(15, 12, 0.7), CFrame.new(position), COLORS.darkWood, Enum.Material.Wood)
	local canvas = makePart(world, "PizzaArtCanvas", Vector3.new(13.5, 10.5, 0.25), CFrame.new(position + Vector3.new(0, 0, 0.5)), Color3.fromRGB(255, 243, 209))
	local pizza = makePart(world, "WallPizza", Vector3.new(0.3, 7, 7), CFrame.new(position + Vector3.new(0, 0, 0.72)) * CFrame.Angles(0, 0, math.pi / 2), COLORS.yellow)
	pizza.Shape = Enum.PartType.Cylinder
	for _, offset in { Vector3.new(-2, 1.8, 1), Vector3.new(1.8, 1.1, 1), Vector3.new(0, -2, 1) } do
		local topping = makePart(world, "ArtPepperoni", Vector3.new(0.35, 1.3, 1.3), CFrame.new(position + offset + Vector3.new(0, 0, 0.85)) * CFrame.Angles(0, 0, math.pi / 2), accent)
		topping.Shape = Enum.PartType.Cylinder
	end
	frame.CanCollide = false
	canvas.CanCollide = false
end

local function buildKitchen(world: Folder)
	local kitchen = Instance.new("Model")
	kitchen.Name = "Kitchen"
	kitchen.Parent = world

	local counter = markSplatSurface(makePart(kitchen, "ServiceCounter", Vector3.new(112, 6, 7), CFrame.new(0, 2.5, -75), COLORS.darkWood, Enum.Material.WoodPlanks))
	counter:SetAttribute("MissSurface", true)
	makePart(kitchen, "CounterTop", Vector3.new(114, 1, 9), CFrame.new(0, 5.8, -75), Color3.fromRGB(238, 224, 205), Enum.Material.Marble)

	local ovenBody = makePart(kitchen, "PizzaOven", Vector3.new(27, 18, 8), CFrame.new(-40, 9, -90.5), Color3.fromRGB(215, 190, 157), Enum.Material.Brick)
	local ovenMouth = makePart(kitchen, "OvenMouth", Vector3.new(16, 9, 0.8), CFrame.new(-40, 7.2, -85.9), Color3.fromRGB(34, 28, 27), Enum.Material.Slate)
	local fire = makePart(kitchen, "OvenFire", Vector3.new(10, 2.5, 0.4), CFrame.new(-40, 3.7, -85.35), Color3.fromRGB(255, 118, 34), Enum.Material.Neon)
	fire.CanCollide = false
	local ovenLight = Instance.new("PointLight")
	ovenLight.Color = Color3.fromRGB(255, 132, 50)
	ovenLight.Brightness = 2
	ovenLight.Range = 22
	ovenLight.Parent = fire
	surfaceText(ovenBody, "OvenSign", Enum.NormalId.Back, "STONE-FIRED\nPIZZA OVEN", COLORS.darkRed)

	local menu = makePart(kitchen, "MenuBoard", Vector3.new(47, 15, 0.8), CFrame.new(21, 20, -94.6), COLORS.green, Enum.Material.Wood)
	surfaceText(menu, "Menu", Enum.NormalId.Back, "TODAY'S MENU\nCHEESE   PEPPERONI   VEGGIE\nEVERY PIZZA: LAUNCH-READY!", Color3.fromRGB(255, 244, 203), nil, 27)

	local register = makeReactive(kitchen, "CashRegister", Vector3.new(5, 3.5, 4), CFrame.new(29, 8, -73), COLORS.steel, Enum.Material.Metal)
	surfaceText(register, "RegisterDisplay", Enum.NormalId.Back, "$ PIZZA $", COLORS.yellow, COLORS.dark, 20)

	for index = 1, 4 do
		makeReactive(kitchen, "PizzaBox", Vector3.new(8, 0.8, 8), CFrame.new(45, 6.5 + index * 0.85, -74.5) * CFrame.Angles(0, math.rad((index % 2) * 5), 0), index % 2 == 0 and Color3.fromRGB(246, 221, 177) or Color3.fromRGB(233, 205, 159), Enum.Material.Cardboard)
	end

	for index = 1, 5 do
		local cup = makeReactive(kitchen, "Cup", Vector3.new(1.4, 2.5, 1.4), CFrame.new(-8 + index * 2, 7.5, -74), Color3.fromRGB(244, 244, 238))
		cup.Shape = Enum.PartType.Cylinder
		cup.Orientation = Vector3.new(0, 0, 90)
	end

	buildPizzaArt(world, Vector3.new(-51, 20, -94.5), COLORS.red)
	buildPizzaArt(world, Vector3.new(53, 20, -94.5), COLORS.green)
end

local function addHair(model: Model, head: BasePart, style: string, color: Color3)
	local function hairPart(name: string, size: Vector3, offset: Vector3, shape: Enum.PartType?)
		local item = makePart(model, name, size * 0.72, head.CFrame * CFrame.new(offset * 0.72), color)
		item.CanCollide = false
		item:SetAttribute("CustomerPart", true)
		item:SetAttribute("TableId", model:GetAttribute("TableId"))
		item:SetAttribute("ResetCFrame", item.CFrame)
		if shape then
			item.Shape = shape
		end
		return item
	end

	if style == "cap" then
		hairPart("Cap", Vector3.new(4.5, 1.3, 4.5), Vector3.new(0, 1.8, 0), Enum.PartType.Cylinder).Orientation = Vector3.new(0, 0, 90)
		hairPart("CapBrim", Vector3.new(3.5, 0.4, 1.4), Vector3.new(0, 1.35, 2.1))
	elseif style == "bow" then
		hairPart("Hair", Vector3.new(4.2, 2, 4.1), Vector3.new(0, 1.25, -0.25), Enum.PartType.Ball)
		hairPart("BowLeft", Vector3.new(1.5, 1.3, 0.7), Vector3.new(-0.9, 2.3, 0.3), Enum.PartType.Ball).Color = Color3.fromRGB(255, 94, 127)
		hairPart("BowRight", Vector3.new(1.5, 1.3, 0.7), Vector3.new(0.9, 2.3, 0.3), Enum.PartType.Ball).Color = Color3.fromRGB(255, 94, 127)
	elseif style == "spikes" then
		hairPart("Hair", Vector3.new(4.4, 2.1, 4.2), Vector3.new(0, 1.35, -0.2), Enum.PartType.Ball)
		for x = -1.5, 1.5, 1.5 do
			local spike = hairPart("HairSpike", Vector3.new(0.9, 2.4, 0.9), Vector3.new(x, 2.5, 0), Enum.PartType.Ball)
			spike.Orientation = Vector3.new(0, 0, x * 12)
		end
	elseif style == "beanie" then
		hairPart("Beanie", Vector3.new(4.5, 2.2, 4.3), Vector3.new(0, 1.4, -0.15), Enum.PartType.Ball).Color = Color3.fromRGB(45, 130, 92)
		hairPart("Pompom", Vector3.new(1.3, 1.3, 1.3), Vector3.new(0, 3, 0), Enum.PartType.Ball).Color = Color3.fromRGB(255, 211, 74)
	elseif style == "bun" then
		hairPart("Hair", Vector3.new(4.3, 2.2, 4.2), Vector3.new(0, 1.3, -0.25), Enum.PartType.Ball)
		hairPart("HairBun", Vector3.new(2.5, 2.5, 2.5), Vector3.new(0, 2.7, -0.6), Enum.PartType.Ball)
	elseif style == "chef" then
		hairPart("ChefHatBase", Vector3.new(4.6, 1.4, 4.4), Vector3.new(0, 1.9, 0), Enum.PartType.Cylinder).Color = Color3.fromRGB(250, 247, 234)
		for x = -1.2, 1.2, 1.2 do
			hairPart("ChefHatPuff", Vector3.new(2.4, 2.4, 2.4), Vector3.new(x, 3, 0), Enum.PartType.Ball).Color = Color3.fromRGB(250, 247, 234)
		end
	end
end

local function buildCustomer(parent: Model, definition, seatPosition: Vector3)
	local model = Instance.new("Model")
	model.Name = "Customer"
	model:SetAttribute("TableId", definition.id)
	model:SetAttribute("CustomerName", definition.customer)
	model.Parent = parent

	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.BreakJointsOnDeath = false
	humanoid.Parent = model

	local root = makePart(model, "HumanoidRootPart", Vector3.new(2, 2, 1), CFrame.new(seatPosition + Vector3.new(0, 4.5, 0)), definition.skin)
	root.Transparency = 1
	root.CanCollide = false
	model.PrimaryPart = root

	local torso = makePart(model, "Torso", Vector3.new(3.2, 3.6, 1.8), CFrame.new(seatPosition + Vector3.new(0, 4.7, 0)), definition.shirt)
	local head = makePart(model, "Head", Vector3.new(3.1, 3.1, 3.1), CFrame.new(seatPosition + Vector3.new(0, 7.8, 0)), definition.skin)
	head.Shape = Enum.PartType.Ball
	local leftArm = makePart(model, "LeftArm", Vector3.new(1.1, 3.4, 1.1), CFrame.new(seatPosition + Vector3.new(-2.15, 4.8, 0.2)) * CFrame.Angles(0, 0, math.rad(-8)), definition.skin)
	local rightArm = makePart(model, "RightArm", Vector3.new(1.1, 3.4, 1.1), CFrame.new(seatPosition + Vector3.new(2.15, 4.8, 0.2)) * CFrame.Angles(0, 0, math.rad(8)), definition.skin)
	local leftLeg = makePart(model, "LeftLeg", Vector3.new(1.2, 3.1, 1.3), CFrame.new(seatPosition + Vector3.new(-0.82, 2.4, 1.1)) * CFrame.Angles(math.rad(-28), 0, 0), Color3.fromRGB(54, 68, 91))
	local rightLeg = makePart(model, "RightLeg", Vector3.new(1.2, 3.1, 1.3), CFrame.new(seatPosition + Vector3.new(0.82, 2.4, 1.1)) * CFrame.Angles(math.rad(-28), 0, 0), Color3.fromRGB(54, 68, 91))
	for _, bodyPart in { torso, head, leftArm, rightArm, leftLeg, rightLeg } do
		bodyPart.CanCollide = false
		bodyPart:SetAttribute("CustomerPart", true)
		bodyPart:SetAttribute("TableId", definition.id)
		bodyPart:SetAttribute("ResetCFrame", bodyPart.CFrame)
	end

	surfaceText(head, "Face", Enum.NormalId.Back, "^  ^\n\\___/", COLORS.dark, nil, 45)
	addHair(model, head, definition.style, Color3.fromRGB(63, 43, 37))
	local marker = billboard(head, "WaitingMarker", "🍕", definition.color, Vector3.new(0, 4.7, 0), Vector2.new(42, 42))
	marker.MaxDistance = 95
	local customerPrompt = prompt(head, "CustomerPrompt", "Say Hi", definition.customer, 24)
	customerPrompt:SetAttribute("TableId", definition.id)
	return model
end

local function buildTable(world: Folder, definition)
	local model = Instance.new("Model")
	model.Name = string.format("Table_%d_%s", definition.id, definition.customer)
	model:SetAttribute("TableId", definition.id)
	model:SetAttribute("CustomerName", definition.customer)
	model.Parent = world

	local p = definition.position
	local topWidth = definition.id <= 2 and 14 or (definition.id <= 4 and 16 or 18)
	local topDepth = definition.id <= 2 and 9 or (definition.id <= 4 and 10 or 11)
	local seatOffset = topDepth * 0.5 + 3.2
	local rug = makePart(model, "Rug", Vector3.new(topWidth + 7, 0.12, topDepth + 9), CFrame.new(p + Vector3.new(0, -0.38, -1)), definition.color:Lerp(COLORS.cream, 0.58), Enum.Material.Fabric)
	rug.CanCollide = false
	rug.CanTouch = false
	local top = makePart(model, "TableTop", Vector3.new(topWidth, 1, topDepth), CFrame.new(p + Vector3.new(0, 4.2, 0)), Color3.fromRGB(250, 231, 196), Enum.Material.Wood)
	top:SetAttribute("TableId", definition.id)
	top:SetAttribute("DeliverySurface", true)
	top:SetAttribute("SplatSurface", true)
	makePart(model, "TablePost", Vector3.new(3, 4.2, 3), CFrame.new(p + Vector3.new(0, 1.7, 0)), COLORS.darkWood, Enum.Material.Wood)
	makePart(model, "TableBase", Vector3.new(9, 0.8, 7), CFrame.new(p + Vector3.new(0, -0.2, 0)), COLORS.darkWood, Enum.Material.Wood)

	local plate = makePart(model, "Plate", Vector3.new(0.35, 6.8, 6.8), CFrame.new(p + Vector3.new(0, 4.85, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(255, 255, 248))
	plate.Shape = Enum.PartType.Cylinder
	plate.CanCollide = false
	plate:SetAttribute("TableId", definition.id)
	plate:SetAttribute("DeliverySurface", true)
	local ring = makePart(model, "TargetRing", Vector3.new(0.15, 8, 8), CFrame.new(p + Vector3.new(0, 5.04, 0)) * CFrame.Angles(0, 0, math.pi / 2), definition.color, Enum.Material.Neon)
	ring.Shape = Enum.PartType.Cylinder
	ring.CanCollide = false
	ring.CanTouch = false
	ring.Transparency = 0.18
	ring:SetAttribute("TableId", definition.id)

	local boothSeat = makePart(model, "BoothSeat", Vector3.new(topWidth - 2, 1.5, 4.2), CFrame.new(p + Vector3.new(0, 2, -seatOffset - 0.5)), definition.color, Enum.Material.Fabric)
	local boothBack = makePart(model, "BoothBack", Vector3.new(topWidth - 1, definition.id <= 2 and 6 or 7, 1.5), CFrame.new(p + Vector3.new(0, 5, -seatOffset - 2.2)), definition.color:Lerp(COLORS.darkRed, 0.2), Enum.Material.Fabric)
	boothSeat:SetAttribute("SplatSurface", true)
	boothBack:SetAttribute("SplatSurface", true)

	local edge = topWidth * 0.5 - 1.15
	local shaker = makeReactive(model, "TableParmesan", Vector3.new(1.15, 2.1, 1.15), CFrame.new(p + Vector3.new(-edge, 5.75, -0.6)), Color3.fromRGB(247, 235, 187))
	shaker.Shape = Enum.PartType.Cylinder
	local sauce = makeReactive(model, "TableSauce", Vector3.new(1.2, 2.5, 1.2), CFrame.new(p + Vector3.new(edge, 5.95, 0.7)), definition.id % 2 == 0 and Color3.fromRGB(211, 48, 47) or Color3.fromRGB(237, 169, 43))
	sauce.Shape = Enum.PartType.Cylinder
	if definition.id >= 3 then
		local menu = makeReactive(model, "TableMenu", Vector3.new(2.8, 2.2, 0.35), CFrame.new(p + Vector3.new(edge - 1.2, 6.0, -2.7)) * CFrame.Angles(0, math.rad(-12), 0), COLORS.green, Enum.Material.Wood)
		menu.CanCollide = false
	end

	buildCustomer(model, definition, p + Vector3.new(0, 0, -seatOffset))
	return model
end

local function buildCondimentStation(world: Folder, x: number, z: number)
	local station = Instance.new("Model")
	station.Name = "CondimentStation"
	station.Parent = world
	makePart(station, "Stand", Vector3.new(10, 5, 6), CFrame.new(x, 2, z), COLORS.darkWood, Enum.Material.Wood)
	makePart(station, "Top", Vector3.new(11, 0.7, 7), CFrame.new(x, 4.8, z), Color3.fromRGB(238, 221, 194), Enum.Material.Marble)
	for index, data in {
		{ Color3.fromRGB(216, 45, 45), "KETCHUP" },
		{ Color3.fromRGB(245, 194, 50), "MUSTARD" },
		{ Color3.fromRGB(82, 164, 75), "PEPPER" },
	} do
		local bottle = makeReactive(station, data[2], Vector3.new(1.5, 3, 1.5), CFrame.new(x - 3 + index * 2.2, 6.5, z), data[1])
		bottle.Shape = Enum.PartType.Cylinder
		bottle.Orientation = Vector3.new(0, 0, 90)
	end
	local sign = makeReactive(station, "NapkinSign", Vector3.new(7, 3.5, 0.6), CFrame.new(x, 8, z - 2.7), COLORS.green)
	surfaceText(sign, "Sign", Enum.NormalId.Back, "NAPKINS\n& SAUCE", Color3.new(1, 1, 1), nil, 20)
end

local function buildLauncher(world: Folder)
	local station = Instance.new("Model")
	station.Name = "LauncherStation"
	station.Parent = world
	makePart(station, "Platform", Vector3.new(30, 1, 20), CFrame.new(0, -0.1, 66), COLORS.darkWood, Enum.Material.WoodPlanks)
	local marquee = makePart(station, "Backboard", Vector3.new(12, 4, 1), CFrame.new(18, 9, 72.5), COLORS.red, Enum.Material.Wood)
	marquee.CanCollide = false
	surfaceText(station.Backboard, "StationTitle", Enum.NormalId.Back, "PIZZA\nLAUNCH", COLORS.yellow, nil, 23)

	local operatorConsole = makePart(station, "OperatorConsole", Vector3.new(9, 4.5, 3), CFrame.new(0, 3.2, 73), COLORS.green, Enum.Material.Metal)
	operatorConsole.CanCollide = false
	surfaceText(operatorConsole, "ConsoleLabel", Enum.NormalId.Back, "PRESS E\nTO LAUNCH", COLORS.yellow, COLORS.dark, 18)
	prompt(operatorConsole, "LauncherPrompt", "Operate Launcher", "Pizza Cannon", 12)
	local operatorSpot = makePart(station, "OperatorSpot", Vector3.new(0.18, 8, 8), CFrame.new(0, 0.04, 73) * CFrame.Angles(0, 0, math.pi / 2), COLORS.green, Enum.Material.Neon)
	operatorSpot.Shape = Enum.PartType.Cylinder
	operatorSpot.CanCollide = false
	operatorSpot.CanTouch = false
	operatorSpot.Transparency = 0.3

	local recordConsole = makePart(station, "RecordRunConsole", Vector3.new(10, 5.5, 3), CFrame.new(-13, 3.7, 73), COLORS.red, Enum.Material.Metal)
	recordConsole.CanCollide = false
	surfaceText(recordConsole, "RecordRunSign", Enum.NormalId.Back, "1-MINUTE RECORD RUN\nFAR TABLES SCORE MORE", COLORS.yellow, COLORS.dark, 18)
	prompt(recordConsole, "RecordRunPrompt", "Start 1-Minute Record Run", "Pizza Launch Records", 12)
	local recordGlow = makePart(station, "RecordRunGlow", Vector3.new(0.16, 9, 9), CFrame.new(-13, 0.04, 73) * CFrame.Angles(0, 0, math.pi / 2), COLORS.yellow, Enum.Material.Neon)
	recordGlow.Shape = Enum.PartType.Cylinder
	recordGlow.CanCollide = false
	recordGlow.CanTouch = false
	recordGlow.Transparency = 0.38

	local bestDisplay = makePart(station, "PersonalBestDisplay", Vector3.new(10, 3.6, 0.7), CFrame.new(-13, 8.8, 72.7), COLORS.darkRed, Enum.Material.Wood)
	bestDisplay.CanCollide = false
	surfaceText(bestDisplay, "PersonalBestGui", Enum.NormalId.Back, "YOUR BEST\nLOADING...", COLORS.cream, nil, 18)

	-- A compact restaurant machine, deliberately all behind the muzzle so the
	-- aiming lane remains clean from the operator camera to every table.
	local base = makePart(station, "CannonBase", Vector3.new(18, 5, 16), CFrame.new(0, 2.5, 65), COLORS.darkRed, Enum.Material.Metal)
	base.Shape = Enum.PartType.Cylinder
	base.Orientation = Vector3.new(0, 0, 90)
	makePart(station, "BaseTrim", Vector3.new(19, 1.1, 17), CFrame.new(0, 4.4, 65), COLORS.yellow, Enum.Material.Metal)
	local feedOven = makePart(station, "PizzaFeedOven", Vector3.new(13, 11, 10), CFrame.new(0, 7, 75), COLORS.darkWood, Enum.Material.Brick)
	local ovenDoor = makePart(station, "OvenMouth", Vector3.new(8, 6, 0.45), CFrame.new(0, 7, 69.8), COLORS.dark, Enum.Material.Metal)
	ovenDoor.CanCollide = false
	local ovenFire = makePart(station, "OvenGlow", Vector3.new(6.8, 4.6, 0.18), CFrame.new(0, 7, 69.52), COLORS.orange, Enum.Material.Neon)
	ovenFire.CanCollide = false
	local ovenLight = Instance.new("PointLight")
	ovenLight.Color = COLORS.orange
	ovenLight.Brightness = 2.3
	ovenLight.Range = 19
	ovenLight.Parent = ovenFire
	surfaceText(feedOven, "OvenBrand", Enum.NormalId.Back, "MAMA MIA\nPIZZA PRESS", COLORS.cream, COLORS.darkRed, 18)
	local steam = Instance.new("Smoke")
	steam.Name = "WarmOvenSteam"
	steam.Color = Color3.fromRGB(255, 238, 210)
	steam.Opacity = 0.24
	steam.RiseVelocity = 3
	steam.Size = 4
	steam.Parent = feedOven
	makePart(station, "FeedBelt", Vector3.new(8, 0.7, 10), CFrame.new(0, 5.1, 71.5), COLORS.steel, Enum.Material.Metal)
	for z = 68, 75, 2 do
		local roller = makePart(station, "FeedRoller", Vector3.new(1, 6.5, 1), CFrame.new(0, 5.85, z), COLORS.yellow, Enum.Material.Metal)
		roller.Shape = Enum.PartType.Cylinder
		roller.Orientation = Vector3.new(0, 0, 90)
	end
	for _, x in { -7.5, 7.5 } do
		local wheel = makePart(station, "CannonWheel", Vector3.new(2, 11, 11), CFrame.new(x, 3.2, 66), COLORS.steel, Enum.Material.Metal)
		wheel.Shape = Enum.PartType.Cylinder
	end
	local gaugePost = makePart(station, "PressureGaugePost", Vector3.new(0.8, 7, 0.8), CFrame.new(10, 7, 70), COLORS.steel, Enum.Material.Metal)
	local gauge = makePart(station, "PressureGauge", Vector3.new(0.65, 6, 6), CFrame.new(10, 10, 70), COLORS.cream, Enum.Material.Metal)
	gauge.Shape = Enum.PartType.Cylinder
	gauge.Orientation = Vector3.new(0, 0, 90)
	gauge.CanCollide = false
	surfaceText(gauge, "PressureReadout", Enum.NormalId.Back, "POWER\nHOT", COLORS.darkRed, nil, 16)
	local leverBase = makePart(station, "CrankBase", Vector3.new(3.5, 3.5, 3.5), CFrame.new(-10, 5.5, 70), COLORS.steel, Enum.Material.Metal)
	local lever = makePart(station, "LaunchCrank", Vector3.new(1, 9, 1), CFrame.new(-10, 9, 70) * CFrame.Angles(0, 0, math.rad(-32)), COLORS.red, Enum.Material.Metal)
	local leverKnob = makePart(station, "CrankKnob", Vector3.new(2.6, 2.6, 2.6), lever.CFrame * CFrame.new(0, 4.4, 0), COLORS.yellow, Enum.Material.SmoothPlastic)
	leverKnob.Shape = Enum.PartType.Ball

	local rig = Instance.new("Model")
	rig.Name = "AimRig"
	rig.Parent = station
	local pivot = makePart(rig, "AimPivot", Vector3.new(0.2, 0.2, 0.2), CFrame.new(Config.LAUNCH_ORIGIN), Color3.new(1, 1, 1))
	pivot.Transparency = 1
	pivot.CanCollide = false
	pivot.CanTouch = false
	rig.PrimaryPart = pivot
	local barrel = makePart(rig, "Barrel", Vector3.new(7.4, 7.4, 16), CFrame.new(Config.LAUNCH_ORIGIN + Vector3.new(0, 0, 7.4)), Color3.fromRGB(186, 47, 46), Enum.Material.Metal)
	barrel.CanCollide = false
	local barrelBand = makePart(rig, "BarrelBand", Vector3.new(8.2, 8.2, 1.2), CFrame.new(Config.LAUNCH_ORIGIN + Vector3.new(0, 0, 2.0)), COLORS.yellow, Enum.Material.Metal)
	barrelBand.CanCollide = false
	local muzzle = makePart(rig, "Muzzle", Vector3.new(9, 9, 2.2), CFrame.new(Config.LAUNCH_ORIGIN), COLORS.yellow, Enum.Material.Metal)
	muzzle.CanCollide = false
	local muzzleOpening = makePart(rig, "MuzzleOpening", Vector3.new(0.25, 6.7, 6.7), CFrame.new(Config.LAUNCH_ORIGIN + Vector3.new(0, 0, -1.15)), COLORS.dark, Enum.Material.SmoothPlastic)
	muzzleOpening.CanCollide = false
	local loadedPizza = makePart(rig, "LoadedPizza", Vector3.new(0.5, 5.8, 5.8), CFrame.new(Config.LAUNCH_ORIGIN + Vector3.new(0, 0, -1.35)) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(255, 197, 68), Enum.Material.SmoothPlastic)
	loadedPizza.Shape = Enum.PartType.Cylinder
	loadedPizza.CanCollide = false
	for _, offset in { Vector3.new(0, 1.3, 1.1), Vector3.new(0, -1.2, 1.0), Vector3.new(0, 0.2, -1.45) } do
		local pepperoni = makePart(rig, "LoadedPepperoni", Vector3.new(0.22, 1.05, 1.05), loadedPizza.CFrame * CFrame.new(offset), COLORS.red, Enum.Material.SmoothPlastic)
		pepperoni.Shape = Enum.PartType.Cylinder
		pepperoni.CanCollide = false
	end
	local muzzleLight = Instance.new("PointLight")
	muzzleLight.Color = COLORS.yellow
	muzzleLight.Brightness = 1.2
	muzzleLight.Range = 13
	muzzleLight.Parent = muzzle

	for _, x in { -13, 13 } do
		local rail = makePart(station, "SafetyRail", Vector3.new(1, 5, 18), CFrame.new(x, 2.5, 65), COLORS.yellow, Enum.Material.Metal)
		rail.CanCollide = false
	end

	local frontCounter = Instance.new("Model")
	frontCounter.Name = "FrontOrderCounter"
	frontCounter.Parent = world
	local counterBody = makePart(frontCounter, "CounterBody", Vector3.new(27, 5.5, 8), CFrame.new(40, 2.25, 67), COLORS.darkWood, Enum.Material.WoodPlanks)
	counterBody:SetAttribute("SplatSurface", true)
	local counterTop = makePart(frontCounter, "CounterTop", Vector3.new(29, 0.8, 10), CFrame.new(40, 5.35, 67), Color3.fromRGB(243, 225, 197), Enum.Material.Marble)
	counterTop:SetAttribute("SplatSurface", true)
	local register = makeReactive(frontCounter, "FrontRegister", Vector3.new(5, 3.2, 4), CFrame.new(36, 7.3, 67), COLORS.steel, Enum.Material.Metal)
	surfaceText(register, "RegisterFace", Enum.NormalId.Back, "ORDER\nHERE", COLORS.yellow, COLORS.dark, 20)
	prompt(register, "RegisterPrompt", "Check Shift", "Order Register", 11)
	for index, data in {
		{ "Parmesan", Color3.fromRGB(244, 237, 199) },
		{ "PepperFlakes", Color3.fromRGB(190, 56, 45) },
		{ "NapkinDispenser", Color3.fromRGB(194, 201, 207) },
	} do
		local prop = makeReactive(frontCounter, data[1], Vector3.new(1.6, 2.6, 1.6), CFrame.new(42 + index * 2.2, 7, 67), data[2], index == 3 and Enum.Material.Metal or Enum.Material.SmoothPlastic)
		prop.Shape = index == 3 and Enum.PartType.Block or Enum.PartType.Cylinder
	end
end

local function buildLegendsBoard(world: Folder)
	local model = Instance.new("Model")
	model.Name = "PizzaLaunchLegends"
	model.Parent = world
	makePart(model, "Frame", Vector3.new(1.2, 22, 32), CFrame.new(59.2, 15, 45), COLORS.darkWood, Enum.Material.Wood)
	local board = makePart(model, "LegendsBoard", Vector3.new(1.35, 19, 29), CFrame.new(58.5, 15, 45), COLORS.darkRed, Enum.Material.SmoothPlastic)
	board.CanCollide = false
	surfaceText(board, "LegendsGui", Enum.NormalId.Left, "PIZZA LAUNCH LEGENDS\n\nLoading all-time records...", COLORS.cream, nil, 20)
	for _, y in { 4.2, 25.8 } do
		local lamp = makePart(model, "BoardLamp", Vector3.new(2, 1, 30), CFrame.new(57.5, y, 45), COLORS.yellow, Enum.Material.Neon)
		lamp.CanCollide = false
	end
end

local function buildDecor(world: Folder)
	buildCondimentStation(world, -57, 0)
	buildCondimentStation(world, 57, -18)

	for _, position in {
		Vector3.new(-43, 26, 27), Vector3.new(0, 26, 2), Vector3.new(43, 26, -20), Vector3.new(0, 26, -52),
	} do
		buildHangingLight(world, position)
	end

	for _, data in {
		{ -60, 14, 39, Color3.fromRGB(119, 198, 230) },
		{ 60, 14, 21, Color3.fromRGB(119, 198, 230) },
		{ -60, 14, -48, Color3.fromRGB(255, 198, 95) },
		{ 60, 14, -62, Color3.fromRGB(255, 198, 95) },
	} do
		local window = makePart(world, "RestaurantWindow", Vector3.new(0.45, 15, 19), CFrame.new(data[1], data[2], data[3]), data[4], Enum.Material.Glass)
		window.Transparency = 0.25
		window.CanCollide = false
		makePart(world, "WindowCross", Vector3.new(0.7, 1, 19), CFrame.new(data[1] * 0.999, data[2], data[3]), COLORS.darkWood)
		makePart(world, "WindowCross", Vector3.new(0.7, 15, 1), CFrame.new(data[1] * 0.999, data[2], data[3]), COLORS.darkWood)
	end

	for _, x in { -51, 51 } do
		local anchor = makePart(world, "BalloonAnchor", Vector3.new(0.6, 0.6, 0.6), CFrame.new(x, 3, 52), COLORS.dark)
		anchor.CanCollide = false
		for index, color in { COLORS.red, COLORS.yellow, COLORS.green } do
			local balloon = makeReactive(world, "Balloon", Vector3.new(3.2, 4, 3.2), CFrame.new(x + (index - 2) * 2.5, 12 + index, 52), color, Enum.Material.SmoothPlastic)
			balloon.Shape = Enum.PartType.Ball
			balloon.CanCollide = false
		end
	end

	local cupTray = makePart(world, "CupTray", Vector3.new(11, 1, 7), CFrame.new(0, 2.2, -1), COLORS.darkWood, Enum.Material.Wood)
	for index = 1, 4 do
		local cup = makeReactive(world, "LooseCup", Vector3.new(1.7, 3.4, 1.7), CFrame.new(-4.2 + index * 1.7, 4.35, -1), index % 2 == 0 and COLORS.red or COLORS.yellow)
		cup.Shape = Enum.PartType.Cylinder
		cup.Orientation = Vector3.new(0, 0, 90)
	end
	local floorSign = makeReactive(world, "WobblySpecialSign", Vector3.new(10, 7, 1), CFrame.new(0, 4, -32), COLORS.green, Enum.Material.Wood)
	floorSign:SetAttribute("MinRound", 3)
	surfaceText(floorSign, "Special", Enum.NormalId.Back, "TODAY'S SPECIAL\nFLYING PIZZA", Color3.new(1, 1, 1), nil, 20)
	for index = 1, 3 do
		local box = makeReactive(world, "LoosePizzaBox", Vector3.new(8, 0.9, 8), CFrame.new((index - 2) * 1.1, 0.3 + index * 0.9, -63), Color3.fromRGB(242, 214, 166), Enum.Material.Cardboard)
		box:SetAttribute("MinRound", 4)
	end
end

function WorldBuilder.build()
	local old = Workspace:FindFirstChild("PizzaLaunchWorld")
	if old then
		old:Destroy()
	end
	configureLighting()
	StarterGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor

	local world = Instance.new("Folder")
	world.Name = "PizzaLaunchWorld"
	world.Parent = Workspace

	buildShell(world)
	buildStorefrontExterior(world)
	buildCustomerEntrances(world)
	buildKitchen(world)
	buildDecor(world)
	buildLauncher(world)
	buildLegendsBoard(world)
	for _, definition in Config.TABLES do
		buildTable(world, definition)
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "PlayerSpawn"
	spawn.Size = Vector3.new(10, 1, 8)
	local spawnPosition = Vector3.new(Config.WALK_SPAWN_CFRAME.Position.X, 0, Config.WALK_SPAWN_CFRAME.Position.Z)
	spawn.CFrame = CFrame.lookAt(spawnPosition, spawnPosition + Config.WALK_SPAWN_CFRAME.LookVector)
	spawn.Anchored = true
	spawn.Transparency = 1
	spawn.CanCollide = true
	spawn.Neutral = true
	spawn.Parent = world
	return world
end

return WorldBuilder
