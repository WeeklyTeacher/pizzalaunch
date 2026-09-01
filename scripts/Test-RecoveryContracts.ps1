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
    'src\server\InteractionService.luau' = '0C898C82732795319F395F45BE69018C78B77156C2F01739C6E97DDA876BEA1B'
    'src\server\LayoutService.luau' = 'CAC15A2013C3A8E6E6AAF3BE948803CC9D72BD92F87A30C166C267F6FBCD2D6D'
    'src\server\PropService.luau' = 'CB4C89F36DDF3ED91E85447D9D849C38F3CF844E69DE3BE708D9EA72CCC031E2'
    'src\server\init.server.luau' = '6EA4502197116E37571D53A7A24A0C1227DBC8270C3614A3518DD3B8F161D7C4'
}
foreach ($relativePath in $transferInvariantHashes.Keys) {
    $actual = Get-NormalizedSourceHash (Join-Path $root $relativePath)
    Assert-True ($actual -eq $transferInvariantHashes[$relativePath]) "$relativePath remains byte-identical to Transfer"
}
Assert-True ((Get-NormalizedSourceHash (Join-Path $root 'src\server\RecordRunService.luau')) -eq '9058017153B709B67651B0DEC1F924D2FD0706CF2F584DA1D46B6B2FC393A348') 'RecordRunService remains unchanged from the protected visual-expansion checkpoint'
Assert-True ((Get-NormalizedSourceHash (Join-Path $root 'default.project.json')) -eq '2CAB2897048D4EA3A3F1B23EE29B8E1C41E520FAECF18F9D002774431970A000') 'Rojo project mapping remains unchanged from the protected visual-expansion checkpoint'

$worldPath = Join-Path $root 'src\server\WorldBuilder.luau'
$world = Get-Content -LiteralPath $worldPath -Raw
$config = Get-Content -LiteralPath (Join-Path $root 'src\shared\Config.luau') -Raw
$customers = Get-Content -LiteralPath (Join-Path $root 'src\server\CustomerService.luau') -Raw
$gameService = Get-Content -LiteralPath (Join-Path $root 'src\server\GameService.luau') -Raw
$client = Get-Content -LiteralPath (Join-Path $root 'src\client\init.client.luau') -Raw
$dialogue = Get-Content -LiteralPath (Join-Path $root 'src\server\CustomerDialogue.luau') -Raw
$shiftEvents = Get-Content -LiteralPath (Join-Path $root 'src\server\ShiftEventService.luau') -Raw
$worldActivity = Get-Content -LiteralPath (Join-Path $root 'src\server\WorldActivityService.luau') -Raw

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
Assert-True ($config.Contains('Config.RECORD_RUN_STORE = "PizzaLaunch_RecordRun_AllTime_v1"')) 'OrderedDataStore name is unchanged'
Assert-True ($config.Contains('Config.LAUNCH_ORIGIN = Vector3.new(0, 12, 50)')) 'Transfer launcher origin is unchanged'
Assert-True ($config.Contains('Vector3.new(-24, 2.5, 2)') -and $config.Contains('Vector3.new(24, 2.5, -55)')) 'Transfer near/far table geometry is present'

foreach ($stateName in @('Entering', 'WalkingToSeat', 'SeatedWaiting', 'Served', 'HappyReaction', 'Eating', 'Leaving', 'Despawn')) {
    Assert-True ($customers.Contains('"' + $stateName + '"')) "customer lifecycle contains $stateName"
}
Assert-True ($gameService.Contains('local function onLaunch')) 'authoritative pizza launch handler is present'
Assert-True ($gameService.Contains('RecordRunService.begin(player)')) 'Record Run start path is present'
Assert-True ($gameService.Contains('cleanupLauncherSession(player, "recordCompleted"')) 'Record Run completion uses launcher cleanup'
Assert-True ($client.Contains('roundOverlay.Name = "RoundClearedBanner"')) 'round-clear feedback uses the compact banner path'
Assert-True (-not $client.Contains('roundOverlay.Size = UDim2.fromOffset(510, 190)')) 'legacy blocking round-clear overlay size is absent'
Assert-True ($client.Contains('if state.event == "launched"')) 'launcher cosmetics wait for a server-accepted launch'
Assert-True ($client.Contains('dialogueCard.Name = "CustomerDialogueCard"')) 'customer greetings use the contextual side card'
Assert-True ($client.Contains('dialogueText.TextScaled = false')) 'customer dialogue never uses oversized TextScaled rendering'
Assert-True ($client.Contains('dialogueCard.Active = false')) 'customer dialogue card is non-modal'
Assert-True ($client.Contains('eventBanner.Name = "ShiftEventBanner"')) 'shift events use a compact side banner'
Assert-True ($world.Contains('ring:SetAttribute("DeliveryZone", true)')) 'Wider Plates owns a physical server-visible delivery zone'
Assert-True ($gameService.Contains('updateDeliveryZones(newLevel, false)')) 'Wider Plates updates the authoritative zone immediately after purchase'
Assert-True ($gameService.Contains('RecordRunService.isSession(player) and 0 or state.upgrades.power')) 'Hotter Oven remains disabled for Record Run fairness'
Assert-True ($gameService.Contains('local effectiveReload = recordSession and Config.RELOAD_TIME')) 'Speedy Oven reload remains server-authoritative and Record Run neutral'
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
