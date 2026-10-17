import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

// Outside-click dismissal for bar popups: while one is open, a clear layer
// covers every screen below the bar and closes it on a click. The bar stays
// uncovered, so a click on another module opens that module's popup at once.
Variants {
  // island style: the popup lives in the bar window, its focus grab dismisses
  model: PopupManager.current && !PopupManager.holding && !Theme.island ? Quickshell.screens : []

  PanelWindow {
    required property var modelData

    screen: modelData
    anchors { left: true; right: true; top: true; bottom: true }
    margins.top: Theme.barEdge
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-popup-catcher"
    color: "transparent"

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.AllButtons
      onPressed: if (PopupManager.current) PopupManager.current.visible = false
    }
  }
}
