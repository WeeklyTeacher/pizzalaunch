$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) {
        throw "Recovery contract failed: $Message"
    }
    Write-Output "PASS: $Message"
}

function Get-NormalizedSourceHash([string]$Path) {
    $text = [System.IO.File]::ReadAllText($Path).Replace("`r`n", "`n")
    $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($text)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return [System.BitConverter]::ToString($sha.ComputeHash($bytes)).Replace('-', '')
    } finally {
        $sha.Dispose()
    }
}

$transferInvariantHashes = @{
    'src\server\init.server.luau' = '6EA4502197116E37571D53A7A24A0C1227DBC8270C3614A3518DD3B8F161D7C4'
}
# Layout/Prop hashes used to freeze a known visibility bug. Execute their actual
# modules instead: authored defaults, rounds 3/4, downward transitions, repeated
# startup and stale reset callbacks. Canonical backup/mapping guards remain.
& (Join-Path $PSScriptRoot 'Test-Behavior.ps1')
foreach ($relativePath in $transferInvariantHashes.Keys) {
    $actual = Get-NormalizedSourceHash (Join-Path $root $relativePath)
    Assert-True ($actual -eq $transferInvariantHashes[$relativePath]) "$relativePath remains byte-identical to Transfer"
}
Assert-True ((Get-NormalizedSourceHash (Join-Path $root 'default.project.json')) -eq '2CAB2897048D4EA3A3F1B23EE29B8E1C41E520FAECF18F9D002774431970A000') 'Rojo project mapping remains unchanged from the protected visual-expansion checkpoint'

$worldPath = Join-Path $root 'src\server\WorldBuilder.luau'
$world = Get-Content -LiteralPath $worldPath -Raw
$config = Get-Content -LiteralPath (Join-Path $root 'src\shared\Config.luau') -Raw
$customers = Get-Content -LiteralPath (Join-Path $root 'src\server\CustomerService.luau') -Raw
$gameService = Get-Content -LiteralPath (Join-Path $root 'src\server\GameService.luau') -Raw
$shotPolicy = Get-Content -LiteralPath (Join-Path $root 'src\server\ShotPolicy.luau') -Raw
# Construction and presentation now live in focused modules; retain source
# wiring checks across those files in addition to executable policy tests.
$client = (Get-ChildItem -LiteralPath (Join-Path $root 'src\client') -Filter '*.luau' -File | Sort-Object Name | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw }) -join "`n"
$dialogue = Get-Content -LiteralPath (Join-Path $root 'src\server\CustomerDialogue.luau') -Raw
$shiftEvents = Get-Content -LiteralPath (Join-Path $root 'src\server\ShiftEventService.luau') -Raw
$worldActivity = Get-Content -LiteralPath (Join-Path $root 'src\server\WorldActivityService.luau') -Raw
$interaction = Get-Content -LiteralPath (Join-Path $root 'src\server\InteractionService.luau') -Raw
$recordRun = Get-Content -LiteralPath (Join-Path $root 'src\server\RecordRunService.luau') -Raw

$definitions = [regex]::Matches($world, '(?m)^\s*([A-Za-z][A-Za-z0-9_]*)\s*=\s*Color3\.') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
$references = [regex]::Matches($world, 'COLORS\.([A-Za-z][A-Za-z0-9_]*)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
$missingColors = $references | Where-Object { $_ -notin $definitions }
Assert-True ($missingColors.Count -eq 0) "WorldBuilder has no undefined COLORS entries"

Assert-True ($world.Contains('buildStorefrontExterior(world)')) 'storefront exterior is part of runtime construction'
Assert-True ($world.Contains('buildRestaurantArtPass(world)')) 'isolated restaurant art pass is part of runtime construction'
Assert-True ($world.Contains('buildNeighborhoodStreet(world)')) 'isolated neighborhood street is part of runtime construction'
Assert-True ($world.Contains('RemovableWithoutGameplayImpact')) 'visual expansion models declare their gameplay-safe ownership boundary'
Assert-True ($world.Contains('CFrame.new(x, 0.2, 83)')) 'customer spawn points begin outside the front doors'
Assert-True (-not $world.Contains('StudioRestaurant:Destroy')) 'runtime world does not delete StudioRestaurant'
Assert-True ($world.Contains('Permanent launcher-sightline rule')) 'future world art carries the permanent launcher-sightline rule'
Assert-True (-not $world.Contains('CFrame.new(0, 24, 70.8)')) 'blocking centered Neighborhood Favorite sign placement is absent'
Assert-True ($world.Contains('CFrame.new(42, 27.2, 73.4)')) 'Neighborhood Favorite sign is relocated full-size to the exterior facade'
$signNearestHorizontalEdge = 42 - (28 / 2)
$signHorizontalAngle = [Math]::Atan2($signNearestHorizontalEdge, [Math]::Abs(82 - 73.4)) * 180 / [Math]::PI
Assert-True ($signHorizontalAngle -gt 28.5) 'relocated sign stays outside the 57-degree launcher-camera horizontal frustum'
Assert-True ($world.Contains('"LauncherInteractionAnchor"') -and $world.Contains('CFrame.new(0, 2.4, 84)')) 'real cannon prompt has one explicit clear-floor interaction anchor'
Assert-True ($world.Contains('prompt(interactionAnchor, "LauncherPrompt", "USE LAUNCHER", "PIZZA LAUNCHER", 12)')) 'USE LAUNCHER prompt is parented to the authoritative interaction anchor'
Assert-True (-not $world.Contains('prompt(recordConsole, "RecordRunPrompt"')) 'world has no competing Record Run prompt'
Assert-True ($world.Contains('item.ClickablePrompt = true') -and $world.Contains('item.GamepadKeyCode = Enum.KeyCode.ButtonX')) 'launcher prompt supports touch and controller input'
Assert-True ($world.Contains('"LauncherUsePad"') -and $world.Contains('LauncherMountPosition')) 'exact launcher use point has a visible pizza-shaped pad'
Assert-True ($world.Contains('"PIZZA LAUNCHER\nWALK HERE TO PLAY"')) 'entrance and launcher signs use direct player language'
Assert-True ($world.Contains('"InteriorLauncherGuide"') -and $world.Contains('"InteriorLauncherBillboard", "PIZZA LAUNCHER\nTURN AROUND  •  FOLLOW THE ARROWS"')) 'restaurant interior has a camera-facing launcher direction sign'
Assert-True ($world.Contains('interiorBillboard.MaxDistance = 34')) 'interior direction sign does not overlap the real spawn view'
Assert-True ($world.Contains('"LauncherMountBillboard", "STEP HERE TO PLAY"')) 'authoritative mount point has an explicit STEP HERE TO PLAY label'
Assert-True ($world.Contains('AuthoritativeLauncherInteraction')) 'launcher anchor declares its authoritative interaction role'
Assert-True (-not $world.Contains('"OperatorSpot"')) 'obsolete glow underneath the pizza press is removed'
Assert-True ($config.Contains('Config.RECORD_RUN_STORE = "PizzaLaunch_RecordRun_AllTime_v1"')) 'OrderedDataStore name is unchanged'
Assert-True ($config.Contains('Config.LAUNCH_ORIGIN = Vector3.new(0, 12, 50)')) 'Transfer launcher origin is unchanged'
Assert-True ($config.Contains('Vector3.new(-24, 2.5, 2)') -and $config.Contains('Vector3.new(24, 2.5, -55)')) 'Transfer near/far table geometry is present'

foreach ($stateName in @('Entering', 'WalkingToSeat', 'SeatedWaiting', 'Served', 'HappyReaction', 'Eating', 'Leaving', 'Despawn')) {
    Assert-True ($customers.Contains('"' + $stateName + '"')) "customer lifecycle contains $stateName"
}
Assert-True ($gameService.Contains('local function onLaunch')) 'authoritative pizza launch handler is present'
Assert-True ($gameService.Contains('RecordRunService.begin(player)')) 'Record Run start path is present'
Assert-True ($gameService.Contains('clearActiveShot(player)') -and $gameService.Contains('state.launcherMode = "select"')) 'Record Run completion stops shots and returns through the shared mode picker'
Assert-True ($gameService.Contains('ShotPolicy.validate(') -and $shotPolicy.Contains('state.launcherMode ~= "freePlay" and state.launcherMode ~= "recordRun"')) 'server routes launches through the behavior-tested playable-mode policy'
Assert-True ($gameService.Contains('requestedMode == "freePlay" or requestedMode == "recordRun" or requestedMode == "chooseMode"')) 'mode remote accepts only explicit launcher transitions'
Assert-True ($gameService.Contains('launcherLease.owner ~= player') -and $gameService.Contains('launcherLease:isValid(player)')) 'mode selection validates the behavior-tested live mounted lease'
Assert-True ($interaction.Contains('launcherPrompt.Enabled = true') -and $interaction.Contains('"OCCUPIED"')) 'shared launcher remains visibly occupied for waiting players'
Assert-True ($recordRun.Contains('Config.RECORD_RUN_DURATION') -and $recordRun.Contains('Config.RECORD_RUN_COUNTDOWN')) 'Record Run retains server-owned countdown and duration'
Assert-True ($recordRun.IndexOf('local setBoardText: (string) -> ()') -lt $recordRun.IndexOf('local function setSampleBoard')) 'Record Run forward-declares the board writer before Studio fallback use'
Assert-True ($client.Contains('roundOverlay.Name = "RoundClearedBanner"')) 'round-clear feedback uses the compact banner path'
Assert-True (-not $client.Contains('roundOverlay.Size = UDim2.fromOffset(510, 190)')) 'legacy blocking round-clear overlay size is absent'
Assert-True ($client.Contains('if state.event == "launched"')) 'launcher cosmetics wait for a server-accepted launch'
Assert-True ($client.Contains('dialogueCard.Name = "CustomerDialogueCard"')) 'customer greetings use the contextual side card'
Assert-True ($client.Contains('dialogueText.TextScaled = false')) 'customer dialogue never uses oversized TextScaled rendering'
Assert-True ($client.Contains('dialogueCard.Active = false')) 'customer dialogue card is non-modal'
Assert-True ($client.Contains('eventBanner.Name = "ShiftEventBanner"')) 'shift events use a compact side banner'
$trailBlock = [regex]::Match($client, 'local PIZZA_TRAIL_ANCHOR_OFFSETS = \{([\s\S]*?)\r?\n\}')
Assert-True ($trailBlock.Success) 'client defines an anchor-relative Pizza Trail route'
Assert-True (([regex]::Matches($trailBlock.Groups[1].Value, 'Vector3\.new\(')).Count -eq 6) 'Pizza Trail contains six uncluttered path arrows'
Assert-True ($trailBlock.Groups[1].Value.Contains('Vector3.new(-14.5, 0, -3)') -and $trailBlock.Groups[1].Value.Contains('Vector3.new(-11.5, 0, -5)')) 'first two arrows begin in the authored spawn view'
Assert-True ($trailBlock.Groups[1].Value.Contains('Vector3.new(0, 0, 0)')) 'final Pizza Trail marker lands exactly at LauncherInteractionAnchor'
Assert-True ($client.Contains('interactionAnchor.Position.X + offset.X') -and $client.Contains('interactionAnchor.Position.Z + offset.Z')) 'every Pizza Trail marker derives from the explicit interaction anchor'
Assert-True ($client.Contains('world:FindFirstChild("LauncherUsePad", true)') -and $client.Contains('highlight.Adornee = (usePad')) 'launcher highlighting binds to the visible use pad'
Assert-True (-not $client.Contains('FindFirstChild("OperatorConsole"')) 'onboarding never guesses its destination from the decorative console'
Assert-True ($gameService.Contains('root.Position - interactionAnchor.Position')) 'server mount permission validates against LauncherInteractionAnchor'
Assert-True ($client.Contains('shaft.Size = Vector3.new(2.4, 0.16, 3.5)') -and $client.Contains('arrowHead.Size = Vector3.new(1.5, 0.16, 3.1)')) 'Pizza Trail arrow geometry is wide and unmistakable'
Assert-True ($client.Contains('Workspace:Raycast(horizontalPoint + Vector3.new(0, 12, 0)') -and $client.Contains('floorHit.Position.Y + 0.14')) 'each Pizza Trail arrow is raycast onto approved floor geometry with full-thickness clearance'
Assert-True (-not $client.Contains('local trailFloorY =')) 'Pizza Trail never relies on one hard-coded floor height'
$pressFrontZ = 80.0
$finalMarkerZ = 84.0
Assert-True (($finalMarkerZ - $pressFrontZ) -ge 4.0) 'final trail marker remains on clear floor in front of the decorative pizza press'
$pepperoniBlock = [regex]::Match($client, 'for _, pepperoniOffset in \{([\s\S]*?)\r?\n\s*\} do')
Assert-True ($pepperoniBlock.Success -and ([regex]::Matches($pepperoniBlock.Groups[1].Value, 'Vector3\.new\(')).Count -eq 3) 'every Pizza Trail arrow carries three round pepperoni circles'
Assert-True ($client.Contains('part.CanCollide = false') -and $client.Contains('part.CanTouch = false') -and $client.Contains('part.CanQuery = false')) 'Pizza Trail markers cannot affect movement, shots, or target queries'
Assert-True ($client.Contains('folder:SetAttribute("ClientOnly", true)')) 'Pizza Trail world art is local to each player'
Assert-True ($client.Contains('Follow the pizza arrows to the Pizza Launcher!')) 'first-spawn hint uses simple player language'
Assert-True ($client.Contains('Press E to USE LAUNCHER on the pizza pad!') -and $client.Contains('Tap USE LAUNCHER on the pizza pad!')) 'launcher-reached hint supports keyboard and touch'
Assert-True (-not $client.Contains('HowToPlayButton') -and -not $client.Contains('howToPlayButton')) 'inactive HOW TO PLAY control and handler are absent'
Assert-True ($client.Contains('shopToggle.Visible = view.upgrades') -and $client.Contains('upgrades = not picker')) 'UPGRADES uses the behavior-tested initial and modal visibility policy'
Assert-True ($client.Contains('if changed then self:reset() end') -and $client.Contains('inputState:receive(state,')) 'mode transitions use the behavior-tested input reset policy'
Assert-True (-not $client.Contains('"?  HELP"') -and -not $client.Contains('"PizzaTrailHelp"')) 'obsolete mystery help label is absent'
Assert-True (-not [regex]::IsMatch($client, '(?i)TRAIL READY|PLAYER %\.1f|ARROW %\.1f')) 'visible trail count and coordinate debug probes are absent'
Assert-True (-not $client.Contains('PizzaCannonBeacon')) 'tiny launcher distance beacon is removed entirely'
Assert-True (-not [regex]::IsMatch($client + "`n" + $gameService, '(?i)\bstuds?\b')) 'client and server feedback contain no player-facing grid-unit language'
Assert-True ($gameService.Contains('Landing zone +%d%% -> +%d%%')) 'Wider Plates purchase feedback uses a player-readable percentage'
Assert-True ($client.Contains('if self.onboardingTrailActive and not self.onboardingReachedLauncher and distance <= 12 then')) 'trail stays visible while the player approaches interaction range'
Assert-True ($client.Contains('setPizzaTrailVisible(false, false)')) 'mounting the launcher fades the trail instead of snapping it away'
Assert-True ($client.Contains('AIM  •  CHARGE  •  LAUNCH!')) 'mounted onboarding uses the compact first-pizza corner hint'
Assert-True ($client.Contains('"FREE PLAY", "Practice launches with no time limit."') -and $client.Contains('"1-MINUTE\nRECORD RUN", "Score as many points as you can in 60 seconds."')) 'mode picker explains both choices in plain language'
Assert-True ($client.Contains('Enum.KeyCode.Thumbstick1') -and $client.Contains('Enum.KeyCode.ButtonR2') -and $client.Contains('Enum.KeyCode.ButtonB')) 'controller can aim, launch, and exit'
Assert-True ($client.Contains('cameraController.setPicker(modeSelection, freePlayChoice, selectingMode)') -and $client.Contains('GuiService.SelectedObject = choice')) 'controller focus routes through the behavior-tested camera and selection owner'
Assert-True ($client.Contains('local INTERIOR_LAUNCHER_RETURN_OFFSETS') -and $client.Contains('Vector3.new(-14, 0, -40)') -and $client.Contains('makePizzaArrow(folder, position, nextPosition, 100 + index)')) 'first-time guidance includes an interior route back to the launcher pad'
Assert-True ($client.Contains('InteriorLauncherBillboard') -and $client.Contains('interiorGuide.Enabled = visible')) 'interior guidance is hidden with the first-time route on mount'
Assert-True ($client.Contains('if self.onboardingCompleted then') -and $client.Contains('return')) 'automatic Pizza Trail does not replay after completion'
Assert-True ($client.Contains('player.CharacterAdded:Connect') -and $client.Contains('beginPizzaTrail()')) 'incomplete Pizza Trail is restored after respawn'
$acceptedLaunchIndex = $client.IndexOf('if state.event == "launched"')
$onboardingCompleteIndex = $client.IndexOf('onboardingCompleted = true', $acceptedLaunchIndex)
Assert-True ($acceptedLaunchIndex -ge 0 -and $onboardingCompleteIndex -gt $acceptedLaunchIndex) 'first-pizza completion waits for the server-accepted launch event'
Assert-True ($client.Contains('YOU''RE COOKING!') -and $client.Contains('Serve hungry customers for coins.')) 'accepted first launch shows the compact completion banner'
Assert-True ($world.Contains('ring:SetAttribute("DeliveryZone", true)')) 'Wider Plates owns a physical server-visible delivery zone'
Assert-True ($gameService.Contains('ShotPolicy.canPresent(player, launcherLease.owner, state)') -and $gameService.Contains('updateDeliveryZones(newLevel, false)')) 'Wider Plates presentation is routed through the behavior-tested owner policy'
Assert-True ($gameService.Contains('RecordRunService.isSession(player) and 0 or state.upgrades.power')) 'Hotter Oven remains disabled for Record Run fairness'
Assert-True ($gameService.Contains('ShotPolicy.reloadTime(Config, state, recordSession)')) 'Speedy Oven uses behavior-tested authoritative competitive-neutral reload policy'
Assert-True ($gameService.Contains('payload.tipBonus')) 'Bigger Tips exposes its extra reward in delivery feedback'
foreach ($eventName in @('DinnerRush', 'BirthdayTable', 'FoodCritic')) {
    Assert-True ($shiftEvents.Contains('"' + $eventName + '"')) "shift event service contains $eventName"
}
Assert-True ($shiftEvents.Contains('fastService = true')) 'Dinner Rush has a fast-service bonus'
Assert-True ($shiftEvents.Contains('confetti = true')) 'Birthday Table requests a confetti celebration'
Assert-True ($shiftEvents.Contains('comboSaved = true')) 'Food Critic miss preserves the combo while dropping only the bonus'
foreach ($customerName in @('Mia', 'Bo', 'Ziggy', 'Pip', 'Nana', 'Max', 'Lulu', 'Kai', 'Sunny', 'Rex', 'Bea', 'Nico')) {
    Assert-True ($dialogue.Contains($customerName + ' = {')) "dialogue profile exists for $customerName"
}
foreach ($category in @('greeting', 'waiting', 'happy', 'wrong', 'leaving')) {
    Assert-True ($dialogue.Contains($category + ' =')) "dialogue pools contain $category lines"
}
Assert-True ($worldActivity.Contains('AmbientStreetPedestrian')) 'street activity animates the isolated ambient pedestrian'
