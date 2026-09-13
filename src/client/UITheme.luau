local COLORS = {
	red = Color3.fromRGB(183, 58, 47),
	darkRed = Color3.fromRGB(89, 42, 33),
	cream = Color3.fromRGB(250, 243, 227),
	ink = Color3.fromRGB(62, 50, 40),
	yellow = Color3.fromRGB(232, 181, 70),
	green = Color3.fromRGB(67, 125, 81),
	orange = Color3.fromRGB(193, 114, 70),
	blue = Color3.fromRGB(92, 133, 142),
	surface = Color3.fromRGB(255, 250, 240),
	muted = Color3.fromRGB(116, 99, 78),
	border = Color3.fromRGB(217, 202, 179),
}

local function addCorner(parent: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

local function addStroke(parent: GuiObject, color: Color3, thickness: number)
	local border = Instance.new("UIStroke")
	border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	border.Color = color
	border.Thickness = thickness
	border.Transparency = 0.05
	border.Parent = parent
end

local function addPadding(parent: GuiObject, amount: number)
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, amount)
	padding.PaddingRight = UDim.new(0, amount)
	padding.PaddingTop = UDim.new(0, amount)
	padding.PaddingBottom = UDim.new(0, amount)
	padding.Parent = parent
end

local function makeLabel(parent: Instance, name: string, displayText: string, size: UDim2, position: UDim2, textSize: number): TextLabel
	local item = Instance.new("TextLabel")
	item.Name = name
	item.Size = size
	item.Position = position
	item.BackgroundTransparency = 1
	item.Text = displayText
	item.TextColor3 = COLORS.ink
	item.TextSize = textSize
	item.Font = Enum.Font.GothamMedium
	item.TextWrapped = true
	item.Parent = parent
	return item
end

local function makeButton(parent: Instance, name: string, displayText: string, size: UDim2, position: UDim2, color: Color3): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = color
	button.Text = displayText
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextSize = 19
	button.TextWrapped = true
	button.Font = Enum.Font.GothamBold
	button.AutoButtonColor = false
	button.Parent = parent
	addCorner(button, 12)
	addStroke(button, COLORS.darkRed, 1.5)
	return button
end


return { colors = COLORS, addCorner = addCorner, addStroke = addStroke, addPadding = addPadding, makeLabel = makeLabel, makeButton = makeButton }
