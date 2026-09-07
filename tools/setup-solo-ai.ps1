param([switch]$Start, [switch]$InstallVoice)
# Optional native helpers only. No Python, cloud account, or modification to Sunrise.
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path -Parent $PSScriptRoot
$aiPath = Join-Path $PSScriptRoot 'ai'
New-Item -ItemType Directory -Force -Path $aiPath | Out-Null
New-Item -ItemType File -Force -Path (Join-Path $aiPath '.gdignore') | Out-Null
if ($InstallVoice) {
    $piperZip = Join-Path $aiPath 'piper_windows_amd64.zip'
    if (-not (Test-Path (Join-Path $aiPath 'piper/piper.exe'))) {
        Invoke-WebRequest 'https://github.com/rhasspy/piper/releases/download/2023.11.14-2/piper_windows_amd64.zip' -OutFile $piperZip
        Expand-Archive -LiteralPath $piperZip -DestinationPath $aiPath -Force
    }
    $whisperPath = Join-Path $aiPath 'whisper'
    if (-not (Test-Path (Join-Path $whisperPath 'Release/whisper-server.exe'))) {
        $release = Invoke-RestMethod 'https://api.github.com/repos/ggml-org/whisper.cpp/releases/tags/b4938'
        $asset = $release.assets | Where-Object name -eq 'whisper-bin-x64.zip'
        $archive = Join-Path $aiPath 'whisper-bin-x64.zip'
        Invoke-WebRequest $asset.browser_download_url -OutFile $archive
        Expand-Archive -LiteralPath $archive -DestinationPath $whisperPath -Force
        Write-Output "Whisper release: $($release.tag_name)"
    }
    $voicesPath = Join-Path $aiPath 'voices'
    New-Item -ItemType Directory -Force -Path $voicesPath | Out-Null
    foreach ($voiceName in @('en_US-lessac-medium', 'en_US-joe-medium', 'en_US-amy-medium', 'en_GB-alan-medium', 'en_US-ljspeech-medium', 'en_US-danny-low')) {
        $parts = $voiceName.Split('-')
        $language = $parts[0].Split('_')[0]
        $voiceUrl = "https://huggingface.co/rhasspy/piper-voices/resolve/main/$language/$($parts[0])/$($parts[1])/$($parts[2])"
        foreach ($suffix in @('.onnx', '.onnx.json')) {
            $destination = Join-Path $voicesPath ($voiceName + $suffix)
            if (Test-Path -LiteralPath $destination) { continue }
            $cached = Join-Path $env:APPDATA "Sunrise/piper_voices/$voiceName$suffix"
            if (Test-Path -LiteralPath $cached) { Copy-Item -LiteralPath $cached -Destination $destination }
            else { Invoke-WebRequest "$voiceUrl/$voiceName$suffix" -OutFile $destination }
        }
        $card = Join-Path $voicesPath "$voiceName-MODEL_CARD"
        if (-not (Test-Path -LiteralPath $card)) { Invoke-WebRequest "$voiceUrl/MODEL_CARD" -OutFile $card }
    }
    $speechModel = Join-Path $aiPath 'ggml-base.en.bin'
    if (-not (Test-Path -LiteralPath $speechModel)) {
        Invoke-WebRequest 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin' -OutFile $speechModel
    }
    Get-ChildItem -LiteralPath $voicesPath -Filter '*.onnx' | Get-FileHash -Algorithm SHA256 | Format-Table -AutoSize
}
if ($Start) {
    $server = Get-ChildItem -LiteralPath (Join-Path $aiPath 'whisper') -Filter 'whisper-server.exe' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    $speechModel = Join-Path $aiPath 'ggml-base.en.bin'
    if ($server -and (Test-Path -LiteralPath $speechModel) -and -not (Get-NetTCPConnection -State Listen -LocalPort 8179 -ErrorAction SilentlyContinue)) {
        Start-Process -FilePath $server.FullName -ArgumentList @('--host', '127.0.0.1', '--port', '8179', '-m', "`"$speechModel`"", '-t', '4') -WindowStyle Hidden | Out-Null
    }
    Write-Output 'Optional whisper.cpp requested on loopback port 8179. It remains running after the game exits. Start LM Studio local server on port 1234 separately; select LFM2.5-2.6B or Granite 4.1-3B. No LLM weights are downloaded.'
}
