import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.kit

// About: what this shell believes, how it is put together, who made it and
// what it runs on, and a forced restart of the shell.
Column {
  id: root

  // the window's fixed header shows these; the page under it scrolls
  readonly property string icon: "info"
  readonly property string title: "About"
  readonly property string subtitle: "DIOMINVD'S DOTFILES · ARCH · HYPRLAND · QUICKSHELL"

  // groups for the Shell Manager's sidebar: a click scrolls to `y`
  readonly property var jumps: [
    { key: "philosophy", label: "Philosophy", y: philosophy.y },
    { key: "concept",    label: "Concept",    y: concept.y },
    { key: "author",     label: "Author",     y: author.y },
    { key: "system",     label: "System",     y: system.y }
  ]

  property var versions: ({})

  spacing: 14

  onVisibleChanged: if (visible && !versionProc.running) versionProc.running = true

  Process {
    id: versionProc
    command: ["bash", "-c", "printf '%s\\n' \"$(hyprctl version -j | jq -r .version)\" \"$(qs --version | awk '{print $2}')\" "
                          + "\"$(uname -r)\" \"$(cat ~/.dotfiles/.theme 2>/dev/null || echo gruvbox)\" \"$(git -C ~/.dotfiles rev-parse --short HEAD)\""]
    stdout: StdioCollector {
      onStreamFinished: {
        const [hypr, qs, kernel, theme, commit] = text.trim().split("\n");
        root.versions = { hypr, qs, kernel, theme, commit };
      }
    }
  }

  component Paragraph: KitText {
    width: parent.width
    wrapMode: Text.WordWrap
    color: Theme.foreground2
    lineHeight: 1.15
  }

  // ---- philosophy ----
  KitLabel { id: philosophy; text: "PHILOSOPHY" }

  Paragraph {
    text: "Quiet by default. A desktop should stay out of the way until you need it, then answer at once "
        + "and say exactly what it is doing — nothing blinks, nothing guesses."
  }
  Paragraph {
    text: "Terminal-minded: one monospace font, sharp corners, nearly monochrome. Colour is never decoration — "
        + "green means fine, yellow wants attention, red is wrong. Everything else is shades of one theme."
  }
  Paragraph {
    text: "Yours to change, never to fight: every option lives in one place, every change shows at once, "
        + "and anything touching the system tells you what it will do before it does it."
  }

  KitLine {}

  // ---- concept ----
  KitLabel { id: concept; text: "CONCEPT" }

  Paragraph {
    text: "Plain files in one git repository. Each program's config is linked into ~/.config file by file "
        + "(install.py), a theme overrides only the files it colours, and /etc gets copies, never links."
  }
  Paragraph {
    text: "The shell is one Quickshell config: a bar of modules, each a script that talks to the system, "
        + "a service that keeps the state and a view that only reads it — all drawn from the same small kit "
        + "of parts, so a new one looks as if it was always there."
  }
  Paragraph {
    text: "Apps of the shell — this Shell Manager, the Task Manager, the Cleaner, the capture tool — are "
        + "windows of their own, opened by a key, set up here."
  }

  KitLine {}

  // ---- author ----
  KitLabel { id: author; text: "AUTHOR" }

  KitRow {
    label: "diominvd"
    hint: "Made for his own laptop, shared as it is"

    KitButton {
      icon: "external"
      text: "GitHub"
      onClicked: Qt.openUrlExternally("https://github.com/diominvd/dotfiles")
    }
  }

  KitLine {}

  // ---- system ----
  KitLabel { id: system; text: "SYSTEM"; value: (root.versions.commit ?? "").toUpperCase() }

  KitInfo { width: parent.width; label: "Theme"; value: root.versions.theme ?? "--" }
  KitInfo { width: parent.width; label: "Hyprland"; value: root.versions.hypr ?? "--" }
  KitInfo { width: parent.width; label: "Quickshell"; value: root.versions.qs ?? "--" }
  KitInfo { width: parent.width; label: "Kernel"; value: root.versions.kernel ?? "--" }

  // a fresh process: this one is killed, Hyprland starts a new one
  KitRow {
    label: "Restart the shell"
    hint: "Kills Quickshell and starts it anew"

    KitButton {
      icon: "refresh"
      text: "Restart"
      onClicked: Quickshell.execDetached(["sh", "-c",
        "qs kill -c shell; while qs list -c shell 2>/dev/null | grep -q Instance; do sleep 0.2; done; "
        + "hyprctl eval 'hl.exec_cmd(\"qs -c shell\")'"])
    }
  }
}
