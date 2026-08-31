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

function InteractionService.setLauncherAvailable(available: boolean)
	if launcherPrompt then
		launcherPrompt.Enabled = available
	end
	if recordRunPrompt then
		recordRunPrompt.Enabled = available
	end
end

return InteractionService
