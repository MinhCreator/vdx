pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Hyprland's binds for the Shell Manager, as they are in effect
// (`hyprctl binds -j`). The description "Group · What it does"
// (hypr/components/keybinds.lua) gives the group and the name; binds
// without one go to Other. A run of numbered binds (workspaces 1–10) folds
// into one row.
Singleton {
  id: root

  // ---- state ----
  property var groups: []                   // [{name, binds: [{what, keys: [string]}]}]
  property int count: 0                     // binds in all, before folding
  property string error: ""

  function refresh() { if (!proc.running) proc.running = true; }

  // the window mode decides the wheel's and the touchpad's binds
  property string mode: "tiling"
  FileView {
    path: Quickshell.env("HOME") + "/.local/state/dotfiles/window-mode"
    printErrors: false
    watchChanges: true
    onFileChanged: reload()
    onLoaded: { root.mode = text().trim() || "tiling"; root.refresh(); }
  }

  // modmask bits, in the order they are written
  readonly property var mods: [[64, "Super"], [4, "Ctrl"], [8, "Alt"], [1, "Shift"]]
  readonly property var keyNames: ({
    "mouse:272": "LMB", "mouse:273": "RMB", "mouse:274": "MMB", "mouse_down": "Wheel ↓", "mouse_up": "Wheel ↑",
    "comma": ",", "period": ".", "left": "←", "right": "→", "up": "↑", "down": "↓",
    "space": "Space", "return": "Enter", "escape": "Esc", "tab": "Tab"
  })

  function keysOf(b) {
    const keys = mods.filter(m => b.modmask & m[0]).map(m => m[1]);
    const k = keyNames[b.key.toLowerCase()] ?? (b.key.length === 1 ? b.key.toUpperCase() : b.key);
    return keys.concat([k]);
  }

  // the keys of the bind named `what` ("Task manager"), [] when none
  function keysFor(what) {
    for (const g of groups)
      for (const b of g.binds) if (b.what === what) return b.keys;
    return [];
  }

  function build(list) {
    const groups = [];
    const byName = {};
    for (const b of list) {
      const desc = b.has_description ? b.description : "";
      const cut = desc.indexOf(" · ");
      const group = cut > 0 ? desc.slice(0, cut) : "Other";
      const what = cut > 0 ? desc.slice(cut + 3) : desc || (b.dispatcher + " " + b.arg).trim();
      if (!byName[group]) { byName[group] = { name: group, binds: [] }; groups.push(byName[group]); }
      byName[group].binds.push({ what: what, keys: keysOf(b) });
    }
    for (const g of groups) g.binds = fold(g.binds);
    // touchpad gestures aren't binds to hyprctl: those of the window mode (hypr/components/windowmode.lua)
    if (mode === "scrolling")
      groups.push({ name: "Touchpad", binds: [
        { what: "Next column", keys: ["3 fingers ←"] },
        { what: "Previous column", keys: ["3 fingers →"] },
        { what: "Workspace above / below", keys: ["3 fingers ↕"] }
      ] });
    return groups;
  }

  // "Go to 1" … "Go to 10" on Super+1 … Super+0 → "Go to 1–10" on Super, 1…0
  function fold(binds) {
    const out = [];
    const runs = {};
    for (const b of binds) {
      const m = b.what.match(/^(.*?)(\d+)$/);
      const last = b.keys[b.keys.length - 1];
      if (m && /^\d$/.test(last)) {
        const id = m[1] + "|" + b.keys.slice(0, -1).join("+");
        if (!runs[id]) {
          runs[id] = { prefix: m[1], mods: b.keys.slice(0, -1), from: +m[2], to: +m[2], first: last, lastKey: last };
          out.push(runs[id]);
        } else {
          runs[id].to = +m[2];
          runs[id].lastKey = last;
        }
      } else {
        out.push(b);
      }
    }
    return out.map(r => r.prefix === undefined ? r
      : { what: r.prefix + r.from + (r.to !== r.from ? "–" + r.to : ""),
          keys: r.mods.concat([r.first + (r.lastKey !== r.first ? "…" + r.lastKey : "")]) });
  }

  Component.onCompleted: refresh()

  Process {
    id: proc
    command: ["hyprctl", "binds", "-j"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const list = JSON.parse(text);
          root.count = list.length;
          root.groups = root.build(list);
          root.error = "";
        } catch (e) {
          root.error = "hyprctl binds: " + e;
        }
      }
    }
  }
}
