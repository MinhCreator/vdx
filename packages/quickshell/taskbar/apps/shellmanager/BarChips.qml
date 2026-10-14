import QtQuick
import qs.bar
import qs.config
import qs.kit

// A wrapping row of plugin icons on the Bar page — one zone or the tray. Each
// icon drags; `page` (the BarPage) tracks the pointer and drops.
Flow {
  id: root

  required property Item page
  required property Item dragArea
  property var ids: []
  property string zone: ""
  readonly property alias chips: chipRepeater

  spacing: page.chipSpacing

  Repeater {
    id: chipRepeater
    model: root.ids

    Rectangle {
      id: chip

      required property string modelData
      required property int index

      readonly property bool hot: root.page.hoverId === modelData && root.page.dragId === ""
      readonly property bool target: root.page.dropZone === root.zone && root.page.dragId !== ""

      width: root.page.chipSize
      height: root.page.chipSize
      color: hot ? Theme.background3 : "transparent"
      border.width: 1
      border.color: hot ? Theme.foreground2 : Theme.background3
      opacity: root.page.dragId === modelData ? 0.25 : 1

      KitIcon {
        anchors.centerIn: parent
        name: BarLayout.icon(chip.modelData)
        solid: ShellSettings.solidIcons
        size: 16
      }

      // insertion marker before this chip, or after the last one (not in the tray)
      Rectangle {
        readonly property bool after: chip.index === root.ids.length - 1 && root.page.dropIndex === root.ids.length
        visible: chip.target && root.zone !== "tray" && (root.page.dropIndex === chip.index || after)
        x: after ? parent.width + 1 : -3
        width: 2
        height: parent.height
        color: Theme.foreground0
      }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        onEntered: root.page.hoverId = chip.modelData
        onExited: if (root.page.hoverId === chip.modelData) root.page.hoverId = ""
        onPressed: mouse => {
          root.page.dragId = chip.modelData;
          const p = mapToItem(root.dragArea, mouse.x, mouse.y);
          root.page.track(p.x, p.y);
        }
        onPositionChanged: mouse => {
          if (root.page.dragId === "") return;
          const p = mapToItem(root.dragArea, mouse.x, mouse.y);
          root.page.track(p.x, p.y);
        }
        onReleased: root.page.drop()
      }
    }
  }
}
