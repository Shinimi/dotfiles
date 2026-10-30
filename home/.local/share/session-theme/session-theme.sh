#!/usr/bin/env bash
# session-theme.sh mono|purple — your apps follow the desktop you log into: black in Hyprland (mono), purple in Niri.
# Same designs in both; only the colours change.
# Puts that set of theme files in place (GTK, kitty, Discord, the browser theme + new tab, Spotify) and switches
# the Qt/KDE colour scheme (Dolphin, Kate…) and Steam's accent. Hyprland and Niri each run it at login.
# Files: files.txt lists them; mono/ is the black set, purple/ is made from it by recolor.py. Made by Claude.
set -u
T="$HOME/.local/share/session-theme"
mode=${1:-}; [ "$mode" = mono ] || [ "$mode" = purple ] || { echo "usage: session-theme.sh mono|purple" >&2; exit 2; }
[ "$(cat "$T/current" 2>/dev/null)" = "$mode" ] && [ "${2:-}" != --force ] && exit 0

changed=()
while read -r f; do
  [ -z "$f" ] && continue
  src="$T/$mode/$f"; dst="$HOME/$f"
  [ -f "$src" ] || continue
  cmp -s "$src" "$dst" || { cp "$src" "$dst"; changed+=("$f"); }
done < "$T/files.txt"
has() { printf '%s\n' "${changed[@]}" | grep -q "$1"; }

# Qt / KDE apps (Dolphin, Ark, Kate…): the colour scheme, live
scheme=$([ "$mode" = purple ] && echo Purple || echo Monochrome)
plasma-apply-colorscheme "$scheme" >/dev/null 2>&1

# kitty: reload the colours in every open window
has kitty && pkill -USR1 -x kitty 2>/dev/null

# browsers: the theme is cached; drop the cache so the next start reads the new colours
has mono-chrome && rm -f "$HOME/.local/share/mono-chrome/Cached Theme.pak"

# Steam (Millennium): the accent colour (applies the next time Steam starts)
python3 -I - "$HOME/.config/millennium/config.json" "$mode" <<'PY'
import json, sys
p, mode = sys.argv[1:]
try:
    d = json.load(open(p))
except OSError:
    sys.exit()
d.setdefault("general", {})["accentColor"] = "#B392F0" if mode == "purple" else "#BDBDBD"
json.dump(d, open(p, "w"), indent=4)
PY

# Spotify (Spicetify): your Monochrome theme with its black [Night] or [Purple] colours. The colours are built into
# Spotify, so re-apply (quietly; Spotify picks it up the next time it starts)
if [ "$mode" = purple ]; then st="Monochrome Purple"; else st="Monochrome Night"; fi
set -- $st
if [ "$(spicetify config current_theme 2>/dev/null)" != "$1" ] || [ "$(spicetify config color_scheme 2>/dev/null)" != "$2" ]; then
  (spicetify config current_theme "$1" color_scheme "$2" -q && spicetify apply -n -q) >/dev/null 2>&1 &
fi

echo "$mode" > "$T/current"
