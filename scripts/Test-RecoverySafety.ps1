param(
    [string]$ProjectPath = (Join-Path $PSScriptRoot '..\default.project.json'),
    [string]$BackupPath = (Join-Path $PSScriptRoot '..\recovery\PizzaLaunchTransfer.rbxl')
)

$ErrorActionPreference = 'Stop'
$expectedBackupHash = '73B3D5DF3B72F9B13350790759B715BC0E510BB7A41FED3C895F58BD17F11088'
$resolvedProject = (Resolve-Path -LiteralPath $ProjectPath).Path
$project = Get-Content -LiteralPath $resolvedProject -Raw | ConvertFrom-Json
$workspaceNode = $project.tree.Workspace

if ($null -eq $workspaceNode) {
    throw 'Recovery safety check failed: project has no explicit Workspace safety node.'
}
if ($null -ne $workspaceNode.'$path') {
    throw 'Recovery safety check failed: Workspace must never have a $path mapping.'
}
if ($workspaceNode.'$ignoreUnknownInstances' -ne $true) {
    throw 'Recovery safety check failed: Workspace.$ignoreUnknownInstances must be true.'
}

if (Test-Path -LiteralPath $BackupPath) {
    $actualHash = (Get-FileHash -LiteralPath $BackupPath -Algorithm SHA256).Hash
    if ($actualHash -ne $expectedBackupHash) {
        throw "Recovery safety check failed: Transfer backup hash changed ($actualHash)."
    }
} else {
    Write-Warning "Transfer backup not present at $BackupPath; project safety was checked, backup hash was not."
}

Write-Output 'PASS: Workspace has no $path mapping.'
Write-Output 'PASS: Workspace ignores unknown Studio-owned instances.'
if (Test-Path -LiteralPath $BackupPath) {
    Write-Output "PASS: Transfer backup SHA-256 is $expectedBackupHash."
}
