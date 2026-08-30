local Config = {}

Config.REMOTES_FOLDER = "PizzaLaunchRemotes"
Config.LAUNCH_REMOTE = "LaunchPizza"
Config.STATE_REMOTE = "GameState"
Config.PURCHASE_REMOTE = "PurchaseUpgrade"

Config.GRAVITY = 196.2
Config.LAUNCH_ANGLE = math.rad(42)
Config.MIN_SPEED = 96
Config.MAX_SPEED = 155
Config.CHARGE_TIME = 1.25
Config.RELOAD_TIME = 0.85
Config.PROJECTILE_LIFETIME = 5
Config.MAX_AIM_X = 0.82

Config.LAUNCH_ORIGIN = Vector3.new(0, 7.1, 56)
Config.CAMERA_POSITION = Vector3.new(0, 31, 79)
Config.CAMERA_FOCUS = Vector3.new(0, 5, -24)

Config.TABLES = {
	{ id = 1, position = Vector3.new(-24, 2.5, 14), color = Color3.fromRGB(255, 196, 74), customer = "Mia" },
	{ id = 2, position = Vector3.new(0, 2.5, 4), color = Color3.fromRGB(104, 210, 255), customer = "Bo" },
	{ id = 3, position = Vector3.new(25, 2.5, -7), color = Color3.fromRGB(255, 133, 153), customer = "Ziggy" },
	{ id = 4, position = Vector3.new(-29, 2.5, -29), color = Color3.fromRGB(150, 230, 135), customer = "Pip" },
	{ id = 5, position = Vector3.new(2, 2.5, -43), color = Color3.fromRGB(200, 153, 255), customer = "Nana" },
	{ id = 6, position = Vector3.new(31, 2.5, -57), color = Color3.fromRGB(255, 167, 88), customer = "Max" },
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
}

function Config.speedFromCharge(charge: number): number
	return Config.MIN_SPEED + (Config.MAX_SPEED - Config.MIN_SPEED) * math.clamp(charge, 0, 1)
end

function Config.rangeFromCharge(charge: number): number
	local speed = Config.speedFromCharge(charge)
	return speed * speed * math.sin(2 * Config.LAUNCH_ANGLE) / Config.GRAVITY
end

return Config
