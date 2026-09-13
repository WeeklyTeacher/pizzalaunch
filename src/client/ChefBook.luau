local Theme = require(script.Parent.UITheme)
local Presentation = require(script.Parent.ChefBookPresentation)
local ChefBook = {}

function ChefBook.new(context)
	local self = { snapshot = { status = "loading" }, opened = false, mounted = false, covered = false, requestId = 0 }
	local colors, config = Theme.colors, context.config
	local function alive() return not context.isAlive or context.isAlive() end
	local function label(parent, name, text, size, position, font)
		local item = Theme.makeLabel(parent, name, text, size, position, font)
		item.ZIndex = 32
		return item
	end
	local button = Theme.makeButton(context.gui, "ChefBookToggle", "CHEF BOOK", UDim2.fromOffset(108, 44), UDim2.fromOffset(0, 60), colors.cream)
	button.TextColor3, button.TextSize, button.ZIndex = colors.ink, 14, 25
	local panel = Instance.new("Frame")
	panel.Name, panel.AnchorPoint = "ChefBookPanel", Vector2.new(0.5, 0)
	panel.BackgroundColor3, panel.Visible, panel.ZIndex = colors.cream, false, 30
	panel.Parent = context.gui
	Theme.addCorner(panel, 16)
	Theme.addStroke(panel, colors.border, 1.5)
	local title = label(panel, "BookTitle", "CHEF BOOK", UDim2.new(1, -78, 0, 30), UDim2.fromOffset(14, 8), 23)
	title.TextXAlignment = Enum.TextXAlignment.Left
	local status = label(panel, "BookStatus", "", UDim2.new(1, -28, 0, 40), UDim2.fromOffset(14, 42), 14)
	status.TextXAlignment = Enum.TextXAlignment.Left
	local close = Theme.makeButton(panel, "CloseBook", "X", UDim2.fromOffset(44, 44), UDim2.new(1, -54, 0, 8), colors.red)
	close.ZIndex = 33
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name, scroll.BackgroundTransparency, scroll.BorderSizePixel = "BookPages", 1, 0
	scroll.ScrollBarThickness, scroll.ZIndex = 6, 31
	scroll.Selectable = true
	scroll.Parent = panel
	local y = 0
	local resize = {}
	local function heading(name, text, height)
		local item = label(scroll, name, text, UDim2.new(1, -14, 0, height or 30), UDim2.fromOffset(4, y), 18)
		item.TextXAlignment = Enum.TextXAlignment.Left
		y += (height or 30) + 6
		return item
	end
	local totals = heading("BookTotals", "", 72)
	totals.TextSize = 16
	local goalRows = {}
	heading("MasteryHeading", "MASTERY GOALS")
	for _, goal in config.goals do
		local name = label(scroll, "Goal_" .. goal.id, goal.name, UDim2.new(1, -16, 0, 24), UDim2.fromOffset(8, y), 16)
		name.TextXAlignment = Enum.TextXAlignment.Left
		local progress = label(scroll, "Progress_" .. goal.id, "", UDim2.new(1, -16, 0, 22), UDim2.fromOffset(8, y + 25), 14)
		progress.TextXAlignment = Enum.TextXAlignment.Left
		goalRows[goal.id] = progress
		y += 57
	end
	local function stampGrid(headingName, headingText, keys, prefix)
		heading(headingName, headingText)
		local cells, start = {}, y
		for index, key in keys do
			local cell = label(scroll, prefix .. key, key, UDim2.fromOffset(70, 38), UDim2.fromOffset(0, 0), 14)
			cell.BackgroundTransparency = 0
			Theme.addCorner(cell, 8)
			cells[key] = cell
			table.insert(resize, function(width)
				local cellWidth = (width - 14 - 5 * 6) / 6
				cell.Size = UDim2.fromOffset(cellWidth, 38)
				cell.Position = UDim2.fromOffset(4 + ((index - 1) % 6) * (cellWidth + 6), start + math.floor((index - 1) / 6) * 44)
			end)
		end
		y += math.ceil(#keys / 6) * 44 + 12
		return cells
	end
	local tableStamps = stampGrid("TableStampsHeading", "TABLE STAMPS • Serve each table", { "1", "2", "3", "4", "5", "6" }, "TableStamp_")
	local customerNames = {}
	for name in config.customers do table.insert(customerNames, name) end
	table.sort(customerNames)
	local customerStamps = stampGrid("CustomerStampsHeading", "CUSTOMER STAMPS", customerNames, "CustomerStamp_")
	heading("RecordTiersHeading", "PERSONAL RECORD MILESTONES")
	local tierRows = {}
	for _, score in config.recordTiers do
		local row = label(scroll, "RecordTier_" .. score, "", UDim2.new(1, -16, 0, 26), UDim2.fromOffset(8, y), 16)
		row.TextXAlignment = Enum.TextXAlignment.Left
		tierRows[score] = row
		y += 30
	end
	local recordNote = heading("RecordNote", "Chef Book counts completed runs since this book was added.", 36)
	recordNote.TextSize = 14
	heading("NameplatesHeading", "EARNED NAMEPLATES")
	local cosmeticRows = {}
	for _, id in config.cosmeticOrder do
		local definition = config.cosmetics[id]
		local row = Theme.makeButton(scroll, "Nameplate_" .. id, "", UDim2.new(1, -14, 0, 74), UDim2.fromOffset(4, y), colors.surface)
		row.ZIndex = 32
		local name = label(row, "Name", definition.name, UDim2.new(1, -140, 0, 24), UDim2.fromOffset(12, 7), 16)
		name.TextXAlignment = Enum.TextXAlignment.Left
		local requirement = label(row, "Requirement", "", UDim2.new(1, -140, 0, 34), UDim2.fromOffset(12, 33), 14)
		requirement.TextXAlignment = Enum.TextXAlignment.Left
		local action = label(row, "EquipState", "LOCKED", UDim2.fromOffset(106, 44), UDim2.new(1, -118, 0, 15), 14)
		action.BackgroundTransparency = 0
		Theme.addCorner(action, 10)
		cosmeticRows[id] = { row = row, requirement = requirement, action = action, definition = definition }
		row.Activated:Connect(function()
			if self.mounted or not alive() or not self.opened or not Presentation.canEquip(self.snapshot, id) or self.snapshot.equipped == id then return end
			self.requestId += 1
			context.actionRemote:FireServer("equip", id, context.getEpoch(), self.requestId)
		end)
		y += 82
	end
	scroll.CanvasSize = UDim2.fromOffset(0, y + 8)
	close.NextSelectionDown = scroll
	scroll.NextSelectionUp = close
	function self.isOpen() return self.opened end
	function self.close(notify)
		self.opened = false
		panel.Visible = false
		if notify ~= false then context.onChanged() end
	end
	function self.setContext(mounted, covered)
		self.mounted, self.covered = mounted, covered
		if mounted or covered then self.close(false) end
	end
	function self.navigation()
		return self.opened and panel or nil, self.opened and close or nil
	end
	function self.request()
		if self.mounted or not alive() then return end
		self.requestId += 1
		context.actionRemote:FireServer("request", nil, context.getEpoch(), self.requestId)
	end
	button.Activated:Connect(function()
		if self.mounted or self.covered or not alive() then return end
		self.opened = not self.opened
		context.onChanged()
		if self.opened then self.request() end
	end)
	close.Activated:Connect(function() self.close() end)
	context.inputService.InputBegan:Connect(function(input)
		if self.opened and input.KeyCode == Enum.KeyCode.ButtonB and not context.inputService:GetFocusedTextBox() then self.close() end
	end)
	function self.receive(snapshot)
		self.snapshot = snapshot
		status.Text = Presentation.status(snapshot)
		local mastery = snapshot.mastery or {}
		totals.Text = string.format("%d deliveries • %d Perfect • %d Great\n%d far tables • %d takeout\n%d completed runs • Book best %d", mastery.deliveries or 0, mastery.perfect or 0, mastery.great or 0, mastery.farDeliveries or 0, mastery.takeout or 0, mastery.recordRuns or 0, mastery.recordBest or 0)
		for _, goal in config.goals do
			local text, complete = Presentation.goal(snapshot, goal)
			goalRows[goal.id].Text = text
			goalRows[goal.id].TextColor3 = complete and colors.green or colors.muted
		end
		for _, stamps in { { cells = tableStamps, flags = snapshot.tableStamps or {} }, { cells = customerStamps, flags = snapshot.customerStamps or {} } } do
			for key, cell in stamps.cells do
				local earned = stamps.flags[key] == true
				cell.Text = earned and key .. " ✓" or key
				cell.BackgroundColor3 = earned and colors.green or colors.border
				cell.TextColor3 = earned and Color3.new(1, 1, 1) or colors.ink
			end
		end
		for score, row in tierRows do
			local complete = (mastery.recordBest or 0) >= score
			row.Text = string.format("%d POINTS • %s", score, complete and "COMPLETE" or "KEEP PRACTICING")
			row.TextColor3 = complete and colors.green or colors.muted
		end
		for id, row in cosmeticRows do
			local requirement, action, enabled = Presentation.cosmetic(snapshot, id, row.definition)
			row.requirement.Text, row.action.Text = requirement, action
			row.row.Selectable = enabled
			row.action.BackgroundColor3 = enabled and colors.red or (action == "EQUIPPED" and colors.green or colors.border)
			row.action.TextColor3 = (enabled or action == "EQUIPPED") and Color3.new(1, 1, 1) or colors.ink
		end
		if context.onProfile then context.onProfile(snapshot) end
		-- Profile traffic cannot enter mounted HUD/input presentation. The hidden
		-- book updates its own rows, ready for the player's next walking visit.
		if not self.mounted then context.onChanged() end
	end
	function self.render()
		local layout = context.getLayout()
		button.Size = UDim2.fromOffset(layout.navWidth, 44)
		button.Position = UDim2.fromOffset(layout.width - layout.margin - layout.navWidth, layout.margin + 50)
		button.Visible = not self.mounted and not self.covered and not self.opened and alive()
		panel.Visible = self.opened and not self.mounted and not self.covered
		local width, height = math.min(560, layout.width - layout.margin * 2), math.min(600, layout.height - 74)
		local key = string.format("%d:%d", width, height)
		if key ~= self.layoutKey then
			self.layoutKey = key
			panel.Size, panel.Position = UDim2.fromOffset(width, height), UDim2.new(0.5, 0, 0, 64)
			scroll.Size, scroll.Position = UDim2.fromOffset(width - 20, height - 100), UDim2.fromOffset(10, 90)
			for _, callback in resize do callback(width - 20) end
		end
	end
	self.receive(self.snapshot)
	return self
end

return ChefBook
