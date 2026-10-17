import QtQuick
import Quickshell
import Quickshell.Io
import qs.components
import qs.config
import qs.kit

// Capture as a window of its own (how it opens: Shell apps): the library of the
// saved screenshots and recordings. Taking one is the bar popup's job.
// `qs -c shell ipc call captures <toggle|open|library|close>`; Escape closes.
FloatingWindow {
  id: root

  title: "Capture"
  visible: false
  implicitWidth: 760
  implicitHeight: 600
  color: Theme.background0

  // Hyprland closing the window hides it but leaves FloatingWindow's own
  // visible set, so the next `visible = true` would do nothing: reset it.
  onVisibleChanged: if (visible) library.refresh(); else visible = false;

  KitHeader {
    id: header

    anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.windowPadding; topMargin: Theme.windowPadding - Theme.headerInset }
    icon: "camera"
    title: "Capture"
    subtitle: CaptureService.recording ? "RECORDING · LIBRARY" : "LIBRARY"
  }

  // the foot: the library's clear, pinned under a separator like the other apps' feet
  Column {
    id: foot

    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Theme.windowPadding; bottomMargin: Theme.windowPadding }
    spacing: Theme.gapWide
    visible: library.items.length > 0

    KitLine {}

    KitButton {
      width: parent.width
      icon: "trash"
      iconTint: library.confirming ? Theme.red : Theme.foreground0
      text: library.confirming ? "Move all " + library.items.length + " to trash?" : "Clear library"
      onClicked: library.clearAll()
    }
  }

  Flickable {
    id: page

    anchors {
      left: parent.left; right: parent.right
      top: header.bottom; topMargin: Theme.gapGroup
      bottom: foot.visible ? foot.top : parent.bottom
      leftMargin: Theme.windowPadding; rightMargin: Theme.windowPadding
      bottomMargin: foot.visible ? Theme.gapGroup : Theme.windowPadding
    }
    contentHeight: library.implicitHeight
    clip: true

    CaptureLibrary {
      id: library

      width: page.width
    }
  }

  Shortcut {
    sequences: [StandardKey.Cancel]
    onActivated: root.visible = false
  }

  IpcHandler {
    target: "captures"
    function toggle(): void { Hypr.toggleWindow(root); }
    function open(): void { root.visible = true; }
    function library(): void { root.visible = true; }
    function close(): void { root.visible = false; }
  }
}
