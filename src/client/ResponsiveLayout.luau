-- Layout uses the safe content area; input choice changes controls, not font scale.
local ResponsiveLayout = {}

function ResponsiveLayout.inputKind(preferred, touchAvailable, keyboardAvailable)
	local name = preferred and preferred.Name
	if name == "Touch" then return "touch" end
	if name == "Gamepad" then return "gamepad" end
	if name == "KeyboardAndMouse" then return "keyboard" end
	return touchAvailable and not keyboardAvailable and "touch" or "keyboard"
end

function ResponsiveLayout.compute(width: number, height: number, inputKind: string)
	width, height = math.max(320, width), math.max(240, height)
	local compact = height < 540 or width < 800
	local margin = compact and 10 or 18
	local navWidth = compact and 108 or 144
	local statsWidth = compact and 142 or 202
	local topWidth = math.min(compact and 340 or 400, width - 2 * (math.max(navWidth, statsWidth) + margin + 8))
	local pickerWidth = math.min(640, width - margin * 2)
	local pickerHeight = math.min(compact and 244 or 280, height - margin * 2)
	return {
		width = width, height = height, compact = compact, inputKind = inputKind, margin = margin,
		navWidth = navWidth, navHeight = 44, statsWidth = statsWidth, topWidth = math.max(260, topWidth),
		pickerWidth = pickerWidth, pickerHeight = pickerHeight,
		controlsWidth = compact and (inputKind == "touch" and 286 or 330) or 430,
		controlsHeight = compact and 98 or 112,
		fireWidth = compact and 108 or 138, fireHeight = compact and 76 or 88,
		shopWidth = math.min(460, width - margin * 2), shopHeight = math.min(560, height - 64 - margin),
		resultWidth = math.min(520, width - margin * 2), resultHeight = math.min(228, height - margin * 2),
		feedbackWidth = math.min(430, width - margin * 2),
		activityWidth = math.min(420, width - margin * 2), activityY = compact and 64 or 82,
		bodyText = compact and 16 or 18, secondaryText = 14,
		exitText = inputKind == "touch" and "EXIT" or (inputKind == "gamepad" and "EXIT  [B]" or "EXIT  [Q]"),
		helpText = inputKind == "touch" and "HOLD + RELEASE" or (inputKind == "gamepad" and "HOLD RT + RELEASE" or "HOLD SPACE + RELEASE"),
	}
end

return ResponsiveLayout
