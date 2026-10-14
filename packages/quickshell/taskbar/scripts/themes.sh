#!/usr/bin/env bash
# Dotfiles themes for the Shell Manager.
# Prints one line per theme: "<name> <colour per role in $roles>"
# (from themes/<name>/quickshell/taskbar/config/Colors.qml), then "---" and the
# active theme (.theme, gruvbox when absent).
set -u
cd "$HOME/.dotfiles" || exit 1
roles=(background0 background1 background3 frame foreground0 foreground2 muted gray red yellow green blue)
for dir in themes/*/; do
  name=$(basename "$dir")
  file="$dir/quickshell/taskbar/config/Colors.qml"
  line=$name
  for role in "${roles[@]}"; do
    hex=$(sed -n "s/.*property color $role: *\"\(#[0-9a-fA-F]\{6\}\)\".*/\1/p" "$file" 2>/dev/null | head -1)
    line+=" ${hex:-#000000}"
  done
  echo "$line"
done
echo ---
cat .theme 2>/dev/null || echo gruvbox
