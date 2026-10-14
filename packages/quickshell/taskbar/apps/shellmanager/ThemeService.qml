pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Dotfiles themes (~/.dotfiles/themes/<name>) for the Shell Manager: the list,
// the active one (.theme, gruvbox when absent) and switching through
// `install.py theme set`, which relinks every program's colours; the bar
// reloads itself when .theme changes (shell.qml).
Singleton {
  id: root

  readonly property string dotfiles: Quickshell.env("HOME") + "/.dotfiles"

  property var themes: []
  property string current: ""
  property bool busy: false
  property string error: ""

  function refresh() { listProc.running = true; }

  function apply(name) {
    if (busy || name === current) return;
    busy = true;
    error = "";
    setProc.command = ["python3", dotfiles + "/install.py", "theme", "set", name];
    setProc.running = true;
  }

  Component.onCompleted: refresh()

  Process {
    id: listProc
    command: ["bash", "-c", "cd \"$HOME/.dotfiles\" && for d in themes/*/; do basename \"$d\"; done; echo ---; cat .theme 2>/dev/null || echo gruvbox"]
    stdout: StdioCollector {
      onStreamFinished: {
        const [list, active] = text.split("---\n");
        root.themes = list.split("\n").filter(s => s !== "");
        root.current = (active ?? "").trim();
      }
    }
  }

  Process {
    id: setProc
    stderr: StdioCollector { id: setErr }
    onExited: code => {
      root.busy = false;
      if (code !== 0) root.error = setErr.text.trim() || "install.py theme set failed";
      root.refresh();
    }
  }
}
