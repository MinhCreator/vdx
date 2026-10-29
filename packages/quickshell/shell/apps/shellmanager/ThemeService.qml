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
  // the curtain (components/ThemeCurtain) hides the switch: up while applying and
  // until the new colours are read, in the new theme's background
  property bool covering: false
  property color coverColor: Theme.background0

  function refresh() { if (!listProc.running) listProc.running = true; }

  // ---- light and dark ----
  // a theme "<name>-light" is <name>'s light twin (themes/mktheme.py); the mode is the active one's
  readonly property bool light: current.endsWith("-light")
  readonly property var bases: themes.filter(n => !n.endsWith("-light"))
  function baseOf(name) { return name.replace(/-light$/, ""); }
  // a theme in a mode: its twin when there is one, else itself
  function variant(name, lightMode) {
    const n = lightMode ? baseOf(name) + "-light" : baseOf(name);
    return themes.includes(n) ? n : name;
  }
  // the themes to pick from in the active mode
  readonly property var inMode: bases.map(n => variant(n, light))
  function setLight(on) { if (on !== light) apply(variant(current, on)); }

  function apply(name) {
    if (busy || name === current) return;
    busy = true;
    applying = name;
    error = "";
    coverColor = colors[name]?.background0 ?? Theme.background0;
    covering = true;
    coverSafety.restart();
    setProc.command = ["python3", dotfiles + "/install.py", "theme", "set", name];
    setProc.running = true;
  }

  Component.onCompleted: refresh()

  // the screen is repainted a moment after the colours are read
  Timer {
    id: uncover
    interval: 150
    onTriggered: root.covering = false
  }

  // never stuck: a switch that hangs lifts the curtain anyway
  Timer {
    id: coverSafety
    interval: 15000
    onTriggered: root.covering = false
  }

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
        // the default theme leads the list, the rest keep their order
        root.themes = names.filter(n => n === "default").concat(names.filter(n => n !== "default"));
        root.current = (active ?? "").trim();
        Theme.live = colors[root.current] ?? ({});
        if (!root.busy) uncover.restart();
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
