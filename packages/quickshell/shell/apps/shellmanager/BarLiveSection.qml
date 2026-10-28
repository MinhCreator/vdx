import QtQuick
import qs.config
import qs.kit

// One block of Bar › Live, a settings section: a small-caps caption, then its rows (the page's KitGrouper boxes them) — a drag
// handle, a same-size sample of the pill, the name, a switch. The row order is
// the priority; drag a row by its handle to move it.
Column {
  id: root

  property string section: ""
  property string title: ""
  property var info: ({})                      // kind -> { label, hint }

  readonly property var kinds: ShellSettings.liveOrdered(section)
  readonly property int rowHeight: 52

  function move(kind, to) {
    const list = kinds.filter(k => k !== kind);
    list.splice(Math.max(0, Math.min(list.length, to)), 0, kind);
    if (list.join() !== kinds.join()) ShellSettings.liveSetOrder(section, list);
  }
  // the row under a y of this column
  function rowAt(y) {
    let at = 0;
    for (let i = 0; i < rows.count; i++) {
      const r = rows.itemAt(i);
      if (r && y >= r.y) at = i;
    }
    return at;
  }

  KitLabel { text: root.title }

  Repeater {
    id: rows
    model: root.kinds

    Item {
      id: row
      required property string modelData
      required property int index
      readonly property bool on: ShellSettings.liveKind(modelData)

      width: root.width
      height: root.rowHeight

      // the handle: two columns of three dots
      Item {
        id: handle
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        width: 12
        height: 22
        Grid {
          anchors.centerIn: parent
          columns: 2
          spacing: 3
          Repeater { model: 6; Rectangle { width: 2; height: 2; color: grip.pressed ? Theme.foreground0 : Theme.dim } }
        }
        MouseArea {
          id: grip
          anchors { fill: parent; margins: -8 }
          cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
          onPositionChanged: mouse => { if (pressed) root.move(row.modelData, root.rowAt(mapToItem(root, mouse.x, mouse.y).y)); }
        }
      }

      LivePreview {
        id: preview
        anchors { left: handle.right; leftMargin: Theme.gapWide; verticalCenter: parent.verticalCenter }
        kind: row.modelData
        opacity: row.on && ShellSettings.liveEnabled ? 1 : 0.45
      }

      Column {
        anchors { left: preview.right; leftMargin: Theme.gapWide; right: sw.left; rightMargin: Theme.gapWide; verticalCenter: parent.verticalCenter }
        spacing: Theme.gapTight
        KitText { width: parent.width; text: root.info[row.modelData]?.label ?? row.modelData; elide: Text.ElideRight }
        KitText { width: parent.width; text: root.info[row.modelData]?.hint ?? ""; color: Theme.muted; font.pixelSize: Theme.fontSize - 1; elide: Text.ElideRight }
      }

      KitSwitch {
        id: sw
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        checked: row.on
        onToggled: ShellSettings.setLook("live" + row.modelData.charAt(0).toUpperCase() + row.modelData.slice(1), !checked, "island")
      }
    }
  }

  KitGrouper {}
}
