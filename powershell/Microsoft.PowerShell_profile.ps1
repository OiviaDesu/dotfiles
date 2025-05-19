# Import-Module PSFzf

# Set-PSReadLineKeyHandler -Chord 'Ctrl+t' -ScriptBlock { Invoke-FzfTabCompletion }
# Set-PSReadLineKeyHandler -Chord 'Ctrl+r' -ScriptBlock { Invoke-FuzzyHistory }

# oh-my-posh init pwsh --config 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/powerlevel10k_modern.omp.json' | Invoke-Expression

# winfetch

# Aliases
Set-Alias c clear
Set-Alias cls clear
Set-Alias la "ls -Force"
Set-Alias ll "ls -al"
# Add more as needed

# Path Additions (if needed)
# $env:PATH += ";$HOME\.local\bin;$HOME\.npm-packages\bin;$HOME\.node\bin"

# PowerShell History Settings
Set-PSReadLineOption -HistorySavePath "$HOME\.histfile"
Set-PSReadLineOption -MaximumHistoryCount 1000

# PSFzf/fzf
if (Get-Module -ListAvailable PSFzf) {
    Import-Module PSFzf
    Set-PSReadLineKeyHandler -Chord 'Ctrl+r' -ScriptBlock { Invoke-FuzzyHistory }
    Set-PSReadLineKeyHandler -Chord 'Ctrl+t' -ScriptBlock { Invoke-FzfTabCompletion }
}

# Oh My Posh
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\powerlevel10k_modern.omp.json" | Invoke-Expression

# winfetch (optional/manual run to keep startup fast)
winfetch
