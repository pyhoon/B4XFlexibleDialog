<#
.SYNOPSIS
    Packages the B4XFlexibleDialog B4J sources into a distributable .b4xlib.

.DESCRIPTION
    A .b4xlib is a ZIP archive containing:
      - platform-independent .bas modules at the root,
      - platform-specific modules under a B4J/ folder,
      - a Files/ folder with assets (prefs.css),
      - a manifest.txt describing version and dependencies.

    Shared modules must not reference JavaFX types so they can be reused by other
    platform ports later.

.EXAMPLE
    powershell -File tools/package-b4xlib.ps1 -Version 0.2.0
#>
[CmdletBinding()]
param(
    [string]$SourceDir,
    [string]$OutputDir,
    [string]$Version = '0.2',
    [string]$LibraryName = 'B4XFlexibleDialog'
)

$ErrorActionPreference = 'Stop'

if (-not $SourceDir) { $SourceDir = Join-Path $PSScriptRoot '..\B4XFlexibleDialog\B4J' }
if (-not $OutputDir) { $OutputDir = Join-Path $PSScriptRoot '..\dist' }

# Platform-independent modules (no JavaFX/UI references).
$sharedModules = @(
    'PrefsModel', 'PrefsController', 'PrefsLocalization', 'PrefsTheme', 'PrefsStore', 'PrefsFileResult', 'PrefsSelfTest'
)

# B4J (JavaFX) modules.
$b4jModules = @(
    'B4XFlexibleDialog', 'PrefsDialog', 'PrefsPage', 'PrefsFileProvider'
)

$SourceDir = (Resolve-Path -LiteralPath $SourceDir).Path

function Copy-Module {
    param([string]$Name, [string]$Target)
    $src = Join-Path $SourceDir ($Name + '.bas')
    if (-not (Test-Path -LiteralPath $src)) { throw "Missing module: $src" }
    Copy-Item -LiteralPath $src -Destination $Target -Force
}

$stage = Join-Path ([System.IO.Path]::GetTempPath()) ('b4xlib_' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage | Out-Null
New-Item -ItemType Directory -Path (Join-Path $stage 'B4J') | Out-Null
New-Item -ItemType Directory -Path (Join-Path $stage 'Files') | Out-Null

try {
    foreach ($m in $sharedModules) { Copy-Module -Name $m -Target $stage }
    foreach ($m in $b4jModules) { Copy-Module -Name $m -Target (Join-Path $stage 'B4J') }

    $css = Join-Path $SourceDir 'Files\prefs.css'
    if (-not (Test-Path -LiteralPath $css)) { throw "Missing asset: $css" }
    Copy-Item -LiteralPath $css -Destination (Join-Path $stage 'Files') -Force

    $manifest = "Version=$Version`r`nB4J.DependsOn=jFX, Json`r`n"
    Set-Content -LiteralPath (Join-Path $stage 'manifest.txt') -Value $manifest -NoNewline -Encoding Ascii

    if (-not (Test-Path -LiteralPath $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir | Out-Null }
    $OutputDir = (Resolve-Path -LiteralPath $OutputDir).Path
    $target = Join-Path $OutputDir ($LibraryName + '.b4xlib')
    if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Force }

    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    # Build entries with forward-slash names (b4xlib expects '/', not '\').
    $archive = [System.IO.Compression.ZipFile]::Open($target, [System.IO.Compression.ZipArchiveMode]::Create)
    try {
        $entries = [System.Collections.Generic.List[object]]::new()
        $entries.Add([pscustomobject]@{ Path = (Join-Path $stage 'manifest.txt'); Name = 'manifest.txt' })
        foreach ($m in $sharedModules) {
            $entries.Add([pscustomobject]@{ Path = (Join-Path $stage ($m + '.bas')); Name = ($m + '.bas') })
        }
        foreach ($m in $b4jModules) {
            $entries.Add([pscustomobject]@{ Path = (Join-Path $stage ('B4J\' + $m + '.bas')); Name = ('B4J/' + $m + '.bas') })
        }
        $entries.Add([pscustomobject]@{ Path = (Join-Path $stage 'Files\prefs.css'); Name = 'Files/prefs.css' })

        foreach ($e in $entries) {
            $entry = $archive.CreateEntry($e.Name, [System.IO.Compression.CompressionLevel]::Optimal)
            $out = $entry.Open()
            try {
                $bytes = [System.IO.File]::ReadAllBytes($e.Path)
                $out.Write($bytes, 0, $bytes.Length)
            }
            finally { $out.Dispose() }
        }
    }
    finally { $archive.Dispose() }

    Write-Host ("Created {0} ({1:N0} bytes)" -f $target, (Get-Item -LiteralPath $target).Length)
}
finally {
    if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
}
