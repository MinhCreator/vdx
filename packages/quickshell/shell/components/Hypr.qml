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
  function iconOf(t) {
    const e = DesktopEntries.heuristicLookup(classOf(t));
    return Quickshell.iconPath(e?.icon ?? classOf(t).toLowerCase(), true);
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
