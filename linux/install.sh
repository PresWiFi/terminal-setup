#!/usr/bin/env bash
# Linux terminal setup: zsh (made your login shell), Oh My Posh (M365Princess), Meslo Nerd Font,
# F-14 fastfetch, btop, and the Iceberg Light / Calamity themes. Safe to re-run.
# Works with apt, dnf, pacman, and zypper. Tools your distro doesn't package come from GitHub.
#
# Usage: ./linux/install.sh [--opacity 0-100] [--no-chsh]
#   --opacity N   Terminal background opacity for GNOME Terminal / Ptyxis (default 90)
#   --no-chsh     Install everything but keep your current login shell

set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=../unix/common.sh
. "$ROOT/unix/common.sh"
parse_args "$@"

[[ $(uname) == Linux ]] || die 'This script is for Linux. On macOS use macos/install.sh.'
if [[ $EUID -eq 0 ]]; then SUDO=''; elif has sudo; then SUDO=sudo; else die 'Needs root or sudo to install packages.'; fi
IS_WSL=0; [[ -n ${WSL_DISTRO_NAME:-} || -e /proc/sys/fs/binfmt_misc/WSLInterop ]] && IS_WSL=1

BIN=$HOME/.local/bin
mkdir -p "$BIN"
export PATH="$BIN:$PATH"

case $(uname -m) in
  x86_64 | amd64) ARCH_GO=amd64 ARCH_FF=amd64 ARCH_BTOP=x86_64 ;;
  aarch64 | arm64) ARCH_GO=arm64 ARCH_FF=aarch64 ARCH_BTOP=aarch64 ;;
  *) ARCH_GO='' ;;
esac

# 1. Packages
if has apt-get; then
  PM=apt
  pm_install() { $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$@"; }
  $SUDO apt-get update -qq
elif has dnf; then
  PM=dnf; pm_install() { $SUDO dnf install -y -q "$@"; }
elif has pacman; then
  PM=pacman; pm_install() { $SUDO pacman -S --needed --noconfirm "$@"; }
elif has zypper; then
  PM=zypper; pm_install() { $SUDO zypper --non-interactive install "$@"; }
else
  die 'No supported package manager (apt, dnf, pacman, zypper) found.'
fi
info "Installing zsh and basics with $PM"
base=(zsh git curl unzip tar fontconfig)
[[ $PM == dnf ]] && base+=(util-linux-user)  # provides chsh on Fedora
[[ $PM == apt ]] && base+=(ca-certificates)
pm_install "${base[@]}"

# fastfetch and btop: try the distro package first (older releases like Ubuntu 24.04 lack fastfetch)
for pkg in fastfetch btop; do
  has "$pkg" && { info "$pkg already installed"; continue; }
  pm_install "$pkg" >/dev/null 2>&1 && has "$pkg" && { info "Installed $pkg with $PM"; continue; }
  [[ -n $ARCH_GO ]] || { warn "No $pkg package and no GitHub build for $(uname -m); skipping"; continue; }

  info "Downloading $pkg from GitHub"
  tmp=$(mktemp -d)
  if [[ $pkg == fastfetch ]]; then
    curl -fsSL "https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-$ARCH_FF.tar.gz" | tar xz -C "$tmp"
    install -m 755 "$tmp/fastfetch-linux-$ARCH_FF/usr/bin/fastfetch" "$BIN/fastfetch"
  else
    curl -fsSL "https://github.com/aristocratos/btop/releases/latest/download/btop-$ARCH_BTOP-unknown-linux-musl.tar.gz" | tar xz -C "$tmp"
    install -m 755 "$tmp/btop/bin/btop" "$BIN/btop"
    mkdir -p "$HOME/.local/share/btop" && cp -r "$tmp/btop/themes" "$HOME/.local/share/btop/"
  fi
  rm -rf "$tmp"
done

if has oh-my-posh; then
  info 'oh-my-posh already installed'
else
  [[ -n $ARCH_GO ]] || die "No Oh My Posh build for $(uname -m)"
  info 'Downloading oh-my-posh from GitHub'
  curl -fsSL -o "$BIN/oh-my-posh" "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-$ARCH_GO"
  chmod +x "$BIN/oh-my-posh"
fi

# 2. Nerd Font. Under WSL the font comes from Windows (run windows/Install-TerminalSetup.ps1 there).
if [[ $IS_WSL -eq 1 ]]; then
  info 'WSL detected: skipping font, Windows Terminal uses the Windows font'
else
  install_font
  if has fc-cache; then fc-cache -f >/dev/null 2>&1 || true; fi
fi

# 3. Terminal font and transparency (GNOME Terminal and Ptyxis; others are listed in the README)
if [[ $IS_WSL -eq 0 && -n ${DBUS_SESSION_BUS_ADDRESS:-} ]] && has gsettings; then
  schemas=$(gsettings list-schemas 2>/dev/null || true)
  if grep -qx org.gnome.Terminal.ProfilesList <<<"$schemas"; then
    id=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")
    p="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$id/"
    gsettings set "$p" use-system-font false &&
      gsettings set "$p" font 'MesloLGM Nerd Font 12' &&
      gsettings set "$p" use-transparent-background true &&
      gsettings set "$p" background-transparency-percent $((100 - OPACITY)) &&
      info 'GNOME Terminal configured' || warn 'Could not configure GNOME Terminal'
  fi
  if grep -qx org.gnome.Ptyxis <<<"$schemas"; then
    id=$(gsettings get org.gnome.Ptyxis default-profile-uuid | tr -d "'")
    gsettings set org.gnome.Ptyxis use-system-font false &&
      gsettings set org.gnome.Ptyxis font-name 'MesloLGM Nerd Font 12' &&
      gsettings set "org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/$id/" opacity "$(awk "BEGIN{print $OPACITY/100}")" &&
      info 'Ptyxis configured' || warn 'Could not configure Ptyxis'
  fi
fi

# 4. zsh: load the profile and make it the login shell
hook_zshrc "$ROOT"
[[ $CHANGE_SHELL -eq 1 ]] && set_login_shell_zsh "$SUDO"

printf '\nDone. Log out and back in (or run: exec zsh) to start using zsh.\n'
[[ $IS_WSL -eq 0 ]] && echo 'If your terminal is not GNOME Terminal or Ptyxis, set its font to "MesloLGM Nerd Font".'
exit 0
