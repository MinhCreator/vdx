import QtQuick
import Quickshell
import Quickshell.Io
import qs.components
import qs.config
import qs.kit

// Capture as a window of its own (how it opens: Shell apps).
// `qs -c shell ipc call captures <toggle|open|library|close>`; Escape closes.
// The Capture tab is the bar popup's choices with all of them shown; the
// Library tab lists the saved screenshots and recordings.
FloatingWindow {
  id: root

  title: "Capture"
  visible: false
  implicitWidth: 760
  implicitHeight: 600
  color: Theme.background0

  property string tab: "capture"

  // Hyprland closing the window hides it but leaves FloatingWindow's own
  // visible set, so the next `visible = true` would do nothing: reset it.
  onVisibleChanged: if (visible) library.refresh(); else visible = false;
  onTabChanged: if (tab === "library") library.refresh();

  KitHeader {
    id: header

    anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.windowPadding; topMargin: Theme.windowPadding - Theme.headerInset }
    icon: "camera"
    title: "Capture"
    subtitle: CaptureService.recording ? "RECORDING" : "SCREENSHOTS AND RECORDINGS"

    KitChoices {
      model: [{ label: "Capture", value: "capture" }, { label: "Library", value: "library" }]
      current: root.tab
      onPicked: value => root.tab = value
    }
  }

  Flickable {
    id: page

    anchors {
      left: parent.left; right: parent.right; bottom: parent.bottom
      top: header.bottom; topMargin: Theme.gapGroup
      leftMargin: Theme.windowPadding; rightMargin: Theme.windowPadding; bottomMargin: Theme.windowPadding
    }
    contentHeight: pageColumn.implicitHeight
    clip: true

    Column {
      id: pageColumn

      width: page.width
      spacing: Theme.gapGroup

      CaptureControls {
        visible: root.tab === "capture"
        width: parent.width
        onStarted: {
          root.visible = false;
          selectionDelay.restart();
        }
      }

      CaptureLibrary {
        id: library

        visible: root.tab === "library"
        width: parent.width
      }
    }
  }

  // the window hides first, so the selection starts on the screen it left
  Timer {
    id: selectionDelay

    interval: 150
    onTriggered: CaptureService.startSelection()
  }

  Shortcut {
    sequences: [StandardKey.Cancel]
    onActivated: root.visible = false
  }

  IpcHandler {
    target: "captures"
    function toggle(): void { Hypr.toggleWindow(root); }
    function open(): void { root.visible = true; }
    function library(): void { root.tab = "library"; root.visible = true; }
    function close(): void { root.visible = false; }
  }
}
