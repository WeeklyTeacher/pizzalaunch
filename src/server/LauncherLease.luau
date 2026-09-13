-- The station owns one character snapshot. Old characters can never release a new lease.
local LauncherLease = {}
LauncherLease.__index = LauncherLease

function LauncherLease.new()
	return setmetatable({ owner = nil, character = nil, generation = 0 }, LauncherLease)
end

function LauncherLease:acquire(player, character, mountCFrame): boolean
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if self.owner or not character or not character.Parent or not player.Parent or player.Character ~= character
		or not humanoid or not humanoid.Parent or humanoid.Health <= 0
		or not root or not root.Parent or not root:IsA("BasePart") or root.Anchored then
		return false
	end
	self.generation += 1
	self.owner, self.character = player, character
	self.humanoid, self.root, self.mountCFrame = humanoid, root, mountCFrame
	self.saved = {
		walkSpeed = humanoid.WalkSpeed, jumpPower = humanoid.JumpPower,
		jumpHeight = humanoid.JumpHeight, autoRotate = humanoid.AutoRotate, anchored = root.Anchored,
	}
	root.CFrame, root.Anchored = mountCFrame, true
	humanoid.WalkSpeed, humanoid.JumpPower, humanoid.JumpHeight, humanoid.AutoRotate = 0, 0, 0, false
	return true
end

function LauncherLease:isValid(player): boolean
	local character, root, humanoid = self.character, self.root, self.humanoid
	return self.owner == player and player.Parent ~= nil and player.Character == character
		and character ~= nil and character.Parent ~= nil
		and character:FindFirstChild("HumanoidRootPart") == root
		and character:FindFirstChildOfClass("Humanoid") == humanoid
		and root.Parent ~= nil and humanoid.Parent ~= nil and humanoid.Health > 0
		and root.Anchored and (root.Position - self.mountCFrame.Position).Magnitude <= 4
end

function LauncherLease:release(player, exitCFrame, expectedCharacter): boolean
	if self.owner ~= player or (expectedCharacter and expectedCharacter ~= self.character) then return false end
	local root, humanoid, saved = self.root, self.humanoid, self.saved
	self.owner, self.character, self.root, self.humanoid, self.saved = nil, nil, nil, nil, nil
	self.generation += 1
	if root and root.Parent then
		root.Anchored = saved.anchored
		root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
		if exitCFrame then root.CFrame = exitCFrame end
	end
	if humanoid and humanoid.Parent then
		humanoid.WalkSpeed, humanoid.JumpPower, humanoid.JumpHeight = saved.walkSpeed, saved.jumpPower, saved.jumpHeight
		humanoid.AutoRotate = saved.autoRotate
	end
	return true
end

return LauncherLease
