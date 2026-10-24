# Sourced from ~/.zshrc by the macOS and Linux installers. Edits here apply to every new tab.

TERMINAL_SETUP_SHARED=${${(%):-%x}:A:h:h}/shared
TERMINAL_SETUP_STATE=${XDG_CONFIG_HOME:-$HOME/.config}/terminal-setup/theme
typeset -gA TERMINAL_THEMES=(light 'Iceberg Light' dark 'Calamity')

[[ -d $HOME/.local/bin && :$PATH: != *:$HOME/.local/bin:* ]] && path=($HOME/.local/bin $path)

# Basic zsh defaults, mainly for people coming from bash. Your own ~/.zshrc settings after this line win.
HISTFILE=${HISTFILE:-$HOME/.zsh_history}
HISTSIZE=10000
SAVEHIST=10000
setopt share_history hist_ignore_dups hist_ignore_space
(( $+functions[compdef] )) || { autoload -Uz compinit && compinit }
bindkey -e

if (( $+commands[oh-my-posh] )); then
  eval "$(oh-my-posh init zsh --config $TERMINAL_SETUP_SHARED/M365Princess.omp.json)"
fi

# Shows the F-14 fastfetch screen. Runs on startup; type `ff` to show it again.
# The logo path is passed here because the config's %VAR% path only expands on Windows.
ff() {
  fastfetch --config $TERMINAL_SETUP_SHARED/fastfetch/config.jsonc \
    --logo-type file --logo $TERMINAL_SETUP_SHARED/fastfetch/f14-logo.txt "$@"
}

# Prints "key #hex" pairs for one scheme in schemes.json.
_terminal_setup_scheme() {
  awk -v want="$1" '
    /"name"/ { split($0, a, "\""); cur = a[4]; next }
    cur == want && /"#/ { split($0, a, "\""); print a[2], a[4] }
  ' $TERMINAL_SETUP_SHARED/schemes.json
}

# Recolors the current tab with xterm escape codes (iTerm2, Ghostty, GNOME Terminal, Konsole,
# kitty, WezTerm, Alacritty, Windows Terminal/WSL). Terminal.app ignores the palette codes,
# so there it also updates the profile's background, text, and cursor colors.
_terminal_setup_apply() {
  local name=$1 key hex out=
  local -A ansi=(black 0 red 1 green 2 yellow 3 blue 4 purple 5 cyan 6 white 7)
  local -A rgb
  while read -r key hex; do
    case $key in
      bright*) out+="\e]4;$(( ansi[${(L)key#bright}] + 8 ));$hex\a" ;;
      background) out+="\e]11;$hex\a"; rgb[bg]=$hex ;;
      foreground) out+="\e]10;$hex\a"; rgb[fg]=$hex ;;
      cursorColor) out+="\e]12;$hex\a"; rgb[cursor]=$hex ;;
      selectionBackground) out+="\e]17;$hex\a" ;;
      *) (( $+ansi[$key] )) && out+="\e]4;$ansi[$key];$hex\a" ;;
    esac
  done < <(_terminal_setup_scheme $name)
  [[ -n $out ]] || { print -u2 "Scheme not found in schemes.json: $name"; return 1 }
  [[ -t 1 ]] && print -n -- $out

  if [[ $TERM_PROGRAM == Apple_Terminal && $2 == persist ]]; then
    local -A as  # AppleScript colors are 16-bit {r, g, b}
    for key hex in ${(kv)rgb}; do
      as[$key]="{$(( 16#${hex:1:2} * 257 )), $(( 16#${hex:3:2} * 257 )), $(( 16#${hex:5:2} * 257 ))}"
    done
    osascript >/dev/null <<EOF || print -u2 'Could not update Terminal.app colors (allow Automation in System Settings > Privacy).'
tell application "Terminal"
  repeat with s in {default settings, current settings of selected tab of front window}
    set background color of s to $as[bg]
    set normal text color of s to $as[fg]
    set cursor color of s to $as[cursor]
  end repeat
end tell
EOF
  fi
}

# Switches between Iceberg Light and Calamity. No argument toggles. Example: theme dark
theme() {
  local mode=${1:-toggle} current
  current=$(cat $TERMINAL_SETUP_STATE 2>/dev/null)
  [[ $mode == toggle ]] && { [[ $current == dark ]] && mode=light || mode=dark }
  if (( ! $+TERMINAL_THEMES[$mode] )); then
    print -u2 'Usage: theme [light|dark|toggle]'; return 1
  fi
  mkdir -p ${TERMINAL_SETUP_STATE:h} && print $mode > $TERMINAL_SETUP_STATE
  _terminal_setup_apply $TERMINAL_THEMES[$mode] persist && print "Terminal theme: $TERMINAL_THEMES[$mode]"
}

if [[ -o interactive && $TERM_PROGRAM != vscode ]]; then
  # Terminal.app keeps colors in its profile, so only re-send them elsewhere.
  if [[ $TERM_PROGRAM != Apple_Terminal ]]; then
    () {
      local mode=$(cat $TERMINAL_SETUP_STATE 2>/dev/null)
      [[ $mode == (light|dark) ]] || mode=light
      _terminal_setup_apply $TERMINAL_THEMES[$mode]
    }
  fi
  (( $+commands[fastfetch] )) && ff
fi
