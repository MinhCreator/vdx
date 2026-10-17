import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.apps.capture
import qs.bar
import qs.config

// The keybind's panel when no bar's Capture module answers (none placed on
// this bar, or only on another monitor): the same panel as the module's, from
// the centre of the focused bar. Every bar holds one; only the focused
// monitor's answers. Start closes it and the selection waits until it is gone.
Item {
  id: root

  required property PanelWindow bar
  required property Item anchorItem     // where the popup hangs: the bar's centre

  property int elapsed: 0
  property bool startPending: false

  Connections {
    target: CaptureService
    function onPanelFallbackRequested() {
      if ((Hyprland.focusedMonitor?.name ?? "") !== (root.bar.screen?.name ?? "")) return;
      popup.toggle();
    }
  }

  Timer {
    id: settle
    interval: Motion.slow + 60
    onTriggered: {
      root.startPending = false;
      CaptureService.startSelection();
    }
  }

  Timer {
    interval: 500
    running: CaptureService.recording
    repeat: true
    triggeredOnStart: true
    onTriggered: root.elapsed = Math.floor((Date.now() - CaptureService.recordStarted) / 1000)
  }

  BarPopup {
    id: popup
    anchorItem: root.anchorItem
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
      onLibraryRequested: {
        popup.visible = false;
        CaptureService.openLibrary();
      }
    }
  }
}
