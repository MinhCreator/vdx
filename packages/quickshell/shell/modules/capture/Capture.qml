import QtQuick
import Quickshell
import qs.apps.capture
import qs.bar
import qs.config
import qs.kit

// Screen capture in the bar: a camera; a click is Super+Shift+S (the screens
// freeze, the overlay's toolbar holds the choices). While recording: a red
// dot with the elapsed time, and a click stops it.
Item {
  id: root

  required property PanelWindow bar

  // the Folder's tile: the same as a click
  function openPopup() { CaptureService.open(); }

  // shown on this bar's screen: the recording shows here, CaptureRecording's
  // panel stays away (a module hidden in a folder or a closed hub does not count)
  function seen() {
    for (let p = root; p; p = p.parent)
      if (!p.visible || p.opacity < 0.5) return false;
    return root.width > 0;
  }

  Connections {
    target: CaptureService
    function onFacesAsked() {
      if (root.seen()) CaptureService.faceScreens = CaptureService.faceScreens.concat([root.bar.screen?.name ?? ""]);
    }
  }

  implicitWidth: face.implicitWidth
  implicitHeight: face.implicitHeight

  KitBarItem {
    id: face
    icon: CaptureService.recording ? "circle" : "camera"
    text: BarLayout.faceText("capture", CaptureService.recording ? CaptureService.elapsedText : "")
    tint: CaptureService.recording ? Theme.red : Theme.foreground0
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: CaptureService.open()
  }
}
