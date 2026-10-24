# Terminal Setup

Oh My Posh + fastfetch + btop for Windows, macOS, and Linux, based on [this guide](https://unknown-technology.com/i-didnt-know-the-windows-terminal-could-look-this-good-fastfetch-oh-my-posh-more/). Each installer sets up the M365Princess prompt, the Meslo Nerd Font, the F-14 fastfetch screen, btop, and the Iceberg Light / Calamity color schemes. All of them are safe to re-run.

```
shared/    prompt theme, color schemes, fastfetch config (used by every platform)
windows/   PowerShell installer and profile
macos/     macOS installer
linux/     Linux installer
unix/      zsh profile and helpers shared by macOS and Linux
```

Clone the repo somewhere permanent first. The shell profile loads files from the clone, so don't delete or move it afterwards. If you do move it, re-run the installer.

```sh
git clone https://github.com/PresWiFi/terminal-setup.git ~/terminal-setup
```

## Windows

In PowerShell 7 or Windows PowerShell 5.1:

```powershell
.\windows\Install-TerminalSetup.ps1               # Windows Terminal + both PowerShell profiles
.\windows\Install-TerminalSetup.ps1 -Opacity 80   # more see-through
.\windows\Install-TerminalSetup.ps1 -NoWinget     # skip winget
```

If scripts are blocked, run `powershell -ExecutionPolicy Bypass -File .\windows\Install-TerminalSetup.ps1`. If winget is missing or fails, the installer downloads portable builds from GitHub into `%LOCALAPPDATA%\Programs\TerminalTools`. It doesn't need admin rights.

## macOS

```sh
~/terminal-setup/macos/install.sh                 # add --opacity 80 for more see-through
```

- Installs Homebrew if it's missing, then `oh-my-posh`, `fastfetch`, and `btop`.
- **iTerm2** (if installed): adds a "Terminal Setup" profile with the font and transparency and makes it the default. Restart iTerm2 afterwards.
- **Terminal.app**: sets the font. macOS may ask to allow Terminal to control Terminal; say yes. Terminal.app can't change its 16-color palette from a script, so `theme` only switches the background, text, and cursor colors there. For the full themes, use iTerm2 or [Ghostty](https://ghostty.org).
- zsh is already the default shell on macOS. If yours isn't, the installer switches it (`--no-chsh` to skip).

## Linux

```sh
~/terminal-setup/linux/install.sh                 # asks for sudo
~/terminal-setup/linux/install.sh --no-chsh       # keep your current login shell
```

- Works with apt (Debian, Ubuntu), dnf (Fedora), pacman (Arch), and zypper (openSUSE).
- Installs zsh and **makes it your login shell**. Log out and back in, or run `exec zsh`.
- Installs fastfetch and btop from your distro, or from GitHub releases into `~/.local/bin` if your distro doesn't package them (Ubuntu 24.04 has no fastfetch, for example).
- Sets the font and transparency in **GNOME Terminal** and **Ptyxis**. For other terminals (Konsole, kitty, Alacritty, ...), set the font to `MesloLGM Nerd Font` yourself.
- **WSL**: the font isn't installed inside Linux, because Windows Terminal draws it. Run the Windows installer on the Windows side to get the font.
- If you install over SSH, install the font on the computer you're connecting *from*.

Your existing `~/.zshrc` is kept. The installer adds one line at the end that loads `unix/profile.zsh`.

## Use

| Command       | Does                                          |
| ------------- | --------------------------------------------- |
| `theme`       | Toggle Iceberg Light ↔ Calamity               |
| `theme light` | Iceberg Light                                 |
| `theme dark`  | Calamity                                      |
| `ff`          | Show the F-14 system info screen again        |
| `btop`        | Live CPU/RAM/disk/network monitor (`q` quits) |

The prompt shows your user, folder, git branch, and time. The F-14 screen shows when a tab opens (not in VS Code's terminal).

On Windows, `theme` changes Windows Terminal's settings. On macOS and Linux it recolors the terminal with escape codes and remembers your choice in `~/.config/terminal-setup/theme`, so new tabs open in the same theme.

## Customize

| To change        | Edit                                                       |
| ---------------- | ---------------------------------------------------------- |
| Prompt           | `shared/M365Princess.omp.json` ([themes](https://ohmyposh.dev/docs/themes)) |
| F-14 info screen | `shared/fastfetch/config.jsonc`, `shared/fastfetch/f14-logo.txt` |
| Color schemes    | `shared/schemes.json` (on Windows, re-run the installer)    |
| Startup (Windows) | `windows/profile.ps1`                                     |
| Startup (macOS/Linux) | `unix/profile.zsh`                                    |

The profiles load these files straight from the repo, so your edits apply to new tabs.
