# WezTerm Setup on Windows

## 1. Install Tools

```powershell
winget install wez.wezterm
winget install Starship.Starship
winget install Fastfetch-cli.Fastfetch
winget install ajeetdsouza.zoxide
winget install junegunn.fzf
winget install aristocratos.btop4win
```

### Install a Nerd Font

1.  Download JetBrainsMono Nerd Font from [nerdfonts.com](https://www.nerdfonts.com)
2.  Extract the zip
3.  Select all `.ttf` files → Right click → **Install for all users**

## 2. Dotfiles Structure

Your dotfiles repo should contain:

```text
dotfiles/
├── wezterm_windows/
│   └── wezterm.lua
```

## 3. Create Symlinks (Run as Administrator)

Start PowerShell as Administrator:

```powershell
Start-Process powershell -Verb RunAs
```

In the elevated shell:

### WezTerm config

```powershell
New-Item -ItemType SymbolicLink -Path "C:\Users\christian.kornfeld\.wezterm.lua" -Target "C:\Users\christian.kornfeld\Source\Repos\dotfiles\wezterm_windows\wezterm.lua"
```

> [!NOTE]
> If any of these files already exist, delete them first:

```powershell
Remove-Item "C:\Users\christian.kornfeld\.wezterm.lua"
Remove-Item $PROFILE
```

## 4. PowerShell Profile

edit with `notepad $PROFILE`


```powershell
# Fastfetch on startup
fastfetch

# Starship prompt
Invoke-Expression (&starship init powershell)

# Zoxide (smarter cd)
Invoke-Expression (& { (zoxide init powershell | Out-String) })

# Fzf keybinding (Ctrl+R for fuzzy history search)
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineOption -PredictionViewStyle ListView

# Aliases
Set-Alias -Name ll -Value Get-ChildItem
```

---

### Restore on a new machine:
Clone your dotfiles repo, run the `winget` installs, install the Nerd Font, create the symlinks (as admin), and restart WezTerm. Done.