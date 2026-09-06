param([string]$Engine = (Join-Path $PSScriptRoot 'godot\Godot_console.exe'), [string]$Address = '127.0.0.1')
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path -Parent $PSScriptRoot
$receiptPath = Join-Path $projectPath 'artifacts'
New-Item -ItemType Directory -Force -Path $receiptPath | Out-Null
$processes = @()
Write-Output "ENet three-process test: $Address port 27877"
try {
    foreach ($role in @('host', 'ghost', 'guest')) {
        $arguments = @('--headless', '--path', "`"$projectPath`"", '--script', 'res://tests/network_test.gd', '--', "--net-$role", $Address)
        $process = Start-Process -FilePath $Engine -ArgumentList $arguments -WindowStyle Hidden -PassThru `
            -RedirectStandardOutput (Join-Path $receiptPath "network-$role.log") `
            -RedirectStandardError (Join-Path $receiptPath "network-$role.err")
        $processes += @{ Role = $role; Process = $process }
        if ($role -eq 'host') { Start-Sleep -Milliseconds 500 }
    }
    $failed = $false
    foreach ($entry in $processes) {
        if (-not $entry.Process.WaitForExit(40000)) {
            $entry.Process.Kill()
            $failed = $true
            Write-Output "TIMEOUT: $($entry.Role)"
        }
        $entry.Process.Refresh()
        $output = Get-Content -LiteralPath (Join-Path $receiptPath "network-$($entry.Role).log") -Raw
        $errors = Get-Content -LiteralPath (Join-Path $receiptPath "network-$($entry.Role).err") -Raw
        Write-Output $output
        if ($errors) { Write-Output $errors }
        if ($entry.Process.ExitCode -ne 0 -or $output -notmatch 'checks, 0 failures' -or $errors -match 'SCRIPT ERROR|ERROR:|FAIL:') {
            $failed = $true
        }
    }
    if ($failed) { throw 'ENet lifecycle or routing tests failed; see artifacts/network-*.log and .err.' }
} finally {
    foreach ($entry in $processes) {
        if (-not $entry.Process.HasExited) { $entry.Process.Kill() }
        $entry.Process.Dispose()
    }
}
