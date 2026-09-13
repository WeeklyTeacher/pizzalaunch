-- Original, source-native Pizza Launch hero prefab. Dimensions are in studs.
-- The visual rig aims around Config.LAUNCH_ORIGIN; no visual defines shot physics.
local LauncherArt = {}

local function part(parent, name, size, frame, color, material, shape)
	local item = Instance.new("Part")
	item.Name, item.Size, item.CFrame = name, size, frame
	item.Color, item.Material = color, material or Enum.Material.SmoothPlastic
	item.Anchored, item.CanCollide, item.CanTouch, item.CanQuery = true, false, false, false
	item.TopSurface, item.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	item:SetAttribute("CosmeticOnly", true)
	if shape then item.Shape = shape end
	item.Parent = parent
	return item
end

local function textFace(parent, name, face, text, color)
	local gui = Instance.new("SurfaceGui")
	gui.Name, gui.Face = name, face
	gui.SizingMode, gui.PixelsPerStud = Enum.SurfaceGuiSizingMode.PixelsPerStud, 48
	gui.LightInfluence, gui.Parent = 0.2, parent
	local label = Instance.new("TextLabel")
	label.Name, label.Size = "Label", UDim2.fromScale(1, 1)
	label.BackgroundTransparency, label.TextColor3 = 1, color
	label.Text, label.TextScaled, label.TextWrapped = text, true, true
	label.Font, label.Parent = Enum.Font.GothamBold, gui
	return gui
end

function LauncherArt.build(station, Config, colors, pizzaVisual)
	station:SetAttribute("ArtPrefab", "LauncherArt.v1")
	local steel = Color3.fromRGB(88, 99, 101)
	local warmMetal = Color3.fromRGB(219, 171, 76)
	local ovenCream = Color3.fromRGB(241, 226, 199)
	local cylinderZ = CFrame.Angles(0, math.pi / 2, 0)
	local cylinderY = CFrame.Angles(0, 0, math.pi / 2)

	-- One stable walking collider follows the oven housing. It is behind every
	-- permitted launch direction; the old oversized cylinder envelope is retired.
	local collider = part(station, "LauncherHousingCollider", Vector3.new(12, 8, 11), CFrame.new(0, 4.4, 66), colors.dark)
	collider.Transparency, collider.CanCollide = 1, true
	collider:SetAttribute("CosmeticOnly", nil)
	collider:SetAttribute("LauncherHousingCollision", true)

	part(station, "CannonBase", Vector3.new(1.8, 15, 14), CFrame.new(0, 0.5, 66) * cylinderY, steel, Enum.Material.Metal, Enum.PartType.Cylinder)
	part(station, "BaseTrim", Vector3.new(13, 0.65, 12), CFrame.new(0, 1.65, 66), colors.darkRed)
	part(station, "ForwardChassis", Vector3.new(11, 1, 17), CFrame.new(0, 1.4, 57), steel, Enum.Material.Metal)
	for _, x in { -4.7, 4.7 } do
		part(station, "MuzzleYoke", Vector3.new(0.8, 10.6, 0.8), CFrame.new(x, 6.6, 50), steel, Enum.Material.Metal)
		part(station, "MuzzleBearing", Vector3.new(1.5, 1.5, 1.5), CFrame.new(x, 12, 50), warmMetal, Enum.Material.Metal, Enum.PartType.Ball)
	end
	local oven = part(station, "PizzaFeedOven", Vector3.new(12, 7.2, 10.5), CFrame.new(0, 5.4, 66), colors.red)
	part(station, "OvenCrown", Vector3.new(12, 3, 10.5), CFrame.new(0, 8.1, 66), colors.red, nil, Enum.PartType.Ball)
	part(station, "OvenDoorSurround", Vector3.new(9.2, 5.8, 0.45), CFrame.new(0, 5.1, 71.42), ovenCream)
	part(station, "OvenMouth", Vector3.new(7.7, 4.5, 0.18), CFrame.new(0, 5.0, 71.71), colors.dark)
	local glow = part(station, "OvenGlow", Vector3.new(6.7, 1.0, 0.12), CFrame.new(0, 3.3, 71.85), colors.orange, Enum.Material.Neon)
	local ovenLight = Instance.new("PointLight")
	ovenLight.Color, ovenLight.Brightness, ovenLight.Range = Color3.fromRGB(255, 181, 96), 2.3, 12
	ovenLight.Shadows, ovenLight.Parent = false, glow
	for _, x in { -4.8, 4.8 } do
		part(station, "OvenDoorRivet", Vector3.new(0.3, 0.3, 0.15), CFrame.new(x, 6.8, 71.68), warmMetal, Enum.Material.Metal, Enum.PartType.Ball)
	end
	local steam = Instance.new("Smoke")
	steam.Name, steam.Color = "WarmOvenSteam", Color3.fromRGB(246, 236, 215)
	steam.Opacity, steam.RiseVelocity, steam.Size = 0.24, 2, 2
	steam.Parent = oven
	part(station, "FeedBelt", Vector3.new(8.5, 0.55, 5), CFrame.new(0, 3.05, 74), steel, Enum.Material.Metal)
	for _, x in { -4.2, 4.2 } do
		part(station, "FeedTrayRail", Vector3.new(0.3, 0.75, 5), CFrame.new(x, 3.4, 74), ovenCream, Enum.Material.Metal)
	end
	for z = 72.3, 75.3, 1 do
		local roller = part(station, "FeedRoller", Vector3.new(7.6, 0.42, 0.42), CFrame.new(0, 3.45, z), steel, Enum.Material.Metal, Enum.PartType.Cylinder)
		roller:SetAttribute("CosmeticBaseCFrame", roller.CFrame)
	end

	-- The gauge's local -X disk face points toward the operator (+Z).
	part(station, "PressureGaugePost", Vector3.new(0.65, 6, 0.65), CFrame.new(8.1, 6.4, 66.5), steel, Enum.Material.Metal)
	part(station, "GaugeRim", Vector3.new(0.75, 5.4, 5.4), CFrame.new(8.1, 10, 66.5) * cylinderZ, steel, Enum.Material.Metal, Enum.PartType.Cylinder)
	local gauge = part(station, "PressureGauge", Vector3.new(0.18, 4.75, 4.75), CFrame.new(8.1, 10, 66.94) * cylinderZ, ovenCream, nil, Enum.PartType.Cylinder)
	textFace(gauge, "PressureReadout", Enum.NormalId.Left, "POWER\n0%", colors.darkRed)
	for index = 0, 6 do
		local angle = math.rad(-140 + index * 46.7)
		part(station, "GaugeTick", Vector3.new(0.18, 0.4, 0.12), CFrame.new(8.1 + math.sin(angle) * 2.05, 10 + math.cos(angle) * 2.05, 67.1) * CFrame.Angles(0, 0, -angle), index >= 5 and colors.red or steel)
	end
	part(station, "CrankBase", Vector3.new(2.2, 2.2, 2.2), CFrame.new(-7.7, 6.2, 67), steel, Enum.Material.Metal, Enum.PartType.Ball)
	local crankRig = Instance.new("Model")
	crankRig.Name, crankRig.Parent = "CosmeticCrankRig", station
	local crankBase = CFrame.new(-7.7, 6.2, 67)
	crankRig:SetAttribute("BasePivot", crankBase)
	local crankPivot = part(crankRig, "CrankPivot", Vector3.one * 0.2, crankBase, steel)
	crankPivot.Transparency, crankRig.PrimaryPart = 1, crankPivot
	local lever = part(crankRig, "LaunchCrank", Vector3.new(0.7, 4.5, 0.7), crankBase * CFrame.Angles(0, 0, math.rad(-28)) * CFrame.new(0, 1.8, 0), warmMetal, Enum.Material.Metal)
	part(crankRig, "CrankKnob", Vector3.new(1.65, 1.65, 1.65), lever.CFrame * CFrame.new(0, 2.25, 0), colors.red, nil, Enum.PartType.Ball)

	-- The muzzle is the fixed visual pivot. A short barrel keeps its full sweep
	-- ahead of the oven collider and above the floor for the complete aim range.
	local rig = Instance.new("Model")
	rig.Name, rig.Parent = "AimRig", station
	local origin = CFrame.new(Config.LAUNCH_ORIGIN)
	local pivot = part(rig, "AimPivot", Vector3.one * 0.2, origin, steel)
	pivot.Transparency, rig.PrimaryPart = 1, pivot
	part(rig, "Barrel", Vector3.new(8, 6.6, 6.6), origin * CFrame.new(0, 0, 4) * cylinderZ, colors.red, Enum.Material.Metal, Enum.PartType.Cylinder)
	for _, z in { 1.3, 6.8 } do
		part(rig, "BarrelBand", Vector3.new(0.7, 7.0, 7.0), origin * CFrame.new(0, 0, z) * cylinderZ, warmMetal, Enum.Material.Metal, Enum.PartType.Cylinder)
	end
	part(rig, "Muzzle", Vector3.new(0.8, 7.9, 7.9), origin * cylinderZ, warmMetal, Enum.Material.Metal, Enum.PartType.Cylinder)
	part(rig, "MuzzleOpening", Vector3.new(0.15, 6.8, 6.8), origin * CFrame.new(0, 0, -0.5) * cylinderZ, colors.dark, nil, Enum.PartType.Cylinder)
	-- A Z-thin block keeps the attachment's Front emission axis aligned with -Z.
	local flash = part(rig, "CosmeticMuzzleFlash", Vector3.new(6.9, 6.9, 0.12), origin * CFrame.new(0, 0, -0.67), colors.orange, Enum.Material.Neon)
	flash.Transparency, flash.CastShadow = 1, false
	local fireLight = Instance.new("PointLight")
	fireLight.Name, fireLight.Color = "FireLight", Color3.fromRGB(255, 186, 111)
	fireLight.Brightness, fireLight.Range, fireLight.Enabled, fireLight.Shadows = 2, 12, false, false
	fireLight.Parent = flash
	local attachment = Instance.new("Attachment")
	attachment.Name, attachment.Parent = "MuzzleEffects", flash
	local flour = Instance.new("ParticleEmitter")
	flour.Name, flour.Enabled, flour.Rate = "FlourPuff", false, 0
	flour.Color, flour.EmissionDirection = ColorSequence.new(ovenCream), Enum.NormalId.Front
	flour.Lifetime, flour.Speed = NumberRange.new(0.2, 0.4), NumberRange.new(7, 11)
	flour.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 3.4) })
	flour.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
	flour.SpreadAngle, flour.Parent = Vector2.new(15, 15), attachment
	local spark = Instance.new("ParticleEmitter")
	spark.Name, spark.Enabled, spark.Rate = "CheeseSpark", false, 0
	spark.Color, spark.EmissionDirection = ColorSequence.new(colors.yellow), Enum.NormalId.Front
	spark.Lifetime, spark.Speed = NumberRange.new(0.16, 0.27), NumberRange.new(9, 14)
	spark.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0) })
	spark.SpreadAngle, spark.Parent = Vector2.new(10, 10), attachment
	local loaded = part(rig, "LoadedPizza", Vector3.new(0.5, 5.8, 5.8), origin * CFrame.new(0, 0, -0.8) * cylinderZ, colors.yellow, nil, Enum.PartType.Cylinder)
	loaded.Transparency = 1
	pizzaVisual.attach(loaded, { diameter = 5.8, name = "LoadedPizzaVisual", loaded = true })
	return rig
end

return LauncherArt
