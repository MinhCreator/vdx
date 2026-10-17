import QtQuick
import qs.apps.capture
import qs.config
import qs.kit

// The capture module's popup: the app's choices (CaptureControls) with what the
// bar module's options let it show (Apps › Bar module). Start closes the popup
// and hands over to the selection; a recording shows its time and stops here.
KitFrame {
  id: root

  property int elapsed: 0

  signal started()

  KitHeader {
    icon: CaptureService.kind === "record" ? "video" : "camera"
    title: "Capture"
    subtitle: CaptureService.recording
      ? "RECORDING · " + String(Math.floor(root.elapsed / 60)).padStart(2, "0") + ":" + String(root.elapsed % 60).padStart(2, "0")
      : controls.labels[CaptureService.mode] + " · " + controls.labels[CaptureService.kind]
        + (CaptureService.cursor ? " · CURSOR" : "")
  }

  KitLine {}

  CaptureControls {
    id: controls

    width: parent.width
    showSound: ModuleSettings.get("capture", "popupSound", true)
    showFps: ModuleSettings.get("capture", "popupFps", true)
    showQuality: ModuleSettings.get("capture", "popupQuality", true)
    showAdvanced: ModuleSettings.get("capture", "popupAdvanced", true)
    advancedOpen: ModuleSettings.get("capture", "popupAdvancedOpen", false)
    showNotes: ModuleSettings.get("capture", "popupNotes", true)
    showCursor: ModuleSettings.get("capture", "popupCursor", true)
    onStarted: root.started()
  }
}
