import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.kit

// The toolbar's Delay running: the seconds left, at the bottom of the focused
// monitor, away from the popups and the island one may want in the shot. A
// click or Super+Shift+S cancels. It is gone before the screens freeze again.
Variants {
  model: CaptureService.countdown > 0
    ? Quickshell.screens.filter(s => s.name === (Hyprland.focusedMonitor?.name ?? s.name)).slice(0, 1) : []

  PanelWindow {
    required property var modelData

    screen: modelData
    anchors.bottom: true
    margins.bottom: 32
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-capture-countdown"
    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight
    color: "transparent"

    Rectangle {
      id: pill

      implicitWidth: row.implicitWidth + 2 * Theme.gapWide
      implicitHeight: Theme.controlHeight + 2 * Theme.gapMedium
      radius: Theme.radiusSurface
      color: Theme.background0
      border.width: Theme.windowFrameWidth
      border.color: Theme.popupFrame

      Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.gapMedium

        KitIcon { anchors.verticalCenter: parent.verticalCenter; name: "clock" }

        KitText {
          anchors.verticalCenter: parent.verticalCenter
          text: "Capture in " + CaptureService.countdown + " s"
          font.weight: Font.DemiBold
        }

        KitText {
          anchors.verticalCenter: parent.verticalCenter
          text: "click to cancel"
          color: Theme.muted
          font.pixelSize: Theme.fontSize - 2
        }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: CaptureService.cancelDelay()
      }
    }
  }
}
