local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local ProjectileService = {}
local CHARACTERS, PROJECTILES, PROPS = "PizzaLaunchCharacters", "PizzaLaunchProjectiles", "PizzaLaunchProps"
local characterConnections = {}
local active = {}
local visuals = {}

function ProjectileService.start(world)
	for _, group in { CHARACTERS, PROJECTILES, PROPS } do
		if not PhysicsService:IsCollisionGroupRegistered(group) then PhysicsService:RegisterCollisionGroup(group) end
	end
	PhysicsService:CollisionGroupSetCollidable(CHARACTERS, PROJECTILES, false)
	PhysicsService:CollisionGroupSetCollidable(CHARACTERS, PROPS, false)
	for _, part in world:GetDescendants() do
		if part:IsA("BasePart") and part:GetAttribute("ReactiveProp") then part.CollisionGroup = PROPS end
	end
end

function ProjectileService.unbindCharacter(player)
	local connection = characterConnections[player]
	if connection then connection:Disconnect() end
	characterConnections[player] = nil
end

function ProjectileService.bindCharacter(player, character)
	ProjectileService.unbindCharacter(player)
	local function assign(part)
		if part:IsA("BasePart") then part.CollisionGroup = CHARACTERS end
	end
	for _, part in character:GetDescendants() do assign(part) end
	characterConnections[player] = character.DescendantAdded:Connect(assign)
end

function ProjectileService.isCharacterPart(part): boolean
	for _, player in Players:GetPlayers() do
		if player.Character and part:IsDescendantOf(player.Character) then return true end
	end
	return false
end

function ProjectileService.prepare(pizza)
	pizza.CollisionGroup = PROJECTILES
end

function ProjectileService.track(player, pizza, epoch)
	local shot = { pizza = pizza, epoch = epoch }
	active[player] = shot
	return shot
end

function ProjectileService.isCurrent(player, pizza, epoch): boolean
	local shot = active[player]
	return shot ~= nil and shot.pizza == pizza and shot.epoch == epoch and pizza.Parent ~= nil
end

function ProjectileService.resolve(player, pizza, epoch): boolean
	if not ProjectileService.isCurrent(player, pizza, epoch) then return false end
	local shot = active[player]
	active[player] = nil
	if shot.connection then shot.connection:Disconnect() end
	-- A landed/missed pizza may linger for feedback, but cannot obstruct a later run.
	pizza.CanCollide, pizza.CanTouch, pizza.CanQuery = false, false, false
	visuals[player] = visuals[player] or {}
	visuals[player][pizza] = epoch
	return true
end

function ProjectileService.removeVisual(player, pizza)
	local owned = visuals[player]
	if owned then
		owned[pizza] = nil
		if next(owned) == nil then visuals[player] = nil end
	end
	if pizza.Parent then pizza:Destroy() end
end

function ProjectileService.clear(player)
	local shot = active[player]
	active[player] = nil
	if shot then
		if shot.connection then shot.connection:Disconnect() end
		if shot.pizza.Parent then shot.pizza:Destroy() end
	end
	local owned = visuals[player]
	visuals[player] = nil
	for pizza in owned or {} do
		if pizza.Parent then pizza:Destroy() end
	end
end

function ProjectileService.create(Config, player: Player, direction: Vector3, charge: number, powerLevel: number, playSound, SOUND): BasePart
	local pizza = Instance.new("Part")
	pizza.Name = string.format("%s_Pizza", player.Name)
	pizza.Shape = Enum.PartType.Cylinder
	pizza.Size = Vector3.new(0.65, 6, 6)
	pizza.CFrame = CFrame.new(Config.LAUNCH_ORIGIN + direction * 1.8) * CFrame.Angles(0, 0, math.pi / 2)
	pizza.Color = Color3.fromRGB(255, 199, 63)
	pizza.Material = Enum.Material.SmoothPlastic
	pizza.CustomPhysicalProperties = PhysicalProperties.new(0.65, 0.38, 0.62, 1, 1)
	pizza:SetAttribute("OwnerUserId", player.UserId)
	ProjectileService.prepare(pizza)
	pizza.Parent = Workspace

	for index, offset in {
		Vector3.new(0.42, -1.5, -0.9), Vector3.new(0.42, 1.2, -1.2),
		Vector3.new(0.42, -0.4, 1.35), Vector3.new(0.42, 1.35, 0.8),
	} do
		local topping = Instance.new("Part")
		topping.Name = string.format("Pepperoni%d", index)
		topping.Shape = Enum.PartType.Ball
		topping.Size = Vector3.new(1.05, 0.35, 1.05)
		topping.Color = Color3.fromRGB(190, 46, 45)
		topping.Material = Enum.Material.SmoothPlastic
		topping.CFrame = pizza.CFrame * CFrame.new(offset)
		topping.CanCollide = false
		topping.CanTouch = false
		topping.CanQuery = false
		topping.Massless = true
		topping.Parent = pizza
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = pizza
		weld.Part1 = topping
		weld.Parent = topping
	end

	local speed = Config.speedFromCharge(charge, powerLevel)
	pizza.AssemblyLinearVelocity = direction.Unit * speed
	pizza.AssemblyAngularVelocity = Vector3.new(direction.Z * 17, 5, -direction.X * 17)
	pizza:SetNetworkOwner(nil)
	playSound(pizza, SOUND.launch, 0.72, 1.06)
	task.delay(0.16, function()
		if pizza.Parent then
			playSound(pizza, SOUND.whoosh, 0.28, 1.3)
		end
	end)
	return pizza
end

return ProjectileService
