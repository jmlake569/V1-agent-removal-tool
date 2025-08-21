# V1ES Agent Removal Script

A PowerShell script for removing Trend Micro V1ES (Vision One Endpoint Security) agents from Windows systems.

## Overview

This script provides a reliable method to uninstall V1ES agents by:
- Extracting the uninstaller from a local or network source
- Creating a scheduled task to run the uninstaller with SYSTEM privileges
- Monitoring the uninstall process and displaying logs
- Providing detailed error reporting and status updates

## Prerequisites

- **Windows PowerShell 5.0 or later**
- **Administrator privileges** (required for accessing C:\Windows\Temp and creating scheduled tasks)
- **V1ESUninstallTool.zip** file (either locally or on a network share)

## Usage

### Basic Usage (Local Uninstaller)

```powershell
# Run with default settings (uses C:\Windows\Temp\V1ESUninstallTool.zip)
.\remove-agent.ps1
```

### From Network Share

```powershell
# Pull uninstaller from a Windows share
.\remove-agent.ps1 -SharePath "\\server\share\V1ESUninstallTool.zip"
```

### Custom Extraction Path

```powershell
# Use custom extraction directory
.\remove-agent.ps1 -V1ESUninstPath "C:\CustomPath\V1ESUninstall\"
```

### Combined Options

```powershell
# Pull from share and use custom path
.\remove-agent.ps1 -SharePath "\\server\share\V1ESUninstallTool.zip" -V1ESUninstPath "C:\CustomPath\V1ESUninstall\"
```

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `V1ESUninstPath` | string | `C:\Windows\Temp\V1ESUninstall\` | Directory to extract uninstaller files |
| `SharePath` | string | `""` | Network path to V1ESUninstallTool.zip (optional) |

## How It Works

1. **Source Validation**: Checks if uninstaller exists locally or copies from network share
2. **Directory Creation**: Creates extraction directory if it doesn't exist
3. **File Extraction**: Extracts V1ESUninstallTool.zip to the specified directory
4. **EXE Detection**: Automatically finds the uninstaller executable
5. **Task Creation**: Creates a scheduled task to run uninstaller with SYSTEM privileges
6. **Process Monitoring**: Waits for uninstall to complete (up to 60 minutes)
7. **Log Display**: Shows relevant log files and completion status

## File Locations

### Default Paths
- **Uninstaller ZIP**: `C:\Windows\Temp\V1ESUninstallTool.zip`
- **Extraction Directory**: `C:\Windows\Temp\V1ESUninstall\`
- **Scheduled Task**: `V1ES Uninstall Task`

### Log Files Monitored
- `C:\Windows\Temp\V1ESUninst\V1ESUninstallTool.log`
- `C:\Windows\Temp\V1ESUninst\ComUnist.log`
- `C:\Windows\Temp\V1ESUninst\Log_CUT.log`
- `C:\Windows\Temp\V1ESUninst\DSA_CUT.log`
- `C:\Windows\Temp\XBCUninstaller.log`

## Running the Script

### Method 1: Direct Execution (Requires Admin)
```powershell
# Right-click PowerShell and "Run as Administrator"
.\remove-agent.ps1
```

### Method 2: Elevated Execution
```powershell
Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PWD\remove-agent.ps1`""
```

### Method 3: Execution Policy Bypass
```powershell
powershell -ExecutionPolicy Bypass -File ".\remove-agent.ps1"
```

## Expected Output

```
Using uninstaller from: C:\Windows\Temp\V1ESUninstallTool.zip
Package extracted.
Uninstaller EXE detected: C:\Windows\Temp\V1ESUninstall\V1ESUninstallTool.exe
Scheduled task [V1ES Uninstall Task] created. Waiting for uninstall to complete...
Task status: Running (Elapsed: 0 minutes)
Task status: Running (Elapsed: 0.5 minutes)
...
Uninstall task completed successfully!

===== C:\Windows\Temp\XBCUninstaller.log =====
[Log contents displayed here]

Press any key to close this window...
```

## Troubleshooting

### Common Issues

#### "Access is denied" Error
- **Cause**: Not running as Administrator
- **Solution**: Run PowerShell as Administrator

#### "Uninstaller zip not found"
- **Cause**: V1ESUninstallTool.zip missing from expected location
- **Solution**: Ensure file exists or use `-SharePath` parameter

#### "No EXE found in directory"
- **Cause**: Extraction failed or wrong file format
- **Solution**: Verify ZIP file integrity and contents

#### Task Creation Fails
- **Cause**: Insufficient permissions or task already exists
- **Solution**: Run as Administrator, check for existing tasks

### Error Codes

| Error | Meaning | Action |
|-------|---------|--------|
| `return code: 103` | Agent not found (already uninstalled) | Normal - agent successfully removed |
| `win_err=2` | Registry key not found | Normal - cleanup completed |
| `Access denied` | Permission issue | Run as Administrator |

## Monitoring Progress

The script provides real-time status updates:
- **Task status**: Shows if uninstaller is running
- **Elapsed time**: Tracks how long the process has been running
- **Log output**: Displays relevant log entries
- **Completion message**: Confirms successful uninstall

## Timeout Settings

- **Task delay**: 2 minutes (configurable in script)
- **Maximum wait time**: 60 minutes
- **Status check interval**: 30 seconds

## Security Considerations

- Script requires Administrator privileges
- Uninstaller runs with SYSTEM privileges
- Network shares should be properly secured
- Temporary files are cleaned up automatically

## Support

For issues with the script:
1. Check log files in `C:\Windows\Temp\XBCUninstaller.log`
2. Verify Administrator privileges
3. Ensure V1ESUninstallTool.zip is valid
4. Check network connectivity if using share path

## Version History

- **v1.0**: Initial release with local uninstaller support
- **v1.1**: Added Windows share support
- **v1.2**: Added progress monitoring and log display
- **v1.3**: Added window persistence and error handling 
