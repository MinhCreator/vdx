import QtQuick
import qs.bar
import qs.config
import qs.kit

// The folder: a tile per tucked-away module (icon and name); a click opens
// that module's popup. Which modules live here is set on Shell Manager › Bar.
KitFrame {
  id: root

  property var ids: []

  signal picked(string id)

  KitHeader {
    icon: "folder"
    title: "Folder"
    subtitle: root.ids.length + (root.ids.length === 1 ? " MODULE" : " MODULES")
  }

  KitLine {}

  KitText {
    visible: root.ids.length === 0
    width: parent.width
    text: "Empty. Put modules here in Shell Manager › Bar, row FOLDER."
    color: Theme.muted
    wrapMode: Text.WordWrap
    font.pixelSize: Theme.fontSize - 1
  }

  Grid {
    id: tiles
    visible: root.ids.length > 0
    width: parent.width
    columns: 3
    spacing: 6

    Repeater {
      model: root.ids

      Rectangle {
        id: tile

        required property string modelData

        readonly property var module: BarLayout.modules.find(p => p.id === modelData) ?? null

        width: (root.width - 2 * 16 - 2 * 6) / 3
        height: 58
        color: tileArea.containsMouse ? Theme.background3 : Theme.background1

        Column {
          anchors.centerIn: parent
          spacing: 6

          KitIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: tile.module?.icon ?? ""
            size: 18
          }

          KitText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: tile.module?.label ?? tile.modelData
            font.pixelSize: Theme.fontSize - 2
          }
        }

        MouseArea {
          id: tileArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.picked(tile.modelData)
        }
      }
    }
  }
}
