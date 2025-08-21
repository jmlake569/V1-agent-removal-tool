# =========================
# V1ES Uninstaller Script
# =========================

# Set as argument path for local V1ESUninstall package or Windows share
param (
    [string]$V1ESUninstPath = "C:\Windows\Temp\V1ESUninstall\",
    [string]$SharePath = ""
)

$V1ESUninstZip    = "C:\Windows\Temp\V1ESUninstallTool.zip"
$TaskName         = "V1ES Uninstall Task"

# If share path is provided, copy from share first
if ($SharePath -ne "") {
    Write-Host "Copying uninstaller from share: $SharePath"
    try {
        # Extract filename from share path
        $fileName = Split-Path $SharePath -Leaf
        $localZipPath = Join-Path $env:TEMP $fileName
        
        # Copy from share to local temp
        Copy-Item -Path $SharePath -Destination $localZipPath -Force
        Write-Host "Successfully copied from share to: $localZipPath"
        
        # Update the zip path to use the local copy
        $V1ESUninstZip = $localZipPath
    }
    catch {
        Write-Host "ERROR: Failed to copy from share: $($_.Exception.Message)"
        exit 1
    }
}

# Create directory if it doesn't exist
if (-not (Test-Path $V1ESUninstPath)) {
    try {
        New-Item -ItemType Directory -Path $V1ESUninstPath -Force | Out-Null
        Write-Host "Created directory: $V1ESUninstPath"
    }
    catch {
        Write-Host "ERROR: Cannot create directory $V1ESUninstPath. Run as Administrator."
        exit 1
    }
}

Write-Host "Using uninstaller from: $V1ESUninstZip"

# Check if zip file exists
if (Test-Path $V1ESUninstZip) {
    # Extract zip
    try {
        Expand-Archive -Path $V1ESUninstZip -DestinationPath $V1ESUninstPath -Force
        Write-Host "Package extracted."
    }
    catch {
        Write-Host "Error extracting archive: $($_.Exception.Message)"
        exit 1
    }
} else {
    Write-Host "ERROR: Uninstaller zip not found at: $V1ESUninstZip"
    exit 1
}

# Detect EXE dynamically (in case filename changes)
$V1ESUninstExe = Get-ChildItem -Path $V1ESUninstPath -Filter *.exe | Select-Object -First 1
if (-not $V1ESUninstExe) {
    Write-Host "ERROR: No EXE found in directory: $V1ESUninstPath"
    Write-Host "Available files:"
    Get-ChildItem -Path $V1ESUninstPath | ForEach-Object { Write-Host "  - $($_.Name)" }
    exit 1
}

Write-Host "Uninstaller EXE detected: $($V1ESUninstExe.FullName)"

# Create scheduled task to run with SYSTEM rights
$action    = New-ScheduledTaskAction -Execute $V1ESUninstExe.FullName
$trigger   = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(2)
$principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Register-ScheduledTask -Action $action -Principal $principal -Trigger $trigger -TaskName $TaskName -Settings $settings -Force
Write-Host "Scheduled task [$TaskName] created. Waiting for uninstall to complete..."

# Wait for scheduled task to finish
$maxWaitTime   = 3600  # seconds (60 minutes)
$checkInterval = 30    # seconds
$elapsedTime   = 0

while ($elapsedTime -lt $maxWaitTime) {
    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

    if (-not $task) {
        Write-Host "Task no longer exists, assuming uninstall finished."
        break
    }

    $taskState = $task.State
    Write-Host "Task status: $taskState (Elapsed: $($elapsedTime/60) minutes)"

    $taskInfo = Get-ScheduledTaskInfo -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($taskInfo.LastRunTime -and $taskInfo.LastTaskResult -eq 0) {
        Write-Host "Uninstall task completed successfully!"
        break
    }

    Start-Sleep -Seconds $checkInterval
    $elapsedTime += $checkInterval
}

if ($elapsedTime -ge $maxWaitTime) {
    Write-Host "WARNING: Maximum wait time reached. Uninstall may still be running."
}

# Display output logs if they exist
$logDir = "C:\Windows\Temp\V1ESUninst"
$logFiles = @(
    "$logDir\V1ESUninstallTool.log",
    "$logDir\ComUnist.log",
    "$logDir\Log_CUT.log",
    "$logDir\DSA_CUT.log",
    "C:\Windows\Temp\XBCUninstaller.log"
)

foreach ($log in $logFiles) {
    if (Test-Path $log) {
        Write-Host "`n===== $log ====="
        Get-Content -Path $log -Tail 50
    }
    else {
        Write-Host "`n(Log not found: $log)"
    }
}
