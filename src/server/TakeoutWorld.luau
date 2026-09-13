-- Source-owned activity fixtures outside launcher/customer lanes. All fixtures
-- are nonphysical; the server validates character distance to configured points.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Config = require(ReplicatedStorage.Shared.TakeoutConfig)
local TakeoutWorld = {}
local ownedModel, stationLabel, milestoneLabel
local CREAM = Color3.fromRGB(248, 236, 212)
local RED = Color3.fromRGB(184, 53, 47)
local GREEN = Color3.fromRGB(63, 112, 78)

local function part(parent, name, size, position, color)
	local item = Instance.new("Part")
	item.Name, item.Size, item.CFrame = name, size, CFrame.new(position)
	item.Anchored, item.CanCollide, item.CanTouch, item.CanQuery = true, false, false, false
	item.Color, item.Material = color, Enum.Material.SmoothPlastic
	item.TopSurface, item.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	item.Parent = parent
	return item
end

local function label(anchor, name, text, width, height, distance)
	local gui = Instance.new("BillboardGui")
	gui.Name, gui.Adornee = name, anchor
	gui.Size = UDim2.fromOffset(width, height)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 2.8, 0)
	gui.MaxDistance, gui.AlwaysOnTop, gui.LightInfluence = distance, false, 0
	gui.Parent = anchor
	local textLabel = Instance.new("TextLabel")
	textLabel.Name, textLabel.Size = "Label", UDim2.fromScale(1, 1)
	textLabel.BackgroundColor3, textLabel.BackgroundTransparency = CREAM, 0.04
	textLabel.TextColor3, textLabel.Text = RED, text
	textLabel.Font, textLabel.TextSize = Enum.Font.GothamBold, 16
	textLabel.TextWrapped, textLabel.TextScaled = true, false
	textLabel.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0, 10), textLabel
	return textLabel
end

local function prompt(anchor, name, action, object)
	local item = Instance.new("ProximityPrompt")
	item.Name, item.ActionText, item.ObjectText = name, action, object
	item.MaxActivationDistance, item.HoldDuration = Config.promptDistance, 0
	item.RequiresLineOfSight, item.ClickablePrompt = false, true
	item.KeyboardKeyCode, item.GamepadKeyCode = Enum.KeyCode.E, Enum.KeyCode.ButtonX
	item.Parent = anchor
	return item
end

function TakeoutWorld.start(world)
	-- Never find/delete a model by name: only replace this module's own reference.
	if ownedModel and ownedModel.Parent then ownedModel:Destroy() end
	ownedModel = Instance.new("Model")
	ownedModel.Name = "TakeoutActivity"
	ownedModel:SetAttribute("SourceOwnedActivity", true)
	ownedModel.Parent = world
	local pickup = Config.pickupPosition
	local shelf = part(ownedModel, "ReadyPizzaShelf", Vector3.new(8, 0.7, 5), pickup + Vector3.new(0, -0.8, 0), GREEN)
	for _, x in { -3, 3 } do
		part(ownedModel, "ShelfLeg", Vector3.new(0.6, 2, 0.6), pickup + Vector3.new(x, -2, 0), GREEN)
	end
	local box = part(ownedModel, "ReadyPizzaBox", Vector3.new(4, 0.65, 4), pickup + Vector3.new(0, -0.1, 0), CREAM)
	part(ownedModel, "BoxSeal", Vector3.new(1.1, 0.04, 3.6), pickup + Vector3.new(0, 0.25, 0), RED)
	label(box, "TakeoutSign", "TAKEOUT RUNNER\nPick up a ready pizza", 218, 52, 50)
	prompt(shelf, "TakeoutPickupPrompt", "PICK UP PIZZA", "TAKEOUT RUNNER")
	for _, destination in Config.destinations do
		local anchor = part(ownedModel, "DeliveryPoint_" .. destination.id, Vector3.new(3, 0.15, 3), destination.position + Vector3.new(0, -2.8, 0), GREEN)
		local interaction = part(ownedModel, "DeliveryAnchor_" .. destination.id, Vector3.one, destination.position, CREAM)
		interaction.Transparency = 1
		local deliveryPrompt = prompt(interaction, "TakeoutDeliveryPrompt", "DELIVER PIZZA", destination.name)
		deliveryPrompt:SetAttribute("DestinationId", destination.id)
		label(anchor, "DeliverySign", destination.name .. "\nTAKEOUT DROP-OFF", 190, 48, 24)
	end
	local display = part(ownedModel, "NowPlayingStand", Vector3.new(5, 3, 0.45), Vector3.new(19, 4, 96), GREEN)
	stationLabel = label(display, "NowPlaying", "PIZZA LAUNCHER\nREADY FOR A CHEF", 240, 80, 42)
	milestoneLabel = label(shelf, "RestaurantMilestone", "NEIGHBORHOOD SERVICE  0 / 12", 252, 34, 24)
	milestoneLabel.Parent.StudsOffsetWorldSpace = Vector3.new(0, -1.7, 0)
	return ownedModel
end

function TakeoutWorld.update(station, milestone)
	if stationLabel and stationLabel.Parent then
		local mode = station.launcherMode
		local detail = "READY FOR A CHEF"
		if mode == "freePlay" then detail = "FREE PLAY · NO TIME LIMIT"
		elseif mode == "select" then detail = "CHOOSING A MODE"
		elseif mode == "recordRun" then
			if station.recordStatus == "running" then
				local seconds = math.max(0, math.ceil((station.endsAt or 0) - Workspace:GetServerTimeNow()))
				detail = string.format("1-MINUTE RECORD RUN\n%d POINTS · %d:%02d", station.score or 0, math.floor(seconds / 60), seconds % 60)
			elseif station.recordStatus == "countdown" then detail = "1-MINUTE RECORD RUN · GET READY"
			else detail = "1-MINUTE RECORD RUN · RESULTS" end
		end
		stationLabel.Text = (station.operatorName and ("NOW PLAYING · " .. station.operatorName) or "PIZZA LAUNCHER") .. "\n" .. detail
	end
	if milestoneLabel and milestoneLabel.Parent and milestone then
		milestoneLabel.Text = string.format("NEIGHBORHOOD SERVICE  %d / %d", milestone.progress, milestone.target)
	end
end

return TakeoutWorld
