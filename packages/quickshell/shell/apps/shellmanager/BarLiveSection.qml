import QtQuick
import qs.config
import qs.kit

// One block of Bar › Live: a title with a caption, what the kind of activity
// is, and its rows — a drag handle, a sample of the pill, the name, a switch.
// The row order is the priority; drag a row by its handle to move it.
Rectangle {
  id: root

  property string section: ""
  property string title: ""
  property string caption: ""
  property string text: ""
  property var info: ({})                      // kind -> { label, hint }
  default property alias extra: tail.data      // more rows under the list (a block's own options)

  readonly property var kinds: ShellSettings.liveOrdered(section)
  readonly property int rowHeight: 64

  implicitHeight: body.implicitHeight + 16
  radius: Theme.radiusCard
  color: Theme.background1

  function move(kind, to) {
    const list = kinds.filter(k => k !== kind);
    list.splice(Math.max(0, Math.min(list.length, to)), 0, kind);
    if (list.join() !== kinds.join()) ShellSettings.liveSetOrder(section, list);
  }

  Column {
    id: body
    anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 22; rightMargin: 22; topMargin: 8 }

    Item {
      width: parent.width
      height: 44
      KitText { anchors { left: parent.left; verticalCenter: parent.verticalCenter } text: root.title; font.weight: Font.Medium }
      KitText { anchors { right: parent.right; verticalCenter: parent.verticalCenter } text: root.caption; color: Theme.muted; font.pixelSize: Theme.fontSize - 2 }
    }
    KitText {
      width: Math.min(parent.width, 600)
      text: root.text
      color: Theme.muted
      font.pixelSize: Theme.fontSize - 1
      wrapMode: Text.WordWrap
      bottomPadding: 12
    }

    Column {
      id: list
      width: parent.width

      Repeater {
        model: root.kinds

        Rectangle {
          id: row
          required property string modelData
          required property int index
          readonly property bool on: ShellSettings.liveOn(modelData)

          width: list.width
          height: root.rowHeight
          radius: 14
          color: grip.pressed ? Theme.background2 : "transparent"

          Rectangle { visible: row.index > 0 && !grip.pressed; anchors { top: parent.top; left: parent.left; right: parent.right } height: 1; color: Qt.rgba(1, 1, 1, 0.06) }

          // the handle: two columns of three dots
          Item {
            id: handle
            anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
            width: 14
            height: 24
            Grid {
              anchors.centerIn: parent
              columns: 2
              spacing: 3
              Repeater { model: 6; Rectangle { width: 3; height: 3; radius: 1.5; color: Theme.dim } }
            }
            MouseArea {
              id: grip
              anchors { fill: parent; margins: -8 }
              cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
              onPositionChanged: mouse => {
                if (!pressed) return;
                const y = mapToItem(list, mouse.x, mouse.y).y;
                root.move(row.modelData, Math.floor(y / root.rowHeight));
              }
            }
          }

          LivePreview {
            id: preview
            anchors { left: handle.right; leftMargin: 16; verticalCenter: parent.verticalCenter }
            kind: row.modelData
            opacity: row.on ? 1 : 0.45
          }

          Column {
            anchors { left: preview.right; leftMargin: 16; right: sw.left; rightMargin: 16; verticalCenter: parent.verticalCenter }
            spacing: 2
            KitText { width: parent.width; text: root.info[row.modelData]?.label ?? row.modelData; elide: Text.ElideRight }
            KitText { width: parent.width; text: root.info[row.modelData]?.hint ?? ""; color: Theme.muted; font.pixelSize: Theme.fontSize - 2; elide: Text.ElideRight }
          }

          KitSwitch {
            id: sw
            anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
            checked: row.on
            onToggled: ShellSettings.setLook("live" + row.modelData.charAt(0).toUpperCase() + row.modelData.slice(1), !checked, "island")
          }
        }
      }
    }

    Column { id: tail; width: parent.width }
  }
}
