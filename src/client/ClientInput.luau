local ClientInput = {}

function ClientInput.bind(context)
	local self = { connections = {} }
	local inputState, ui, inputService = context.inputState, context.ui, context.UserInputService
	local colors = context.COLORS
	local function connect(signal, callback)
		table.insert(self.connections, signal:Connect(callback))
	end
	local function release(input)
		inputState:setTouch("", input, false)
		local request = inputState:release(input, os.clock())
		if request then
			context.launchRemote:FireServer(context.currentDirection(), request.charge, request.requestId, request.cleanupEpoch)
		end
	end
	local function begin(input)
		inputState:begin(input, os.clock())
	end
	local function aim(position)
		if not inputState.aimable or inputState.blocked then return end
		local camera = context.getCamera()
		if not camera then return end
		local viewport = camera.ViewportSize
		if viewport.X <= 0 or viewport.Y <= 0 then return end
		inputState.aimYaw = math.clamp((position.X / viewport.X - 0.5) * 2, -1, 1)
		inputState.aimPitch = 1 - math.clamp((position.Y / viewport.Y - 0.12) / 0.7, 0, 1)
	end
	for direction, button in ui.aimButtons do
		button.TextSize = 22
		connect(button.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				inputState:setTouch(direction, input, true)
			end
		end)
		connect(button.InputEnded, function(input) inputState:setTouch(direction, input, false) end)
	end
	connect(ui.fireButton.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then begin(input) end
	end)
	connect(ui.fireButton.InputEnded, release)
	local aimKeyMap = {
		[Enum.KeyCode.A] = "left", [Enum.KeyCode.Left] = "left",
		[Enum.KeyCode.D] = "right", [Enum.KeyCode.Right] = "right",
		[Enum.KeyCode.W] = "up", [Enum.KeyCode.Up] = "up",
		[Enum.KeyCode.S] = "down", [Enum.KeyCode.Down] = "down",
	}
	connect(inputService.InputBegan, function(input, processed)
		if inputService:GetFocusedTextBox() then return end
		if context.isOperating() and (input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.ButtonB) then
			context.modeRemote:FireServer("walk")
			return
		end
		if not inputState.aimable or inputState.blocked then return end
		local key = aimKeyMap[input.KeyCode]
		if key then
			inputState.keyboardHeld[key] = true
		elseif input.KeyCode == Enum.KeyCode.ButtonR2 or input.KeyCode == Enum.KeyCode.Space then
			-- Mounted movement locking may mark Space as processed. Modal and
			-- focused-text gates above still prevent it from launching through UI.
			begin(input)
		elseif not processed and input.UserInputType == Enum.UserInputType.MouseButton1 then
			begin(input)
		end
	end)
	-- The global release owns touch cancellation even after a finger leaves a
	-- control. Each arrow and the charge finger keep independent identities.
	connect(inputService.InputEnded, function(input)
		local key = aimKeyMap[input.KeyCode]
		if key then inputState.keyboardHeld[key] = false end
		release(input)
	end)
	connect(inputService.InputChanged, function(input, processed)
		if not inputState.aimable or inputState.blocked then return end
		if input.KeyCode == Enum.KeyCode.Thumbstick1 then
			inputState.gamepadAim = Vector2.new(input.Position.X, input.Position.Y)
		elseif not processed and (input.UserInputType == Enum.UserInputType.MouseMovement
			or (input.UserInputType == Enum.UserInputType.Touch and input ~= inputState.activeFireInput and not inputState.touchOwners[input])) then
			aim(input.Position)
		end
	end)
	connect(inputService.WindowFocusReleased, function() inputState:cancelCharge() end)
	connect(inputService.TextBoxFocused, function() inputState:cancelCharge() end)

	function self.render()
		local now = os.clock()
		local ready = inputState:isReady(now)
		if inputState.charging then
			ui.fireButton.Text = "RELEASE!"
			ui.fireButton.BackgroundColor3 = colors.orange
		elseif inputState.pendingRequestId then
			ui.fireButton.Text = "LAUNCHING"
			ui.fireButton.BackgroundColor3 = Color3.fromRGB(142, 128, 119)
		elseif ready then
			ui.fireButton.Text = "HOLD\nLAUNCH"
			ui.fireButton.BackgroundColor3 = colors.red
		elseif inputState.reloadReadyAt > now then
			ui.fireButton.Text = string.format("RELOAD\n%.1fs", inputState.reloadReadyAt - now)
			ui.fireButton.BackgroundColor3 = Color3.fromRGB(142, 128, 119)
		else
			ui.fireButton.Text = "OVEN\nRELOAD"
			ui.fireButton.BackgroundColor3 = Color3.fromRGB(142, 128, 119)
		end
		local touch = inputService.TouchEnabled
		ui.fireButton.Size = inputState.charging and (touch and UDim2.fromOffset(134, 86) or UDim2.fromOffset(166, 110))
			or (touch and UDim2.fromOffset(128, 80) or UDim2.fromOffset(160, 104))
		for direction, button in ui.aimButtons do
			button.BackgroundColor3 = inputState.touchHeld[direction] and colors.yellow
				or ((direction == "up" or direction == "down") and colors.orange or colors.red)
		end
	end
	function self.destroy()
		inputState:cancelCharge()
		for _, connection in self.connections do connection:Disconnect() end
		table.clear(self.connections)
	end
	return self
end

return ClientInput
