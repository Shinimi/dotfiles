#!/usr/bin/env bash
# papirus-folders-color.sh <color> – builds ~/.local/share/icons/Papirus-Shinobu: Papirus-Dark with
# folders in another colour (blue, indigo, violet, cyan, teal, pink, magenta, green, grey, nordic). Made by Claude.
c="${1:-blue}"; base=/usr/share/icons/Papirus-Dark; out="$HOME/.local/share/icons/Papirus-Shinobu"
rm -rf "$out"; mkdir -p "$out"; dirs=()
for sd in "$base"/*/; do
  size=$(basename "$sd"); src="$(readlink -f "$sd")/places"; [ -d "$src" ] || continue
  mkdir -p "$out/$size/places"; dirs+=("$size/places")
  while IFS= read -r l; do
    t=$(readlink "$l"); n=$(basename "$l")
    case "$t" in *-blue*) nt="${t/-blue/-$c}"; [ -e "$src/$nt" ] && ln -s "$src/$nt" "$out/$size/places/$n" ;; esac
  done < <(find "$src" -maxdepth 1 -type l)
done
{
  echo "[Icon Theme]"; echo "Name=Papirus-Shinobu"; echo "Comment=Papirus-Dark with $c folders (made by Claude)"
  echo "Inherits=Papirus-Dark,breeze-dark,hicolor"
  printf 'Directories=%s\n' "$(IFS=,; echo "${dirs[*]}")"
  for d in "${dirs[@]}"; do
    s=${d%%x*}; s=${s%%@*}; sc=1; [[ $d == *@2x* ]] && sc=2
    printf '\n[%s]\nContext=Places\nSize=%s\nScale=%s\nType=Fixed\n' "$d" "$s" "$sc"
  done
} > "$out/index.theme"
gtk-update-icon-cache -q -f "$out" 2>/dev/null || true
echo "$out ($(find "$out" -type l | wc -l) folder icons, $c)"
