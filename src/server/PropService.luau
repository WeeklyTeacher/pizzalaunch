local Workspace = game:GetService("Workspace")

local PropService = {}

local registered = {}
local activeCount = 0

local function register(prop: BasePart)
	if registered[prop] then return end
	local reset = prop:GetAttribute("ResetCFrame")
	if typeof(reset) ~= "CFrame" then
		reset = prop.CFrame
		prop:SetAttribute("ResetCFrame", reset)
	end
	registered[prop] = {
		canCollide = prop.CanCollide,
		canTouch = prop.CanTouch,
		transparency = prop.Transparency,
	}
	prop:SetAttribute("PropState", "Ready")
end

local function resetProp(prop: BasePart)
	local data = registered[prop]
	if not data or not prop.Parent then return end
	if prop:GetAttribute("PropState") == "Knocked" then
		activeCount = math.max(0, activeCount - 1)
	end
	prop.Anchored = true
	prop.AssemblyLinearVelocity = Vector3.zero
	prop.AssemblyAngularVelocity = Vector3.zero
	prop.CFrame = prop:GetAttribute("ResetCFrame")
	prop.CanCollide = data.canCollide
	prop.CanTouch = data.canTouch
	prop.Transparency = data.transparency
	prop:SetAttribute("RecentlyHit", false)
	prop:SetAttribute("PropState", "Ready")
end

function PropService.start(world: Instance)
	table.clear(registered)
	activeCount = 0
	for _, descendant in world:GetDescendants() do
		if descendant:IsA("BasePart") and descendant:GetAttribute("ReactiveProp") then
			register(descendant)
		end
	end
end

function PropService.knock(prop: BasePart, pizzaVelocity: Vector3): boolean
	if not prop:GetAttribute("ReactiveProp") or prop:GetAttribute("RecentlyHit") or activeCount >= 8 then
		return false
	end
	register(prop)
	local reset = prop:GetAttribute("ResetCFrame")
	if typeof(reset) ~= "CFrame" then return false end

	activeCount += 1
	prop:SetAttribute("RecentlyHit", true)
	prop:SetAttribute("PropState", "Knocked")
	prop.Anchored = false
	prop.CanCollide = true
	prop:SetNetworkOwner(nil)
	local direction = pizzaVelocity.Magnitude > 0.1 and pizzaVelocity.Unit or Vector3.new(0, 0.5, -1).Unit
	local sizeScale = math.clamp(prop.Size.Magnitude / 5, 0.55, 1.4)
	prop:ApplyImpulse((direction * (48 / sizeScale) + Vector3.new(0, 34 / sizeScale, 0)) * prop.AssemblyMass)
	prop:ApplyAngularImpulse(Vector3.new(math.random(-22, 22), math.random(-22, 22), math.random(-22, 22)) * prop.AssemblyMass / sizeScale)

	local token = Workspace:GetServerTimeNow()
	prop:SetAttribute("ResetToken", token)
	local delaySeconds = math.clamp(3.4 + sizeScale, 3.8, 5)
	task.delay(delaySeconds, function()
		if prop.Parent and prop:GetAttribute("ResetToken") == token then
			resetProp(prop)
		end
	end)
	return true
end

function PropService.resetAll()
	for prop in registered do
		if prop.Parent then
			prop:SetAttribute("ResetToken", Workspace:GetServerTimeNow())
			resetProp(prop)
		end
	end
	activeCount = 0
	local mess = Workspace:FindFirstChild("PizzaMess")
	if mess then mess:ClearAllChildren() end
end

function PropService.getActiveCount(): number
	return activeCount
end

return PropService
