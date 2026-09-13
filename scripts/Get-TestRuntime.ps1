$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$version = '0.10.5'
$archiveHash = 'AD0305F5CC6D7FF20996644B40BF7DE0DE613812F431CA241456E16F9FC89CDA'
$downloadUrl = "https://github.com/lune-org/lune/releases/download/v$version/lune-$version-windows-x86_64.zip"

# No installation, PATH changes, credential access, or writes outside the project.
foreach ($relative in @('.qa-artifacts', '.qa-artifacts\tools', ".qa-artifacts\tools\lune-$version")) {
    $directory = Join-Path $root $relative
    if (Test-Path -LiteralPath $directory) {
        if ((Get-Item -LiteralPath $directory).Attributes -band [IO.FileAttributes]::ReparsePoint) {
            throw "Refusing tool directory with a reparse point: $directory"
        }
    } else {
        New-Item -ItemType Directory -Path $directory | Out-Null
    }
}
$toolDirectory = Join-Path $root ".qa-artifacts\tools\lune-$version"
$archivePath = Join-Path $toolDirectory 'release.zip'
$executablePath = Join-Path $toolDirectory 'lune.exe'
foreach ($path in @($archivePath, $executablePath)) {
    if ((Test-Path -LiteralPath $path) -and ((Get-Item -LiteralPath $path).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        throw "Refusing tool file with a reparse point: $path"
    }
}
if (-not (Test-Path -LiteralPath $archivePath)) {
    Invoke-WebRequest -UseBasicParsing -Uri $downloadUrl -OutFile $archivePath
}
if ((Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash -ne $archiveHash) {
    throw 'Pinned Lune archive SHA-256 mismatch; preserving the file for inspection.'
}

# Read only the expected executable entry; arbitrary archive paths are never extracted.
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead($archivePath)
try {
    $entry = $archive.GetEntry('lune.exe')
    if ($null -eq $entry) { throw 'Pinned Lune archive lacks lune.exe.' }
    $entryStream = $entry.Open()
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $expectedExecutableHash = [BitConverter]::ToString($sha.ComputeHash($entryStream)).Replace('-', '')
    } finally {
        $entryStream.Dispose()
        $sha.Dispose()
    }
    if (Test-Path -LiteralPath $executablePath) {
        if ((Get-FileHash -LiteralPath $executablePath -Algorithm SHA256).Hash -ne $expectedExecutableHash) {
            throw 'Cached Lune executable differs from the pinned archive; preserving it for inspection.'
        }
    } else {
        $entryStream = $entry.Open()
        $outputStream = [IO.File]::Open($executablePath, [IO.FileMode]::CreateNew)
        try { $entryStream.CopyTo($outputStream) } finally {
            $entryStream.Dispose()
            $outputStream.Dispose()
        }
    }
} finally { $archive.Dispose() }
Write-Output $executablePath
