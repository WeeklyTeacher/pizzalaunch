-- Bounded server feedback. Gameplay origins, colliders and rewards are owned elsewhere.
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local function playSound(parent: Instance, soundId: string, volume: number, playbackSpeed: number?)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume
	sound.PlaybackSpeed = playbackSpeed or 1
	sound.RollOffMaxDistance = 140
	sound.RollOffMinDistance = 10
	sound.Parent = parent
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	task.delay(5, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
end

local function coinBurst(position: Vector3, color: Color3)
	local folder = Instance.new("Folder")
	folder.Name = "CoinBurst"
	folder.Parent = Workspace
	for index = 1, 9 do
		local coin = Instance.new("Part")
		coin.Name = "Coin"
		coin.Shape = Enum.PartType.Cylinder
		coin.Size = Vector3.new(0.25, 1.3, 1.3)
		coin.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2)
		coin.Anchored = true
		coin.CanCollide = false
		coin.CanTouch = false
		coin.CanQuery = false
		coin.Material = Enum.Material.Neon
		coin.Color = index % 3 == 0 and color or Color3.fromRGB(255, 211, 55)
		coin.Parent = folder
		local angle = index / 9 * math.pi * 2
		local target = position + Vector3.new(math.cos(angle) * 7, 5 + (index % 3) * 2, math.sin(angle) * 4)
		TweenService:Create(coin, TweenInfo.new(0.65, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = target,
			Transparency = 1,
			Orientation = Vector3.new(0, index * 70, 90),
		}):Play()
	end
	task.delay(0.8, function()
		folder:Destroy()
	end)
end

local function confettiBurst(position: Vector3)
	local folder = Instance.new("Folder")
	folder.Name = "BirthdayConfetti"
	folder.Parent = Workspace
	local colors = {
		Color3.fromRGB(255, 85, 96), Color3.fromRGB(255, 211, 55),
		Color3.fromRGB(76, 200, 124), Color3.fromRGB(82, 180, 235),
	}
	for index = 1, 18 do
		local piece = Instance.new("Part")
		piece.Name = "Confetti"
		piece.Size = Vector3.new(0.22, 0.65, 0.35)
		piece.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
		piece.Anchored = true
		piece.CanCollide = false
		piece.CanTouch = false
		piece.CanQuery = false
		piece.Material = Enum.Material.Neon
		piece.Color = colors[(index - 1) % #colors + 1]
		piece.Parent = folder
		local angle = index / 18 * math.pi * 2
		local distance = 4 + index % 4
		TweenService:Create(piece, TweenInfo.new(0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = position + Vector3.new(math.cos(angle) * distance, 6 + index % 5, math.sin(angle) * distance),
			Orientation = Vector3.new(index * 43, index * 71, index * 29),
			Transparency = 1,
		}):Play()
	end
	task.delay(1, function()
		folder:Destroy()
	end)
end

local function surfaceNormal(hit: BasePart, point: Vector3): Vector3
	local localPoint = hit.CFrame:PointToObjectSpace(point)
	local half = hit.Size * 0.5
	local normalized = Vector3.new(
		math.abs(localPoint.X) / math.max(half.X, 0.01),
		math.abs(localPoint.Y) / math.max(half.Y, 0.01),
		math.abs(localPoint.Z) / math.max(half.Z, 0.01)
	)
	local localNormal
	if normalized.X >= normalized.Y and normalized.X >= normalized.Z then
		localNormal = Vector3.new(math.sign(localPoint.X), 0, 0)
	elseif normalized.Y >= normalized.Z then
		localNormal = Vector3.new(0, math.sign(localPoint.Y), 0)
	else
		localNormal = Vector3.new(0, 0, math.sign(localPoint.Z))
	end
	return hit.CFrame:VectorToWorldSpace(localNormal)
end

local function splatFolder(): Folder
	local folder = Workspace:FindFirstChild("PizzaMess")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "PizzaMess"
		folder.Parent = Workspace
	end
	while #folder:GetChildren() >= 24 do
		folder:GetChildren()[1]:Destroy()
	end
	return folder :: Folder
end

local function createSplat(hit: BasePart, position: Vector3, color: Color3)
	local normal = surfaceNormal(hit, position)
	local splat = Instance.new("Part")
	splat.Name = "CheesySplat"
	splat.Shape = Enum.PartType.Cylinder
	splat.Size = Vector3.new(0.12, math.random(40, 65) / 10, math.random(40, 65) / 10)
	splat.CFrame = CFrame.lookAt(position + normal * 0.1, position + normal) * CFrame.Angles(0, math.pi / 2, 0)
	splat.Anchored = true
	splat.CanCollide = false
	splat.CanTouch = false
	splat.CanQuery = false
	splat.Material = Enum.Material.SmoothPlastic
	splat.Color = color
	splat.Transparency = 0.08
	splat.Parent = splatFolder()

	for index = 1, 3 do
		local blob = Instance.new("Part")
		blob.Name = "SauceBlob"
		blob.Shape = Enum.PartType.Ball
		local scale = math.random(7, 14) / 10
		blob.Size = Vector3.new(scale, scale, scale)
		blob.Position = position + normal * 0.35 + Vector3.new(math.random(-16, 16) / 10, math.random(-9, 14) / 10, math.random(-16, 16) / 10)
		blob.Anchored = true
		blob.CanCollide = false
		blob.CanTouch = false
		blob.CanQuery = false
		blob.Color = index == 1 and Color3.fromRGB(191, 48, 43) or color
		blob.Parent = splat
	end

	task.delay(7, function()
		if splat.Parent then
			for _, descendant in splat:GetDescendants() do
				if descendant:IsA("BasePart") then
					TweenService:Create(descendant, TweenInfo.new(1), { Transparency = 1 }):Play()
				end
			end
			TweenService:Create(splat, TweenInfo.new(1), { Transparency = 1 }):Play()
			task.delay(1.1, function()
				if splat.Parent then
					splat:Destroy()
				end
			end)
		end
	end)
end

local function impactRing(position: Vector3, color: Color3)
	local ring = Instance.new("Part")
	ring.Name = "PizzaImpact"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.18, 2, 2)
	ring.CFrame = CFrame.new(position + Vector3.new(0, 0.25, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanTouch = false
	ring.CanQuery = false
	ring.Material = Enum.Material.Neon
	ring.Color = color
	ring.Transparency = 0.1
	ring.Parent = Workspace
	TweenService:Create(ring, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.18, 15, 15),
		Transparency = 1,
	}):Play()
	task.delay(0.65, function()
		ring:Destroy()
	end)
end

return {
	playSound = playSound,
	coinBurst = coinBurst,
	confettiBurst = confettiBurst,
	createSplat = createSplat,
	impactRing = impactRing,
}
