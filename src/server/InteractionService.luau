local InteractionService = {}

local connections: { RBXScriptConnection } = {}
local launcherPrompt: ProximityPrompt?
local recordRunPrompt: ProximityPrompt?

local function connectPrompt(item: ProximityPrompt, handlers)
	if item.Name == "LauncherPrompt" then
		launcherPrompt = item
		table.insert(connections, item.Triggered:Connect(handlers.launcher))
	elseif item.Name == "RecordRunPrompt" then
		recordRunPrompt = item
		table.insert(connections, item.Triggered:Connect(handlers.recordRun))
	elseif item.Name == "RegisterPrompt" then
		table.insert(connections, item.Triggered:Connect(handlers.register))
	elseif item.Name == "CustomerPrompt" then
		table.insert(connections, item.Triggered:Connect(function(player)
			handlers.customer(player, item:GetAttribute("TableId"))
		end))
	elseif item.Name == "TakeoutPickupPrompt" and handlers.takeoutPickup then
		table.insert(connections, item.Triggered:Connect(handlers.takeoutPickup))
	elseif item.Name == "TakeoutDeliveryPrompt" and handlers.takeoutDelivery then
		table.insert(connections, item.Triggered:Connect(function(player)
			handlers.takeoutDelivery(player, item:GetAttribute("DestinationId"))
		end))
	end
end

function InteractionService.start(world: Instance, handlers)
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	launcherPrompt = nil
	recordRunPrompt = nil

	for _, descendant in world:GetDescendants() do
		if descendant:IsA("ProximityPrompt") then
			connectPrompt(descendant, handlers)
		end
	end
end

function InteractionService.setLauncherAvailable(available: boolean, reservedName: string?)
	if launcherPrompt then
		-- Keep the shared attraction visible and triggerable while occupied so a
		-- second player gets an explicit server response instead of a vanishing UI.
		launcherPrompt.Enabled = true
		launcherPrompt.ActionText = reservedName and "RESERVED TURN" or (available and "USE LAUNCHER" or "OCCUPIED")
		launcherPrompt.ObjectText = reservedName and ("NEXT: " .. reservedName) or (available and "PIZZA LAUNCHER" or "JOIN LINE OR DO TAKEOUT")
	end
	if recordRunPrompt then
		recordRunPrompt.Enabled = false
	end
end

return InteractionService
