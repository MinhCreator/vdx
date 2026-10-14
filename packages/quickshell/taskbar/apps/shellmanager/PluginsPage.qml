import QtQuick
import Quickshell
import qs.bar
import qs.config
import qs.kit

// Plugins: the list on the left with a switch per plugin (dim: off — gone
// from every bar), the chosen one's options on the right: its own <Name>Settings.qml
// (the registry's `settings`), values kept in PluginSettings, Reset to the
// defaults. The header stays; each pane scrolls on its own. Where a plugin
// sits is set on the Bar page.
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
      width: 220
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
              readonly property bool on: BarLayout.pluginOn(modelData.id)

              width: rows.width
              height: 30
              color: active ? Theme.background3 : rowArea.containsMouse ? Theme.background1 : "transparent"

              KitIcon {
                id: rowIcon
                anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                name: row.modelData.icon
                tint: row.active ? Theme.foreground0 : row.on ? Theme.foreground2 : Theme.muted
                size: 14
              }

              // plugins switched off read dimmer
              KitText {
                anchors { left: rowIcon.right; leftMargin: 8; right: rowSwitch.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                text: row.modelData.label
                elide: Text.ElideRight
                color: row.active || rowArea.containsMouse ? Theme.foreground0 : row.on ? Theme.foreground2 : Theme.muted
                font.weight: row.active ? Font.ExtraBold : Font.DemiBold
              }

              MouseArea {
                id: rowArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: row.active ? Qt.ArrowCursor : Qt.PointingHandCursor
                onClicked: root.selected = row.modelData.id
              }

              // quick on / off without opening the plugin
              KitSwitch {
                id: rowSwitch
                anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                checked: row.on
                trackColor: row.active ? Theme.background0 : Theme.background3
                onToggled: BarLayout.setPluginOn(row.modelData.id, !row.on)
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

        // heading: icon, name and about; Reset brings the options' defaults back
        Item {
          width: parent.width
          height: Math.max(heading.implicitHeight, resetButton.height)

          Row {
            id: heading
            anchors { left: parent.left; right: resetButton.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
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

          KitButton {
            id: resetButton
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            visible: !!root.plugin?.settings
            icon: "rotate-ccw"
            text: "Reset"
            disabled: !PluginSettings.changed(root.selected)
            onClicked: PluginSettings.reset(root.selected)
          }
        }

        KitLine {}

        // hidden when off: a zero-height item still takes a Column gap
        Loader {
          width: parent.width
          visible: active
          active: !!root.plugin?.settings
          source: active ? Quickshell.shellPath("plugins/" + root.plugin.id + "/" + root.plugin.settings) : ""
        }

        // a plugin without options gets a row in their place, like one
        KitRow {
          visible: !root.plugin?.settings
          label: "No options"
          hint: "nothing to set for this plugin"
          labelColor: Theme.foreground2
        }
      }
    }
  }

  onSelectedChanged: pane.contentY = 0
}
