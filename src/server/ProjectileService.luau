local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local PizzaVisual = require(game:GetService("ReplicatedStorage").Shared.PizzaVisual)

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

function ProjectileService.consumeVisual(pizza): boolean
	if not pizza.Parent or pizza:GetAttribute("Resolved") ~= true then return false end
	local model = pizza:FindFirstChild("PizzaVisual")
	if not model then return false end
	-- The delivered pizza fades without resizing or revealing its physics proxy.
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part:GetAttribute("PizzaCosmetic") then
			TweenService:Create(part, TweenInfo.new(0.42, Enum.EasingStyle.Quad), { Transparency = 1 }):Play()
		end
	end
	return true
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

	pizza.Transparency = 1
	PizzaVisual.attach(pizza)

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
