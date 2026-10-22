source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end
export PATH="$HOME/.local/bin:$PATH"

# Tokyo Night prompt
if status is-interactive; and type -q starship
    starship init fish | source
end

# monochrome fetch on every new terminal (frieren-fetch); `fetch` / `si` run it again, `ff` = fastfetch. Made by Claude.
function fish_greeting
    frieren-fetch
end
alias fetch frieren-fetch
alias si frieren-fetch
alias ff fastfetch
