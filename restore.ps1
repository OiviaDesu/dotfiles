# Path of your backup folder containing the dotfiles
$backupDir = Read-Host "Enter the backup folder path (e.g. D:\dotfiles_backup)"

if (-not (Test-Path $backupDir)) {
    Write-Error "Backup folder $backupDir does not exist. Exiting."
    exit 1
}

# Paths to original locations
$profileDest = $PROFILE
$profileSource = Join-Path $backupDir "Microsoft.PowerShell_profile.ps1"

$wtSettingsDest = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
$wtSettingsSource = Join-Path $backupDir "windows-terminal-settings.json"

# Restore PowerShell profile
if (Test-Path $profileSource) {
    # Backup existing profile before overwriting
    if (Test-Path $profileDest) {
        Rename-Item -Path $profileDest -NewName ("Microsoft.PowerShell_profile_backup_" + (Get-Date -Format "yyyyMMddHHmmss") + ".ps1")
        Write-Host "Backed up existing profile before restoring."
    }

    Copy-Item -Path $profileSource -Destination $profileDest -Force
    Write-Host "Restored PowerShell profile from backup."
} else {
    Write-Warning "Backup PowerShell profile not found at $profileSource"
}

# Restore Windows Terminal settings
if (Test-Path $wtSettingsSource) {
    if (Test-Path $wtSettingsDest) {
        Rename-Item -Path $wtSettingsDest -NewName ("settings_backup_" + (Get-Date -Format "yyyyMMddHHmmss") + ".json")
        Write-Host "Backed up existing Windows Terminal settings before restoring."
    }

    Copy-Item -Path $wtSettingsSource -Destination $wtSettingsDest -Force
    Write-Host "Restored Windows Terminal settings from backup."
} else {
    Write-Warning "Backup Windows Terminal settings not found at $wtSettingsSource"
}

Write-Host "Restore complete."

# Note: After restoring, you may need to restart PowerShell or Windows Terminal for changes to take effect.