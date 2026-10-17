import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.apps.capture
import qs.bar
import qs.config
import qs.kit

// Screen capture in the bar: a camera; while recording, a red dot with the
// elapsed time. A click or Super+Shift+S opens its panel, which comes out of
// the island like the other modules' popups; the selection starts from there.
Item {
  id: root

  required property PanelWindow bar

  // the Folder opens capture's popup when its tile is clicked
  function openPopup() { popup.toggle(); }

  // the focused monitor's bar shows the panel
  Connections {
    target: CaptureService
    function onPanelRequested() {
      if ((Hyprland.focusedMonitor?.name ?? "") !== (root.bar.screen?.name ?? "")) return;
      CaptureService.panelHandled = true;
      popup.toggle();
    }
  }

  property int elapsed: 0

  implicitWidth: face.implicitWidth
  implicitHeight: face.implicitHeight

  KitBarItem {
    id: face
    icon: CaptureService.recording ? "circle" : "camera"
    text: BarLayout.faceText("capture", CaptureService.recording
      ? String(Math.floor(root.elapsed / 60)).padStart(2, "0") + ":" + String(root.elapsed % 60).padStart(2, "0")
      : "")
    tint: CaptureService.recording ? Theme.red : Theme.foreground0
  }

  Timer {
    interval: 500
    running: CaptureService.recording
    repeat: true
    triggeredOnStart: true
    onTriggered: root.elapsed = Math.floor((Date.now() - CaptureService.recordStarted) / 1000)
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: popup.toggle()
  }

  // Start closes the panel; the selection waits until the island has folded
  // back to the bar, so the still shows the bar and not the panel
  property bool startPending: false

  Timer {
    id: settle
    interval: Motion.slow + 60
    onTriggered: {
      root.startPending = false;
      CaptureService.startSelection();
    }
  }

  BarPopup {
    id: popup
    anchorItem: root
    moduleId: "capture"
    bar: root.bar
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight
    onHidden: if (root.startPending) settle.restart()

    CapturePopup {
      id: content
      anchors.fill: parent
      elapsed: root.elapsed
      onStarted: {
        root.startPending = true;
        popup.visible = false;
      }
    }
  }
}
