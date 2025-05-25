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
    Set-PSReadLineKeyHandler -Chord 'Ctrl+r' -ScriptBlock { Invoke-FuzzyHistory }
    Set-PSReadLineKeyHandler -Chord 'Ctrl+t' -ScriptBlock { Invoke-FzfTabCompletion }
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
