local Config = {}

Config.REMOTES_FOLDER = "PizzaLaunchRemotes"
Config.LAUNCH_REMOTE = "LaunchPizza"
Config.STATE_REMOTE = "GameState"
Config.PURCHASE_REMOTE = "PurchaseUpgrade"

Config.GRAVITY = 196.2
Config.MIN_SPEED = 96
Config.MAX_SPEED = 155
Config.CHARGE_TIME = 1.25
Config.RELOAD_TIME = 0.85
Config.PROJECTILE_LIFETIME = 5
Config.MAX_AIM_X = 0.82
Config.MIN_PITCH = math.rad(27)
Config.MAX_PITCH = math.rad(58)
Config.DEFAULT_PITCH = math.rad(41)
Config.MAX_YAW = math.rad(33)

Config.LAUNCH_ORIGIN = Vector3.new(0, 8.2, 58)
Config.CAMERA_POSITION = Vector3.new(0, 29, 82)
Config.CAMERA_FOCUS = Vector3.new(0, 6.5, -22)

Config.TABLES = {
	{ id = 1, position = Vector3.new(-21, 2.5, 17), color = Color3.fromRGB(255, 190, 65), customer = "Mia", skin = Color3.fromRGB(246, 199, 154), shirt = Color3.fromRGB(255, 102, 118), style = "bow" },
	{ id = 2, position = Vector3.new(21, 2.5, 9), color = Color3.fromRGB(80, 201, 244), customer = "Bo", skin = Color3.fromRGB(126, 82, 56), shirt = Color3.fromRGB(63, 135, 224), style = "cap" },
	{ id = 3, position = Vector3.new(-27, 2.5, -13), color = Color3.fromRGB(255, 120, 145), customer = "Ziggy", skin = Color3.fromRGB(226, 165, 115), shirt = Color3.fromRGB(126, 83, 202), style = "spikes" },
	{ id = 4, position = Vector3.new(27, 2.5, -23), color = Color3.fromRGB(117, 218, 126), customer = "Pip", skin = Color3.fromRGB(255, 220, 177), shirt = Color3.fromRGB(52, 176, 113), style = "beanie" },
	{ id = 5, position = Vector3.new(-19, 2.5, -48), color = Color3.fromRGB(190, 137, 245), customer = "Nana", skin = Color3.fromRGB(111, 70, 49), shirt = Color3.fromRGB(233, 103, 55), style = "bun" },
	{ id = 6, position = Vector3.new(20, 2.5, -57), color = Color3.fromRGB(255, 155, 72), customer = "Max", skin = Color3.fromRGB(235, 184, 139), shirt = Color3.fromRGB(229, 70, 65), style = "chef" },
}

Config.ACCURACY = {
	{ name = "PERFECT!", radius = 2.8, coins = 20, color = Color3.fromRGB(255, 224, 84) },
	{ name = "GREAT!", radius = 5.5, coins = 14, color = Color3.fromRGB(100, 255, 162) },
	{ name = "DELIVERED!", radius = 9, coins = 10, color = Color3.fromRGB(120, 205, 255) },
}

Config.UPGRADES = {
	tips = { name = "BIGGER TIPS", description = "+25% coins", costs = { 35, 85, 160 } },
	assist = { name = "WIDER PLATES", description = "easier accuracy", costs = { 45, 100, 180 } },
	reload = { name = "SPEEDY OVEN", description = "faster reload", costs = { 40, 95, 170 } },
	power = { name = "HOTTER OVEN", description = "+4% launch power", costs = { 50, 110, 195 } },
}

Config.ROUNDS = {
	{ name = "FIRST ORDERS", goal = 3, tables = { 1, 2 }, accuracyScale = 1.4, reward = 25, color = Color3.fromRGB(99, 211, 139) },
	{ name = "DINNER RUSH", goal = 4, tables = { 1, 2, 3, 4 }, accuracyScale = 1.18, reward = 45, color = Color3.fromRGB(255, 193, 69) },
	{ name = "FULL HOUSE", goal = 5, tables = { 3, 4, 5, 6 }, accuracyScale = 1, reward = 70, color = Color3.fromRGB(255, 126, 103) },
	{ name = "MASTER CHEF", goal = 6, tables = { 1, 2, 3, 4, 5, 6 }, accuracyScale = 0.82, reward = 100, color = Color3.fromRGB(191, 132, 245) },
}

function Config.speedFromCharge(charge: number, powerLevel: number?): number
	local base = Config.MIN_SPEED + (Config.MAX_SPEED - Config.MIN_SPEED) * math.clamp(charge, 0, 1)
	return base * (1 + (powerLevel or 0) * 0.04)
end

function Config.directionFromAim(yawAmount: number, pitchAmount: number): Vector3
	local yaw = math.clamp(yawAmount, -1, 1) * Config.MAX_YAW
	local pitch = Config.MIN_PITCH + math.clamp(pitchAmount, 0, 1) * (Config.MAX_PITCH - Config.MIN_PITCH)
	local horizontal = math.cos(pitch)
	return Vector3.new(math.sin(yaw) * horizontal, math.sin(pitch), -math.cos(yaw) * horizontal).Unit
end

function Config.landingPoint(direction: Vector3, speed: number, landingY: number?): (Vector3, number)
	local origin = Config.LAUNCH_ORIGIN
	local targetY = landingY or 6.8
	local velocity = direction.Unit * speed
	local discriminant = velocity.Y * velocity.Y + 2 * Config.GRAVITY * (origin.Y - targetY)
	local flightTime = (velocity.Y + math.sqrt(math.max(0, discriminant))) / Config.GRAVITY
	local point = origin + velocity * flightTime + Vector3.new(0, -0.5 * Config.GRAVITY * flightTime * flightTime, 0)
	return point, flightTime
end

return Config
