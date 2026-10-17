import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.kit

// The saved screenshots and recordings as a file list: a search field, the
// columns as sort buttons (a second click reverses), a row opens the file.
Column {
  id: root

  spacing: Theme.gapMedium

  property var items: []
  property bool loading: false
  property string query: ""
  property string sortKey: "date"
  property bool sortDesc: true
  // the first press asks again; a second press within a few seconds moves them all
  property bool confirming: false

  // the columns after the name: the heads and the rows share them
  readonly property var colWidths: ({ type: 96, date: 150, size: 72 })
  readonly property var colOrder: ["type", "date", "size"]

  // where a column starts and how wide it is in a row `total` wide
  function colLeft(key, total) {
    if (key === "name") return 0;
    let x = total;
    for (const k of colOrder) {
      x -= colWidths[k];
      if (k === key) return x;
    }
    return x;
  }

  function colWidth(key, total) {
    return key === "name" ? total - colOrder.reduce((sum, k) => sum + colWidths[k], 0) : colWidths[key];
  }

  // the rows on show: filtered by the search, sorted by the column
  readonly property var shown: {
    const q = query.trim().toLowerCase();
    const keys = {
      name: i => i.name.toLowerCase(),
      type: i => i.video ? 1 : 0,
      date: i => i.time,
      size: i => i.bytes
    };
    const key = keys[sortKey];
    const rows = items.filter(i => q === "" || i.name.toLowerCase().includes(q));
    rows.sort((a, b) => {
      const x = key(a), y = key(b);
      return x < y ? -1 : x > y ? 1 : 0;
    });
    return sortDesc ? rows.reverse() : rows;
  }

  // every file in the library goes to the trash (gio trash keeps it recoverable),
  // not only the rows the search shows
  function clearAll() {
    if (!confirming) { confirming = true; confirmTimer.restart(); return; }
    confirming = false;
    const paths = items.map(i => i.path);
    if (paths.length === 0) return;
    Quickshell.execDetached(["sh", "-c", 'for f in "$@"; do gio trash -- "$f"; done; notify-send -a Capture "Library cleared" "$# files moved to the trash"', "sh"].concat(paths));
    reloadTimer.restart();
  }

  function refresh() {
    loading = true;
    list.running = true;
  }

  function sortBy(key) {
    if (sortKey === key) sortDesc = !sortDesc;
    else { sortKey = key; sortDesc = key === "date" || key === "size"; }
  }

  function size(bytes) {
    return bytes >= 1048576 ? (bytes / 1048576).toFixed(1) + " MB" : Math.max(1, Math.round(bytes / 1024)) + " KB";
  }

  function when(seconds) {
    return Qt.formatDateTime(new Date(seconds * 1000), "d MMM yyyy, HH:mm");
  }

  KitLabel {
    text: "LIBRARY"
    value: root.loading ? "LOADING…" : root.shown.length === root.items.length
      ? root.items.length + " FILES" : root.shown.length + " OF " + root.items.length
  }

  KitInput {
    placeholder: "Search by name"
    onTextEdited: root.query = text
  }

  KitButton {
    visible: root.items.length > 0
    anchors.right: parent.right
    icon: "trash"
    iconTint: root.confirming ? Theme.red : Theme.foreground0
    text: root.confirming ? "Move all " + root.items.length + " to trash?" : "Clear library"
    onClicked: root.clearAll()
  }

  // the column heads: the active one carries its direction
  Item {
    id: heads

    width: parent.width
    height: Theme.fontSize + 10

    Repeater {
      model: ["name", "type", "date", "size"]

      Item {
        required property string modelData

        x: root.colLeft(modelData, heads.width)
        width: root.colWidth(modelData, heads.width)
        height: heads.height

        KitText {
          anchors { left: parent.left; right: parent.right; leftMargin: Theme.gapSmall; rightMargin: Theme.gapSmall; verticalCenter: parent.verticalCenter }
          horizontalAlignment: modelData === "size" ? Text.AlignRight : Text.AlignLeft
          elide: Text.ElideRight
          font.pixelSize: Theme.fontSize - 2
          font.letterSpacing: 1
          color: root.sortKey === modelData ? Theme.foreground0 : Theme.muted
          text: ({ name: "NAME", type: "TYPE", date: "DATE", size: "SIZE" })[modelData]
            + (root.sortKey === modelData ? (root.sortDesc ? " ↓" : " ↑") : "")
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.sortBy(modelData)
        }
      }
    }
  }

  KitLine {}

  // the rows: icon and name, then type, date and size; a click opens the file
  Column {
    width: parent.width

    Repeater {
      model: root.shown

      Rectangle {
        required property var modelData

        width: parent.width
        height: Theme.fontSize + 14
        radius: Theme.radiusControl
        color: rowArea.containsMouse ? Theme.controlHover : Theme.clear

        Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }

        KitIcon {
          id: icon

          x: Theme.gapSmall
          anchors.verticalCenter: parent.verticalCenter
          name: modelData.video ? "video" : "camera"
          tint: Theme.muted
          size: Theme.fontSize
        }

        KitText {
          x: icon.x + icon.width + Theme.gapSmall
          width: root.colWidth("name", parent.width) - x - Theme.gapSmall
          anchors.verticalCenter: parent.verticalCenter
          elide: Text.ElideRight
          text: modelData.name
        }

        KitText {
          x: root.colLeft("type", parent.width) + Theme.gapSmall
          width: root.colWidth("type", parent.width) - Theme.gapSmall
          anchors.verticalCenter: parent.verticalCenter
          elide: Text.ElideRight
          color: Theme.muted
          text: modelData.video ? "Recording" : "Screenshot"
        }

        KitText {
          x: root.colLeft("date", parent.width) + Theme.gapSmall
          width: root.colWidth("date", parent.width) - Theme.gapSmall
          anchors.verticalCenter: parent.verticalCenter
          elide: Text.ElideRight
          color: Theme.muted
          text: root.when(modelData.time)
        }

        KitText {
          x: root.colLeft("size", parent.width)
          width: root.colWidth("size", parent.width) - Theme.gapSmall
          anchors.verticalCenter: parent.verticalCenter
          horizontalAlignment: Text.AlignRight
          color: Theme.muted
          text: root.size(modelData.bytes)
        }

        MouseArea {
          id: rowArea

          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: Quickshell.execDetached(["xdg-open", modelData.path])
        }
      }
    }
  }

  Timer {
    id: confirmTimer

    interval: 4000
    onTriggered: root.confirming = false
  }

  // gio trash runs outside this process, so the list is read again once it is done
  Timer {
    id: reloadTimer

    interval: 800
    onTriggered: root.refresh()
  }

  KitText {
    visible: !root.loading && root.items.length === 0
    color: Theme.muted
    text: "Nothing saved yet"
  }

  KitText {
    visible: !root.loading && root.items.length > 0 && root.shown.length === 0
    color: Theme.muted
    text: "No file matches " + root.query.trim()
  }

  Process {
    id: list

    command: ["sh", "-c", 'find "$1" "$2" -maxdepth 1 -type f \\( -name "*.png" -o -name "*.mp4" \\) -printf "%T@ %s %p\\n" 2>/dev/null | sort -u | sort -rn | head -200',
              "sh", CaptureService.shotDir, CaptureService.videoDir]
    stdout: StdioCollector {
      onStreamFinished: {
        const rows = [];
        for (const line of text.split("\n")) {
          const m = line.match(/^(\d+)(?:\.\d+)? (\d+) (.+)$/);
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
