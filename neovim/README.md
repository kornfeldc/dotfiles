# Windows
1. Install neovim
2. Install a c compiler
    ```bash
    choco install mingw
    ```
    If this is not working, then try this in an Admin Powershell
    ```ps
    # 1) kill any stuck chocolatey processes
    Get-Process choco*, msiexec -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

    # 2) remove the global lock file (safe when no choco process is running)
    Remove-Item -Force 'C:\ProgramData\chocolatey\chocolateyinstall.lock' -ErrorAction SilentlyContinue

    # 3) (optional) ensure choco itself is fine
    choco upgrade chocolatey -y
    choco install mingw
    ```
3. Install the [JetBrainsMono Nerd Font](https://www.nerdfonts.com/font-downloads)
4. Install lazyvim 
   * Clone the starter
       ```bash
       git clone https://github.com/LazyVim/starter ~/.config/nvim
       ```
   * (opt: Remove the .git folder, so you can add it to your own repo later)
5. Install [Neovide](https://neovide.dev/)
6. Setup symlinks for the dotfiles
7. Optional: create the registry entry for "Open in neovide" context menu