pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import "../../kit/reply.js" as Reply

// The system monospace font for the Shell Manager (scripts/fonts.py): the list
// (curated Nerd Fonts and whatever monospace is installed), installing one into
// ~/.local/share/fonts and making it `monospace` everywhere. The shell follows
// through ShellSettings.font; a font installed after the shell started is
// unknown to it, so the shell restarts to pick it up.
Singleton {
  id: root

  readonly property string script: Paths.scriptsDir + "/fonts.py"

  // ---- state ----
  property var fonts: []                    // [{id, family, installed}]
  property string current: ""               // what fontconfig resolves `monospace` to
  property bool busy: false
  property string working: ""               // the family being installed / applied
  property string error: ""

  function refresh() { if (!listProc.running) listProc.running = true; }

  function apply(font) {
    if (busy || font.family === current) return;
    busy = true;
    working = font.family;
    error = "";
    run(font.installed ? ["set", font.family] : ["install", font.id]);
  }

  function run(args) {
    actProc.command = ["python3", script].concat(args);
    actProc.running = true;
  }

  function parse(text) {
    return Reply.parse(text, "fonts.py");
  }

  // the running shell only knows the fonts it found at start
  function restartShell() {
    Quickshell.execDetached(["bash", "-c",
      "sleep 0.3; kill " + Quickshell.processId + "; while kill -0 " + Quickshell.processId
      + " 2>/dev/null; do sleep 0.1; done; setsid qs -c shell -d"]);
  }

  Component.onCompleted: refresh()

  Process {
    id: listProc
    command: ["python3", root.script, "list"]
    stdout: StdioCollector {
      onStreamFinished: {
        const r = root.parse(text);
        if (!r.ok) { root.error = r.error; return; }
        root.fonts = r.fonts;
        root.current = r.current;
      }
    }
  }

  Process {
    id: actProc
    stdout: StdioCollector {
      onStreamFinished: {
        const r = root.parse(text);
        if (!r.ok) {
          root.busy = false;
          root.working = "";
          root.error = r.error;
          return;
        }
        if (actProc.command[2] === "install") { root.run(["set", r.family]); return; }
        const family = root.working;
        root.busy = false;
        root.working = "";
        ShellSettings.set("font", family);
        if (!Qt.fontFamilies().includes(family)) root.restartShell();
        else root.refresh();
      }
    }
  }
}
