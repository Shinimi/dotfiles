# zsh · monochrome. Fetch first (before the instant prompt), then CachyOS's zsh + Powerlevel10k. Made by Claude.
[[ -o interactive && -z "$NO_FETCH" ]] && command -v frieren-fetch >/dev/null && frieren-fetch
source /usr/share/cachyos-zsh-config/cachyos-config.zsh

export PATH="$HOME/.local/bin:$PATH"
alias fetch=frieren-fetch si=frieren-fetch ff=fastfetch
# monochrome syntax highlighting / suggestions
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[command]='fg=255'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=255'
ZSH_HIGHLIGHT_STYLES[alias]='fg=255'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=167'
ZSH_HIGHLIGHT_STYLES[path]='fg=250,underline'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=245'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=245'
ZSH_HIGHLIGHT_STYLES[arg0]='fg=255'
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=240'
