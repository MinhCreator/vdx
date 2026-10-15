import QtQuick
import Quickshell.Hyprland
import qs.components
import qs.config

// Hyprland workspaces across all outputs; special workspaces are hidden. Shows
// numbers (names; icons when the theme sets workspaceFormat "{icon}") or small
// squares (Plugins › Workspaces). Focused and visible workspaces are
// highlighted; click activates.
Row {
  id: root

  readonly property bool squares: PluginSettings.get("workspaces", "style", "numbers") === "squares"

  spacing: squares ? 4 : 0

  Repeater {
    model: Hyprland.workspaces

    Item {
      id: workspace

      required property var modelData

      readonly property bool highlighted: modelData.focused || modelData.active

      visible: !modelData.name.startsWith("special")
      readonly property color tone: area.containsMouse
        ? (highlighted ? Theme.yellow : Theme.foreground0)
        : (highlighted ? Theme.foreground1 : Theme.gray)

      implicitWidth: root.squares ? 10 : Math.max(label.implicitWidth, Theme.workspaceMinWidth) + 4
      implicitHeight: label.implicitHeight

      // squares: a filled one for the focused / visible, an outline for the rest
      Rectangle {
        anchors.centerIn: parent
        visible: root.squares
        width: 8
        height: 8
        color: workspace.highlighted ? workspace.tone : "transparent"
        border.width: workspace.highlighted ? 0 : 1
        border.color: workspace.tone

        Behavior on color { ColorAnimation { duration: 500; easing.type: Easing.OutSine } }
      }

      ThemeText {
        id: label
        anchors.centerIn: parent
        visible: !root.squares
        text: {
          if (Theme.workspaceFormat === "{icon}") {
            if (workspace.modelData.focused && Theme.workspaceIconActive !== "") return Theme.workspaceIconActive;
            if (Theme.workspaceIconDefault !== "") return Theme.workspaceIconDefault;
          }
          return workspace.modelData.name.replace(/^name:/, "");
        }
        color: workspace.tone

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
