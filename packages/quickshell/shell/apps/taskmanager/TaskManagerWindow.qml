import QtQuick
import Quickshell
import Quickshell.Io
import qs.components
import qs.config

// The task manager as a window of its own (its window rule comes from scripts/shellapps.py (Shell Manager › Shell apps)). Super+D or
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
    function toggle(): void { Hypr.toggleWindow(root); }
    function open(): void { root.visible = true; }
    function close(): void { root.visible = false; }
  }
}
