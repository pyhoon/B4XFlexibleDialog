<#
.SYNOPSIS
    Builds and runs the B4J assertion harness headlessly and reports pass/fail.

.DESCRIPTION
    Builds the B4J library project (which runs the shared, UI-free PrefsSelfTest
    plus the inline core/store/facade assertions at startup) and runs it with a
    headless JavaFX classpath. The run outputs "PASS:"/"FAIL:" lines and a
    "SelfTest passed=<n> failed=<m>" summary. The script fails the run if any
    "FAIL:" line appears or the self-test reports a non-zero failed count.

    Because the StartUp subs run before the form is shown, the process only needs
    to survive long enough to flush its log, so the window is closed after
    -WaitSeconds.

.EXAMPLE
    powershell -File tools/run-b4j-tests.ps1
#>
[CmdletBinding()]
param(
    [string]$B4JBuilder = 'C:\Program Files\B4X\B4J\B4JBuilder.exe',
    [string]$JavaExe = 'C:\Java\jdk-19.0.2\bin\java.exe',
    [string]$JfxModulePath = 'C:\Java\jdk-19.0.2\javafx\lib',
    [string]$ProjectRoot,
    [int]$WaitSeconds = 12
)

$ErrorActionPreference = 'Stop'

if (-not $ProjectRoot) { $ProjectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path }
$projectDir = Join-Path $ProjectRoot 'B4XFlexibleDialog\B4J'
$projectFile = Join-Path $projectDir 'B4XFlexibleDialog.b4j'
$jar = Join-Path $projectDir 'Objects\B4XFlexibleDialog.jar'

foreach ($path in @($B4JBuilder, $JavaExe, $ProjectRoot)) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Not found: $path" }
}

Write-Host 'Building B4J library test harness...'
$buildArgs = @('-Task=Build', "-BaseFolder=$projectDir", "-Project=$projectFile", '-ShowWarnings=True')
& $B4JBuilder @buildArgs | Out-Null
if ($LASTEXITCODE -ne 0) { throw "B4J build failed (exit $LASTEXITCODE)." }
if (-not (Test-Path -LiteralPath $jar)) { throw "Jar not produced: $jar" }

$classPath = $jar + [System.IO.Path]::PathSeparator + 'C:\Program Files\B4X\B4J\Libraries\*' + [System.IO.Path]::PathSeparator + 'C:\Program Files\B4X\B4J\base.jar'
$commandLine = '"' + $JavaExe + '" -Dfile.encoding=UTF8 --module-path "' + $JfxModulePath +
    '" --add-modules javafx.controls,javafx.graphics,javafx.swing,javafx.web,javafx.fxml -cp "' +
    $classPath + '" b4j.example.main'

Write-Host 'Running assertion harness headlessly...'
$job = Start-Job -ScriptBlock { param($l) cmd /c $l 2>&1 } -ArgumentList $commandLine
Start-Sleep -Seconds $WaitSeconds
$output = Receive-Job -Job $job
Stop-Job -Job $job -ErrorAction SilentlyContinue
Remove-Job -Job $job -Force -ErrorAction SilentlyContinue

$failLines = @($output | Where-Object { $_ -match 'FAIL:' })
$selfTestLine = $output | Where-Object { $_ -match 'SelfTest passed=' } | Select-Object -Last 1
$passCount = @($output | Where-Object { $_ -match '(^| )PASS:' }).Count
$failCount = $failLines.Count

Write-Host ''
Write-Host ("PASS: {0}  FAIL: {1}" -f $passCount, $failCount)
if ($selfTestLine) { Write-Host $selfTestLine }

$selfTestOk = $false
if ($selfTestLine -match 'SelfTest passed=(\d+) failed=(\d+)') {
    $selfTestOk = ([int]$Matches[2] -eq 0)
}

if ($failCount -gt 0 -or -not $selfTestOk) {
    if ($failLines) { $failLines | ForEach-Object { Write-Host $_ } }
    Write-Host 'RESULT: FAILED'
    exit 1
}

Write-Host 'RESULT: PASSED'
exit 0
