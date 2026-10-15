pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Small Hyprland helpers the shell's windows share: the focused monitor's
// screen, a window's address as the dispatchers want it, a Lua call.
Singleton {
  readonly property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
                                       ?? Quickshell.screens[0]

  // "0x…" for "address:…" selectors (a toplevel's address may come without it)
  function addr(toplevel) { return toplevel.address.startsWith("0x") ? toplevel.address : "0x" + toplevel.address; }
  function target(toplevel) { return "address:" + addr(toplevel); }

  // Lua in Hyprland's config state (hypr/components: SnapWindow, MinimizeWindow…)
  function call(lua) { Quickshell.execDetached(["hyprctl", "eval", lua]); }
}
