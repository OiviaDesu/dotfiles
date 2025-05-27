# PowerShell Automated Setup Script
# Run this as administrator in a new PowerShell window!

Write-Host "Starting PowerShell dev environment bootstrap ..." -ForegroundColor Cyan

# -----------------------------
# BASIC CONFIGURATION (Update as needed)
# -----------------------------
$profileUrl = "https://URL-TO-YOUR-PROFILE"  # <-- Replace with your GIST RAW url if desired.

# -----------------------------
# 1. Winget Packages
# -----------------------------
$wingetPackages = @(
    "Microsoft.PowerShell",                  # PowerShell (latest)
    "Microsoft.WindowsTerminal",             # Windows Terminal
    "JanDeDobbeleer.OhMyPosh",               # Oh My Posh
    "JanDeDobbeleer.OhMyPosh.Themes",        # Oh My Posh themes
    "ajeetdsouza.zoxide",                    # zoxide
    "Git.Git",                               # Git
    "junegunn.fzf",                          # fzf
    "NerdFonts.Hack",                        # Hack Nerd Font (change or add your favorite)
    "flashfetch",                             # flashfetch (optional)
    "voidtools.Everything"                    # Everything (optional)
)

foreach ($pkg in $wingetPackages) {
    Write-Host "Installing $pkg from winget..." -ForegroundColor Gray
    winget install --id $pkg --silent --accept-source-agreements --accept-package-agreements
}

# -----------------------------
# 2. PowerShell Modules
# -----------------------------
$pwshModules = @(
    "posh-git",
    "PSReadLine",
    "PSFzf"
    "PSEverything"
)

foreach ($mod in $pwshModules) {
    Write-Host "Installing $mod PowerShell module..." -ForegroundColor Gray
    Install-Module $mod -Scope CurrentUser -Force -SkipPublisherCheck
}

# -----------------------------
# 3. Download $PROFILE (if provided)
# -----------------------------
if ($profileUrl -notlike "https://URL-TO-YOUR-PROFILE") {
    $profileDir = Split-Path -Parent $PROFILE
    if (-not (Test-Path $profileDir)) { New-Item -Path $profileDir -ItemType Directory | Out-Null }
    Write-Host "Downloading your PowerShell profile..." -ForegroundColor Gray
    Invoke-WebRequest $profileUrl -UseBasicParsing -OutFile $PROFILE
    Write-Host "Your PowerShell profile has been saved to $PROFILE" -ForegroundColor Green
} else {
    Write-Host "Please manually set your PowerShell profile later (`notepad $PROFILE`)." -ForegroundColor Yellow
}

# -----------------------------
# 4. Post-Install Messages
# -----------------------------
Write-Host ""
Write-Host "Setup complete!" -ForegroundColor Green
Write-Host "Open Windows Terminal > Settings > PowerShell profile, and set the font to a Nerd Font like 'Hack Nerd Font' for Oh My Posh icons."
Write-Host ""
Write-Host "To reload your new profile now, run:  . `$PROFILE"
Write-Host ""

# (Optional) Reload profile automatically
if (Test-Path $PROFILE) {
    . $PROFILE
    Write-Host "Profile loaded!"
} else {
    Write-Host "Profile not found, skipping reload."
}
