import QtQuick
import qs.bar
import qs.config
import qs.kit

// Plugins: a tile per plugin, click to switch it on / off.
Column {
  id: root

  spacing: 14

  KitHeader {
    icon: "grid"
    title: "Plugins"
    subtitle: BarLayout.plugins.length + " TOTAL · "
      + (BarLayout.plugins.length - BarLayout.hidden.length) + " ON · "
      + BarLayout.hidden.length + " OFF"
  }

  KitLine {}

  Grid {
    id: tiles
    width: parent.width
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
}
