$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) {
        throw "Recovery contract failed: $Message"
    }
    Write-Output "PASS: $Message"
}

$transferInvariantHashes = @{
    'src\server\CustomerService.luau' = '78E7214C2D762165637761BED10F8663A5636B59B25739B67D928F9A00D05E4F'
    'src\server\InteractionService.luau' = '0C898C82732795319F395F45BE69018C78B77156C2F01739C6E97DDA876BEA1B'
    'src\server\LayoutService.luau' = 'CAC15A2013C3A8E6E6AAF3BE948803CC9D72BD92F87A30C166C267F6FBCD2D6D'
    'src\server\PropService.luau' = 'CB4C89F36DDF3ED91E85447D9D849C38F3CF844E69DE3BE708D9EA72CCC031E2'
    'src\server\init.server.luau' = '6EA4502197116E37571D53A7A24A0C1227DBC8270C3614A3518DD3B8F161D7C4'
}
foreach ($relativePath in $transferInvariantHashes.Keys) {
    $actual = (Get-FileHash -LiteralPath (Join-Path $root $relativePath) -Algorithm SHA256).Hash
    Assert-True ($actual -eq $transferInvariantHashes[$relativePath]) "$relativePath remains byte-identical to Transfer"
}

$worldPath = Join-Path $root 'src\server\WorldBuilder.luau'
$world = Get-Content -LiteralPath $worldPath -Raw
$config = Get-Content -LiteralPath (Join-Path $root 'src\shared\Config.luau') -Raw
$customers = Get-Content -LiteralPath (Join-Path $root 'src\server\CustomerService.luau') -Raw
$gameService = Get-Content -LiteralPath (Join-Path $root 'src\server\GameService.luau') -Raw

$definitions = [regex]::Matches($world, '(?m)^\s*([A-Za-z][A-Za-z0-9_]*)\s*=\s*Color3\.') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
$references = [regex]::Matches($world, 'COLORS\.([A-Za-z][A-Za-z0-9_]*)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
$missingColors = $references | Where-Object { $_ -notin $definitions }
Assert-True ($missingColors.Count -eq 0) "WorldBuilder has no undefined COLORS entries"

Assert-True ($world.Contains('buildStorefrontExterior(world)')) 'storefront exterior is part of runtime construction'
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
