# ======================
# OIVIA POWERSHELL PROFILE
# Inspired by zsh+kitty+oh-my-zsh workflow
# ======================

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

# --- PS Everything Functions ---
function Set-LocationFuzzyEverything {
    if (-not (Get-Module -ListAvailable PSEverything)) {
        Write-Host "PSEverything module not found. Installing..." -ForegroundColor Yellow
        try {
            Install-Module PSEverything -Force -Scope CurrentUser
            Import-Module PSEverything
        } catch {
            Write-Host "Failed to install PSEverything. Using local directory search..." -ForegroundColor Yellow
            # Fallback to recursive directory search
            $selected = Get-ChildItem -Directory -Recurse | Select-Object -ExpandProperty FullName | fzf --prompt="Directory > "
            if ($selected) {
                Set-Location $selected
                Write-Host "Changed directory to: $selected" -ForegroundColor Green
            }
            return
        }
    }
    
    if (-not (Get-Module PSEverything)) {
        Import-Module PSEverything
    }
    
    try {
        $selected = Search-Everything -FolderInclude | Select-Object -ExpandProperty FullName | fzf --prompt="Directory > " --preview="ls {}"
        if ($selected) {
            Set-Location $selected
            Write-Host "Changed directory to: $selected" -ForegroundColor Green
        }
    } catch {
        Write-Host "PSEverything search failed. Make sure Everything is running." -ForegroundColor Red
        # Fallback
        $selected = Get-ChildItem -Directory -Recurse | Select-Object -ExpandProperty FullName | fzf --prompt="Directory > "
        if ($selected) {
            Set-Location $selected
            Write-Host "Changed directory to: $selected" -ForegroundColor Green
        }
    }
}

function Invoke-FuzzyGitStatus {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "Git not found. Please install Git first." -ForegroundColor Red
        return
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
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Write-Host "Scoop not found. Please install Scoop first from scoop.sh" -ForegroundColor Red
        return
    }
    
    $action = @('search', 'install', 'uninstall', 'update', 'list', 'info') | fzf --prompt="Scoop Action > "
    
    switch ($action) {
        'search' {
            $query = Read-Host "Enter search term"
            if ($query) {
                $packages = scoop search $query | Select-String "^\s*(\S+)\s+" | ForEach-Object { $_.Matches[0].Groups[1].Value }
                $selected = $packages | fzf --prompt="Select package > " --preview="scoop info {}"
                if ($selected) {
                    $installChoice = Read-Host "Install $selected? (y/N)"
                    if ($installChoice -eq 'y' -or $installChoice -eq 'Y') {
                        scoop install $selected
                    }
                }
            }
        }
        'install' {
            $packages = scoop search | Select-String "^\s*(\S+)\s+" | ForEach-Object { $_.Matches[0].Groups[1].Value }
            $selected = $packages | fzf --prompt="Install package > " --preview="scoop info {}"
            if ($selected) {
                scoop install $selected
            }
        }
        'uninstall' {
            $installed = scoop list | Select-String "^\s*(\S+)\s+" | ForEach-Object { $_.Matches[0].Groups[1].Value }
            $selected = $installed | fzf --prompt="Uninstall package > "
            if ($selected) {
                $confirmChoice = Read-Host "Uninstall $selected? (y/N)"
                if ($confirmChoice -eq 'y' -or $confirmChoice -eq 'Y') {
                    scoop uninstall $selected
                }
            }
        }
        'update' {
            $installed = scoop list | Select-String "^\s*(\S+)\s+" | ForEach-Object { $_.Matches[0].Groups[1].Value }
            $selected = $installed | fzf --prompt="Update package > " --multi
            if ($selected) {
                $selected | ForEach-Object { scoop update $_ }
            } else {
                scoop update
            }
        }
        'list' {
            scoop list | more
        }
        'info' {
            $packages = scoop search | Select-String "^\s*(\S+)\s+" | ForEach-Object { $_.Matches[0].Groups[1].Value }
            $selected = $packages | fzf --prompt="Package info > " --preview="scoop info {}"
            if ($selected) {
                scoop info $selected
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

# --- Quick directory jumping (zoxide integration) ---
Invoke-Expression (&zoxide init powershell | Out-String)

# --- PowerShell History and Syntax Highlighting / Suggestions ---
Import-Module PSReadLine
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

# --- Fuzzy Finder (PSFzf) Integration ---
if (Get-Module -ListAvailable PSFzf) {
    Import-Module PSFzf
    # Use Ctrl+r for reverse history search, but replace Ctrl+t with directory search
    Set-PsFzfOption -PSReadlineChordReverseHistory 'Ctrl+r'
    Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }
    
    # Ctrl+T does the same as 'cde' command
    Set-PSReadLineKeyHandler -Key 'Ctrl+t' -ScriptBlock { Set-LocationFuzzyEverything }
}

# --- posh-git Integration ---
if (Get-Module -ListAvailable posh-git) {
    Import-Module posh-git
}

# --- Optional: Show system info (flashfetch) ---
if (Get-Command flashfetch -ErrorAction SilentlyContinue) {
    flashfetch
}

# --- Prompt Timer, Welcome & Oh My Posh ---
function Prompt {
    if ($global:LASTPROMPTTIME) {
        $elapsed = [datetime]::Now - $global:LASTPROMPTTIME
        if ($elapsed.TotalSeconds -gt 1) {
            Write-Host "⏱  Last command time: $($elapsed.TotalSeconds) sec" -ForegroundColor Yellow
        }
    }
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
    }
    $global:LASTPROMPTTIME = Get-Date
    (oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\powerlevel10k_modern.omp.json" | Invoke-Expression)
}
Prompt
