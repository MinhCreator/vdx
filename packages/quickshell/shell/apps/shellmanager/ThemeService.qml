pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Dotfiles themes (~/.dotfiles/themes/<name>) for the Shell Manager: the list,
// the active one (.theme, gruvbox when absent) and switching through
// `install.py theme set`, which relinks every program's colours. The active
// theme's colours go to Theme.live, so the shell recolours without a reload.
Singleton {
  id: root

  readonly property string dotfiles: Quickshell.env("HOME") + "/.dotfiles"

  property var themes: []
  // name -> that theme's colours by role (the order of scripts/themes.sh)
  readonly property var roles: ["background0", "background1", "background2", "background3",
                                "foreground0", "foreground1", "foreground2", "red", "orange", "yellow",
                                "green", "aqua", "blue", "purple", "gray", "muted", "frame", "dim"]
  property var colors: ({})
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
    command: ["bash", Paths.scriptsDir + "/themes.sh"]
    stdout: StdioCollector {
      onStreamFinished: {
        const [list, active] = text.split("---\n");
        const colors = {};
        const names = [];
        for (const line of list.split("\n").filter(l => l !== "")) {
          const [name, ...values] = line.split(" ");
          names.push(name);
          const roleColors = {};
          root.roles.forEach((role, i) => roleColors[role] = values[i] ?? "#000000");
          colors[name] = roleColors;
        }
        root.colors = colors;
        root.themes = names;
        root.current = (active ?? "").trim();
        Theme.live = colors[root.current] ?? ({});
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
