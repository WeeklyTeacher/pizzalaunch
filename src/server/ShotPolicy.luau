-- Pure authority rules: inventory does not own the shared launcher presentation.
local ShotPolicy = {}

function ShotPolicy.isFinite(value): boolean
	return typeof(value) == "number" and value == value and value > -math.huge and value < math.huge
end

function ShotPolicy.canPresent(player, owner, state): boolean
	return player == owner and state ~= nil and state.mode == "launcher" and state.launcherMode ~= "recordRun"
end

function ShotPolicy.reloadTime(config, state, recordSession): number
	return recordSession and config.RELOAD_TIME or config.RELOAD_TIME * (1 - state.upgrades.reload * 0.12)
end

function ShotPolicy.validate(config, state, ownsLease, canLaunch, recordSession, direction, charge, requestId, epoch, now)
	if not state or not ownsLease or state.mode ~= "launcher" then return nil, "lease" end
	if epoch ~= state.cleanupEpoch then return nil, "staleSession" end
	if not ShotPolicy.isFinite(requestId) or requestId < 1 or requestId > 2147483647 or requestId % 1 ~= 0 then return nil, "request" end
	if requestId <= (state.lastRequestId or 0) then return nil, "duplicate" end
	if state.shotActive then return nil, "shotActive" end
	if state.launcherMode ~= "freePlay" and state.launcherMode ~= "recordRun" then return nil, "chooseMode" end
	if not canLaunch or (state.launcherMode == "recordRun" and not recordSession) then return nil, "runPhase" end
	if typeof(direction) ~= "Vector3" or not ShotPolicy.isFinite(charge)
		or not ShotPolicy.isFinite(direction.X) or not ShotPolicy.isFinite(direction.Y) or not ShotPolicy.isFinite(direction.Z)
		or not ShotPolicy.isFinite(direction.Magnitude) or direction.Magnitude < 0.9 then return nil, "aim" end
	direction = direction.Unit
	local pitch = math.asin(math.clamp(direction.Y, -1, 1))
	local yaw = math.atan2(direction.X, -direction.Z)
	if pitch < config.MIN_PITCH - 0.02 or pitch > config.MAX_PITCH + 0.02 or math.abs(yaw) > config.MAX_YAW + 0.02 or direction.Z > -0.3 then return nil, "aim" end
	local reloadTime = ShotPolicy.reloadTime(config, state, recordSession)
	if now - state.lastLaunch < reloadTime then return nil, "reload" end
	return { direction = direction, charge = math.clamp(charge, 0, 1), reloadTime = reloadTime }, nil
end

return ShotPolicy
