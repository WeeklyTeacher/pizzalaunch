local loadModule = require("./support/LoadModule")
local roblox = require("@lune/roblox")
local Vector3, CFrame = roblox.Vector3, roblox.CFrame
local config = loadModule("src/shared/Config.luau")
local services = {}
for _, name in {"Workspace", "Lighting", "StarterGui", "ReplicatedStorage"} do services[name] = roblox.Instance.new(name) end
local world = require("./support/WorldFixture")(services, config).build()
local station = world.LauncherStation
local rig = station.AimRig
assert(rig.PrimaryPart.CFrame.Position == config.LAUNCH_ORIGIN)
local muzzle, opening, flash = rig.Muzzle, rig.MuzzleOpening, rig.CosmeticMuzzleFlash
for _, disk in {muzzle, opening} do
	assert(disk.Shape == roblox.Enum.PartType.Cylinder and disk.Size.X < disk.Size.Y)
	assert(math.abs(disk.CFrame.RightVector:Dot(Vector3.zAxis)) > .9999, "Aperture disk must face along barrel")
end
assert(flash.Size.Z < flash.Size.X and flash.CFrame.LookVector:Dot(-Vector3.zAxis) > .9999)
local gauge = station.PressureGauge
assert(gauge.PressureReadout.Face == roblox.Enum.NormalId.Left)
assert((-gauge.CFrame.RightVector):Dot(Vector3.zAxis) > .9999, "Readable gauge face must point toward operator")
local collider = station.LauncherHousingCollider
assert(collider.CanCollide and collider.Transparency == 1 and collider.Size.Y <= 8)
assert(collider.CFrame.Position.Z - collider.Size.Z/2 > config.LAUNCH_ORIGIN.Z + 6)
assert(collider.CFrame.Position.Z + collider.Size.Z/2 < 78, "Approach pad needs clear walking space")
local prefabCount = 0
for _, item in station:GetDescendants() do
	if item:IsA("BasePart") and (item:GetAttribute("CosmeticOnly") or item:GetAttribute("PizzaCosmetic") or item == collider) then
		prefabCount += 1
		if item ~= collider then assert(not item.CanCollide and not item.CanTouch and not item.CanQuery) end
	end
end
assert(prefabCount > 40 and prefabCount <= 90, "Hero machine detail must stay within its part budget")
assert(rig.LoadedPizza.Transparency == 1, "Loaded carrier must not duplicate the visual pizza")
local loadedCount = 0
for _, item in rig.LoadedPizza:GetDescendants() do
	if item:IsA("BasePart") then
		loadedCount += 1
		assert(item:GetAttribute("CosmeticLoadedPizza") and item.Massless, "Every loaded detail participates in feedback cleanup")
	end
end
assert(loadedCount > 0 and loadedCount <= 32)
local origin = CFrame.new(config.LAUNCH_ORIGIN)
local parts = {}
for _, item in rig:GetDescendants() do
	if item:IsA("BasePart") then
		assert(not item.CanCollide and not item.CanTouch and not item.CanQuery, "Aim geometry must be nonphysical")
		table.insert(parts, {part=item, relative=origin:ToObjectSpace(item.CFrame)})
	end
end
-- Sweep real prefab bounds over every whole-degree aim setting, including exact
-- extremes. This catches ground/housing intersection without a renderer.
local lowest = math.huge
for yaw = -33, 33 do
	for pitch = 27, 58 do
		local direction = config.directionFromAim(math.rad(yaw)/config.MAX_YAW, (math.rad(pitch)-config.MIN_PITCH)/(config.MAX_PITCH-config.MIN_PITCH))
		-- Lune 0.10.5 lookAt reverses the native Roblox local-Z convention.
		-- Build the documented right/up/back basis explicitly for geometric QA.
		local right = direction:Cross(Vector3.yAxis).Unit
		local up = right:Cross(direction).Unit
		local pivot = CFrame.fromMatrix(config.LAUNCH_ORIGIN, right, up, -direction)
		assert(pivot.LookVector:Dot(direction) > .9999)
		for _, entry in parts do
			local frame, half = pivot * entry.relative, entry.part.Size/2
			for _, x in {-1,1} do for _, y in {-1,1} do for _, z in {-1,1} do
				local corner = frame:PointToWorldSpace(Vector3.new(x*half.X,y*half.Y,z*half.Z))
				lowest = math.min(lowest,corner.Y)
				assert(corner.Y > .4, "Aim sweep intersects platform: "..entry.part.Name)
				assert(corner.Z < collider.CFrame.Position.Z-collider.Size.Z/2, "Aim sweep enters oven housing")
			end end end
		end
	end
end
assert(config.LAUNCH_ORIGIN == Vector3.new(0,12,50))
print(string.format("PASS: actual hero prefab aperture/gauge orientation, nonphysical aim rig, fixed pivot, full aim sweep clearance (lowest %.2f), compact housing and clear approach",lowest))
