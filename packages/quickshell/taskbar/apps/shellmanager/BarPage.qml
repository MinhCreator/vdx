import QtQuick
import qs.bar
import qs.config
import qs.kit

// Bar: how it looks (icon style) and its layout — drag a chip to reorder it or
// move it to another zone (it follows the pointer, a bar marks the slot).
Column {
  id: root

  property string dragId: ""
  property string dropZone: ""
  property int dropIndex: -1

  readonly property int chipHeight: Theme.rowHeight + 4
  readonly property int chipStep: chipHeight + 4

  // Drop slot under the pointer (layout coordinates): the column under x, the
  // gap nearest to y inside its list.
  function track(x, y) {
    ghost.x = x - ghost.width / 2;
    ghost.y = y - ghost.height / 2;
    for (const column of columns.children) {
      if (column.zoneName === undefined || x < column.x || x > column.x + column.width) continue;
      dropZone = column.zoneName;
      dropIndex = Math.max(0, Math.min(column.count, Math.round((y - column.listY) / chipStep)));
      return;
    }
    dropZone = "";
  }

  // Columns show only plugins that are on; the stored order also holds the off
  // ones, so the slot is translated through its visible neighbours.
  function drop() {
    if (dragId !== "" && dropZone !== "") {
      const visible = BarLayout.visibleIn(dropZone);
      const current = visible.indexOf(dragId);
      const slot = current >= 0 && dropIndex > current ? dropIndex - 1 : dropIndex;
      const others = visible.filter(id => id !== dragId);
      const full = BarLayout.layout[dropZone].filter(id => id !== dragId);
      const index = slot < others.length ? full.indexOf(others[slot])
                  : others.length > 0 ? full.indexOf(others[others.length - 1]) + 1
                  : full.length;
      BarLayout.move(dragId, dropZone, index);
    }
    dragId = "";
    dropZone = "";
    dropIndex = -1;
  }

  spacing: 14

  KitHeader {
    icon: "layout"
    title: "Bar"
    subtitle: (BarLayout.plugins.length - BarLayout.hidden.length) + " MODULES ON THE BAR"

    KitButton {
      icon: "rotate-ccw"
      text: "Reset layout"
      disabled: !BarLayout.customized
      onClicked: BarLayout.reset()
    }
  }

  KitLine {}

  KitLabel { text: "ICONS" }

  KitRow {
    label: "Solid icons"
    hint: "filled icons in the bar instead of outlines"

    KitSwitch {
      checked: ShellSettings.solidIcons
      onToggled: ShellSettings.set("solidIcons", !ShellSettings.solidIcons)
    }
  }

  // live preview of the bar's icons in the chosen style
  Rectangle {
    width: parent.width
    height: 40
    color: Theme.background1
    border.width: Theme.frameWidth
    border.color: Theme.background3

    Row {
      anchors.centerIn: parent
      spacing: 22

      Repeater {
        model: ["sun", "volume", "wifi", "shield", "battery", "bot", "bell", "sliders"]

        KitIcon {
          required property string modelData
          name: modelData
          size: Theme.fontSize + 3
          solid: ShellSettings.solidIcons
        }
      }
    }
  }

  KitLine {}

  KitLabel { text: "LAYOUT"; value: "DRAG TO REORDER" }

  Item {
    id: layoutArea
    width: parent.width
    height: columns.height

    Row {
      id: columns
      width: parent.width
      spacing: 12

      Repeater {
        model: BarLayout.zones

        Column {
          id: column

          required property string modelData

          readonly property string zoneName: modelData
          readonly property var ids: BarLayout.visibleIn(modelData)
          readonly property int count: ids.length
          readonly property real listY: list.y
          readonly property bool target: root.dragId !== "" && root.dropZone === zoneName

          width: (columns.width - 2 * columns.spacing) / 3
          spacing: 6

          KitText {
            text: column.modelData.toUpperCase() + " (" + column.count + ")"
            color: column.target ? Theme.foreground0 : Theme.muted
            font.pixelSize: Theme.fontSize - 2
            font.letterSpacing: 1
          }

          Column {
            id: list
            width: parent.width
            spacing: 4

            Repeater {
              model: column.ids

              Rectangle {
                id: chip

                required property string modelData
                required property int index

                width: list.width
                height: root.chipHeight
                color: chipHover.hovered ? Theme.background1 : "transparent"
                border.width: Theme.frameWidth
                border.color: chipHover.hovered ? Theme.foreground2 : Theme.gray
                opacity: root.dragId === modelData ? 0.3 : 1

                HoverHandler { id: chipHover }

                // insertion marker above this chip
                Rectangle {
                  visible: column.target && root.dropIndex === chip.index
                  y: -3
                  width: parent.width
                  height: 2
                  color: Theme.foreground0
                }

                PluginChip { id: content; pluginId: chip.modelData }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                  preventStealing: true
                  onPressed: mouse => {
                    root.dragId = chip.modelData;
                    const p = mapToItem(layoutArea, mouse.x, mouse.y);
                    root.track(p.x, p.y);
                  }
                  onPositionChanged: mouse => {
                    const p = mapToItem(layoutArea, mouse.x, mouse.y);
                    root.track(p.x, p.y);
                  }
                  onReleased: root.drop()
                }
              }
            }

            // Slot after the last chip; an empty zone shows where to drop.
            Rectangle {
              width: list.width
              height: column.count === 0 ? root.chipHeight : 2
              color: column.count === 0 ? "transparent" : Theme.foreground0
              opacity: column.count === 0 || (column.target && root.dropIndex === column.count) ? 1 : 0
              border.width: column.count === 0 ? 1 : 0
              border.color: column.target ? Theme.foreground2 : Theme.background3

              KitText {
                visible: column.count === 0
                anchors.centerIn: parent
                text: "drop here"
                color: Theme.muted
                font.pixelSize: Theme.fontSize - 2
              }
            }
          }
        }
      }
    }

    // The chip being dragged, following the pointer.
    Rectangle {
      id: ghost
      visible: root.dragId !== ""
      width: (columns.width - 2 * columns.spacing) / 3
      height: root.chipHeight
      color: Theme.background3
      border.width: Theme.frameWidth
      border.color: Theme.foreground2

      PluginChip { pluginId: root.dragId }
    }
  }
}
