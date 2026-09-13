-- Source-native hero customer render rig. Existing CustomerPart instances remain
-- the authoritative contact proxies; this articulated model never participates
-- in collisions, delivery availability, physics ownership, or lifecycle timing.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local CustomerRig = {}
CustomerRig.__index = CustomerRig
CustomerRig.MAX_ACTIVE_RIGS = 6
CustomerRig.UPDATE_INTERVAL = 0.1

local activeByTable = {}

local WALKING = { Entering = true, WalkingToSeat = true, Leaving = true }
local ACCESSORIES = { "bow", "cap", "beanie" }

local function now() return Workspace:GetServerTimeNow() end

function CustomerRig:_part(name, size, color, parentPart, offset, shape)
	local part = Instance.new("Part")
	part.Name, part.Size, part.Color = name, size, color
	part.Shape, part.Material = shape or Enum.PartType.Ball, Enum.Material.SmoothPlastic
	part.Anchored, part.Massless = false, true
	part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
	part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	part:SetAttribute("CustomerVisual", true)
	part:SetAttribute("VisualTransparency", 0)
	part.CFrame = parentPart.CFrame * offset
	part.Parent = self.model
	if parentPart then
		local weld = Instance.new("WeldConstraint")
		weld.Part0, weld.Part1, weld.Parent = parentPart, part, part
	end
	return part
end

function CustomerRig:_joint(name, parentPart, size, color, c0, c1)
	local part = self:_part(name, size, color, parentPart, c0 * c1:Inverse())
	part:FindFirstChildOfClass("WeldConstraint"):Destroy()
	local joint = Instance.new("Motor6D")
	joint.Name, joint.Part0, joint.Part1 = name .. "Joint", parentPart, part
	joint.C0, joint.C1, joint.Parent = c0, c1, parentPart
	self.joints[name] = { motor = joint, base = c0 }
	return part
end

function CustomerRig.install(customer)
	local anchor = customer.PrimaryPart
	local tableId = customer:GetAttribute("TableId")
	if not anchor or typeof(tableId) ~= "number" or tableId % 1 ~= 0 or tableId < 1 or tableId > CustomerRig.MAX_ACTIVE_RIGS then return nil end
	local previous = activeByTable[tableId]
	if previous then
		if not previous.customer.Parent or not previous.model.Parent then previous:destroy()
		elseif previous.customer == customer then return previous
		else return nil end
	end
	local self = setmetatable({ customer = customer, anchor = anchor, tableId = tableId, joints = {}, fades = {}, state = "SeatedWaiting", stateAt = now(), visible = true }, CustomerRig)
	activeByTable[tableId] = self
	local model = Instance.new("Model")
	model.Name = "ArticulatedCustomer"
	model:SetAttribute("SourcePrefab", "ToyCustomer_v1")
	model.Parent = customer
	self.model = model
	local root = Instance.new("Part")
	root.Name, root.Size, root.CFrame = "VisualRoot", Vector3.new(0.2, 0.2, 0.2), anchor.CFrame
	root.Anchored, root.Massless, root.Transparency = true, true, 1
	root.CanCollide, root.CanTouch, root.CanQuery, root.CastShadow = false, false, false, false
	root:SetAttribute("CustomerVisual", true)
	root:SetAttribute("VisualTransparency", 1)
	root.Parent = model
	model.PrimaryPart, self.root = root, root
	local skin, shirt = Color3.fromRGB(246, 199, 154), Color3.fromRGB(178, 61, 55)
	local body = self:_joint("Body", root, Vector3.new(3, 3.3, 2.05), shirt, CFrame.new(0, 0.2, 0), CFrame.new())
	body:SetAttribute("ClothingPart", true)
	local apron = self:_part("Apron", Vector3.new(2.3, 2.3, 0.25), Color3.fromRGB(245, 231, 200), body, CFrame.new(0, -0.38, 1), Enum.PartType.Block)
	self:_part("ApronPocket", Vector3.new(1.15, 0.65, 0.2), Color3.fromRGB(73, 113, 78), apron, CFrame.new(0, -0.48, 0.17), Enum.PartType.Block)
	local head = self:_joint("Head", body, Vector3.new(3.15, 3.1, 2.95), skin, CFrame.new(0, 1.7, 0), CFrame.new(0, -1.4, 0))
	head:SetAttribute("SkinPart", true)
	self.head = head
	self.eyes = {}
	for _, side in { -1, 1 } do
		local eye = self:_part("Eye", Vector3.new(0.25, 0.35, 0.13), Color3.fromRGB(46, 33, 29), head, CFrame.new(side * 0.56, 0.12, 1.44))
		table.insert(self.eyes, eye)
		self:_part("EyeSparkle", Vector3.new(0.075, 0.09, 0.04), Color3.fromRGB(255, 248, 228), eye, CFrame.new(-0.035, 0.07, 0.08))
		self:_part("Cheek", Vector3.new(0.43, 0.21, 0.085), Color3.fromRGB(221, 131, 103), head, CFrame.new(side * 0.97, -0.22, 1.27))
	end
	self.mouth = self:_part("Smile", Vector3.new(0.59, 0.18, 0.1), Color3.fromRGB(85, 47, 36), head, CFrame.new(0, -0.55, 1.39))
	self:_part("HairCap", Vector3.new(3.2, 1.3, 2.87), Color3.fromRGB(69, 43, 32), head, CFrame.new(0, 1.12, -0.16))
	for _, side in { -1, 1 } do
		local key = side < 0 and "Left" or "Right"
		local arm = self:_joint(key .. "Arm", body, Vector3.new(1.05, 1.55, 1.08), shirt,
			CFrame.new(side * 1.62, 1.08, 0), CFrame.new(0, 0.69, 0))
		arm:SetAttribute("ClothingPart", true)
		local hand = self:_joint(key .. "Hand", arm, Vector3.new(0.94, 1.62, 1), skin,
			CFrame.new(0, -0.68, 0), CFrame.new(0, 0.7, 0))
		hand:SetAttribute("SkinPart", true)
		local thigh = self:_joint(key .. "Thigh", body, Vector3.new(1.13, 1.47, 1.18), Color3.fromRGB(68, 87, 97),
			CFrame.new(side * 0.75, -1.33, 0), CFrame.new(0, 0.65, 0))
		local shin = self:_joint(key .. "Shin", thigh, Vector3.new(1.03, 1.45, 1.12), Color3.fromRGB(68, 87, 97),
			CFrame.new(0, -0.65, 0), CFrame.new(0, 0.65, 0))
		self:_part(key .. "Shoe", Vector3.new(1.23, 0.63, 1.75), Color3.fromRGB(236, 226, 202), shin, CFrame.new(0, -0.64, 0.28))
	end
	for _, part in customer:GetDescendants() do
		if part:IsA("BasePart") and not part:GetAttribute("CustomerVisual") then
			part:SetAttribute("CustomerRenderProxy", true)
			part.Transparency = 1
		elseif part:IsA("SurfaceGui") and part.Name == "Face" then
			part:SetAttribute("CustomerProxyFace", true)
			part.Enabled = false
		end
	end
	customer:SetAttribute("ArticulatedVisual", true)
	self:setIdentity({ skin = skin, shirt = shirt, name = "Mia" })
	local elapsed = 0
	self.connection = RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < CustomerRig.UPDATE_INTERVAL then return end
		elapsed = 0
		self:step(now())
	end)
	self:step(now())
	return self
end

function CustomerRig:setIdentity(identity)
	for _, part in self.model:GetDescendants() do
		if part:IsA("BasePart") then
			if part:GetAttribute("SkinPart") then part.Color = identity.skin
			elseif part:GetAttribute("ClothingPart") then part.Color = identity.shirt end
		end
	end
	for _, item in self.accessoryParts or {} do item:Destroy() end
	self.accessoryParts = {}
	local style = ACCESSORIES[((#identity.name + string.byte(identity.name, 1)) % #ACCESSORIES) + 1]
	self.model:SetAttribute("AccessoryStyle", style)
	local function add(name, size, color, offset, shape)
		local part = self:_part(name, size, color, self.head, offset, shape)
		if not self.visible then part.Transparency = 1 end
		table.insert(self.accessoryParts, part)
	end
	if style == "bow" then
		for _, side in { -1, 1 } do add("BowRibbon", Vector3.new(0.83, 0.62, 0.44), Color3.fromRGB(187, 53, 49), CFrame.new(-0.92 + side * 0.31, 1.69, 0.43)) end
		add("BowKnot", Vector3.new(0.35, 0.38, 0.5), Color3.fromRGB(231, 172, 73), CFrame.new(-0.92, 1.69, 0.51))
	elseif style == "cap" then
		add("CapCrown", Vector3.new(3.24, 1.12, 2.96), Color3.fromRGB(65, 112, 78), CFrame.new(0, 1.31, 0))
		add("CapBrim", Vector3.new(2.35, 0.15, 1.27), Color3.fromRGB(58, 96, 70), CFrame.new(0, 1.01, 1.17), Enum.PartType.Block)
	else
		add("Beanie", Vector3.new(3.26, 1.44, 3.02), Color3.fromRGB(215, 157, 70), CFrame.new(0, 1.36, -0.08))
		add("BeaniePompom", Vector3.new(0.73, 0.73, 0.73), Color3.fromRGB(244, 228, 190), CFrame.new(0, 2.11, -0.08))
	end
end

function CustomerRig:setState(state)
	if self.state ~= state then self.state, self.stateAt = state, now() end
	-- Lifecycle movement wins over a prior shot's transient expression.
	if WALKING[state] or state == "Despawn" then self.reaction = nil end
end

function CustomerRig:setExpression(text)
	if not self.mouth.Parent then return end
	local eating = string.find(text, "  o", 1, true) ~= nil
	self.mouth.Size = eating and Vector3.new(0.28, 0.31, 0.1) or Vector3.new(0.59, 0.18, 0.1)
end

function CustomerRig:setVisible(visible, duration)
	self.visible = visible
	for _, tween in self.fades do tween:Cancel() end
	self.fades = {}
	for _, part in self.model:GetDescendants() do
		if part:IsA("BasePart") then
			local alpha = visible and (part:GetAttribute("VisualTransparency") or 0) or 1
			if duration and duration > 0 then
				local tween = TweenService:Create(part, TweenInfo.new(duration), { Transparency = alpha })
				table.insert(self.fades, tween)
				tween:Play()
			else part.Transparency = alpha end
		end
	end
end

function CustomerRig:react(reaction, token)
	if WALKING[self.state] or self.state == "Despawn" then return end
	self.reaction = { name = (reaction == "success" or reaction == "crowd") and "Cheer" or "Startled", token = token, untilTime = now() + 1.25 }
end

function CustomerRig:clearReaction()
	self.reaction = nil
	self:step(now())
end

function CustomerRig:step(time)
	if self.destroyed then return end
	if not self.customer.Parent or not self.anchor.Parent or not self.model.Parent or not self.root.Parent then self:destroy(); return end
	local moving = WALKING[self.state] == true
	local stateAge = math.max(0, time - self.stateAt)
	local pose = moving and (self.state == "Leaving" and "Leave" or "Walk")
		or (self.state == "Eating" and "Eat" or (stateAge < 0.45 and "Sit" or (stateAge > 9 and "Wait" or "Idle")))
	if self.state == "HappyReaction" then pose = "Cheer" end
	if self.state == "HitReaction" then pose = "Startled" end
	if self.reaction then
		if time <= self.reaction.untilTime and self.customer:GetAttribute("ReactionToken") == self.reaction.token and not moving then pose = self.reaction.name
		else self.reaction = nil end
	end
	self.model:SetAttribute("VisualPose", pose)
	local position = self.anchor.CFrame.Position
	local delta = self.lastPosition and position - self.lastPosition or Vector3.zero
	local flat = Vector3.new(delta.X, 0, delta.Z)
	if moving and flat.Magnitude > 0.015 then self.heading = CFrame.lookAt(Vector3.zero, flat.Unit) * CFrame.Angles(0, math.pi, 0) end
	if not moving then self.heading = CFrame.new() end
	local sitBlend = pose == "Sit" and math.clamp(stateAge / 0.45, 0, 1) or 1
	local walkingOffset = moving and -3.4 or -3.4 * (1 - sitBlend)
	self.root.CFrame = self.anchor.CFrame * (self.heading or CFrame.new()) * CFrame.new(0, walkingOffset, 0)
	self.lastPosition = position
	local wave = math.sin(time * (moving and 9 or 2.2))
	for name, data in self.joints do
		local pitch, yaw, roll, lift = 0, 0, 0, 0
		local side = string.find(name, "Left", 1, true) and -1 or 1
		if name == "Body" then lift = moving and math.abs(wave) * 0.09 or wave * 0.035
		elseif name == "Head" then yaw = pose == "Wait" and math.sin(time * 0.8) * 0.14 or wave * 0.025
		elseif string.find(name, "Thigh", 1, true) then pitch = moving and wave * side * 0.4 or -1.22 * sitBlend
		elseif string.find(name, "Shin", 1, true) then pitch = moving and math.max(0, -wave * side) * 0.52 or 1.4 * sitBlend
		elseif string.find(name, "Arm", 1, true) then
			pitch = moving and -wave * side * 0.35 or -0.12
			roll = side * 0.05
			if pose == "Cheer" then roll = side * (2.1 + wave * 0.12)
			elseif pose == "Startled" then pitch, roll = -0.65, side * 0.76
			elseif pose == "Eat" then pitch = -0.9 + wave * 0.08
			elseif pose == "Wait" then pitch = -0.32
			elseif pose == "Leave" and side < 0 then roll = -1.55 + wave * 0.1 end
		elseif string.find(name, "Hand", 1, true) then pitch = pose == "Eat" and -1.15 or (pose == "Cheer" and -0.35 or -0.08) end
		data.motor.C0 = data.base * CFrame.new(0, lift, 0) * CFrame.Angles(pitch, yaw, roll)
	end
end

function CustomerRig:destroy()
	if self.destroyed then return end
	self.destroyed = true
	if activeByTable[self.tableId] == self then activeByTable[self.tableId] = nil end
	if self.connection then self.connection:Disconnect() end
	for _, tween in self.fades do tween:Cancel() end
	self.reaction = nil
	if self.model.Parent then self.model:Destroy() end
end

return CustomerRig
