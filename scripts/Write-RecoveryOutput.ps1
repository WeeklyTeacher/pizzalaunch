param(
    [Parameter(Mandatory = $true)][string]$OutputPath,
    [Parameter(Mandatory = $true)][string]$PayloadPath
)
$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'Test-RecoveryOutputPath.ps1') -OutputPath $OutputPath | Out-Null
$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
if ($PayloadPath -notmatch '^\.qa-artifacts/[A-Za-z0-9][A-Za-z0-9_.-]*\.payload$' -or $PayloadPath.Contains('..')) {
    throw 'Recovery payload must be a file directly inside .qa-artifacts.'
}
$resolvedPayload = [IO.Path]::GetFullPath((Join-Path $root $PayloadPath))
$payloadItem = Get-Item -LiteralPath $resolvedPayload
if (($payloadItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -or $payloadItem.Length -eq 0) {
    throw 'Recovery payload must be a nonempty ordinary file.'
}
$resolvedOutput = [IO.Path]::GetFullPath((Join-Path $root $OutputPath))
# CreateNew is atomic: a concurrent creation cannot be silently overwritten.
$outputStream = [IO.File]::Open($resolvedOutput, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
$payload = [IO.File]::OpenRead($resolvedPayload)
try {
    $payload.CopyTo($outputStream)
} finally {
    $payload.Dispose()
    $outputStream.Dispose()
}
