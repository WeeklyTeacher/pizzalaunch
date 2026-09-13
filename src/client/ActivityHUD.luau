local Theme = require(script.Parent.UITheme)
local Presentation = require(script.Parent.ActivityPresentation)
local ActivityHUD = {}

function ActivityHUD.new(context)
	local self = { snapshot = {}, epoch = -1, suppressedEpoch = -1, mounted = false, covered = false,
		routeRequested = false, choiceOpen = false, queueRequestId = 0, takeoutRequestId = 0, routeIndex = 1, nextTextUpdate = 0 }
	local colors = Theme.colors
	local function panel(name, size, position)
		local item = Instance.new("Frame")
		item.Name = name
		item.AnchorPoint = Vector2.new(0.5, 0)
		item.Size = size
		item.Position = position
		item.BackgroundColor3 = colors.cream
		item.Visible = false
		item.ZIndex = 16
		item.Parent = context.gui
		Theme.addCorner(item, 16)
		Theme.addStroke(item, colors.darkRed, 2)
		return item
	end
	local function label(parent, name, text, size, position, fontSize)
		local item = Theme.makeLabel(parent, name, text, size, position, fontSize)
		item.ZIndex = 17
		return item
	end
	local function button(parent, name, text, size, position, color)
		local item = Theme.makeButton(parent, name, text, size, position, color)
		item.TextSize = 14
		item.ZIndex = 18
		return item
	end
	local card = panel("WalkingActivity", UDim2.fromOffset(420, 154), UDim2.new(0.5, 0, 0, 76))
	local title = label(card, "Objective", "TAKEOUT RUNNER", UDim2.new(1, -24, 0, 26), UDim2.fromOffset(12, 8), 18)
	title.TextColor3 = colors.darkRed
	local detail = label(card, "Detail", "", UDim2.new(1, -24, 0, 43), UDim2.fromOffset(12, 36), 14)
	local queueText = label(card, "Queue", "", UDim2.new(1, -24, 0, 22), UDim2.fromOffset(12, 81), 12)
	queueText.TextColor3 = colors.darkRed
	local takeout = button(card, "DoTakeout", "DO TAKEOUT ORDERS", UDim2.new(0.58, -18, 0, 40), UDim2.fromOffset(12, 105), colors.green)
	local leave = button(card, "LeaveLine", "LEAVE LINE", UDim2.new(0.42, -18, 0, 40), UDim2.new(0.58, 6, 0, 105), colors.red)
	local choice = panel("OccupiedLauncherChoices", UDim2.fromOffset(430, 194), UDim2.new(0.5, 0, 0, 88))
	local choiceTitle = label(choice, "Title", "ANOTHER CHEF IS PLAYING", UDim2.new(1, -66, 0, 28), UDim2.fromOffset(12, 10), 19)
	choiceTitle.TextColor3 = colors.darkRed
	local choiceDetail = label(choice, "NowPlaying", "", UDim2.new(1, -24, 0, 56), UDim2.fromOffset(12, 43), 14)
	local join = button(choice, "JoinLine", "JOIN LINE", UDim2.new(0.5, -18, 0, 62), UDim2.fromOffset(12, 115), colors.red)
	local chooseTakeout = button(choice, "ChooseTakeout", "DO TAKEOUT\nORDERS", UDim2.new(0.5, -18, 0, 62), UDim2.new(0.5, 6, 0, 115), colors.green)
	local close = button(choice, "Close", "X", UDim2.fromOffset(36, 36), UDim2.new(1, -46, 0, 8), colors.darkRed)
	join.NextSelectionRight = chooseTakeout
	chooseTakeout.NextSelectionLeft = join
	close.NextSelectionDown = join
	local notice = panel("ActivityNotice", UDim2.fromOffset(380, 64), UDim2.new(0.5, 0, 0, 240))
	local noticeText = label(notice, "Message", "", UDim2.new(1, -20, 1, -12), UDim2.fromOffset(10, 6), 15)
	local marker, markerLabel, carryBox
	local defaultExit = context.exitButton.Text
	local function clearWorld()
		if marker then marker:Destroy(); marker = nil; markerLabel = nil end
		if carryBox then carryBox:Destroy(); carryBox = nil end
	end
	local function setChoice(open)
		if open == self.choiceOpen then return end
		self.choiceOpen = open
		if open and context.UserInputService.GamepadEnabled then
			self.previousSelection = context.GuiService.SelectedObject
			context.GuiService.SelectedObject = join
		elseif not open then
			local selected = context.GuiService.SelectedObject
			if selected and choice:IsAncestorOf(selected) then
				local prior = self.previousSelection
				context.GuiService.SelectedObject = prior and prior.Parent and prior or nil
			end
			self.previousSelection = nil
		end
	end
	local function requestTakeout()
		if self.mounted or self.epoch < 0 or self.epoch <= self.suppressedEpoch then return end
		self.takeoutRequestId += 1
		context.takeoutRemote:FireServer("route", self.epoch, self.takeoutRequestId)
		setChoice(false)
		context.onChanged()
	end
	join.Activated:Connect(function()
		if self.mounted or self.epoch < 0 or self.epoch <= self.suppressedEpoch then return end
		self.queueRequestId += 1
		context.queueRemote:FireServer("join", self.epoch, self.queueRequestId)
	end)
	leave.Activated:Connect(function()
		if self.mounted or self.epoch < 0 or self.epoch <= self.suppressedEpoch then return end
		self.queueRequestId += 1
		context.queueRemote:FireServer("leave", self.epoch, self.queueRequestId)
	end)
	chooseTakeout.Activated:Connect(requestTakeout)
	takeout.Activated:Connect(requestTakeout)
	close.Activated:Connect(function() setChoice(false); context.onChanged() end)
	context.UserInputService.InputBegan:Connect(function(input)
		if self.choiceOpen and not self.mounted and input.KeyCode == Enum.KeyCode.ButtonB then
			setChoice(false)
			context.onChanged()
		end
	end)
	function self.setContext(mounted, covered)
		self.mounted, self.covered = mounted, covered
		if mounted then
			setChoice(false)
			self.routeRequested = false
			clearWorld()
		end
	end
	function self.hasObjective()
		if self.epoch <= self.suppressedEpoch or self.mounted then return false end
		local view = Presentation.select(self.snapshot, context.Workspace:GetServerTimeNow(), self.mounted, self.routeRequested)
		return view.visible or self.choiceOpen
	end
	function self.resetLocal(replacingCharacter)
		self.suppressedEpoch = math.max(self.suppressedEpoch, self.epoch)
		self.suppressedCharacter = not replacingCharacter and (context.player.Character or self.snapshot.character) or nil
		self.routeRequested = false
		self.noticeUntil = 0
		self.rewardNoticeUntil = 0
		setChoice(false)
		clearWorld()
		card.Visible, choice.Visible, notice.Visible = false, false, false
	end
	local function showNotice(text)
		noticeText.Text = text
		self.noticeUntil = context.Workspace:GetServerTimeNow() + 3.5
	end
	function self.receive(snapshot)
		local epoch = snapshot.activityEpoch or 0
		if snapshot.character ~= nil and snapshot.character ~= context.player.Character then return end
		if snapshot.character ~= nil and snapshot.character == self.suppressedCharacter then return end
		if epoch < self.epoch then return end
		if epoch <= self.suppressedEpoch and (snapshot.character == nil or snapshot.character == self.suppressedCharacter) then return end
		-- A new-character snapshot can arrive before CharacterAdded locally.
		-- Instance identity lets its repeated same-epoch snapshot restore the
		-- walking UI after replication, while old-character packets stay stale.
		self.suppressedEpoch = -1
		if epoch ~= self.epoch then
			self.routeRequested = false
			self.noticeUntil = 0
			self.rewardNoticeUntil = 0
			self.routeIndex = 1
			setChoice(false)
			clearWorld()
		end
		local previousOrder = self.snapshot.runner and self.snapshot.runner.orderId
		self.epoch, self.snapshot = epoch, snapshot
		local event, payload = snapshot.event, snapshot.payload or {}
		if event == "launcherOccupied" and not self.mounted then
			setChoice(true)
		elseif event == "takeoutRoute" then
			self.routeRequested = true
			self.routeIndex = 1
			setChoice(false)
		elseif event == "runnerStarted" then
			self.routeRequested = false
			self.routeIndex = 1
			setChoice(false)
		elseif event == "runnerCompleted" then
			self.routeRequested = true
			self.routeIndex = 1
			showNotice(string.format("DELIVERED! +%d COINS\nPick up another box whenever you like.", payload.coinsEarned or 0))
		elseif event == "runnerCancelled" then
			self.routeRequested = false
		elseif event == "runnerRejected" then
			showNotice("Move closer to the pickup or your delivery marker.")
		elseif event == "queueReserved" then
			setChoice(false)
			showNotice("YOUR TURN! Approach the launcher and use its prompt.")
		elseif event == "queueChanged" and snapshot.queue and snapshot.queue.status ~= "none" then
			setChoice(false)
		elseif event == "queueRejected" then
			showNotice("Approach the launcher to join the line.")
		elseif event == "queueLeft" and payload.reason == "reservationExpired" then
			showNotice("Your reservation ended.\nYou can join the line again whenever you like.")
		elseif event == "restaurantReward" then
			showNotice(string.format("RESTAURANT MILESTONE!\nYour contribution earned +%d coins.", payload.coinsEarned or 0))
			self.rewardNoticeUntil = self.noticeUntil
		elseif event == "restaurantMilestone" and context.Workspace:GetServerTimeNow() >= (self.rewardNoticeUntil or 0) then
			showNotice("RESTAURANT MILESTONE!\nThe neighborhood enjoyed another batch of pizzas.")
		end
		if previousOrder ~= (snapshot.runner and snapshot.runner.orderId) then clearWorld(); self.routeIndex = 1 end
		if context.onEconomy then context.onEconomy(snapshot.coins, snapshot.upgrades) end
		self.nextTextUpdate = 0
		context.onChanged()
	end
	local function localPart(name, size, color)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.Color = color
		part.Material = Enum.Material.SmoothPlastic
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.CastShadow = false
		part:SetAttribute("ClientOnly", true)
		part.Parent = context.Workspace
		return part
	end
	local function updateWorld(view)
		local runner = self.snapshot.runner or {}
		local character = context.player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if self.mounted or not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then clearWorld(); return end
		if view.carrying then
			if not carryBox then
				carryBox = localPart("LocalTakeoutBox", Vector3.new(2.3, 0.38, 2.3), colors.cream)
				local sticker = Instance.new("SurfaceGui")
				sticker.Name = "PizzaBoxLabel"
				sticker.Face = Enum.NormalId.Top
				sticker.CanvasSize = Vector2.new(240, 240)
				sticker.Parent = carryBox
				local text = Theme.makeLabel(sticker, "Pizza", "PIZZA\nTO GO", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), 46)
				text.TextColor3 = colors.red
			end
			carryBox.CFrame = root.CFrame * CFrame.new(0, 0.2, -1.6)
		elseif carryBox then carryBox:Destroy(); carryBox = nil end
		local target = view.reserved and self.snapshot.station and self.snapshot.station.interactionPosition
		local markerText = view.reserved and "YOUR TURN • LAUNCHER" or "TAKEOUT PICKUP"
		if not target and (view.carrying or self.routeRequested) and not view.reserved then
			target = view.carrying and runner.destinationPosition or runner.pickupPosition
			markerText = view.carrying and (runner.destinationName or "DELIVERY") or "TAKEOUT PICKUP"
			local points = runner.routePositions or {}
			local waypoint = points[self.routeIndex]
			-- These are clearance corners supplied by the server. Taking a
			-- diagonal shortcut because another point is nearer can cut through
			-- a bench, bin or parked van on the return route.
			while waypoint and (root.Position - waypoint).Magnitude <= 2.5 do
				self.routeIndex += 1
				waypoint = points[self.routeIndex]
			end
			if waypoint then
				target = waypoint
				if self.routeIndex < #points then markerText = "TAKEOUT • THIS WAY" end
			end
		end
		if typeof(target) == "Vector3" then
			if not marker then
				marker = localPart("LocalTakeoutMarker", Vector3.new(0.2, 0.2, 0.2), colors.green)
				marker.Transparency = 1
				local billboard = Instance.new("BillboardGui")
				billboard.Name = "DestinationCue"
				billboard.Size = UDim2.fromOffset(180, 44)
				billboard.AlwaysOnTop = true
				billboard.MaxDistance = 240
				billboard.Adornee = marker
				billboard.Parent = marker
				markerLabel = Theme.makeLabel(billboard, "Destination", "TAKEOUT", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), 15)
				markerLabel.BackgroundTransparency = 0.08
				markerLabel.BackgroundColor3 = colors.cream
				markerLabel.TextColor3 = colors.darkRed
				Theme.addCorner(markerLabel, 10)
				Theme.addStroke(markerLabel, colors.green, 2)
			end
			marker.Position = target + Vector3.new(0, 4, 0)
			markerLabel.Text = markerText
		elseif marker then marker:Destroy(); marker = nil; markerLabel = nil end
	end
	function self.render()
		if self.epoch <= self.suppressedEpoch then return end
		local now = context.Workspace:GetServerTimeNow()
		local view = Presentation.select(self.snapshot, now, self.mounted, self.routeRequested)
		context.exitButton.Text = view.passTurn and "EXIT &\nPASS TURN" or defaultExit
		card.Visible = view.visible and not self.choiceOpen and not self.covered
		choice.Visible = self.choiceOpen and not self.mounted and not self.covered
		notice.Visible = not self.mounted and not self.covered and now < (self.noticeUntil or 0)
		if now >= self.nextTextUpdate then
			self.nextTextUpdate = now + 0.2
			title.Text, detail.Text, queueText.Text = view.title, view.detail, view.queueText
			choiceDetail.Text = view.chefText .. "\n" .. view.stationText
			takeout.Visible, leave.Visible = view.canDoTakeout, view.canLeaveLine
			local camera = context.Workspace.CurrentCamera
			local width = camera and camera.ViewportSize.X or 900
			local availableWidth = math.max(300, math.min(420, width - 36))
			card.Size = UDim2.fromOffset(availableWidth, (view.canDoTakeout or view.canLeaveLine) and 154 or 108)
			choice.Size = UDim2.fromOffset(math.min(430, availableWidth), 194)
			notice.Position = UDim2.new(0.5, 0, 0, card.Visible and 240 or 88)
		end
		updateWorld(view)
	end
	context.activityRemote.OnClientEvent:Connect(self.receive)
	return self
end

return ActivityHUD
