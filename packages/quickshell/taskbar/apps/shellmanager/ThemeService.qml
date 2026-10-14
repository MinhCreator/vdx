pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Dotfiles themes (~/.dotfiles/themes/<name>) for the Shell Manager: the list,
// the active one (.theme, gruvbox when absent) and switching through
// `install.py theme set`, which relinks every program's colours; the bar
// reloads itself when .theme changes (shell.qml).
Singleton {
  id: root

  readonly property string dotfiles: Quickshell.env("HOME") + "/.dotfiles"

  property var themes: []
  // name -> that theme's colours by role (the order of scripts/themes.sh)
  readonly property var roles: ["background0", "background1", "background3", "frame", "foreground0",
                                "foreground2", "muted", "gray", "red", "yellow", "green", "blue"]
  property var palettes: ({})
  property string current: ""
  property bool busy: false
  property string applying: ""              // the theme being switched to
  property string error: ""

  function refresh() { if (!listProc.running) listProc.running = true; }

  function apply(name) {
    if (busy || name === current) return;
    busy = true;
    applying = name;
    error = "";
    setProc.command = ["python3", dotfiles + "/install.py", "theme", "set", name];
    setProc.running = true;
  }

  Component.onCompleted: refresh()

  Process {
    id: listProc
    command: ["bash", Theme.scriptsDir + "/themes.sh"]
    stdout: StdioCollector {
      onStreamFinished: {
        const [list, active] = text.split("---\n");
        const palettes = {};
        const names = [];
        for (const line of list.split("\n").filter(l => l !== "")) {
          const [name, ...colors] = line.split(" ");
          names.push(name);
          const palette = {};
          root.roles.forEach((role, i) => palette[role] = colors[i] ?? "#000000");
          palettes[name] = palette;
        }
        root.palettes = palettes;
        root.themes = names;
        root.current = (active ?? "").trim();
      }
    }
  }

  Process {
    id: setProc
    stderr: StdioCollector { id: setErr }
    onExited: code => {
      root.busy = false;
      root.applying = "";
      if (code !== 0) root.error = setErr.text.trim() || "install.py theme set failed";
      root.refresh();
    }
  }
}
