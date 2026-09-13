-- The single visibility policy for mounted modes and overlapping upgrades.
local UIPresentation = {}

function UIPresentation.select(state, shopOpen: boolean, onboardingCompleted: boolean)
	local mounted = state.mode == "launcher"
	local mode = state.launcherMode or "none"
	local status = state.recordRun and state.recordRun.status or "idle"
	local picker = mounted and mode == "select"
	local record = mounted and mode == "recordRun"
	local aim = mounted and (mode == "freePlay" or (record and (status == "countdown" or status == "running")))
	return {
		mounted = mounted,
		picker = picker,
		shop = shopOpen and not picker,
		upgrades = not picker,
		controls = aim and not shopOpen,
		exit = mounted,
		walking = not mounted,
		round = mounted and mode == "freePlay" and not shopOpen,
		stats = not picker and not record and not shopOpen,
		recordHud = record and not shopOpen and (status == "countdown" or status == "running"),
		results = record and (status == "saving" or status == "finished") and not shopOpen,
		continue = record and status == "finished" and not shopOpen,
		changeMode = mounted and mode == "freePlay" and not shopOpen,
	}
end

return UIPresentation
