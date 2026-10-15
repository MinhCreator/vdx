import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

// A full-screen layer over the focused monitor that dims it (Theme.scrim) and
// takes the keyboard while open: the system menu and the overview. Children
// sit on the dimmed screen and fade with it; a click on the screen itself
// emits dismissed().
PanelWindow {
  id: root

  property bool open: false
  property string namespace: "shell"
  default property alias content: scrim.data
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
    color: Theme.scrim
    opacity: root.open ? 1 : 0
    Behavior on opacity { NumberAnimation { id: fade; duration: 140 } }

    MouseArea { anchors.fill: parent; onClicked: root.dismissed() }
  }
}
