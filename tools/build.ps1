param([switch]$SkipChecks)
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectPath
if (-not $SkipChecks) { & (Join-Path $PSScriptRoot 'check.ps1') }
$engine = Join-Path $PSScriptRoot 'godot\Godot_console.exe'
$runtime = Join-Path $PSScriptRoot 'godot\Godot.exe'
if (-not (Test-Path -LiteralPath $runtime)) { throw 'Place the paired Godot binaries in tools/godot first.' }
$buildPath = Join-Path $projectPath 'build'
New-Item -ItemType Directory -Force -Path $buildPath | Out-Null
& $engine --headless --path $projectPath --export-pack 'Windows Desktop' (Join-Path $buildPath 'Seance.pck') --log-file (Join-Path $projectPath 'artifacts/export.log')
if ($LASTEXITCODE -ne 0) { throw 'PCK export failed.' }
$exportLog = Get-Content -LiteralPath (Join-Path $projectPath 'artifacts/export.log') -Raw
if ($exportLog -match 'SCRIPT ERROR|ERROR:') { throw 'Export reported an error. Inspect artifacts/export.log.' }
Copy-Item -LiteralPath $runtime -Destination (Join-Path $buildPath 'Seance.exe')
Copy-Item -LiteralPath $engine -Destination (Join-Path $buildPath 'Seance_console.exe')
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'portable-play.cmd') -Destination (Join-Path $buildPath 'PLAY.cmd')
Copy-Item -LiteralPath (Join-Path $projectPath 'README.md') -Destination (Join-Path $buildPath 'README.md')
Copy-Item -LiteralPath (Join-Path $projectPath 'docs\ASSETS.md') -Destination (Join-Path $buildPath 'ASSETS.md')
New-Item -ItemType Directory -Force -Path (Join-Path $buildPath 'docs') | Out-Null
Get-ChildItem -LiteralPath (Join-Path $projectPath 'docs') -File | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $buildPath "docs\$($_.Name)")
}
& $engine --headless --path $projectPath --script res://tests/engine_notices.gd
if ($LASTEXITCODE -ne 0) { throw 'Engine notice generation failed.' }
Write-Output 'Built build/Seance.exe and Seance.pck. This is an unsigned editor-runtime development bundle, not a release-template export.'
