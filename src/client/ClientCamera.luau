-- Owns only local camera, navigation focus and default movement presentation.
-- Character pose, health validation and the launcher lease stay server-owned.
local ClientCamera = {}

function ClientCamera.new(context)
	local self = { mounted = false, connections = {}, characterConnections = {}, touchDefaults = {}, cameraDefaults = {}, characterToken = 0 }
	local player, playerGui = context.player, context.playerGui
	local Workspace, GuiService, actions = context.Workspace, context.GuiService, context.ContextActionService
	local controls
	function self.getCamera() return Workspace.CurrentCamera end
	function self.isAlive()
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		return character ~= nil and character.Parent ~= nil and humanoid ~= nil and humanoid.Health > 0 and root ~= nil and root:IsA("BasePart") and root.Parent ~= nil
	end
	local function rememberCamera(camera)
		if camera and not self.cameraDefaults[camera] then
			self.cameraDefaults[camera] = { kind = camera.CameraType, subject = camera.CameraSubject, fov = camera.FieldOfView }
		end
	end
	local function lockTouch(touchGui)
		if not touchGui:IsA("ScreenGui") or touchGui.Name ~= "TouchGui" then return end
		if self.mounted then
			if self.touchDefaults[touchGui] == nil then self.touchDefaults[touchGui] = touchGui.Enabled end
			touchGui.Enabled = false
		end
	end
	local function watchTouch(touchGui)
		if touchGui.Name ~= "TouchGui" or not touchGui:IsA("ScreenGui") then return end
		table.insert(self.connections, touchGui:GetPropertyChangedSignal("Enabled"):Connect(function()
			if self.mounted and touchGui.Enabled then lockTouch(touchGui) end
		end))
		lockTouch(touchGui)
	end
	function self.setMounted(mounted: boolean)
		local changed = mounted ~= self.mounted
		self.mounted = mounted
		if mounted then
			if changed then
				self.previousSelection = GuiService.SelectedObject
				actions:BindActionAtPriority("BlockMovement", function() return Enum.ContextActionResult.Sink end, false, Enum.ContextActionPriority.High.Value,
					Enum.PlayerActions.CharacterForward, Enum.PlayerActions.CharacterBackward, Enum.PlayerActions.CharacterLeft,
					Enum.PlayerActions.CharacterRight, Enum.PlayerActions.CharacterJump)
			end
			rememberCamera(self.getCamera())
			if controls then controls:Disable() end
			for _, item in playerGui:GetChildren() do lockTouch(item) end
		else
			actions:UnbindAction("BlockMovement")
			if controls then controls:Enable() end
			for item, enabled in self.touchDefaults do if item.Parent then item.Enabled = enabled end end
			table.clear(self.touchDefaults)
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local current = self.getCamera()
			for camera, prior in self.cameraDefaults do
				if camera.Parent then
					camera.CameraType = prior.kind == Enum.CameraType.Scriptable and Enum.CameraType.Custom or prior.kind
					camera.FieldOfView = prior.fov
					camera.CameraSubject = (camera == current and humanoid) or (prior.subject and prior.subject.Parent and prior.subject) or nil
				end
			end
			if current and not self.cameraDefaults[current] then
				current.CameraType = Enum.CameraType.Custom
				if humanoid then current.CameraSubject = humanoid end
			end
			table.clear(self.cameraDefaults)
			if changed then
				local selection = self.previousSelection
				GuiService.SelectedObject = selection and selection.Parent and selection or nil
				self.previousSelection = nil
			end
		end
	end
	function self.setPicker(picker, choice, visible: boolean)
		if visible and context.UserInputService.GamepadEnabled then
			GuiService.SelectedObject = choice
		elseif GuiService.SelectedObject and picker:IsAncestorOf(GuiService.SelectedObject) then
			GuiService.SelectedObject = nil
		end
	end
	function self.render(frame)
		if not self.mounted then return end
		local camera = self.getCamera()
		if not camera then return end
		rememberCamera(camera)
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = frame
		camera.FieldOfView = 57
	end
	function self.watchCharacter(onInvalid, onReady)
		local function attach(character)
			self.characterToken += 1
			self.watchedCharacter = character
			local token = self.characterToken
			for _, connection in self.characterConnections do connection:Disconnect() end
			table.clear(self.characterConnections)
			onInvalid("replacement")
			task.defer(function()
				local humanoid = character:WaitForChild("Humanoid", 8)
				if token ~= self.characterToken or player.Character ~= character or not humanoid then return end
				local function invalidate(reason)
					if token == self.characterToken and player.Character == character then onInvalid(reason) end
				end
				table.insert(self.characterConnections, humanoid.Died:Connect(function() invalidate("death") end))
				table.insert(self.characterConnections, character.ChildRemoved:Connect(function(child)
					if child == humanoid or child.Name == "HumanoidRootPart" then invalidate("characterInvalid") end
				end))
				if humanoid.Health <= 0 then onInvalid("death") else onReady(character) end
			end)
		end
		table.insert(self.connections, player.CharacterRemoving:Connect(function(character)
			if character ~= self.watchedCharacter then return end
			self.characterToken += 1
			self.watchedCharacter = nil
			for _, connection in self.characterConnections do connection:Disconnect() end
			table.clear(self.characterConnections)
			onInvalid("removing")
		end))
		table.insert(self.connections, player.CharacterAdded:Connect(attach))
		if player.Character then attach(player.Character) end
	end
	table.insert(self.connections, playerGui.ChildAdded:Connect(watchTouch))
	for _, child in playerGui:GetChildren() do watchTouch(child) end
	task.defer(function()
		local module = player.PlayerScripts:WaitForChild("PlayerModule", 8)
		if not module then return end
		local success, result = pcall(require, module)
		if success and result.GetControls then
			controls = result:GetControls()
			if self.mounted then controls:Disable() else controls:Enable() end
		end
	end)
	return self
end

return ClientCamera
