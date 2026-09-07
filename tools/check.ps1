param([switch]$Rendered, [switch]$SkipNetwork, [string]$Engine = '', [string]$LintBin = '')
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectPath
if (-not $Engine) { $Engine = Join-Path $PSScriptRoot 'godot\Godot_console.exe' }
if (-not (Test-Path -LiteralPath $Engine)) { throw 'Supply -Engine pointing to Godot 4.6+ console executable.' }
if (-not $LintBin) {
    $LintBin = Join-Path (Split-Path -Parent $projectPath) 'sunrise\.venv\Scripts'
}
$formatter = Join-Path $LintBin 'gdformat.exe'
$linter = Join-Path $LintBin 'gdlint.exe'
if (-not (Test-Path -LiteralPath $formatter) -or -not (Test-Path -LiteralPath $linter)) {
    throw 'Install requirements-dev.txt in a development venv and pass its Scripts directory as -LintBin.'
}
New-Item -ItemType Directory -Force -Path (Join-Path $projectPath 'artifacts') | Out-Null
& $formatter --check scripts world ui tests tools
if ($LASTEXITCODE -ne 0) { throw 'Formatting failed. Run gdformat on scripts world ui tests tools.' }
& $linter scripts world ui tests tools
if ($LASTEXITCODE -ne 0) { throw 'GDScript lint failed.' }
$sources = Get-ChildItem scripts, world, ui, tests, tools, shaders -Recurse -File |
    Where-Object { $_.Extension -in @('.gd', '.gdshader', '.py', '.ps1') }
$largest = 0
foreach ($source in $sources) {
    # Count all newline-delimited lines, including blank ones.
    $lineCount = [System.IO.File]::ReadAllLines($source.FullName).Count
    $largest = [Math]::Max($largest, $lineCount)
    if ($lineCount -ge 1000) { throw "File limit exceeded: $($source.FullName) ($lineCount lines)" }
}
if (Get-ChildItem -LiteralPath $projectPath -Force -File -Filter '.env*') { throw 'Credential files must remain outside this repository.' }
Write-Output "SOURCE LIMIT: $($sources.Count) files; largest $largest lines (limit <1000)."

function Invoke-EngineCheck([string]$Name, [string[]]$TaskArguments, [string]$Marker = '') {
    $stdout = Join-Path $projectPath "artifacts/check-$Name.log"
    $stderr = Join-Path $projectPath "artifacts/check-$Name.err"
    $engineArgs = @('--path', "`"$projectPath`"") + $TaskArguments
    $process = Start-Process -FilePath $Engine -ArgumentList $engineArgs -WindowStyle Hidden -PassThru `
        -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    try {
        $timeout = if ($Name -eq 'import') { 300000 } else { 60000 }
        if (-not $process.WaitForExit($timeout)) {
            $process.Kill()
            throw "Engine $Name timed out. Inspect artifacts/check-$Name.*"
        }
        $process.Refresh()
        $output = (Get-Content -LiteralPath $stdout -Raw) + (Get-Content -LiteralPath $stderr -Raw)
        if ($process.ExitCode -ne 0 -or $output -match 'SCRIPT ERROR|ERROR:|FAIL:' -or ($Marker -and $output -notmatch $Marker)) {
            Write-Output $output
            throw "Engine $Name failed."
        }
        Write-Output "ENGINE $Name : PASS"
        if ($Marker) { ($output -split "`n" | Where-Object { $_ -match $Marker }) | Write-Output }
    } finally {
        if (-not $process.HasExited) { $process.Kill() }
        $process.Dispose()
    }
}

# --check-only --script on UI dependencies crashed this local engine. Loading
# scripts through a SceneTree harness exercises the real compiler safely.
Invoke-EngineCheck 'import' @('--headless', '--editor', '--import', '--quit')
Invoke-EngineCheck 'compile' @('--headless', '--script', 'res://tests/compile_test.gd') 'COMPILE: PASS'
Invoke-EngineCheck 'rules' @('--headless', '--script', 'res://tests/rules_test.gd') 'RULES: .*0 failures'
Invoke-EngineCheck 'npc' @('--headless', '--script', 'res://tests/npc_test.gd') 'NPC: .*0 failures'
Invoke-EngineCheck 'round-summary' @('--headless', '--script', 'res://tests/round_summary_test.gd') 'ROUND SUMMARY: .*0 failures'
Invoke-EngineCheck 'playtest-bridge' @('--headless', '--script', 'res://tests/playtest_bridge_test.gd') 'PLAYTEST BRIDGE: .*0 failures'
Invoke-EngineCheck 'agent-harness' @('--headless', '--script', 'res://tests/agent_harness_test.gd') 'AGENT HARNESS: .*0 failures'
Invoke-EngineCheck 'assets' @('--headless', '--script', 'res://tests/assets_test.gd') 'ASSETS: .*0 failures'
Invoke-EngineCheck 'runtime' @('--headless', '--script', 'res://tests/runtime_test.gd', '--', '--qa') 'RUNTIME: .*0 failures'
Invoke-EngineCheck 'features' @('--headless', '--script', 'res://tests/features_test.gd', '--', '--qa') 'FEATURES: .*0 failures'
Invoke-EngineCheck 'social' @('--headless', '--script', 'res://tests/social_runtime_test.gd', '--', '--qa') 'SOCIAL UI: .*0 failures'
if (-not $SkipNetwork) { & (Join-Path $PSScriptRoot 'test-network.ps1') -Engine $Engine }
if ($Rendered) {
    Invoke-EngineCheck 'rendered-round-summary' @('--script', 'res://tests/round_summary_test.gd', '--', '--qa') 'ROUND SUMMARY: .*0 failures'
    Invoke-EngineCheck 'rendered-social' @('--script', 'res://tests/social_runtime_test.gd', '--', '--qa') 'SOCIAL UI: .*0 failures'
    Invoke-EngineCheck 'rendered' @('--script', 'res://tests/runtime_test.gd', '--', '--qa') 'RUNTIME: .*0 failures'
    Invoke-EngineCheck 'rendered-features' @('--script', 'res://tests/features_test.gd', '--', '--qa') 'FEATURES: .*0 failures'
}
Write-Output 'CHECK: PASS'
