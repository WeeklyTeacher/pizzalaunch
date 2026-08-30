local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local GameService = {}

local states = {}
local launchRemote: RemoteEvent
local stateRemote: RemoteEvent
local purchaseRemote: RemoteEvent

local function createRemotes()
	local old = ReplicatedStorage:FindFirstChild(Config.REMOTES_FOLDER)
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = Config.REMOTES_FOLDER
	folder.Parent = ReplicatedStorage

	launchRemote = Instance.new("RemoteEvent")
	launchRemote.Name = Config.LAUNCH_REMOTE
	launchRemote.Parent = folder
	stateRemote = Instance.new("RemoteEvent")
	stateRemote.Name = Config.STATE_REMOTE
	stateRemote.Parent = folder
	purchaseRemote = Instance.new("RemoteEvent")
	purchaseRemote.Name = Config.PURCHASE_REMOTE
	purchaseRemote.Parent = folder
end

local function tableDefinition(tableId: number)
	for _, definition in Config.TABLES do
		if definition.id == tableId then
			return definition
		end
	end
	return nil
end

local function distanceToTable(tableId: number): number
	local definition = tableDefinition(tableId)
	if not definition then
		return 0
	end
	local delta = definition.position - Config.LAUNCH_ORIGIN
	return Vector3.new(delta.X, 0, delta.Z).Magnitude
end

local function sendState(player: Player, eventName: string?, payload: { [string]: any }?)
	local state = states[player]
	if not state then
		return
	end
	stateRemote:FireClient(player, {
		event = eventName or "state",
		coins = state.coins,
		combo = state.combo,
		bestCombo = state.bestCombo,
		targetId = state.targetId,
		targetDistance = math.floor(distanceToTable(state.targetId) + 0.5),
		payload = payload,
		upgrades = state.upgrades,
	})
end

local function nextTarget(previousId: number?): number
	if #Config.TABLES <= 1 then
		return 1
	end
	local picked = math.random(1, #Config.TABLES)
	while picked == previousId do
		picked = math.random(1, #Config.TABLES)
	end
	return picked
end

local function setLeaderstats(player: Player, coins: number, combo: number)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end
	local coinsValue = leaderstats:FindFirstChild("Coins")
	local comboValue = leaderstats:FindFirstChild("Combo")
	if coinsValue and coinsValue:IsA("IntValue") then
		coinsValue.Value = coins
	end
	if comboValue and comboValue:IsA("IntValue") then
		comboValue.Value = combo
	end
end

local function finishShot(player: Player, pizza: BasePart, result: string, hitPosition: Vector3?, tableId: number?)
	local state = states[player]
	if not state or pizza:GetAttribute("Resolved") then
		return
	end
	pizza:SetAttribute("Resolved", true)
	state.shotActive = false

	local payload = {
		result = result,
		position = hitPosition,
		tableId = tableId,
		coinsEarned = 0,
		comboBonus = 0,
		reloadDelay = math.max(0.15, 0.45 - state.upgrades.reload * 0.1),
	}

	if result == "delivery" and tableId == state.targetId and hitPosition then
		local definition = tableDefinition(tableId)
		local horizontal = Vector3.new(hitPosition.X - definition.position.X, 0, hitPosition.Z - definition.position.Z)
		local accuracy = Config.ACCURACY[#Config.ACCURACY]
		local assistScale = 1 + state.upgrades.assist * 0.12
		for _, tier in Config.ACCURACY do
			if horizontal.Magnitude <= tier.radius * assistScale then
				accuracy = tier
				break
			end
		end
		state.combo += 1
		state.bestCombo = math.max(state.bestCombo, state.combo)
		local comboBonus = math.min((state.combo - 1) * 2, 10)
		local earned = math.floor((accuracy.coins + comboBonus) * (1 + state.upgrades.tips * 0.25) + 0.5)
		state.coins += earned
		payload.result = accuracy.name
		payload.color = accuracy.color
		payload.coinsEarned = earned
		payload.comboBonus = comboBonus
		payload.accuracy = math.floor(horizontal.Magnitude * 10 + 0.5) / 10
		state.targetId = nextTarget(state.targetId)
	else
		state.combo = 0
		payload.result = tableId and "WRONG TABLE!" or result
		payload.color = Color3.fromRGB(255, 145, 105)
	end

	setLeaderstats(player, state.coins, state.combo)
	sendState(player, "shotResult", payload)

	task.delay(1.35, function()
		if pizza.Parent then
			pizza:Destroy()
		end
	end)
end

local function impactEffect(position: Vector3, color: Color3)
	local ring = Instance.new("Part")
	ring.Name = "PizzaImpact"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.18, 2, 2)
	ring.CFrame = CFrame.new(position + Vector3.new(0, 0.25, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanTouch = false
	ring.CanQuery = false
	ring.Material = Enum.Material.Neon
	ring.Color = color
	ring.Transparency = 0.1
	ring.Parent = Workspace
	game:GetService("TweenService"):Create(ring, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.18, 15, 15),
		Transparency = 1,
	}):Play()
	task.delay(0.65, function()
		if ring.Parent then
			ring:Destroy()
		end
	end)
end

local function makePizza(player: Player, direction: Vector3, charge: number): BasePart
	local pizza = Instance.new("Part")
	pizza.Name = string.format("%s_Pizza", player.Name)
	pizza.Shape = Enum.PartType.Cylinder
	pizza.Size = Vector3.new(0.65, 6, 6)
	pizza.Orientation = Vector3.new(0, 0, 90)
	pizza.Position = Config.LAUNCH_ORIGIN + direction * 2
	pizza.Color = Color3.fromRGB(255, 197, 61)
	pizza.Material = Enum.Material.SmoothPlastic
	pizza.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.45, 0.55, 1, 1)
	pizza:SetAttribute("OwnerUserId", player.UserId)
	pizza.Parent = Workspace

	for index, offset in {
		Vector3.new(0.42, -1.5, -0.9),
		Vector3.new(0.42, 1.2, -1.2),
		Vector3.new(0.42, -0.4, 1.35),
		Vector3.new(0.42, 1.35, 0.8),
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

	local crust = Instance.new("SelectionBox")
	crust.Name = "Crust"
	crust.Adornee = pizza
	crust.Color3 = Color3.fromRGB(205, 96, 36)
	crust.LineThickness = 0.08
	crust.SurfaceTransparency = 1
	crust.Parent = pizza

	local speed = Config.speedFromCharge(charge)
	local horizontal = Vector3.new(direction.X, 0, direction.Z).Unit
	pizza.AssemblyLinearVelocity = horizontal * speed * math.cos(Config.LAUNCH_ANGLE) + Vector3.new(0, speed * math.sin(Config.LAUNCH_ANGLE), 0)
	pizza.AssemblyAngularVelocity = Vector3.new(0, 0, -18) + horizontal * 3
	pizza:SetNetworkOwner(nil)
	return pizza
end

local function isFinite(value: number): boolean
	return value == value and value > -math.huge and value < math.huge
end

local function onLaunch(player: Player, directionValue: any, chargeValue: any)
	local state = states[player]
	if not state or state.shotActive then
		return
	end
	if typeof(directionValue) ~= "Vector3" or typeof(chargeValue) ~= "number" then
		return
	end
	if not isFinite(chargeValue) or not isFinite(directionValue.X) or not isFinite(directionValue.Y) or not isFinite(directionValue.Z) then
		return
	end
	local horizontal = Vector3.new(directionValue.X, 0, directionValue.Z)
	if horizontal.Magnitude < 0.9 or horizontal.Z > -0.45 then
		return
	end
	local direction = horizontal.Unit
	if math.abs(direction.X) > Config.MAX_AIM_X then
		return
	end
	local now = Workspace:GetServerTimeNow()
	local reloadTime = Config.RELOAD_TIME * (1 - state.upgrades.reload * 0.12)
	if now - state.lastLaunch < reloadTime then
		return
	end
	state.lastLaunch = now
	state.shotActive = true

	local charge = math.clamp(chargeValue, 0, 1)
	local pizza = makePizza(player, direction, charge)
	sendState(player, "launched", { reloadTime = reloadTime })

	local bornAt = now
	local connection: RBXScriptConnection
	connection = pizza.Touched:Connect(function(hit)
		if pizza:GetAttribute("Resolved") or Workspace:GetServerTimeNow() - bornAt < 0.18 then
			return
		end
		local character = player.Character
		if character and hit:IsDescendantOf(character) then
			return
		end
		if hit:GetAttribute("DeliverySurface") then
			connection:Disconnect()
			impactEffect(pizza.Position, Color3.fromRGB(255, 221, 74))
			finishShot(player, pizza, "delivery", pizza.Position, hit:GetAttribute("TableId"))
		elseif hit:GetAttribute("MissSurface") then
			connection:Disconnect()
			impactEffect(pizza.Position, Color3.fromRGB(255, 126, 83))
			finishShot(player, pizza, "FLOOR PIZZA!", pizza.Position, nil)
		end
	end)

	task.delay(Config.PROJECTILE_LIFETIME, function()
		if pizza.Parent and not pizza:GetAttribute("Resolved") then
			if connection.Connected then
				connection:Disconnect()
			end
			finishShot(player, pizza, "LOST IN THE SAUCE!", pizza.Position, nil)
		end
	end)
end

local function onPurchase(player: Player, upgradeId: any)
	local state = states[player]
	local definition = typeof(upgradeId) == "string" and Config.UPGRADES[upgradeId] or nil
	if not state or not definition then
		return
	end
	local level = state.upgrades[upgradeId]
	local cost = definition.costs[level + 1]
	if not cost then
		sendState(player, "purchaseResult", { result = "MAX LEVEL!", success = false })
		return
	end
	if state.coins < cost then
		sendState(player, "purchaseResult", { result = "NEED MORE COINS", success = false, cost = cost })
		return
	end
	state.coins -= cost
	state.upgrades[upgradeId] += 1
	setLeaderstats(player, state.coins, state.combo)
	sendState(player, "purchaseResult", {
		result = string.format("%s LEVEL %d!", definition.name, state.upgrades[upgradeId]),
		success = true,
		upgradeId = upgradeId,
	})
end

local function addPlayer(player: Player)
	states[player] = {
		coins = 0,
		combo = 0,
		bestCombo = 0,
		targetId = nextTarget(nil),
		lastLaunch = -100,
		shotActive = false,
		upgrades = { tips = 0, assist = 0, reload = 0 },
	}

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Parent = leaderstats
	local combo = Instance.new("IntValue")
	combo.Name = "Combo"
	combo.Parent = leaderstats

	player.CharacterAdded:Connect(function(character)
		for _, descendant in character:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.Transparency = 1
				descendant.CanCollide = false
			elseif descendant:IsA("Decal") then
				descendant.Transparency = 1
			end
		end
	end)

	task.delay(1, function()
		if player.Parent then
			sendState(player, "welcome", nil)
		end
	end)
end

function GameService.start()
	createRemotes()
	launchRemote.OnServerEvent:Connect(onLaunch)
	purchaseRemote.OnServerEvent:Connect(onPurchase)
	Players.PlayerAdded:Connect(addPlayer)
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		addPlayer(player)
	end
end

return GameService
