param([Parameter(Mandatory = $true)][string]$OutputPath)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
if ((Get-Location).Path -ne $root) { throw 'Run recovery generation from the repository root.' }
if ($OutputPath -notmatch '^\.qa-artifacts/[A-Za-z0-9][A-Za-z0-9_.-]*\.rbxl$' -or $OutputPath.Contains('..')) {
    throw 'Recovery outputs must be new files directly inside .qa-artifacts.'
}
$directory = Join-Path $root '.qa-artifacts'
if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
    New-Item -ItemType Directory -Path $directory | Out-Null
}
if ((Get-Item -LiteralPath $directory).Attributes -band [IO.FileAttributes]::ReparsePoint) {
    throw 'Recovery output directory must not be a reparse point.'
}
$resolvedOutput = [IO.Path]::GetFullPath((Join-Path $root $OutputPath))
if (-not $resolvedOutput.StartsWith($directory + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Recovery output escapes the project artifact directory.'
}
if (Test-Path -LiteralPath $resolvedOutput) { throw "Refusing to overwrite $resolvedOutput" }
Write-Output 'PASS: new recovery output is confined to the ignored project artifact directory.'
