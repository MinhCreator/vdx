import QtQuick
import Quickshell
import qs.bar
import qs.config
import qs.kit

// Plugins: every plugin on the left, the chosen one's options on the right —
// its own <Name>Settings.qml (the registry's `settings`), values kept in
// PluginSettings. Placing and switching plugins on stays on the Bar page.
Column {
  id: root

  property string selected: BarLayout.plugins[0]?.id ?? ""
  readonly property var plugin: BarLayout.plugins.find(p => p.id === selected) ?? null

  spacing: 14


  KitHeader {
    icon: "grid"
    title: "Plugins"
    subtitle: BarLayout.plugins.filter(p => p.settings).length + " WITH OPTIONS · " + BarLayout.plugins.length + " IN ALL"
  }

  KitLine {}

  Row {
    width: parent.width
    spacing: 18

    // the plugin list, styled like the Shell Manager's own navigation
    Column {
      id: list
      width: 180
      spacing: 4

      Repeater {
        model: BarLayout.plugins

        Rectangle {
          id: row

          required property var modelData

          readonly property bool active: modelData.id === root.selected

          width: list.width
          height: 34
          color: active ? Theme.background3 : rowArea.containsMouse ? Theme.background1 : "transparent"

          KitIcon {
            id: rowIcon
            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
            name: row.modelData.icon
            tint: row.active ? Theme.foreground0 : Theme.foreground2
            size: 16
          }

          KitText {
            anchors { left: rowIcon.right; leftMargin: 10; right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
            text: row.modelData.label
            elide: Text.ElideRight
            color: row.active ? Theme.foreground0 : Theme.foreground2
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

    // the chosen plugin
    Column {
      width: parent.width - list.width - parent.spacing
      spacing: 14

      KitRow {
        label: root.plugin?.label ?? ""
        hint: root.plugin?.about ?? ""
        labelColor: Theme.foreground0
      }

      KitLine {}

      Loader {
        width: parent.width
        active: !!root.plugin?.settings
        source: active ? Quickshell.shellPath("plugins/" + root.plugin.id + "/" + root.plugin.settings) : ""
      }

      KitText {
        visible: !root.plugin?.settings
        text: "No options yet."
        color: Theme.muted
        font.pixelSize: Theme.fontSize - 1
      }
    }
  }
}
