import QtQuick
import qs.components
import qs.config

// Plugin manager, two tabs:
//   PLUGINS — every plugin with a one-line description and an on / off switch;
//   LAYOUT  — the bar's zones side by side; drag a chip to reorder it or move
//             it to another zone (it follows the pointer, a bar marks the slot).
PopupFrame {
  id: root

  property string tab: "plugins"
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

  implicitWidth: Theme.popupWidthWide

  PopupHeader {
    width: parent.width
    glyph: Theme.iconPuzzle
    title: "PLUGINS MANAGER"
    subtitle: BarLayout.plugins.length + " TOTAL · "
      + (BarLayout.plugins.length - BarLayout.hidden.length) + " ON · "
      + BarLayout.hidden.length + " OFF"

    PopupButton {
      anchors.verticalCenter: parent.verticalCenter
      glyph: Theme.iconRestore
      glyphSize: Theme.headerButtonSize
      tint: Theme.foreground0
      frameless: true
      hoverBackground: false
      disabled: !BarLayout.customized
      onClicked: BarLayout.reset()
    }
  }

  PopupTabs {
    width: parent.width
    model: [{ label: "PLUGINS", value: "plugins" }, { label: "LAYOUT", value: "layout" }]
    current: root.tab
    onPicked: value => root.tab = value
  }

  // ---- plugins: on / off -----------------------------------------------------
  Column {
    width: parent.width
    visible: root.tab === "plugins"

    Repeater {
      model: BarLayout.plugins

      Rectangle {
        id: plugin

        required property var modelData

        readonly property bool shown: !BarLayout.hidden.includes(modelData.id)

        width: parent.width
        height: 40
        color: hover.hovered ? Theme.background2 : "transparent"

        HoverHandler { id: hover }

        ThemeText {
          id: pluginIcon
          anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
          width: Theme.fontSize + 8
          horizontalAlignment: Text.AlignHCenter
          text: Theme[plugin.modelData.icon] ?? ""
          color: plugin.shown ? Theme.foreground0 : Theme.muted
          font.pixelSize: Theme.fontSize + 2
        }

        Column {
          anchors {
            left: pluginIcon.right; leftMargin: 10
            right: pluginSwitch.left; rightMargin: 10
            verticalCenter: parent.verticalCenter
          }
          spacing: 1

          ThemeText {
            width: parent.width
            text: plugin.modelData.label
            elide: Text.ElideRight
            color: plugin.shown ? Theme.foreground0 : Theme.muted
          }

          ThemeText {
            width: parent.width
            text: plugin.modelData.about
            elide: Text.ElideRight
            color: Theme.dim
            font.pixelSize: Theme.fontSize - 2
          }
        }

        PopupSwitch {
          id: pluginSwitch
          anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
          checked: plugin.shown
          disabled: plugin.modelData.fixed ?? false
          onToggled: BarLayout.setEnabled(plugin.modelData.id, !plugin.shown)
        }
      }
    }
  }

  // ---- layout: drag between zones --------------------------------------------
  Item {
    id: layoutArea
    width: parent.width
    height: columns.height
    visible: root.tab === "layout"

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

          ThemeText {
            text: column.modelData.toUpperCase() + " · " + column.count
            color: column.target ? Theme.foreground0 : Theme.dim
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
                color: Theme.background2
                opacity: root.dragId === modelData ? 0.3 : 1

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
              border.color: column.target ? Theme.foreground0 : Theme.muted

              ThemeText {
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
      border.width: 1
      border.color: Theme.foreground0

      PluginChip { pluginId: root.dragId }
    }
  }
}
