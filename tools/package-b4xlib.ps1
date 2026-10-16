<#
.SYNOPSIS
    Packages the B4XFlexibleDialog B4J sources into a distributable .b4xlib.

.DESCRIPTION
    A .b4xlib is a ZIP archive containing:
      - platform-independent .bas modules at the root,
      - platform-specific modules under a B4J/, B4A/ and B4i/ folder,
      - a Files/ folder with assets (prefs.css),
      - a manifest.txt describing version and dependencies.

    The library sources live at the repository root of B4XFlexibleDialog/: the
    shared modules and the B4J modules share that folder (the B4J project is in
    B4J/, and only its Files/ assets are shipped). Platform-specific modules for
    other targets live in B4A/ and B4i/ (the B4i renderer/picker are stubs).
    Shared modules must not reference JavaFX types so they can be reused by the
    other ports.

.EXAMPLE
    powershell -File tools/package-b4xlib.ps1 -Version 0.2
#>
[CmdletBinding()]
param(
    [string]$SourceDir,
    [string]$B4JSourceDir,
    [string]$B4ASourceDir,
    [string]$B4iSourceDir,
    [string]$OutputDir,
    [string]$Version = '0.2',
    [string]$LibraryName = 'B4XFlexibleDialog'
)

$ErrorActionPreference = 'Stop'

if (-not $SourceDir) { $SourceDir = Join-Path $PSScriptRoot '..\B4XFlexibleDialog' }
if (-not $B4JSourceDir) { $B4JSourceDir = Join-Path $PSScriptRoot '..\B4XFlexibleDialog\B4J' }
if (-not $B4ASourceDir) { $B4ASourceDir = Join-Path $PSScriptRoot '..\B4XFlexibleDialog\B4A' }
if (-not $B4iSourceDir) { $B4iSourceDir = Join-Path $PSScriptRoot '..\B4XFlexibleDialog\B4i' }
if (-not $OutputDir) { $OutputDir = Join-Path $PSScriptRoot '..\dist' }

# Platform-independent modules (no JavaFX/UI references); live at the source root.
$sharedModules = @(
    'PrefsModel', 'PrefsController', 'PrefsLocalization', 'PrefsTheme', 'PrefsStore', 'PrefsFileResult', 'PrefsSelfTest'
)

# B4J (JavaFX) modules; also live at the source root, shipped under B4J/.
$b4jModules = @(
    'B4XFlexibleDialog', 'PrefsDialog', 'PrefsPage', 'PrefsFileProvider'
)

# B4A (Android) modules.
$b4aModules = @(
    'PrefsRenderer', 'PrefsDirPicker'
)

# B4i (iOS) modules. These are not implemented yet; stubs ship so the shared call
# sites compile against the library on B4i. See B4XFlexibleDialog/B4i/*.bas.
$b4iModules = @(
    'PrefsRenderer', 'PrefsDirPicker'
)

$SourceDir = (Resolve-Path -LiteralPath $SourceDir).Path
$B4JSourceDir = (Resolve-Path -LiteralPath $B4JSourceDir).Path
$B4ASourceDir = (Resolve-Path -LiteralPath $B4ASourceDir).Path
$B4iSourceDir = (Resolve-Path -LiteralPath $B4iSourceDir).Path

function Copy-Module {
    param([string]$Root, [string]$Name, [string]$Target)
    $src = Join-Path $Root ($Name + '.bas')
    if (-not (Test-Path -LiteralPath $src)) { throw "Missing module: $src" }
    Copy-Item -LiteralPath $src -Destination $Target -Force
}

$stage = Join-Path ([System.IO.Path]::GetTempPath()) ('b4xlib_' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage | Out-Null
New-Item -ItemType Directory -Path (Join-Path $stage 'B4J') | Out-Null
New-Item -ItemType Directory -Path (Join-Path $stage 'B4A') | Out-Null
New-Item -ItemType Directory -Path (Join-Path $stage 'B4i') | Out-Null
New-Item -ItemType Directory -Path (Join-Path $stage 'Files') | Out-Null

try {
    foreach ($m in $sharedModules) { Copy-Module -Root $SourceDir -Name $m -Target $stage }
    foreach ($m in $b4jModules) { Copy-Module -Root $SourceDir -Name $m -Target (Join-Path $stage 'B4J') }
    foreach ($m in $b4aModules) { Copy-Module -Root $B4ASourceDir -Name $m -Target (Join-Path $stage 'B4A') }
    foreach ($m in $b4iModules) { Copy-Module -Root $B4iSourceDir -Name $m -Target (Join-Path $stage 'B4i') }

    $css = Join-Path $B4JSourceDir 'Files\prefs.css'
    if (-not (Test-Path -LiteralPath $css)) { throw "Missing asset: $css" }
    Copy-Item -LiteralPath $css -Destination (Join-Path $stage 'Files') -Force

    $manifest = "Version=$Version`r`nB4J.DependsOn=Json, jXUI`r`nB4A.DependsOn=Phone, XUI, JavaObject`r`n"
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
        foreach ($m in $b4aModules) {
            $entries.Add([pscustomobject]@{ Path = (Join-Path $stage ('B4A\' + $m + '.bas')); Name = ('B4A/' + $m + '.bas') })
        }
        foreach ($m in $b4iModules) {
            $entries.Add([pscustomobject]@{ Path = (Join-Path $stage ('B4i\' + $m + '.bas')); Name = ('B4i/' + $m + '.bas') })
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
