# WezTerm Setup on macOS

## 1. Install Tools

```bash
brew install --cask wezterm
brew install starship
brew install fastfetch
brew install zoxide
brew install fzf
brew install btop
```

### Install a Nerd Font

```bash
brew install --cask font-jetbrains-mono-nerd-font
```

## 2. Dotfiles Structure

Your dotfiles repo should contain:

```text
dotfiles/
├── wezterm_macos/
│   └── wezterm.lua
```

## 3. Create Symlinks

### WezTerm config

```bash
ln -sf ~/RiderProjects/dotfiles/wezterm_macos/wezterm.lua ~/.wezterm.lua
```

> [!NOTE]
> If the file already exists, delete it first:

```bash
rm ~/.wezterm.lua
```

## 4. Zsh Profile

Edit `~/.zshrc`:

```zsh
# Fastfetch on startup
fastfetch

# Starship prompt
eval "$(starship init zsh)"

# Zoxide (smarter cd)
eval "$(zoxide init zsh)"

# Fzf keybindings and completion
source <(fzf --zsh)

# Aliases
alias ll="ls -la"
```

---

### Restore on a new machine:
Clone your dotfiles repo, run the `brew` installs, create the symlink, and restart WezTerm. Done.
