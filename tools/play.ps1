param([switch]$Editor, [switch]$Headless, [string]$Test = '')
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path -Parent $PSScriptRoot
$engineCandidates = @(
    (Join-Path $PSScriptRoot 'godot\Godot_console.exe'),
    (Join-Path $PSScriptRoot 'godot\Godot.exe'),
    (Join-Path (Split-Path -Parent $projectPath) 'sunrise\tmp\Godot_v4.7-stable_win64_console.exe')
)
$engineCommand = Get-Command godot -CommandType Application -All -ErrorAction SilentlyContinue |
    Where-Object { $_.Source -and [System.IO.Path]::GetExtension($_.Source) -ieq '.exe' } |
    Select-Object -First 1
if ($engineCommand) { $engineCandidates += $engineCommand.Source }
$enginePath = $engineCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $enginePath) { throw 'Godot 4.6+ is required. Import project.godot in Godot, or place the engine at tools/godot/Godot.exe.' }
# Source checkouts do not contain Godot's generated resource cache. Import before
# every launch so freshly pulled or replaced assets are also brought up to date.
$launchLogs = Join-Path $projectPath 'artifacts'
New-Item -ItemType Directory -Force -Path $launchLogs | Out-Null
$launchStamp = '{0}-{1}' -f (Get-Date -Format 'yyyyMMdd-HHmmssfff'), $PID
$importLog = Join-Path $launchLogs "source-import-$launchStamp.log"
$importErr = Join-Path $launchLogs "source-import-$launchStamp.err"
$importProcess = Start-Process -FilePath $enginePath -ArgumentList @('--headless', '--path', "`"$projectPath`"", '--editor', '--import', '--quit') -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput $importLog -RedirectStandardError $importErr
$importProcess.Refresh()
$importExit = $importProcess.ExitCode
$importProcess.Dispose()
if ($importExit -ne 0 -or ([string](Get-Content -LiteralPath $importErr -Raw)) -match 'SCRIPT ERROR|ERROR:') { throw "Godot resource import failed (exit $importExit); see $importLog and $importErr." }
$engineArgs = @('--path', "`"$projectPath`"")
if ($Editor) { $engineArgs += '--editor' }
if ($Headless) { $engineArgs += '--headless' }
if ($Test) { $engineArgs += @('--script', "res://tests/$Test.gd") }
# A GUI-subsystem Godot executable does not reliably set LASTEXITCODE in
# PowerShell. Wait on the actual process for both editor/game and test launches.
$windowStyle = if ($Headless) { 'Hidden' } else { 'Normal' }
$gameLog = Join-Path $launchLogs "source-play-$launchStamp.log"
$gameErr = Join-Path $launchLogs "source-play-$launchStamp.err"
$gameProcess = Start-Process -FilePath $enginePath -ArgumentList $engineArgs -WindowStyle $windowStyle -Wait -PassThru -RedirectStandardOutput $gameLog -RedirectStandardError $gameErr
$gameProcess.Refresh()
$gameExit = $gameProcess.ExitCode
$gameProcess.Dispose()
exit $gameExit
