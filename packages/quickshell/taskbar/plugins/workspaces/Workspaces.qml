import QtQuick
import Quickshell.Hyprland
import qs.components
import qs.config

// Hyprland workspaces across all outputs; special workspaces are hidden. Shows
// names or, when the theme sets workspaceFormat "{icon}", icons. Focused and
// visible workspaces are highlighted; click activates.
Row {
  leftPadding: Theme.edgeMargin

  Repeater {
    model: Hyprland.workspaces

    Item {
      id: workspace

      required property var modelData

      readonly property bool highlighted: modelData.focused || modelData.active

      visible: !modelData.name.startsWith("special")
      implicitWidth: Math.max(label.implicitWidth, Theme.workspaceMinWidth) + 4
      implicitHeight: label.implicitHeight

      ThemeText {
        id: label
        anchors.centerIn: parent
        text: {
          if (Theme.workspaceFormat === "{icon}") {
            if (workspace.modelData.focused && Theme.workspaceIconActive !== "") return Theme.workspaceIconActive;
            if (Theme.workspaceIconDefault !== "") return Theme.workspaceIconDefault;
          }
          return workspace.modelData.name.replace(/^name:/, "");
        }
        color: area.containsMouse
          ? (workspace.highlighted ? Theme.yellow : Theme.foreground0)
          : (workspace.highlighted ? Theme.foreground1 : Theme.gray)

        Behavior on color { ColorAnimation { duration: 500; easing.type: Easing.OutSine } }
      }

      MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: workspace.modelData.activate()
      }
    }
  }
}
