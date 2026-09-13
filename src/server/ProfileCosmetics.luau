-- Earned server-owned appearance. No avatar physics, launcher tuning or assets.
local Config = require(game:GetService("ReplicatedStorage").Shared.MasteryConfig)
local ProfileCosmetics = {}
local owned = {}

function ProfileCosmetics.clear(player)
	local current = owned[player]
	if current then current.gui:Destroy(); owned[player] = nil end
end

function ProfileCosmetics.apply(player, snapshot, mounted)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	local id = snapshot and snapshot.equipped
	local style = typeof(id) == "string" and Config.cosmetics[id]
	local loaded = snapshot and (snapshot.status == "ready" or snapshot.status == "memory" or snapshot.status == "saveFailed")
	if not player.Parent or not character or not character.Parent or not head or not head:IsA("BasePart")
		or not loaded or not style or not snapshot.earnedCosmetics or snapshot.earnedCosmetics[id] ~= true then
		ProfileCosmetics.clear(player)
		return false
	end
	local current = owned[player]
	if current and (current.head ~= head or current.gui.Parent ~= head) then ProfileCosmetics.clear(player); current = nil end
	if not current then
		local gui = Instance.new("BillboardGui")
		gui.Name, gui.Adornee = "EarnedChefNameplate", head
		gui.Size, gui.StudsOffsetWorldSpace = UDim2.fromOffset(148, 24), Vector3.new(0, 3.2, 0)
		gui.AlwaysOnTop, gui.MaxDistance, gui.LightInfluence = false, 30, 0
		local label = Instance.new("TextLabel")
		label.Name, label.Size = "Style", UDim2.fromScale(1, 1)
		label.BackgroundTransparency, label.TextSize, label.Font = 0.08, 14, Enum.Font.GothamMedium
		label.TextColor3, label.TextStrokeTransparency = Color3.fromRGB(45, 35, 29), 1
		label.Parent = gui
		local corner = Instance.new("UICorner")
		corner.CornerRadius, corner.Parent = UDim.new(0, 8), label
		gui.Parent = head
		current = { gui = gui, label = label, head = head }
		owned[player] = current
	end
	current.label.Text = style.name
	current.label.BackgroundColor3 = Color3.fromRGB(table.unpack(style.color))
	current.gui.Enabled = not mounted
	return true
end

return ProfileCosmetics
