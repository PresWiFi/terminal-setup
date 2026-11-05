# Terminal Setup

Oh My Posh (M365Princess), Meslo Nerd Font, F-14 fastfetch screen, btop, and Iceberg Light / Calamity color schemes for Windows, macOS and Linux. Based on [this guide](https://unknown-technology.com/i-didnt-know-the-windows-terminal-could-look-this-good-fastfetch-oh-my-posh-more/). Installers are safe to re-run.

```
shared/    prompt theme, color schemes, fastfetch config (used by every platform)
windows/   PowerShell installer and profile
macos/     macOS installer
linux/     Linux installer
unix/      zsh profile and helpers shared by macOS and Linux
```

Clone somewhere permanent; the profile loads files from the clone. Re-run the installer if you move it.

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

If scripts are blocked: `powershell -ExecutionPolicy Bypass -File .\windows\Install-TerminalSetup.ps1`. Without winget it downloads portable builds to `%LOCALAPPDATA%\Programs\TerminalTools`. No admin needed.

## macOS

```sh
~/terminal-setup/macos/install.sh                 # add --opacity 80 for more see-through
```

- Installs Homebrew (if missing), `oh-my-posh`, `fastfetch`, `btop`.
- **iTerm2:** adds and defaults a "Terminal Setup" profile. Restart iTerm2.
- **Terminal.app:** sets the font (allow the automation prompt). `theme` only changes background, text and cursor here; use iTerm2 or [Ghostty](https://ghostty.org) for full themes.
- Switches the shell to zsh if needed (`--no-chsh` to skip).

## Linux

```sh
~/terminal-setup/linux/install.sh                 # asks for sudo
~/terminal-setup/linux/install.sh --no-chsh       # keep your current login shell
```

- apt, dnf, pacman, zypper.
- Installs zsh and **sets it as login shell** (`exec zsh` or log out/in).
- fastfetch/btop from the distro, else GitHub releases into `~/.local/bin`.
- Sets font and transparency in GNOME Terminal and Ptyxis. Elsewhere, set `MesloLGM Nerd Font` yourself.
- **WSL / SSH:** install the font on the machine running the terminal (Windows installer for WSL).

Appends one line to `~/.zshrc` to load `unix/profile.zsh`.

## Use

| Command       | Does                                          |
| ------------- | --------------------------------------------- |
| `theme`       | Toggle Iceberg Light ↔ Calamity               |
| `theme light` | Iceberg Light                                 |
| `theme dark`  | Calamity                                      |
| `ff`          | Show the F-14 system info screen again        |
| `btop`        | Live CPU/RAM/disk/network monitor (`q` quits) |

F-14 screen shows on new tabs (not in VS Code). On macOS/Linux the theme choice is saved in `~/.config/terminal-setup/theme`.

## Customize

| To change        | Edit                                                       |
| ---------------- | ---------------------------------------------------------- |
| Prompt           | `shared/M365Princess.omp.json` ([themes](https://ohmyposh.dev/docs/themes)) |
| F-14 info screen | `shared/fastfetch/config.jsonc`, `shared/fastfetch/f14-logo.txt` |
| Color schemes    | `shared/schemes.json` (on Windows, re-run the installer)    |
| Startup (Windows) | `windows/profile.ps1`                                     |
| Startup (macOS/Linux) | `unix/profile.zsh`                                    |

Edits apply to new tabs.
