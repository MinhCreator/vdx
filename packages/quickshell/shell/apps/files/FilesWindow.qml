import QtQuick
import Quickshell
import Quickshell.Io
import qs.components
import qs.config

// The file manager as a window of its own (its window rule comes from
// scripts/shellapps.py, Shell Manager › Shell apps). Super+E or
// `qs -c shell ipc call files toggle`; `ipc call files go <path>` opens a
// folder. Escape clears a search or a selection, then closes.
FloatingWindow {
  id: root

  title: "Files"
  visible: false
  implicitWidth: 1040
  implicitHeight: 640
  color: Theme.background0

  // Hyprland closing the window (Super+C) hides it but leaves FloatingWindow's
  // own visible set, so the next `visible = true` would do nothing: reset it.
  onVisibleChanged: {
    FilesService.active = visible;
    if (visible) FilesService.open();
    else visible = false;
  }

  Loader {
    anchors.fill: parent
    active: root.visible
    sourceComponent: Component { Files { anchors.fill: parent; svc: FilesService; onCloseRequested: root.visible = false } }
  }

  IpcHandler {
    target: "files"
    function toggle(): void { Hypr.toggleWindow(root); }
    function open(): void { root.visible = true; }
    function go(where: string): void {
      FilesService.go(where.replace(/^~(?=\/|$)/, FilesService.home));
      root.visible = true;
    }
    function close(): void { root.visible = false; }
    // the view of the folder shown: list | grid | columns; This computer: list | grid (its own)
    function view(name: string): void {
      FilesService.setOption(FilesService.atComputer ? "computerView" : "view", name);
    }
    // the duplicates of a folder, in the list
    function duplicates(where: string): void {
      FilesService.go(where.replace(/^~(?=\/|$)/, FilesService.home));
      FilesService.findDuplicates(FilesService.path);
      root.visible = true;
    }
    // the file manager opens a path: a folder, or a file in its folder with the file selected
    function reveal(where: string): void {
      FilesService.reveal(where);
      root.visible = true;
    }
    function inspect(where: string): void {
      FilesService.inspect(where);
      root.visible = true;
    }
    // the file-chooser portal's request (scripts/files_portal.py), as JSON
    // answered by the file picker's window (FilePickerWindow), not this one
    function choose(request: string): void { FilesService.choose(request); }
  }
}
