#!/usr/bin/env bash
# macOS terminal setup: Oh My Posh (M365Princess), Meslo Nerd Font, F-14 fastfetch, btop,
# and the Iceberg Light / Calamity themes for zsh. Safe to re-run.
# Configures iTerm2 (font, transparency, set as default profile) and Terminal.app (font) if present.
#
# Usage: ./macos/install.sh [--opacity 0-100] [--no-chsh]
#   --opacity N   iTerm2 background opacity (default 90)
#   --no-chsh     Don't switch your login shell to zsh if it's something else

set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=../unix/common.sh
. "$ROOT/unix/common.sh"
parse_args "$@"

[[ $(uname) == Darwin ]] || die 'This script is for macOS. On Linux use linux/install.sh.'
FONT_PS='MesloLGMNF-Regular'  # PostScript name of "MesloLGM Nerd Font"

# 1. Homebrew and tools
if ! has brew; then
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do [[ -x $b ]] && eval "$("$b" shellenv)" && break; done
fi
if ! has brew; then
  info 'Installing Homebrew (asks for your password)'
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do [[ -x $b ]] && eval "$("$b" shellenv)" && break; done
  has brew || die 'Homebrew install failed'
fi

for pair in oh-my-posh:jandedobbeleer/oh-my-posh/oh-my-posh fastfetch:fastfetch btop:btop; do
  cmd=${pair%%:*} formula=${pair#*:}
  if has "$cmd"; then info "$cmd already installed"; else info "Installing $cmd"; brew install "$formula"; fi
done

# 2. Nerd Font (installs to ~/Library/Fonts)
install_font

# 3. Terminal apps
if [[ -d /Applications/iTerm.app || -d "$HOME/Applications/iTerm.app" ]]; then
  guid=6E1F2C3A-7B4D-4F5E-9A8B-0C1D2E3F4A5B
  dir="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
  mkdir -p "$dir"
  cat >"$dir/terminal-setup.json" <<EOF
{
  "Profiles": [
    {
      "Name": "Terminal Setup",
      "Guid": "$guid",
      "Normal Font": "$FONT_PS 13",
      "Transparency": $(awk "BEGIN{print (100 - $OPACITY) / 100}"),
      "Blur": true,
      "Blur Radius": 10
    }
  ]
}
EOF
  defaults write com.googlecode.iterm2 'Default Bookmark Guid' -string "$guid"
  info 'iTerm2: added "Terminal Setup" profile and made it the default (restart iTerm2)'
fi

if osascript -e "tell application \"Terminal\" to set font name of default settings to \"$FONT_PS\"" \
  -e 'tell application "Terminal" to set font size of default settings to 13' >/dev/null 2>&1; then
  info 'Terminal.app: default profile font set'
else
  warn 'Could not set the Terminal.app font (allow Automation in System Settings > Privacy & Security)'
fi

# 4. zsh: load the profile (zsh is already the macOS default shell)
hook_zshrc "$ROOT"
[[ $CHANGE_SHELL -eq 1 ]] && set_login_shell_zsh ''

printf '\nDone. Open a new terminal window.\n'
exit 0
