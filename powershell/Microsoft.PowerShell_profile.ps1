# ======================
# OIVIA POWERSHELL PROFILE
# Inspired by zsh+kitty+oh-my-zsh workflow
# Optimized for ultra-fast loading with comprehensive lazy initialization
# ======================

# --- Performance Measurement ---
$ProfileLoadStart = Get-Date

# --- Cache for expensive operations ---
$global:ModuleCache = @{}
$global:CommandCache = @{}
$global:LazyInit = @{}

# --- Fast command check with caching ---
function Test-CommandExists {
    param([string]$Command)
    if ($global:CommandCache.ContainsKey($Command)) {
        return $global:CommandCache[$Command]
    }
    $exists = $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
    $global:CommandCache[$Command] = $exists
    return $exists
}

# --- Lazy module import ---
function Import-ModuleLazy {
    param([string]$ModuleName)
    if ($global:ModuleCache.ContainsKey($ModuleName)) {
        return $global:ModuleCache[$ModuleName]
    }
    
    $available = Get-Module -ListAvailable $ModuleName -ErrorAction SilentlyContinue
    if ($available) {
        try {
            Import-Module $ModuleName -ErrorAction SilentlyContinue
            $global:ModuleCache[$ModuleName] = $true
            return $true
        } catch {
            $global:ModuleCache[$ModuleName] = $false
            return $false
        }
    }
    $global:ModuleCache[$ModuleName] = $false
    return $false
}

# --- Lazy initialization wrapper ---
function Initialize-OnDemand {
    param([string]$Component, [scriptblock]$InitScript)
    if (-not $global:LazyInit.ContainsKey($Component)) {
        try {
            & $InitScript
            $global:LazyInit[$Component] = $true
        } catch {
            Write-Warning "Failed to initialize $Component`: $($_.Exception.Message)"
            $global:LazyInit[$Component] = $false
        }
    }
}

# --- Functions ---

function activate  { irm https://get.activated.win | iex }

function cpwd      { $PWD.Path | Set-Clipboard }

function fcd {
    $item = Get-ChildItem -Directory -Recurse | fzf
    if ($item) { Set-Location $item.FullName }
}

function ipinfo    { curl ifconfig.me }

function weather   { curl wttr.in }

function reload    { . $PROFILE; Write-Host "Profile reloaded." -ForegroundColor Green }

function proj {
    $dirs = Get-ChildItem "$HOME\git" -Directory | Select-Object -ExpandProperty FullName
    if ($dirs) {
        $target = $dirs | fzf
        if ($target) { Set-Location $target }
    }
}

function watch ($command, $interval = 2) {
    while ($true) {
        Clear-Host
        Invoke-Expression $command
        Start-Sleep -Seconds $interval
    }
}

function opend {
    $item = Get-ChildItem -Directory | fzf
    if ($item) { explorer $item.FullName }
}

function histf {
    $cmd = Get-Content $HOME\.histfile | fzf
    if ($cmd) { Invoke-Expression $cmd }
}

# --- Helper function for package installation ---
function Install-PackageWithFallback {
    param(
        [string]$PackageName,
        [string]$WingetId = $null,
        [string]$ScoopName = $null
    )
    
    $wingetPackage = if ($WingetId) { $WingetId } else { $PackageName }
    $scoopPackage = if ($ScoopName) { $ScoopName } else { $PackageName }
    
    Write-Host "Installing $PackageName..." -ForegroundColor Yellow
    
    # Try winget first
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        try {
            winget install $wingetPackage --accept-source-agreements --accept-package-agreements
            Write-Host "$PackageName installed via winget!" -ForegroundColor Green
            return $true
        } catch {
            Write-Host "Winget install failed, trying scoop..." -ForegroundColor Yellow
        }
    }
    
    # Fall back to scoop
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        try {
            scoop install $scoopPackage
            Write-Host "$PackageName installed via scoop!" -ForegroundColor Green
            return $true
        } catch {
            Write-Host "Scoop install failed" -ForegroundColor Red
        }
    }
    
    Write-Host "Failed to install $PackageName via winget or scoop" -ForegroundColor Red
    return $false
}

# --- PS Everything Functions ---
function Set-LocationFuzzyEverything {
    # Initialize PSFzf if not already done
    Initialize-PSFzf
    
    # Check and install fzf if missing
    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
        Install-PackageWithFallback -PackageName "fzf" -WingetId "junegunn.fzf" -ScoopName "fzf"
    }
    
    # Check and install PSEverything if missing
    if (-not (Get-Module -ListAvailable PSEverything)) {
        Write-Host "PSEverything module not found. Installing..." -ForegroundColor Yellow
        try {
            Set-PSRepository PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
            Install-Module PSEverything -Force -Scope CurrentUser -AllowClobber
            Import-Module PSEverything
            Write-Host "PSEverything installed successfully!" -ForegroundColor Green
        } catch {
            Write-Host "Failed to install PSEverything`: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Using local directory search as fallback..." -ForegroundColor Yellow
            $selected = Get-ChildItem -Directory -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName | fzf --prompt="Directory (Local) > "
            if ($selected) {
                Set-Location $selected
                Write-Host "Changed directory to: $selected" -ForegroundColor Green
            }
            return
        }
    }
    
    # Import PSEverything if not already loaded
    if (-not (Get-Module PSEverything)) {
        try {
            Import-Module PSEverything -ErrorAction Stop
        } catch {
            Write-Host "Failed to import PSEverything`: $($_.Exception.Message)" -ForegroundColor Red
            $selected = Get-ChildItem -Directory -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName | fzf --prompt="Directory (Local) > "
            if ($selected) {
                Set-Location $selected
                Write-Host "Changed directory to: $selected" -ForegroundColor Green
            }
            return
        }
    }
    
    # Try PSEverything search first
    try {
        $selected = Search-Everything -FolderInclude | Select-Object -ExpandProperty FullName | fzf --prompt="Directory > " --preview="ls {}"
        if ($selected) {
            Set-Location $selected
            Write-Host "Changed directory to: $selected" -ForegroundColor Green
        }
    } catch {
        Write-Host "PSEverything search failed. Make sure Everything is installed and running." -ForegroundColor Yellow
        Write-Host "Download Everything from: https://www.voidtools.com/" -ForegroundColor Cyan
        Write-Host "Using local directory search as fallback..." -ForegroundColor Yellow
        
        # Fallback to local search
        $selected = Get-ChildItem -Directory -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName | fzf --prompt="Directory (Local) > "
        if ($selected) {
            Set-Location $selected
            Write-Host "Changed directory to: $selected" -ForegroundColor Green
        }
    }
}

function Invoke-FuzzyGitStatus {
    # Initialize PSFzf if not already done
    Initialize-PSFzf
    
    # Check and install git if missing
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        if (Install-PackageWithFallback -PackageName "Git" -WingetId "Git.Git" -ScoopName "git") {
            Write-Host "Git installed! You may need to restart PowerShell to use it." -ForegroundColor Green
            return
        } else {
            Write-Host "Please install Git manually from https://git-scm.com/" -ForegroundColor Red
            return
        }
    }
    
    # Check and install fzf if missing
    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
        Install-PackageWithFallback -PackageName "fzf" -WingetId "junegunn.fzf" -ScoopName "fzf"
    }
    
    # Get git status with short format
    $gitStatus = git status --porcelain 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Not in a git repository." -ForegroundColor Yellow
        return
    }
    
    if (-not $gitStatus) {
        Write-Host "Working tree clean - no changes to show." -ForegroundColor Green
        return
    }
    
    # Parse git status and create selectable items
    $statusItems = $gitStatus | ForEach-Object {
        $status = $_.Substring(0, 2)
        $file = $_.Substring(3)
        "$status $file"
    }
    
    $selected = $statusItems | fzf --prompt="Git Status > " --preview="git diff --color=always {2}" --header="Select file to view diff"
    if ($selected) {
        $fileName = ($selected -split '\s+', 3)[2]
        git diff --color=always $fileName | more
    }
}

function Invoke-FuzzyScoop {
    # Initialize PSFzf if not already done
    Initialize-PSFzf
    
    # Check and install fzf if missing
    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
        Install-PackageWithFallback -PackageName "fzf" -WingetId "junegunn.fzf" -ScoopName "fzf"
    }
      # Check and install Scoop if missing (only if winget is not available or user specifically wants scoop)
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Write-Host "Scoop not found. Installing Scoop..." -ForegroundColor Yellow
        try {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
            Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
            Write-Host "Scoop installed successfully!" -ForegroundColor Green
            # Refresh PATH to make scoop available
            $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "User") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
        } catch {
            Write-Host "Failed to install Scoop: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Please install Scoop manually from https://scoop.sh/" -ForegroundColor Cyan
            return
        }
    }
    
    $action = @('search', 'install', 'uninstall', 'update', 'list', 'info', 'winget-search', 'winget-install') | fzf --prompt="Package Action > "
    
    switch ($action) {
        'winget-search' {
            if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
                Write-Host "Winget not available" -ForegroundColor Red
                return
            }
            $query = Read-Host "Enter search term"
            if ($query) {
                try {
                    winget search $query
                } catch {
                    Write-Host "Winget search failed: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
        'winget-install' {
            if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
                Write-Host "Winget not available" -ForegroundColor Red
                return
            }
            $packageId = Read-Host "Enter package ID"
            if ($packageId) {
                try {
                    winget install $packageId --accept-source-agreements --accept-package-agreements
                } catch {
                    Write-Host "Winget install failed: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
        'search' {
            $query = Read-Host "Enter search term"
            if ($query) {
                try {
                    $packages = scoop search $query | Select-String "^\s*(\S+)\s+" | ForEach-Object { $_.Matches[0].Groups[1].Value }
                    if ($packages) {
                        $selected = $packages | fzf --prompt="Select package > " --preview="scoop info {}"
                        if ($selected) {
                            $installChoice = Read-Host "Install $selected? (y/N)"
                            if ($installChoice -eq 'y' -or $installChoice -eq 'Y') {
                                scoop install $selected
                            }
                        }
                    } else {
                        Write-Host "No packages found for '$query'" -ForegroundColor Yellow
                    }
                } catch {
                    Write-Host "Search failed: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
        'install' {
            try {
                $packages = scoop search | Select-String "^\s*(\S+)\s+" | ForEach-Object { $_.Matches[0].Groups[1].Value }
                $selected = $packages | fzf --prompt="Install package > " --preview="scoop info {}"
                if ($selected) {
                    scoop install $selected
                }
            } catch {
                Write-Host "Install operation failed: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        'uninstall' {
            try {
                $installed = scoop list | Select-String "^\s*(\S+)\s+" | ForEach-Object { $_.Matches[0].Groups[1].Value }
                if ($installed) {
                    $selected = $installed | fzf --prompt="Uninstall package > "
                    if ($selected) {
                        $confirmChoice = Read-Host "Uninstall $selected? (y/N)"
                        if ($confirmChoice -eq 'y' -or $confirmChoice -eq 'Y') {
                            scoop uninstall $selected
                        }
                    }
                } else {
                    Write-Host "No packages installed" -ForegroundColor Yellow
                }
            } catch {
                Write-Host "Uninstall operation failed: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        'update' {
            try {
                $installed = scoop list | Select-String "^\s*(\S+)\s+" | ForEach-Object { $_.Matches[0].Groups[1].Value }
                if ($installed) {
                    $selected = $installed | fzf --prompt="Update package > " --multi
                    if ($selected) {
                        $selected | ForEach-Object { scoop update $_ }
                    } else {
                        scoop update
                    }
                } else {
                    Write-Host "No packages installed" -ForegroundColor Yellow
                }
            } catch {
                Write-Host "Update operation failed: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        'list' {
            try {
                scoop list | more
            } catch {
                Write-Host "List operation failed: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        'info' {
            try {
                $packages = scoop search | Select-String "^\s*(\S+)\s+" | ForEach-Object { $_.Matches[0].Groups[1].Value }
                $selected = $packages | fzf --prompt="Package info > " --preview="scoop info {}"
                if ($selected) {
                    scoop info $selected
                }
            } catch {
                Write-Host "Info operation failed: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}

# --- Aliases ---
Set-Alias code     "code-insiders"
Set-Alias c        clear
Set-Alias cls      clear
Set-Alias la       "ls -Force"
Set-Alias ll       "ls -al"
Set-Alias g        git
Set-Alias grep     "Select-String"
Set-Alias ..       "Set-Location .."
Set-Alias ...      "Set-Location ../.."
Set-Alias wsll     "wsl -d archlinux"
Set-Alias ep       "code-insiders $PROFILE"
Set-Alias pbcopy   Set-Clipboard
Set-Alias pbpaste  Get-Clipboard
Set-Alias sysinfo  systeminfo
Set-Alias cde      Set-LocationFuzzyEverything
Set-Alias fgs      Invoke-FuzzyGitStatus
Set-Alias fsc      Invoke-FuzzyScoop

# --- Quick directory jumping (zoxide integration) - Lazy ---
function z {
    Initialize-OnDemand "zoxide" {
        if (Test-CommandExists "zoxide") {
            Invoke-Expression (&zoxide init powershell | Out-String)
        } else {
            Write-Host "zoxide not found. Install with: winget install ajeetdsouza.zoxide" -ForegroundColor Yellow
        }
    }
    if (Test-CommandExists "zoxide") {
        &zoxide @args
    }
}

# --- PowerShell History and Syntax Highlighting / Suggestions - Lazy ---
function Initialize-PSReadLine {
    Initialize-OnDemand "PSReadLine" {
        if (-not (Get-Module -ListAvailable PSReadLine)) {
            Write-Host "PSReadLine module not found. Installing..." -ForegroundColor Yellow
            try {
                Set-PSRepository PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
                Install-Module PSReadLine -Force -Scope CurrentUser -AllowClobber
                Write-Host "PSReadLine installed successfully!" -ForegroundColor Green
            } catch {
                Write-Host "Failed to install PSReadLine`: $($_.Exception.Message)" -ForegroundColor Red
                return
            }
        }

        Import-Module PSReadLine -ErrorAction SilentlyContinue
        Set-PSReadLineOption -HistorySavePath "$HOME\.histfile"
        Set-PSReadLineOption -MaximumHistoryCount 10000
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin
        Set-PSReadLineOption -Colors @{
            Command   = 'Yellow'
            Parameter = 'Cyan'
            String    = 'Magenta'
            Operator  = 'Gray'
            Number    = 'Green'
            Variable  = 'White'
            Member    = 'DarkCyan'
            Error     = 'Red'
            Selection = 'DarkMagenta'
        }
    }
}

# Initialize PSReadLine immediately for core functionality
Initialize-PSReadLine

# --- Fuzzy Finder (PSFzf) Integration - Lazy ---
function Initialize-PSFzf {
    Initialize-OnDemand "PSFzf" {
        if (-not (Get-Module -ListAvailable PSFzf)) {
            Write-Host "PSFzf module not found. Installing..." -ForegroundColor Yellow
            try {
                Set-PSRepository PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
                Install-Module PSFzf -Force -Scope CurrentUser -AllowClobber
                Write-Host "PSFzf installed successfully!" -ForegroundColor Green
            } catch {
                Write-Host "Failed to install PSFzf`: $($_.Exception.Message)" -ForegroundColor Red
                return
            }
        }

        if (Get-Module -ListAvailable PSFzf) {
            Import-Module PSFzf -ErrorAction SilentlyContinue
            # Use Ctrl+r for reverse history search, but replace Ctrl+t with directory search
            Set-PsFzfOption -PSReadlineChordReverseHistory 'Ctrl+r' -ErrorAction SilentlyContinue
            Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion } -ErrorAction SilentlyContinue
            
            # Ctrl+T does the same as 'cde' command
            Set-PSReadLineKeyHandler -Key 'Ctrl+t' -ScriptBlock { Set-LocationFuzzyEverything } -ErrorAction SilentlyContinue
        }
    }
}

# --- Enhanced Tab Completion with Lazy Loading ---
function Invoke-LazyFzfTabCompletion {
    Initialize-PSFzf
    if (Get-Module PSFzf) {
        Invoke-FzfTabCompletion
    } else {
        # Fallback to default tab completion
        [Microsoft.PowerShell.PSConsoleReadLine]::TabCompleteNext()
    }
}

# Set lazy tab completion handler
try {
    Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-LazyFzfTabCompletion } -ErrorAction SilentlyContinue
} catch {
    # Fallback if PSReadLine not available
}

# Set up key handlers immediately but defer module loading
try {
    Set-PSReadLineKeyHandler -Key 'Ctrl+t' -ScriptBlock { 
        Initialize-PSFzf
        Set-LocationFuzzyEverything 
    } -ErrorAction SilentlyContinue
    
    Set-PSReadLineKeyHandler -Key 'Ctrl+r' -ScriptBlock {
        Initialize-PSFzf
        if (Get-Module PSFzf) {
            Invoke-FzfHistory
        }
    } -ErrorAction SilentlyContinue
} catch {
    # Fallback if PSReadLine not available
}

# --- posh-git Integration - Lazy ---
function Initialize-PoshGit {
    # Temporarily disabled due to module nesting error
    # Initialize-OnDemand "posh-git" {
    #     if (-not (Get-Module posh-git)) {
    #         if (Get-Module -ListAvailable posh-git) {
    #             Import-Module posh-git -ErrorAction SilentlyContinue
    #         }
    #     }
    # }
}

# Auto-initialize posh-git when using git commands
function git {
    Initialize-PoshGit
    $gitExe = (Get-Command git.exe -ErrorAction SilentlyContinue)?.Source
    if ($gitExe) {
        & $gitExe @args
    } else {
        Write-Error "git not found in PATH."
    }
}
# --- Optional: Show system info (flashfetch) - Deferred ---
function Show-SystemInfo {
    if (Test-CommandExists "flashfetch") {
        flashfetch
    }
}

# --- Prompt Timer, Welcome & Oh My Posh - Optimized ---
function Initialize-OhMyPosh {
    Initialize-OnDemand "oh-my-posh" {
        if (Test-CommandExists "oh-my-posh") {
            if (Test-Path "$env:POSH_THEMES_PATH\powerlevel10k_modern.omp.json") {
                Invoke-Expression (oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\powerlevel10k_modern.omp.json")
            } else {
                Invoke-Expression (oh-my-posh init pwsh)
            }
        }
    }
}

function Prompt {
    # Show timer for long-running commands
    if ($global:LASTPROMPTTIME) {
        $elapsed = [datetime]::Now - $global:LASTPROMPTTIME
        if ($elapsed.TotalSeconds -gt 1) {
            Write-Host "⏱  Last command time: $($elapsed.TotalSeconds) sec" -ForegroundColor Yellow
        }
    }
    
    # Show welcome message once
    if (-not $global:WELCOME_SHOWN) {
        Write-Host "Okaerinasai, $env:USERNAME! Today is $(Get-Date -Format 'dddd, MMM dd')" -ForegroundColor Green
        $quotes = @(
            "Remember, learn to unlearn!",
            "No Pein no Gain",
            "No Gacha no Life",
            "Do not commit to MAIN branch",
            "maimai is fun, it brings you a pleasure",
            "BREAK!!!",
            "Git push --force with caution =)"
        )
        $selectedQuote = $quotes | Get-Random
        if ($selectedQuote -eq "BREAK!!!") {
            $ansiColor = "`e[38;2;245;163;52m"  # #f5a334
            $reset = "`e[0m"
            Write-Host "${ansiColor}$selectedQuote$reset"
        } else {
            Write-Host $selectedQuote -ForegroundColor Cyan
        }
        $global:WELCOME_SHOWN = $true
        
        # Show system info on first prompt only
        Show-SystemInfo
    }
    
    $global:LASTPROMPTTIME = Get-Date
    
    # Initialize oh-my-posh on first prompt
    Initialize-OhMyPosh
    
    # Simple fallback prompt if oh-my-posh fails
    if (-not (Test-CommandExists "oh-my-posh")) {
        "PS $($PWD.Path)> "
    }
}

# --- Performance Measurement Complete ---
$ProfileLoadEnd = Get-Date
$LoadTime = ($ProfileLoadEnd - $ProfileLoadStart).TotalMilliseconds
if ($LoadTime -gt 100) {
    Write-Host "⚡ Profile loaded in $([math]::Round($LoadTime))ms" -ForegroundColor Yellow
}
prompt
