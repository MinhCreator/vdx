import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

// A solid layer over one screen while a theme is applied: the switch repaints
// every window, and this hides it. Shown at once, gone once the new colours are
// read (ThemeService), no animation.
PanelWindow {
  id: root

  required property var modelData

  screen: modelData
  visible: ThemeService.covering
  anchors { top: true; bottom: true; left: true; right: true }
  exclusionMode: ExclusionMode.Ignore
  color: ThemeService.coverColor
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "shell-theme-curtain"
}
