$ErrorActionPreference = "Stop"

$dotfilesRoot = "C:\Users\OneGa\git\dotfiles"

# Link Windows Terminal Preview settings
$wtPreviewPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"
$wtDotfilesPath = Join-Path $dotfilesRoot "windowsterminal\settings.json"

if (Test-Path $wtPreviewPath) {
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    Rename-Item $wtPreviewPath "$wtPreviewPath.bak.$timestamp"
}

New-Item -ItemType SymbolicLink -Path $wtPreviewPath -Target $wtDotfilesPath

Write-Host "Linked Windows Terminal Preview settings.json"

# Link PowerShell profile
$psProfile = $PROFILE
$psDotfilesProfile = Join-Path $dotfilesRoot "powershell\Microsoft.PowerShell_profile.ps1"

if (Test-Path $psProfile) {
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    Rename-Item $psProfile "$psProfile.bak.$timestamp"
}

New-Item -ItemType SymbolicLink -Path $psProfile -Target $psDotfilesProfile

Write-Host "Linked PowerShell profile"

Write-Host "Setup complete. Please restart Windows Terminal Preview."
Write-Host "Note: You may need to restart PowerShell or Windows Terminal for changes to take effect."