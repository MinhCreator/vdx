import QtQuick
import Quickshell.Hyprland
import qs.config
import qs.kit

// Hyprland workspaces across all outputs; special workspaces are hidden.
// Drawn as digits, squares, dots or dashes (Modules › Workspaces). Focused
// and visible workspaces are highlighted; a click activates.
Row {
  id: root

  readonly property string style: ModuleSettings.get("workspaces", "style", "numbers")
  // the shape styles draw no text: a square, a dot or a dash each
  readonly property bool shape: style === "squares" || style === "dots" || style === "dashes"

  spacing: shape ? 4 : 0

  // desk 10 is key 0, so it sorts first: 0 1 2 … 9
  function order(ws) { return ws.id === 10 ? 0 : ws.id }
  readonly property var ordered: Hyprland.workspaces.values.slice().sort((a, b) => order(a) - order(b))

  Repeater {
    model: root.ordered

    Item {
      id: workspace

      required property var modelData

      readonly property bool highlighted: modelData.focused || modelData.active

      visible: !modelData.name.startsWith("special")
      readonly property color tone: area.containsMouse
        ? (highlighted ? Theme.yellow : Theme.foreground0)
        : (highlighted ? Theme.foreground1 : Theme.gray)

      implicitWidth: root.shape ? (root.style === "dashes" ? 14 : 10) : Math.max(label.implicitWidth, Theme.workspaceMinWidth) + 4
      implicitHeight: label.implicitHeight

      // the shapes: a filled one for the focused / visible, an outline for the
      // rest (dots are round); dashes are always filled, in the tone
      Rectangle {
        anchors.centerIn: parent
        visible: root.shape
        width: root.style === "dashes" ? 12 : 8
        height: root.style === "dashes" ? 2 : 8
        radius: root.style === "dots" ? 4 : 0
        color: root.style === "dashes" || workspace.highlighted ? workspace.tone : "transparent"
        border.width: root.style === "dashes" || workspace.highlighted ? 0 : 1
        border.color: workspace.tone

        Behavior on color { ColorAnimation { duration: 500; easing.type: Easing.OutSine } }
      }

      KitText {
        id: label
        anchors.centerIn: parent
        visible: !root.shape
        // desk 10 is the key 0 (SUPER+0)
        text: workspace.modelData.id === 10 ? "0" : workspace.modelData.name.replace(/^name:/, "")
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
