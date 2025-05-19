# Path to backup destination folder
$backupDir = Read-Host "Enter backup folder path (e.g. D:\dotfiles_backup)"

if (-not (Test-Path $backupDir)) {
    Write-Host "Backup folder does not exist. Creating..."
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
}

# Backup PowerShell profile
$profileSource = $PROFILE
$profileDest = Join-Path $backupDir "Microsoft.PowerShell_profile.ps1"

if (Test-Path $profileSource) {
    Copy-Item -Path $profileSource -Destination $profileDest -Force
    Write-Host "Backed up PowerShell profile to $profileDest"
} else {
    Write-Warning "PowerShell profile not found at $profileSource"
}

# Backup Windows Terminal settings
$wtSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
$wtSettingsDest = Join-Path $backupDir "windows-terminal-settings.json"

if (Test-Path $wtSettingsPath) {
    Copy-Item -Path $wtSettingsPath -Destination $wtSettingsDest -Force
    Write-Host "Backed up Windows Terminal settings to $wtSettingsDest"
} else {
    Write-Warning "Windows Terminal settings file not found at $wtSettingsPath"
}

Write-Host "Backup complete."
