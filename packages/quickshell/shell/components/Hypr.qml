pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Small Hyprland helpers the shell's windows share: the focused monitor's
// screen, a window's address as the dispatchers want it, what a toplevel's
// IPC object says (class, tags, minimized), its app icon, a Lua call.
Singleton {
  readonly property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
                                       ?? Quickshell.screens[0]

  // "0x…" for "address:…" selectors (a toplevel's address may come without it)
  function addr(toplevel) { return toplevel.address.startsWith("0x") ? toplevel.address : "0x" + toplevel.address; }
  function target(toplevel) { return "address:" + addr(toplevel); }

  function classOf(t) { return t.lastIpcObject?.class ?? ""; }
  // Hyprland marks a tag set by a dispatcher with a trailing *
  function tagsOf(t) { return (t.lastIpcObject?.tags ?? []).map(s => s.replace(/\*$/, "")); }
  // minimized windows wait on special:minimized (hypr/components/windowmode.lua)
  function minimized(t) { return t.workspace?.name === "special:minimized"; }
  // its app's icon path, "" when the icon theme has none
  // the icon of an app by its desktop id or name ("" when it has none)
  function iconOfApp(desktop, app) {
    const e = DesktopEntries.heuristicLookup(desktop || app || "");
    return e ? Quickshell.iconPath(e.icon, true) : "";
  }

  function iconOf(t) {
    const e = DesktopEntries.heuristicLookup(classOf(t));
    return Quickshell.iconPath(e?.icon ?? classOf(t).toLowerCase(), true);
  }

  // The main keyboard switches to its layout called us (Hyprland's index in
  // the layouts list); the name and the layouts come as one line from hyprctl.
  function englishLayout() {
    Quickshell.execDetached(["bash", "-c",
      "IFS=$'\\t' read -r n l < <(hyprctl devices -j | jq -r '[.keyboards[] | select(.main)][0] | [.name, .layout] | @tsv'); "
      + "i=$(printf '%s' \"$l\" | tr ',' '\\n' | grep -nx us | head -1 | cut -d: -f1); "
      + "[ -n \"$i\" ] && hyprctl switchxkblayout \"$n\" $((i-1)) >/dev/null"]);
  }

  // text into a file of the dotfiles' state (its folder made first); `after` is a fixed
  // command line run when it is written, never built from input
  function writeState(path, text, after) {
    Quickshell.execDetached(["bash", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s" "$2" > "$1"' + (after ? " && " + after : ""),
                             "_", path, text]);
  }

  // Lua in Hyprland's config state (hypr/components: SnapWindow, MinimizeWindow…)
  function call(lua) { Quickshell.execDetached(["hyprctl", "eval", lua]); }

  // Toggle of a shell window (its IpcHandler): it closes when it is the focused
  // one. Up elsewhere (another workspace, behind others) it is mapped again
  // here, which Hyprland puts on the workspace in use: no second press needed.
  function toggleWindow(win) {
    if (win.visible && Hyprland.activeToplevel?.title !== win.title) {
      win.visible = false;
      Qt.callLater(() => win.visible = true);
    } else {
      win.visible = !win.visible;
    }
  }
}
