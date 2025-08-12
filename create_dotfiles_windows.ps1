Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Check if running as admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Restarting script as Administrator..."
    Start-Process powershell -Verb runAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

# --- Script continues here with admin rights ---
Write-Host "Running with Administrator privileges."

$homedir = $env:USERPROFILE
$dotfiles = "$homedir\source\repos\dotfiles"

Move-Item "$homedir\.ideavimrc" "$dotfiles\ideavim\.ideavimrc" -ErrorAction SilentlyContinue
New-Item -ItemType SymbolicLink -Path "$homedir\.ideavimrc" -Target "$dotfiles\ideavim\.ideavimrc" -Force

Move-Item "$homedir\Documents\AutoHotkey\Untitled.ahk" "$dotfiles\ahk\Untitled.ahk" -ErrorAction SilentlyContinue 
New-Item -ItemType SymbolicLink -Path "$homedir\Documents\AutoHotkey\Untitled.ahk" -Target "$dotfiles\ahk\Untitled.ahk" -Force

