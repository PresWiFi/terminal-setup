# shellcheck shell=bash disable=SC2034
# Helpers shared by macos/install.sh and linux/install.sh. Sourced by bash, not run directly.

info() { printf '\033[36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33mWarning:\033[0m %s\n' "$*" >&2; }
die() { printf '\033[31mError:\033[0m %s\n' "$*" >&2; exit 1; }
has() { command -v "$1" >/dev/null 2>&1; }
: "${USER:=$(id -un)}"

parse_args() {
  OPACITY=90
  CHANGE_SHELL=1
  while [[ $# -gt 0 ]]; do
    case $1 in
      --opacity) OPACITY=${2:?--opacity needs a value}; shift ;;
      --opacity=*) OPACITY=${1#*=} ;;
      --no-chsh) CHANGE_SHELL=0 ;;
      -h | --help) sed -n '2,/^$/s/^# \{0,1\}//p' "$0"; exit 0 ;;
      *) die "Unknown option: $1 (see --help)" ;;
    esac
    shift
  done
  [[ $OPACITY =~ ^[0-9]+$ && $OPACITY -le 100 ]] || die '--opacity must be 0-100'
}

# Makes zsh the login shell. $1 is the command prefix for privileged calls ("sudo" or empty).
set_login_shell_zsh() {
  local sudo=$1 zsh current
  zsh=$(command -v zsh) || die 'zsh is not installed'
  if [[ $(uname) == Darwin ]]; then
    current=$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}')
  else
    current=$(getent passwd "$USER" | cut -d: -f7)
  fi
  if [[ $current == "$zsh" || $current == */zsh ]]; then
    info "Login shell is already zsh ($current)"
    return
  fi
  grep -qx "$zsh" /etc/shells || echo "$zsh" | $sudo tee -a /etc/shells >/dev/null
  info "Changing login shell from ${current:-unknown} to $zsh"
  $sudo chsh -s "$zsh" "$USER" || $sudo usermod -s "$zsh" "$USER" 2>/dev/null || warn "chsh failed. Run: chsh -s $zsh"
}

# Adds a line to ~/.zshrc that sources unix/profile.zsh. $1 is the repo root.
hook_zshrc() {
  local line="source '$1/unix/profile.zsh'"
  touch "$HOME/.zshrc"
  if ! grep -qxF "$line" "$HOME/.zshrc"; then
    printf '\n# Terminal setup (Oh My Posh, fastfetch, themes)\n%s\n' "$line" >>"$HOME/.zshrc"
    info "Added terminal setup to ~/.zshrc"
  fi
}

install_font() {
  info 'Installing Meslo Nerd Font'
  oh-my-posh font install meslo || warn 'Font install failed. Re-run, or install "MesloLGM Nerd Font" yourself.'
}
