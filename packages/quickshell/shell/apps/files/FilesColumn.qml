import QtQuick
import Quickshell.Io
import qs.config
import qs.kit

// A side column of the Columns view: the folder beside the current one (the
// parent above it, or the folder selected in it), read on its own (scripts/
// files.py list). A click goes to the entry: the folder shown becomes the
// current one, and the columns move with it.
Rectangle {
  id: root

  property string folder: ""          // the folder listed; "" shows nothing
  property string highlight: ""       // the path of the row that is current
  property string title: ""           // a caption: PARENT, or the selected folder's name

  signal opened(string path)

  readonly property var rows: list.model

  clip: true
  radius: Theme.radiusCard
  color: "transparent"

  onFolderChanged: {
    if (proc.running) proc.running = false;
    rowsModel = [];
    if (folder !== "") { proc.command = ["python3", FilesService.script, "list", folder]; proc.running = true; }
  }

  property var rowsModel: []

  Process {
    id: proc
    stdout: StdioCollector {
      onStreamFinished: {
        const o = FilesService.parse(text);
        if (!o.ok) { root.rowsModel = []; return; }
        root.rowsModel = FilesService.columnRows(o.entries);
      }
    }
  }

  KitText {
    id: caption
    // the caption starts where the names start
    x: Theme.gapLoose + Theme.iconSmall + Theme.gapMedium
    y: 0   // the same line as the list's caption row
    width: root.width - x - Theme.gapSmall
    text: root.title
    color: Theme.muted
    elide: Text.ElideRight
    font.pixelSize: Theme.fontSize - 2
    font.letterSpacing: 1
  }

  KitLine {
    id: line
    anchors { left: parent.left; right: parent.right; top: caption.bottom; topMargin: Theme.gapTight }
  }

  ListView {
    id: list
    anchors { left: parent.left; right: parent.right; top: line.bottom; bottom: parent.bottom; margins: Theme.gapTight }
    clip: true
    model: root.rowsModel
    boundsBehavior: Flickable.StopAtBounds

    delegate: Rectangle {
      id: row

      required property var modelData

      readonly property bool current: modelData.path === root.highlight

      width: list.width
      height: 28
      radius: Theme.radiusControl
      color: current ? Theme.background3 : area.containsMouse ? Theme.background2 : Theme.clear
      Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }

      KitIcon {
        id: glyph
        anchors { left: parent.left; leftMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }
        name: modelData.kind === "dir" ? "folder" : "file"
        size: Theme.iconSmall
      }

      KitText {
        anchors { left: glyph.right; leftMargin: Theme.gapMedium; right: parent.right; rightMargin: Theme.gapSmall; verticalCenter: parent.verticalCenter }
        text: modelData.name
        elide: Text.ElideRight
        font.weight: row.current ? Font.ExtraBold : Theme.fontWeight
      }

      MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.opened(row.modelData.path)
      }
    }
  }
}
