import QtQuick
import qs.components
import qs.bar
import qs.config
import qs.kit

// Shell Manager, three tabs:
//   APPEARANCE — shell options (ShellSettings);
//   PLUGINS    — a tile per plugin, click to switch it on / off;
//   LAYOUT     — the bar's zones side by side; drag a chip to reorder it or
//                move it to another zone (it follows the pointer, a bar marks
//                the slot).
KitFrame {
  id: root

  property string tab: "appearance"
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

  KitHeader {
    icon: "sliders"
    title: "Shell Manager"
    subtitle: BarLayout.plugins.length + " PLUGINS · "
      + (BarLayout.plugins.length - BarLayout.hidden.length) + " ON · "
      + BarLayout.hidden.length + " OFF"

    KitButton {
      visible: root.tab !== "appearance"
      icon: "rotate-ccw"
      text: "Reset"
      disabled: !BarLayout.customized
      onClicked: BarLayout.reset()
    }
  }

  KitChoices {
    model: [
      { label: "Appearance", value: "appearance", icon: "sun" },
      { label: "Plugins",    value: "plugins",    icon: "grid" },
      { label: "Layout",     value: "layout",     icon: "layout" }
    ]
    current: root.tab
    onPicked: value => root.tab = value
  }

  KitLine {}

  // ---- appearance: shell options ---------------------------------------------
  Column {
    width: parent.width
    visible: root.tab === "appearance"
    spacing: 12

    KitLabel { text: "THEME" }

    // one card per theme: a live miniature in its colours and its name; click
    // to switch (nothing moves, nothing opens)
    Column {
      width: parent.width
      spacing: 6

      Row {
        id: cards
        width: parent.width
        spacing: 8

        readonly property real cardWidth: Math.floor((width - spacing * 2) / 3)

        Repeater {
          model: ThemeService.themes

          Rectangle {
            id: card

            required property string modelData

            readonly property bool active: modelData === ThemeService.current

            width: cards.cardWidth
            height: preview.height + caption.height + 12
            color: active ? Theme.background3 : cardArea.containsMouse ? Theme.background1 : "transparent"
            border.width: Theme.frameWidth
            border.color: active || cardArea.containsMouse ? Theme.foreground2 : Theme.gray

            ThemePreview {
              id: preview
              x: 5
              y: 5
              width: parent.width - 10
              height: Math.round(width * 0.62)
              palette: ThemeService.palettes[card.modelData] ?? ({})
            }

            Item {
              id: caption
              anchors { left: parent.left; right: parent.right; top: preview.bottom; topMargin: 2 }
              height: 26

              KitText {
                anchors { left: parent.left; leftMargin: 7; verticalCenter: parent.verticalCenter }
                text: card.modelData
                color: card.active ? Theme.foreground0 : Theme.foreground2
                font.weight: card.active ? Font.ExtraBold : Font.DemiBold
              }

              Item {
                anchors { right: parent.right; rightMargin: 7; verticalCenter: parent.verticalCenter }
                width: 14
                height: 14

                KitSpinner {
                  anchors.centerIn: parent
                  visible: ThemeService.applying === card.modelData
                }

                KitIcon {
                  anchors.centerIn: parent
                  visible: card.active && ThemeService.applying !== card.modelData
                  name: "check"
                  size: 14
                }
              }
            }

            MouseArea {
              id: cardArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: card.active ? Qt.ArrowCursor : Qt.PointingHandCursor
              onClicked: ThemeService.apply(card.modelData)
            }
          }
        }
      }

      KitText {
        width: parent.width
        visible: ThemeService.error !== ""
        text: ThemeService.error
        color: Theme.red
        wrapMode: Text.WordWrap
        font.pixelSize: Theme.fontSize - 1
      }
    }

    KitLine {}

    KitLabel { text: "BAR" }

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
  }

  // ---- plugins: on / off tiles -------------------------------------------------
  Grid {
    id: tiles
    width: parent.width
    visible: root.tab === "plugins"
    columns: 3
    spacing: 6

    readonly property real tileWidth: Math.floor((width - 2 * 6) / 3)

    Repeater {
      model: BarLayout.plugins.filter(p => !p.fixed)

      Rectangle {
        id: tile

        required property var modelData

        readonly property bool shown: !BarLayout.hidden.includes(modelData.id)

        width: tiles.tileWidth
        height: 52
        color: shown ? Theme.background3 : tileArea.containsMouse ? Theme.background1 : "transparent"
        border.width: Theme.frameWidth
        border.color: shown || tileArea.containsMouse ? Theme.foreground2 : Theme.gray

        KitIcon {
          id: tileIcon
          anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
          name: tile.modelData.icon
          tint: tile.shown ? Theme.foreground0 : Theme.gray
          size: 18
          solid: ShellSettings.solidIcons
        }

        Column {
          anchors { left: tileIcon.right; leftMargin: 10; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
          spacing: 2

          KitText {
            width: parent.width
            text: tile.modelData.label
            elide: Text.ElideRight
            color: tile.shown ? Theme.foreground0 : Theme.foreground2
            font.weight: tile.shown ? Font.ExtraBold : Font.DemiBold
          }

          KitText {
            text: tile.shown ? "ON" : "OFF"
            color: tile.shown ? Theme.green : Theme.gray
            font.pixelSize: Theme.fontSize - 3
            font.letterSpacing: 1
          }
        }

        MouseArea {
          id: tileArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: BarLayout.setEnabled(tile.modelData.id, !tile.shown)
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
