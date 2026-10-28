import QtQuick
import qs.config
import qs.kit

// One block of Bar › Live, in the settings' own style: a small-caps caption
// with a note on the right, a line of what the kind of activity is, then its
// rows — a drag handle, a same-size sample of the pill, the name, a switch.
// The row order is the priority; drag a row by its handle to move it.
Column {
  id: root

  property string section: ""
  property string title: ""
  property string caption: ""
  property string text: ""
  property var info: ({})                      // kind -> { label, hint }
  default property alias extra: tail.data      // a block's own options under the list

  readonly property var kinds: ShellSettings.liveOrdered(section)
  readonly property int rowHeight: 52

  spacing: Theme.sectionGap

  function move(kind, to) {
    const list = kinds.filter(k => k !== kind);
    list.splice(Math.max(0, Math.min(list.length, to)), 0, kind);
    if (list.join() !== kinds.join()) ShellSettings.liveSetOrder(section, list);
  }

  KitLabel { text: root.title; value: root.caption }

  KitText {
    width: parent.width
    visible: root.text !== ""
    text: root.text
    color: Theme.muted
    font.pixelSize: Theme.fontSize - 1
    wrapMode: Text.WordWrap
  }

  Column {
    id: list
    width: parent.width
    visible: root.kinds.length > 0

    Repeater {
      model: root.kinds

      Rectangle {
        id: row
        required property string modelData
        required property int index
        readonly property bool on: ShellSettings.liveOn(modelData)

        width: list.width
        height: root.rowHeight
        radius: Theme.radiusControl
        color: grip.pressed ? Theme.pickFill : hover.hovered ? Theme.controlHover : Theme.clear
        Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }

        HoverHandler { id: hover }

        // the handle: two columns of three dots
        Item {
          id: handle
          anchors { left: parent.left; leftMargin: Theme.gapMedium; verticalCenter: parent.verticalCenter }
          width: 12
          height: 22
          Grid {
            anchors.centerIn: parent
            columns: 2
            spacing: 3
            Repeater { model: 6; Rectangle { width: 2; height: 2; color: grip.pressed || hover.hovered ? Theme.foreground2 : Theme.dim } }
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
          anchors { left: handle.right; leftMargin: Theme.gapWide; verticalCenter: parent.verticalCenter }
          kind: row.modelData
          opacity: row.on ? 1 : 0.45
        }

        Column {
          anchors { left: preview.right; leftMargin: Theme.gapWide; right: sw.left; rightMargin: Theme.gapWide; verticalCenter: parent.verticalCenter }
          spacing: Theme.gapTight
          KitText { width: parent.width; text: root.info[row.modelData]?.label ?? row.modelData; elide: Text.ElideRight }
          KitText { width: parent.width; text: root.info[row.modelData]?.hint ?? ""; color: Theme.muted; font.pixelSize: Theme.fontSize - 1; elide: Text.ElideRight }
        }

        KitSwitch {
          id: sw
          anchors { right: parent.right; rightMargin: Theme.gapMedium; verticalCenter: parent.verticalCenter }
          checked: row.on
          onToggled: ShellSettings.setLook("live" + row.modelData.charAt(0).toUpperCase() + row.modelData.slice(1), !checked, "island")
        }
      }
    }
  }

  Column { id: tail; width: parent.width }
}
