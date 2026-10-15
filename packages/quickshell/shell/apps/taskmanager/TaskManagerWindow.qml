import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// The task manager as a window of its own (Hyprland floats and centres it by
// its title, see hypr/components/rules.lua). Super+D or
// `qs -c shell ipc call taskmanager toggle`; Escape clears the search,
// then closes. Processes are polled only while it is open.
FloatingWindow {
  id: root

  title: "Task Manager"
  visible: false
  implicitWidth: 780
  implicitHeight: 600
  color: Theme.background0

  onVisibleChanged: {
    TaskManagerService.open = visible;
    if (!visible) TaskManagerService.query = "";
  }

  TaskManager {
    id: content
    anchors.fill: parent
    focus: true
  }

  Shortcut {
    sequences: [StandardKey.Cancel]
    onActivated: {
      if (TaskManagerService.query !== "") TaskManagerService.query = "";
      else root.visible = false;
    }
  }

  IpcHandler {
    target: "taskmanager"
    function toggle(): void { root.visible = !root.visible; }
    function open(): void { root.visible = true; }
    function close(): void { root.visible = false; }
  }
}
