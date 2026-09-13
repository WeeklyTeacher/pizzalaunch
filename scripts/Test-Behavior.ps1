param([string]$Filter = '*.spec.luau')

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$runtime = & (Join-Path $PSScriptRoot 'Get-TestRuntime.ps1')
$specs = @(Get-ChildItem -LiteralPath (Join-Path $root 'tests') -File -Filter $Filter | Sort-Object Name)
if ($specs.Count -eq 0) { throw "No behavioral tests match $Filter" }
$failed = @()
Push-Location -LiteralPath $root
try {
    & $runtime run scripts/Test-SourceCompile.luau
    if ($LASTEXITCODE -ne 0) { throw 'Actual Luau source compilation failed.' }
    foreach ($spec in $specs) {
        Write-Output "RUN: $($spec.Name)"
        & $runtime run $spec.FullName
        if ($LASTEXITCODE -ne 0) { $failed += $spec.Name }
    }
} finally { Pop-Location }
if ($failed.Count -gt 0) { throw "Behavioral tests failed: $($failed -join ', ')" }
Write-Output "PASS: $($specs.Count) Luau behavioral test files. Roblox engine/runtime tests are separate."
