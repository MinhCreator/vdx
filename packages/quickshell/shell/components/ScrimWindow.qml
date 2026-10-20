import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

// A full-screen layer over the focused monitor that dims it (Theme.scrim) and
// takes the keyboard while open: the launcher, the keybinds and the overview. Children
// sit on the dimmed screen and fade with it, and zoom in a little as it
// opens (Motion.panels); a click on the screen itself emits dismissed().
PanelWindow {
  id: root

  property bool open: false
  // the dim of the screen behind the content (the launcher's and keybinds' "Dim the background")
  property bool dim: true
  property string namespace: "shell"
  default property alias content: stage.data
  signal dismissed()

  screen: Hypr.focusedScreen
  visible: open || fade.running
  anchors { top: true; bottom: true; left: true; right: true }
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: root.namespace
  WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  Rectangle {
    id: scrim
    anchors.fill: parent
    color: root.dim ? Theme.scrim : "transparent"
    opacity: root.open ? 1 : 0
    Behavior on opacity {
      enabled: Motion.panels
      NumberAnimation { id: fade; duration: Motion.ms(160); easing.type: Motion.easing }
    }

    MouseArea { anchors.fill: parent; onClicked: root.dismissed() }

    // what the panel shows: from 96 % to full size as the screen dims
    Item {
      id: stage
      anchors.fill: parent
      scale: Motion.panels ? 0.96 + 0.04 * scrim.opacity : 1
    }
  }
}
