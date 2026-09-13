-- Reaction poses belong to the current launcher lease. CustomerService alone
-- owns lifecycle, seat selection, availability and arrival/departure movement.
local TweenService = game:GetService("TweenService")

local CustomerFeedback = {}
CustomerFeedback.__index = CustomerFeedback

local SEATED = { SeatedWaiting = true, Served = true, HappyReaction = true, Eating = true, HitReaction = true }

local function isSeated(customer): boolean
	return SEATED[customer:GetAttribute("CustomerState")] == true
end

local function restorePose(customer)
	if not customer.Parent or not isSeated(customer) then return end
	for _, part in customer:GetDescendants() do
		if part:IsA("BasePart") then
			local reset = part:GetAttribute("ResetCFrame")
			if typeof(reset) == "CFrame" then part.CFrame = reset end
		end
	end
end

function CustomerFeedback.new(dependencies)
	return setmetatable({ dependencies = dependencies, reactions = {} }, CustomerFeedback)
end

function CustomerFeedback:text(customer, text)
	local marker = customer:FindFirstChild("WaitingMarker", true)
	local label = marker and marker:FindFirstChild("Label", true)
	if label and label:IsA("TextLabel") then
		if string.find(text, "NOM") then label.Text = "YUM"
		elseif string.find(text, "HEY") then label.Text = "?"
		elseif string.find(text, "WHOA") or string.find(text, "DUCK") then label.Text = "!"
		elseif string.find(text, "YES") or string.find(text, "WOOHOO") or string.find(text, "BEST") then label.Text = "★"
		else label.Text = "🍕" end
	end
end

function CustomerFeedback:_stop(customer, restore)
	local record = self.reactions[customer]
	if not record then return end
	self.reactions[customer] = nil
	for _, tween in record.tweens do tween:Cancel() end
	if self.dependencies.customerService.clearFeedback then self.dependencies.customerService.clearFeedback(customer) end
	if customer.Parent then
		customer:SetAttribute("ReactionToken", (customer:GetAttribute("ReactionToken") or 0) + 1)
		if restore then restorePose(customer) end
	end
end

function CustomerFeedback:clear(player): boolean
	-- Walking cleanup must never cancel another operator's feedback/hitboxes.
	if not player or self.dependencies.getOwner() ~= player then return false end
	for customer in self.reactions do self:_stop(customer, true) end
	return true
end

function CustomerFeedback:react(tableId, reaction): boolean
	local owner = self.dependencies.getOwner()
	local tableModel = self.dependencies.worldTable(tableId)
	local customer = tableModel and tableModel:FindFirstChild("Customer")
	if not owner or not customer or not customer:IsA("Model") or not isSeated(customer) then return false end
	self:_stop(customer, true)
	local token = (customer:GetAttribute("ReactionToken") or 0) + 1
	customer:SetAttribute("ReactionToken", token)
	self.dependencies.customerService.markReacting(customer, 1.7)
	if self.dependencies.customerService.feedbackReaction then self.dependencies.customerService.feedbackReaction(customer, reaction, token) end
	local record = { owner = owner, token = token, tweens = {} }
	self.reactions[customer] = record
	local function tween(part, info, target)
		local effect = TweenService:Create(part, info, target)
		table.insert(record.tweens, effect)
		effect:Play()
	end
	local head = customer:FindFirstChild("Head")
	local torso = customer:FindFirstChild("Torso")
	local leftArm = customer:FindFirstChild("LeftArm")
	local rightArm = customer:FindFirstChild("RightArm")
	local faceGui = customer:FindFirstChild("Face", true)
	local faceLabel = faceGui and faceGui:FindFirstChild("Label")
	local function face(text)
		if faceLabel and faceLabel:IsA("TextLabel") then faceLabel.Text = text end
	end

	if reaction == "success" then
		self:text(customer, "YES! PIZZA!\nBEST DAY EVER!")
		face("*  *\n\\___/")
		if head and head:IsA("BasePart") then
			tween(head, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { CFrame = head.CFrame + Vector3.new(0, 1.8, 0) })
			self.dependencies.coinBurst(head.Position + Vector3.new(0, 4, 0), self.dependencies.tableDefinition(tableId).color)
		end
		for _, arm in { leftArm, rightArm } do
			if arm and arm:IsA("BasePart") then
				local side = arm.Name == "LeftArm" and -1 or 1
				tween(arm, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
					CFrame = arm.CFrame * CFrame.new(side * 0.6, 2, 0) * CFrame.Angles(0, 0, math.rad(side * -115)),
				})
			end
		end
	elseif reaction == "crowd" then
		self:text(customer, "PIZZA STREAK!\nWOOHOO!")
		face("^  ^\n\\___/")
		if head and head:IsA("BasePart") then
			tween(head, TweenInfo.new(0.3, Enum.EasingStyle.Back), { CFrame = head.CFrame + Vector3.new(0, 1.25, 0) })
		end
		if torso and torso:IsA("BasePart") then
			tween(torso, TweenInfo.new(0.3, Enum.EasingStyle.Back), { CFrame = torso.CFrame + Vector3.new(0, 0.55, 0) })
		end
		for _, arm in { leftArm, rightArm } do
			if arm and arm:IsA("BasePart") then
				local side = arm.Name == "LeftArm" and -1 or 1
				tween(arm, TweenInfo.new(0.32, Enum.EasingStyle.Back), {
					CFrame = arm.CFrame * CFrame.new(side * 0.45, 1.6, 0) * CFrame.Angles(0, 0, math.rad(side * -105)),
				})
			end
		end
	elseif reaction == "wrong" then
		self:text(customer, "HEY! NOT MY ORDER!\n...STILL SMELLS GOOD")
		face("O  O\n  o")
		for _, bodyPart in { head, torso, leftArm, rightArm } do
			if bodyPart and bodyPart:IsA("BasePart") then
				tween(bodyPart, TweenInfo.new(0.22, Enum.EasingStyle.Back), { CFrame = bodyPart.CFrame + Vector3.new(3, 0.5, 0) })
			end
		end
	else
		self:text(customer, "WHOA! FLYING PIZZA!\nDUCK!")
		face(">  <\n  O")
		for _, bodyPart in { head, torso } do
			if bodyPart and bodyPart:IsA("BasePart") then
				tween(bodyPart, TweenInfo.new(0.18), { CFrame = bodyPart.CFrame + Vector3.new(0, -2, 0) })
			end
		end
	end
	task.delay(1.25, function()
		if self.reactions[customer] ~= record or not customer.Parent
			or customer:GetAttribute("ReactionToken") ~= token or self.dependencies.getOwner() ~= owner then return end
		-- Lifecycle movement may have started since the reaction. Its pose wins.
		if not isSeated(customer) then self:_stop(customer, false); return end
		for _, part in customer:GetDescendants() do
			if part:IsA("BasePart") then
				local reset = part:GetAttribute("ResetCFrame")
				if typeof(reset) == "CFrame" then tween(part, TweenInfo.new(0.28, Enum.EasingStyle.Quad), { CFrame = reset }) end
			end
		end
		face("^  ^\n\\___/")
		self:text(customer, "PIZZA, PLEASE!")
	end)
	return true
end

return CustomerFeedback
