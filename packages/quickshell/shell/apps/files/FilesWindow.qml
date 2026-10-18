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
  // a picker is more compact than the browser: Hyprland's rule sets the size at every
  // show, so the picker's size is set once the window is up
  function resizeTo(w, h) {
    Quickshell.execDetached(["hyprctl", "eval",
      'hl.dispatch(hl.dsp.window.resize({ x = ' + w + ', y = ' + h + ', window = "title:^(Files)$" }))']);
  }

  onVisibleChanged: {
    FilesService.active = visible;
    if (visible && FilesService.picker) Qt.callLater(() => resizeTo(FilesService.pickerDims[0], FilesService.pickerDims[1]));
    if (visible) FilesService.open();
    else {
      // a picker closed by the window (Hyprland's close) answers the portal as cancelled
      if (FilesService.picker) FilesService.finishPick([], 1);
      visible = false;
    }
  }

  // the picker is done (answered, or replaced): the window gives way
  Connections {
    target: FilesService
    function onPickerDone() { root.visible = false; }
    // a setting of the shell asks for a folder: the window comes up as the picker
    function onPickRequested() { root.visible = true; }
    // a request while the browser is already up does not show the window again: the size is set here too
    function onPickerChanged() {
      if (FilesService.picker) Qt.callLater(() => root.resizeTo(FilesService.pickerDims[0], FilesService.pickerDims[1]));
    }
  }

  Files {
    anchors.fill: parent
    onCloseRequested: root.visible = false
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
    function choose(request: string): void {
      FilesService.choose(request);
      root.visible = true;
    }
  }
}
