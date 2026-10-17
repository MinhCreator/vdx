import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.kit

// The screenshots and recordings in their folders, newest first. A row opens
// the file; the folder button shows where it is.
Column {
  id: root

  spacing: Theme.gapMedium

  property var items: []
  property bool loading: false

  function refresh() {
    loading = true;
    list.running = true;
  }

  function size(bytes) {
    return bytes >= 1048576 ? (bytes / 1048576).toFixed(1) + " MB" : Math.max(1, Math.round(bytes / 1024)) + " KB";
  }

  function when(seconds) {
    return Qt.formatDateTime(new Date(seconds * 1000), "d MMM · HH:mm");
  }

  KitLabel {
    text: "LIBRARY"
    value: root.loading ? "LOADING…" : root.items.length + " FILES"
  }

  Repeater {
    model: root.items

    KitRow {
      required property var modelData

      label: modelData.name
      hint: (modelData.video ? "Recording" : "Screenshot") + " · " + root.when(modelData.time) + " · " + root.size(modelData.bytes)
      wide: true

      KitButton {
        icon: "external"
        text: "Open"
        onClicked: Quickshell.execDetached(["xdg-open", modelData.path])
      }
    }
  }

  KitText {
    visible: !root.loading && root.items.length === 0
    color: Theme.muted
    text: "Nothing saved yet"
  }

  Process {
    id: list

    command: ["sh", "-c", 'find "$1" "$2" -maxdepth 1 -type f \\( -name "*.png" -o -name "*.mp4" \\) -printf "%T@ %s %p\\n" 2>/dev/null | sort -rn | head -60',
              "sh", CaptureService.shotDir, CaptureService.videoDir]
    stdout: StdioCollector {
      onStreamFinished: {
        const rows = [];
        for (const line of text.split("\n")) {
          const m = line.match(/^(\d+)\.\d+ (\d+) (.+)$/);
          if (!m) continue;
          rows.push({ time: Number(m[1]), bytes: Number(m[2]), path: m[3], name: m[3].split("/").pop(),
                      video: m[3].endsWith(".mp4") });
        }
        root.items = rows;
        root.loading = false;
      }
    }
  }
}
