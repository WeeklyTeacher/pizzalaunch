local Workspace = game:GetService("Workspace")

local PropService = {}

function PropService.knock(prop: BasePart, pizzaVelocity: Vector3): boolean
	if not prop:GetAttribute("ReactiveProp") or prop:GetAttribute("RecentlyHit") then
		return false
	end
	local reset = prop:GetAttribute("ResetCFrame")
	if typeof(reset) ~= "CFrame" then
		return false
	end

	prop:SetAttribute("RecentlyHit", true)
	local resetCanCollide = prop.CanCollide
	prop.Anchored = false
	prop.CanCollide = true
	prop:SetNetworkOwner(nil)
	local direction = pizzaVelocity.Magnitude > 0.1 and pizzaVelocity.Unit or Vector3.new(0, 0.5, -1).Unit
	prop:ApplyImpulse((direction * 55 + Vector3.new(0, 38, 0)) * prop.AssemblyMass)
	prop:ApplyAngularImpulse(Vector3.new(math.random(-20, 20), math.random(-20, 20), math.random(-20, 20)) * prop.AssemblyMass)

	local token = Workspace:GetServerTimeNow()
	prop:SetAttribute("ResetToken", token)
	task.delay(4.5, function()
		if not prop.Parent or prop:GetAttribute("ResetToken") ~= token then
			return
		end
		prop.Anchored = true
		prop.AssemblyLinearVelocity = Vector3.zero
		prop.AssemblyAngularVelocity = Vector3.zero
		prop.CFrame = reset
		prop.CanCollide = resetCanCollide
		prop:SetAttribute("RecentlyHit", false)
	end)
	return true
end

return PropService
