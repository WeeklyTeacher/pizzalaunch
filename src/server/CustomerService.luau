local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local CustomerService = {}

local recordsByTable = {}
local identityCounter = 0
local entrancePoints = {}

local IDENTITIES = {
	{ name = "Mia", mood = "SUPER HUNGRY", line = "I saved room for a flying pizza!", skin = Color3.fromRGB(246, 199, 154), shirt = Color3.fromRGB(255, 102, 118), accent = Color3.fromRGB(255, 190, 65) },
	{ name = "Bo", mood = "CHILL", line = "A table delivery would be awesome.", skin = Color3.fromRGB(126, 82, 56), shirt = Color3.fromRGB(63, 135, 224), accent = Color3.fromRGB(80, 201, 244) },
	{ name = "Ziggy", mood = "EXCITED", line = "Make it fly extra high!", skin = Color3.fromRGB(226, 165, 115), shirt = Color3.fromRGB(126, 83, 202), accent = Color3.fromRGB(255, 120, 145) },
	{ name = "Pip", mood = "PECKISH", line = "I can almost smell the cheese!", skin = Color3.fromRGB(255, 220, 177), shirt = Color3.fromRGB(52, 176, 113), accent = Color3.fromRGB(117, 218, 126) },
	{ name = "Nana", mood = "PATIENT", line = "Take your time, chef. Aim true!", skin = Color3.fromRGB(111, 70, 49), shirt = Color3.fromRGB(233, 103, 55), accent = Color3.fromRGB(190, 137, 245) },
	{ name = "Max", mood = "PIZZA EXPERT", line = "Show me your master-chef launch!", skin = Color3.fromRGB(235, 184, 139), shirt = Color3.fromRGB(229, 70, 65), accent = Color3.fromRGB(255, 155, 72) },
	{ name = "Lulu", mood = "GIGGLY", line = "Pizza is funnier when it flies!", skin = Color3.fromRGB(92, 58, 42), shirt = Color3.fromRGB(236, 91, 154), accent = Color3.fromRGB(255, 132, 190) },
	{ name = "Kai", mood = "READY", line = "I have my catching hands ready!", skin = Color3.fromRGB(204, 142, 96), shirt = Color3.fromRGB(39, 164, 174), accent = Color3.fromRGB(74, 222, 211) },
	{ name = "Sunny", mood = "CHEERFUL", line = "A sunny slice, please!", skin = Color3.fromRGB(250, 211, 171), shirt = Color3.fromRGB(244, 151, 45), accent = Color3.fromRGB(255, 214, 73) },
	{ name = "Rex", mood = "STARVING", line = "I could eat a pizza-shaped comet!", skin = Color3.fromRGB(83, 53, 40), shirt = Color3.fromRGB(69, 107, 206), accent = Color3.fromRGB(126, 162, 255) },
	{ name = "Bea", mood = "CURIOUS", line = "Does flying make pizza tastier?", skin = Color3.fromRGB(224, 167, 124), shirt = Color3.fromRGB(116, 78, 178), accent = Color3.fromRGB(190, 142, 244) },
	{ name = "Nico", mood = "IMPATIENT", line = "My tummy is making drum sounds!", skin = Color3.fromRGB(239, 190, 143), shirt = Color3.fromRGB(211, 65, 60), accent = Color3.fromRGB(255, 112, 88) },
}

local function parts(record)
	local result = {}
	for _, descendant in record.customer:GetDescendants() do
		if descendant:IsA("BasePart") then
			table.insert(result, descendant)
		end
	end
	return result
end

local function labelInside(parent: Instance?, name: string): TextLabel?
	local gui = parent and parent:FindFirstChild(name, true)
	local label = gui and gui:FindFirstChild("Label", true)
	return label and label:IsA("TextLabel") and label or nil
end

local function setState(record, stateName: string)
	record.state = stateName
	local history = record.customer:GetAttribute("CustomerStateHistory") or ""
	local updatedHistory = history == "" and stateName or (history .. ">" .. stateName)
	if #updatedHistory > 180 then updatedHistory = string.sub(updatedHistory, -180) end
	record.customer:SetAttribute("CustomerStateHistory", updatedHistory)
	record.customer:SetAttribute("StateChangedAt", Workspace:GetServerTimeNow())
	local available = stateName == "SeatedWaiting"
	record.customer:SetAttribute("CustomerState", stateName)
	record.customer:SetAttribute("DeliveryAvailable", available)
	record.tableModel:SetAttribute("CustomerState", stateName)
	record.tableModel:SetAttribute("DeliveryAvailable", available)
	record.tableModel:SetAttribute("Occupied", stateName ~= "Despawn" and stateName ~= "Empty")
	local prompt = record.customer:FindFirstChild("CustomerPrompt", true)
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.Enabled = available
	end
	local marker = record.customer:FindFirstChild("WaitingMarker", true)
	if marker and marker:IsA("BillboardGui") then
		marker.Enabled = available
	end
end

local function setFace(record, text: string)
	local label = labelInside(record.customer, "Face")
	if label then label.Text = text end
end

local function setMarker(record, text: string)
	local label = labelInside(record.customer, "WaitingMarker")
	if label then
		label.Text = text
		label.TextColor3 = record.identity.accent
	end
end

local function setVisible(record, visible: boolean, duration: number?)
	for _, part in parts(record) do
		local base = part:GetAttribute("CustomerBaseTransparency")
		if typeof(base) ~= "number" then
			base = part.Transparency
			part:SetAttribute("CustomerBaseTransparency", base)
		end
		local target = visible and base or 1
		if duration and duration > 0 then
			TweenService:Create(part, TweenInfo.new(duration), { Transparency = target }):Play()
		else
			part.Transparency = target
		end
	end
	for _, descendant in record.customer:GetDescendants() do
		if descendant:IsA("SurfaceGui") and descendant.Name == "Face" then
			descendant.Enabled = visible
		end
	end
end

local function updateSeat(record)
	record.seatIndex = record.seatIndex % #record.seatOffsets + 1
	record.seatOffset = record.seatOffsets[record.seatIndex]
	for _, part in parts(record) do
		local authored = part:GetAttribute("CustomerAuthoredCFrame")
		if typeof(authored) ~= "CFrame" then
			authored = part.CFrame
			part:SetAttribute("CustomerAuthoredCFrame", authored)
		end
		part:SetAttribute("ResetCFrame", authored + record.seatOffset)
	end
end

local function tweenRootTo(record, targetPosition: Vector3, duration: number)
	local root = record.customer.PrimaryPart
	if not root then return end
	local delta = targetPosition - root.Position
	local info = TweenInfo.new(duration, Enum.EasingStyle.Linear)
	for _, part in parts(record) do
		TweenService:Create(part, info, { CFrame = part.CFrame + delta }):Play()
	end
	task.wait(duration)
end

local function tweenToSeat(record, duration: number)
	local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	for _, part in parts(record) do
		local reset = part:GetAttribute("ResetCFrame")
		if typeof(reset) == "CFrame" then
			TweenService:Create(part, info, { CFrame = reset }):Play()
		end
	end
	task.wait(duration)
end

local function applyIdentity(record)
	identityCounter += 1
	local identity = IDENTITIES[(identityCounter + record.tableId * 2 - 2) % #IDENTITIES + 1]
	record.identity = identity
	record.customer:SetAttribute("CustomerName", identity.name)
	record.customer:SetAttribute("Mood", identity.mood)
	record.customer:SetAttribute("PersonalityLine", identity.line)
	record.customer:SetAttribute("CustomerColor", identity.accent)
	record.tableModel:SetAttribute("CustomerName", identity.name)
	local prompt = record.customer:FindFirstChild("CustomerPrompt", true)
	if prompt and prompt:IsA("ProximityPrompt") then prompt.ObjectText = identity.name end
	for _, part in parts(record) do
		if part.Name == "Torso" then
			part.Color = identity.shirt
		elseif part.Name == "Head" or string.find(part.Name, "Arm") then
			part.Color = identity.skin
		elseif string.find(part.Name, "Hair") or string.find(part.Name, "Cap") or string.find(part.Name, "Beanie") then
			part.Color = identity.shirt:Lerp(Color3.fromRGB(45, 34, 33), 0.45)
		end
	end
	setFace(record, "^  ^\n\\___/")
	setMarker(record, "PIZZA")
end

local function arrivalPoint(record): Vector3
	local side = record.tablePosition.X < 0 and -1 or 1
	local authored = entrancePoints[side]
	return Vector3.new(authored and authored.X or side * 54, record.homeRootY, authored and authored.Z or 70)
end

local function sideAislePoint(record, z: number): Vector3
	local side = record.tablePosition.X < 0 and -1 or 1
	return Vector3.new(side * 52, record.homeRootY, z)
end

local function beginArrival(record, token: number)
	if record.token ~= token or not record.customer.Parent then return end
	setState(record, "Entering")
	applyIdentity(record)
	updateSeat(record)
	local entrance = arrivalPoint(record)
	local root = record.customer.PrimaryPart
	if root then
		local delta = entrance - root.Position
		for _, part in parts(record) do part.CFrame += delta end
	end
	setVisible(record, false)
	setVisible(record, true, 0.35)
	task.wait(0.4)
	if record.token ~= token then return end
	setState(record, "WalkingToSeat")
	tweenRootTo(record, sideAislePoint(record, math.max(record.tablePosition.Z + 5, -60)), 1.15)
	if record.token ~= token then return end
	tweenToSeat(record, 1.1)
	if record.token ~= token then return end
	setFace(record, "^  ^\n\\___/")
	setMarker(record, "PIZZA")
	setState(record, "SeatedWaiting")
end

local function beginDeparture(record, token: number)
	if record.token ~= token or not record.customer.Parent then return end
	setState(record, "Leaving")
	setMarker(record, "BYE")
	local root = record.customer.PrimaryPart
	if root then
		tweenRootTo(record, sideAislePoint(record, root.Position.Z), 1.0)
		tweenRootTo(record, sideAislePoint(record, 55), 1.25)
		tweenRootTo(record, arrivalPoint(record), 0.75)
	end
	setVisible(record, false, 0.3)
	task.wait(0.35)
	if record.token ~= token then return end
	setState(record, "Despawn")
	task.wait(0.8 + (record.tableId % 3) * 0.25)
	beginArrival(record, token)
end

local function idleLoop(record)
	task.spawn(function()
		local beat = 0
		while record.customer.Parent do
			beat += 1
			task.wait(2.5 + (record.tableId % 3) * 0.45)
			if record.state ~= "SeatedWaiting" or (record.customer:GetAttribute("ReactingUntil") or 0) > Workspace:GetServerTimeNow() then continue end
			local head = record.customer:FindFirstChild("Head")
			local arm = record.customer:FindFirstChild(beat % 2 == 0 and "LeftArm" or "RightArm")
			for _, part in { head, arm } do
				if part and part:IsA("BasePart") then
					local reset = part:GetAttribute("ResetCFrame")
					if typeof(reset) == "CFrame" then
						local side = part.Name == "LeftArm" and -1 or 1
						local angle = part.Name == "Head" and math.rad((record.tableId % 2 == 0 and -1 or 1) * 11) or math.rad(side * 14)
						TweenService:Create(part, TweenInfo.new(0.35, Enum.EasingStyle.Sine), { CFrame = reset * CFrame.Angles(0, part.Name == "Head" and angle or 0, part.Name ~= "Head" and angle or 0) }):Play()
					end
				end
			end
			if beat % 4 == 0 then setMarker(record, "...") end
			task.wait(0.65)
			if record.state == "SeatedWaiting" and (record.customer:GetAttribute("ReactingUntil") or 0) <= Workspace:GetServerTimeNow() then
				for _, part in { head, arm } do
					if part and part:IsA("BasePart") then
						local reset = part:GetAttribute("ResetCFrame")
						if typeof(reset) == "CFrame" then TweenService:Create(part, TweenInfo.new(0.3), { CFrame = reset }):Play() end
					end
				end
				setMarker(record, "PIZZA")
			end
		end
	end)
end

function CustomerService.start(world: Instance)
	table.clear(recordsByTable)
	table.clear(entrancePoints)
	for _, side in { -1, 1 } do
		local point = world:FindFirstChild(side < 0 and "CustomerEntranceLeft" or "CustomerEntranceRight", true)
		if point and point:IsA("BasePart") then entrancePoints[side] = point.Position end
	end
	for _, descendant in world:GetDescendants() do
		if descendant:IsA("Model") and descendant.Name == "Customer" then
			local tableId = descendant:GetAttribute("TableId")
			local tableModel = descendant.Parent
			if typeof(tableId) == "number" and tableModel and tableModel:IsA("Model") then
				local root = descendant.PrimaryPart or descendant:FindFirstChild("HumanoidRootPart")
				local capacity = tableId <= 2 and 1 or 2
				tableModel:SetAttribute("SeatCapacity", capacity)
				local record = {
					tableId = tableId, tableModel = tableModel, customer = descendant,
					tablePosition = (tableModel:FindFirstChild("TableTop") and tableModel.TableTop.Position) or tableModel:GetPivot().Position,
					homeRootY = root and root.Position.Y or 4.5,
					seatOffsets = capacity == 1 and { Vector3.zero } or { Vector3.new(-2.5, 0, 0), Vector3.new(2.5, 0, 0) },
					seatIndex = capacity, seatOffset = Vector3.zero,
					state = "SeatedWaiting", token = 0, identity = IDENTITIES[tableId],
				}
				for _, part in parts(record) do
					part:SetAttribute("CustomerAuthoredCFrame", part.CFrame)
					part:SetAttribute("ResetCFrame", part.CFrame)
					part:SetAttribute("CustomerBaseTransparency", part.Transparency)
				end
				recordsByTable[tableId] = record
				applyIdentity(record)
				setState(record, "SeatedWaiting")
				idleLoop(record)
			end
		end
	end
end

function CustomerService.markReacting(customer: Model, duration: number)
	customer:SetAttribute("ReactingUntil", Workspace:GetServerTimeNow() + duration)
end

function CustomerService.isDeliverable(tableId: number): boolean
	local record = recordsByTable[tableId]
	return record ~= nil and record.state == "SeatedWaiting"
end

function CustomerService.claimDelivery(tableId: number): boolean
	local record = recordsByTable[tableId]
	if not record or record.state ~= "SeatedWaiting" then return false end
	record.token += 1
	setState(record, "Served")
	return true
end

function CustomerService.served(tableId: number)
	local record = recordsByTable[tableId]
	if not record or record.state ~= "Served" then return end
	local token = record.token
	setState(record, "HappyReaction")
	CustomerService.markReacting(record.customer, 2.5)
	task.delay(1.7, function()
		if record.token ~= token or record.state ~= "HappyReaction" then return end
		setState(record, "Eating")
		setMarker(record, "YUM")
		setFace(record, "^  ^\n  o")
		task.delay(1.05, function()
			if record.token == token and record.state == "Eating" then task.spawn(beginDeparture, record, token) end
		end)
	end)
end

function CustomerService.hit(tableId: number)
	local record = recordsByTable[tableId]
	if not record or record.state ~= "SeatedWaiting" then return end
	record.token += 1
	local token = record.token
	setState(record, "HitReaction")
	CustomerService.markReacting(record.customer, 1.6)
	task.delay(1.55, function()
		if record.token == token and record.state == "HitReaction" then
			setFace(record, "^  ^\n\\___/")
			setMarker(record, "PIZZA")
			setState(record, "SeatedWaiting")
		end
	end)
end

function CustomerService.getInfo(tableId: number)
	local record = recordsByTable[tableId]
	if not record then return nil end
	return { name = record.identity.name, mood = record.identity.mood, line = record.identity.line, color = record.identity.accent, state = record.state }
end

function CustomerService.getAvailableTables()
	local result = {}
	for tableId, record in recordsByTable do
		if record.state == "SeatedWaiting" then table.insert(result, tableId) end
	end
	table.sort(result)
	return result
end

return CustomerService
