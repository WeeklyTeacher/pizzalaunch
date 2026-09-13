-- Earned appearance only. These are internal catalog keys, not Roblox asset or
-- product IDs. Coins and upgrades remain shift-only and are absent here.
local MasteryConfig = {
	storeName = "PizzaLaunch_PlayerProfile_v1",
	schemaVersion = 1,
	leaseSeconds = 120,
	autosaveSeconds = 30,
	maxCounter = 1000000000,
	counters = { "deliveries", "perfect", "great", "farDeliveries", "takeout", "recordRuns", "recordBest" },
	customers = { Mia = true, Bo = true, Ziggy = true, Pip = true, Nana = true, Max = true,
		Lulu = true, Kai = true, Sunny = true, Rex = true, Bea = true, Nico = true },
	cosmetics = {
		plain = { name = "Neighborhood Chef", color = { 255, 242, 217 }, requirement = "Always available" },
		basil = { name = "Basil Chef", color = { 77, 145, 91 }, counter = "deliveries", goal = 10, requirement = "Serve 10 pizzas" },
		tomato = { name = "Tomato Chef", color = { 197, 66, 51 }, counter = "takeout", goal = 5, requirement = "Complete 5 takeout orders" },
		gold = { name = "Golden Chef", color = { 224, 167, 56 }, counter = "perfect", goal = 15, requirement = "Land 15 Perfect deliveries" },
	},
	cosmeticOrder = { "plain", "basil", "tomato", "gold" },
	goals = {
		{ id = "service", name = "Neighborhood Service", counter = "deliveries", goal = 10 },
		{ id = "accuracy", name = "Perfect Pizzas", counter = "perfect", goal = 15 },
		{ id = "distance", name = "Across the Restaurant", counter = "farDeliveries", goal = 10 },
		{ id = "takeout", name = "Around the Block", counter = "takeout", goal = 5 },
		{ id = "record", name = "Personal Record", counter = "recordBest", goal = 1000 },
	},
	recordTiers = { 500, 1000, 2000, 4000 },
}
return MasteryConfig
