param(
    [Alias('Rounds')][ValidateRange(1,20)][int]$Games = 2,
    [ValidateRange(1,12)][int]$CyclesPerPhase = 4,
    [ValidateRange(0,4)][int]$Viewers = 2,
    [ValidateSet('medium','heir','widow','doctor','keeper','ghost')][string]$Teacher = 'medium',
    [string]$Model = 'granite-4.1-3b',
    [ValidateRange(1,10000)][int]$MaxCalls = 600,
    [string]$Engine = (Join-Path $PSScriptRoot 'godot/Godot_console.exe')
)
# Explicit developer-run local-model playtest. No microphone, paid API, or Python.
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path -Parent $PSScriptRoot
$receiptName = 'agent-party-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8)
$receiptPath = Join-Path $projectPath "artifacts/$receiptName"
New-Item -ItemType Directory -Path $receiptPath | Out-Null
Write-Output "Independent model sessions: 6 players, $Viewers viewers, $Games complete games (3 sittings each)."
Write-Output "LM Studio: http://127.0.0.1:1234/v1; model $Model; teacher $Teacher. Receipts: $receiptPath"
& $Engine --headless --path $projectPath --script res://tools/agent_playtest.gd --log-file (Join-Path $receiptPath 'engine.log') -- --live-local "--model=$Model" "--games=$Games" "--cycles-per-phase=$CyclesPerPhase" "--viewers=$Viewers" "--teacher=$Teacher" "--max-calls=$MaxCalls" "--output=$receiptPath"
if ($LASTEXITCODE -ne 0) { throw "Agent playtest incomplete or failed. Preserve receipts in $receiptPath." }
$engineLog = Get-Content -LiteralPath (Join-Path $receiptPath 'engine.log') -Raw
if ($engineLog -match 'SCRIPT ERROR|ERROR:') { throw "Engine errors occurred. Inspect $receiptPath/engine.log." }
Write-Output "Review $receiptPath/report.md alongside the append-only events.jsonl. Synthetic ratings are not human validation."
