param([string]$Engine = (Join-Path $PSScriptRoot 'godot/Godot_console.exe'))
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path -Parent $PSScriptRoot
$processes = @()
try {
    foreach ($role in @('medium', 'heir', 'widow', 'doctor', 'keeper', 'ghost')) {
        $argsForEngine = @('--headless', '--path', "`"$projectPath`"", '--script', 'res://tests/six_seat_test.gd', '--', $role)
        $process = Start-Process -FilePath $Engine -ArgumentList $argsForEngine -WindowStyle Hidden -PassThru `
            -RedirectStandardOutput (Join-Path $projectPath "artifacts/party-$role.log") `
            -RedirectStandardError (Join-Path $projectPath "artifacts/party-$role.err")
        $processes += @{Role=$role; Process=$process}
        if ($role -eq 'medium') { Start-Sleep -Milliseconds 500 }
    }
    $failed = $false
    foreach ($entry in $processes) {
        if (-not $entry.Process.WaitForExit(110000)) { $entry.Process.Kill(); $failed = $true }
        $entry.Process.Refresh()
        $output = (Get-Content -LiteralPath (Join-Path $projectPath "artifacts/party-$($entry.Role).log") -Raw) + (Get-Content -LiteralPath (Join-Path $projectPath "artifacts/party-$($entry.Role).err") -Raw)
        Write-Output $output
        if ($entry.Process.ExitCode -ne 0 -or $output -notmatch 'checks, 0 failures' -or $output -match 'SCRIPT ERROR|ERROR:|FAIL:') { $failed = $true }
    }
    if ($failed) { throw 'Six-seat exercise failed. See artifacts/party-*.' }
} finally {
    foreach ($entry in $processes) {
        if (-not $entry.Process.HasExited) { $entry.Process.Kill() }
        $entry.Process.Dispose()
    }
}
