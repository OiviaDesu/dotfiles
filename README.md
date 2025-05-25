# Dotfiles Management

This repository contains configuration files and scripts to manage your Windows Terminal and PowerShell profiles using symbolic links, backup, and restore functionality.

## Structure

- `backup.ps1`: Script to backup your current PowerShell profile and Windows Terminal settings to a specified folder.
- `restore.ps1`: Script to restore your PowerShell profile and Windows Terminal settings from a backup folder.
- `setup.ps1`: Script to link your Windows Terminal Preview settings and PowerShell profile to the dotfiles repository using symbolic links.
- `backup/`: Contains backup copies of PowerShell profile and Windows Terminal settings.
- `powershell/`: Contains the PowerShell profile script.
- `windowsterminal/`: Contains Windows Terminal settings files.

## Usage

### Setup

Before running any scripts, ensure that PowerShell script execution is permitted for the current user. Run this command in PowerShell:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

Run `setup.ps1` to create symbolic links from your Windows Terminal Preview and PowerShell profile locations to the dotfiles repository. This will backup existing files by renaming them with a timestamp.

```powershell
.\\setup.ps1
```

After running, restart Windows Terminal Preview and PowerShell to apply changes.

### Backup

Run `backup.ps1` to backup your current PowerShell profile and Windows Terminal settings to a folder you specify.

```powershell
.\\backup.ps1
```

You will be prompted to enter the backup folder path.

### Restore

Run `restore.ps1` to restore your PowerShell profile and Windows Terminal settings from a backup folder.

```powershell
.\\restore.ps1
```

You will be prompted to enter the backup folder path.

## Notes

- Ensure you run these scripts with appropriate permissions.
- Backups are timestamped to avoid overwriting.
- Windows Terminal Preview settings path is used in setup; backup and restore use Windows Terminal stable path.

## License

This repository is provided as-is without warranty.
