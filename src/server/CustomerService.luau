local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local CustomerService = {}

local customersByTable = {}

local function tweenToReset(part: BasePart, duration: number)
	local reset = part:GetAttribute("ResetCFrame")
	if typeof(reset) == "CFrame" then
		TweenService:Create(part, TweenInfo.new(duration, Enum.EasingStyle.Quad), { CFrame = reset }):Play()
	end
end

local function idleLoop(customer: Model, tableId: number)
	task.spawn(function()
		local beat = 0
		while customer.Parent do
			beat += 1
			task.wait(2.4 + (tableId % 3) * 0.55 + (beat % 2) * 0.4)
			if not customer.Parent or (customer:GetAttribute("ReactingUntil") or 0) > Workspace:GetServerTimeNow() then
				continue
			end
			local head = customer:FindFirstChild("Head")
			local arm = customer:FindFirstChild(beat % 2 == 0 and "LeftArm" or "RightArm")
			if head and head:IsA("BasePart") then
				local reset = head:GetAttribute("ResetCFrame")
				if typeof(reset) == "CFrame" then
					local yaw = math.rad((tableId % 2 == 0 and -1 or 1) * (7 + tableId))
					TweenService:Create(head, TweenInfo.new(0.35, Enum.EasingStyle.Sine), { CFrame = reset * CFrame.Angles(0, yaw, 0) }):Play()
				end
			end
			if arm and arm:IsA("BasePart") then
				local reset = arm:GetAttribute("ResetCFrame")
				if typeof(reset) == "CFrame" then
					local side = arm.Name == "LeftArm" and -1 or 1
					TweenService:Create(arm, TweenInfo.new(0.35, Enum.EasingStyle.Sine), { CFrame = reset * CFrame.Angles(0, 0, math.rad(side * 12)) }):Play()
				end
			end
			task.wait(0.65)
			if (customer:GetAttribute("ReactingUntil") or 0) <= Workspace:GetServerTimeNow() then
				if head and head:IsA("BasePart") then
					tweenToReset(head, 0.3)
				end
				if arm and arm:IsA("BasePart") then
					tweenToReset(arm, 0.3)
				end
			end
		end
	end)
end

function CustomerService.start(world: Instance)
	table.clear(customersByTable)
	for _, descendant in world:GetDescendants() do
		if descendant:IsA("Model") and descendant.Name == "Customer" then
			local tableId = descendant:GetAttribute("TableId")
			if typeof(tableId) == "number" then
				customersByTable[tableId] = descendant
				idleLoop(descendant, tableId)
			end
		end
	end
end

function CustomerService.markReacting(customer: Model, duration: number)
	customer:SetAttribute("ReactingUntil", Workspace:GetServerTimeNow() + duration)
end

function CustomerService.served(tableId: number)
	local customer = customersByTable[tableId]
	if not customer or not customer.Parent then
		return
	end
	CustomerService.markReacting(customer, 2.5)
	task.delay(1.35, function()
		if not customer.Parent then
			return
		end
		local side = tableId % 2 == 0 and 1 or -1
		for _, descendant in customer:GetDescendants() do
			if descendant:IsA("BasePart") then
				local reset = descendant:GetAttribute("ResetCFrame")
				if typeof(reset) == "CFrame" then
					TweenService:Create(descendant, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
						CFrame = reset + Vector3.new(side * 4.5, -0.8, 0),
					}):Play()
				end
			end
		end
		task.delay(0.38, function()
			if not customer.Parent then
				return
			end
			for _, descendant in customer:GetDescendants() do
				if descendant:IsA("BasePart") then
					tweenToReset(descendant, 0.45)
				end
			end
		end)
	end)
end

return CustomerService
