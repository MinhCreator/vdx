import QtQuick
import Quickshell
import qs.bar
import qs.config
import qs.kit

// Plugins: the list on the left, the chosen plugin's options on the right —
// its own <Name>Settings.qml (the registry's `settings`), values kept in
// PluginSettings. The header stays; each pane scrolls on its own. Placing
// and switching plugins on stays on the Bar page.
Column {
  id: root

  property string selected: (BarLayout.plugins.find(p => p.settings) ?? BarLayout.plugins[0])?.id ?? ""
  readonly property var plugin: BarLayout.plugins.find(p => p.id === selected) ?? null

  spacing: 14

  KitHeader {
    id: header
    icon: "grid"
    title: "Plugins"
    subtitle: BarLayout.plugins.filter(p => p.settings).length + " WITH OPTIONS · " + BarLayout.plugins.length + " IN ALL"
  }

  KitLine { id: headerLine }

  Row {
    width: parent.width
    height: root.height - header.height - headerLine.height - 2 * root.spacing
    spacing: 18

    // ---- list: framed like an open select, scrolls inside the frame ----------------
    Rectangle {
      id: list
      width: 190
      height: Math.min(parent.height, rows.implicitHeight + 2 * Theme.frameWidth)
      color: "transparent"
      border.width: Theme.frameWidth
      border.color: Theme.gray

      Flickable {
        anchors { fill: parent; margins: Theme.frameWidth }
        contentHeight: rows.implicitHeight
        interactive: contentHeight > height
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
          id: rows
          width: parent.width

          Repeater {
            model: BarLayout.plugins

            Rectangle {
              id: row

              required property var modelData

              readonly property bool active: modelData.id === root.selected
              readonly property bool hasOptions: !!modelData.settings

              width: rows.width
              height: 30
              color: active ? Theme.background3 : rowArea.containsMouse ? Theme.background1 : "transparent"

              KitIcon {
                id: rowIcon
                anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                name: row.modelData.icon
                tint: row.active ? Theme.foreground0 : row.hasOptions ? Theme.foreground2 : Theme.muted
                size: 14
              }

              // plugins without options read dimmer
              KitText {
                anchors { left: rowIcon.right; leftMargin: 8; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                text: row.modelData.label
                elide: Text.ElideRight
                color: row.active || rowArea.containsMouse ? Theme.foreground0 : row.hasOptions ? Theme.foreground2 : Theme.muted
                font.weight: row.active ? Font.ExtraBold : Font.DemiBold
              }

              MouseArea {
                id: rowArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: row.active ? Qt.ArrowCursor : Qt.PointingHandCursor
                onClicked: root.selected = row.modelData.id
              }
            }
          }
        }
      }
    }

    // ---- the chosen plugin: its name and options, scrolling on their own ------------
    Flickable {
      id: pane
      width: parent.width - list.width - parent.spacing
      height: parent.height
      contentHeight: details.implicitHeight
      interactive: contentHeight > height
      clip: true
      boundsBehavior: Flickable.StopAtBounds

      Column {
        id: details
        width: pane.width
        spacing: 14

        // heading: icon, name and about; NO OPTIONS on the right when it has none
        Item {
          width: parent.width
          height: heading.implicitHeight

          Row {
            id: heading
            anchors { left: parent.left; right: badge.visible ? badge.left : parent.right; rightMargin: badge.visible ? 12 : 0 }
            spacing: 10

            KitIcon {
              id: headingIcon
              anchors.verticalCenter: parent.verticalCenter
              name: root.plugin?.icon ?? ""
              size: 18
            }

            Column {
              anchors.verticalCenter: parent.verticalCenter
              width: heading.width - headingIcon.width - heading.spacing
              spacing: 2

              KitText {
                text: root.plugin?.label ?? ""
                font.weight: Font.ExtraBold
              }

              KitText {
                width: parent.width
                text: root.plugin?.about ?? ""
                elide: Text.ElideRight
                color: Theme.muted
                font.pixelSize: Theme.fontSize - 2
              }
            }
          }

          KitBadge {
            id: badge
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            visible: !root.plugin?.settings
            text: "NO OPTIONS"
            tint: Theme.muted
          }
        }

        KitLine { visible: !!root.plugin?.settings }

        Loader {
          width: parent.width
          active: !!root.plugin?.settings
          source: active ? Quickshell.shellPath("plugins/" + root.plugin.id + "/" + root.plugin.settings) : ""
        }
      }
    }
  }

  onSelectedChanged: pane.contentY = 0
}
