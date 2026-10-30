import QtQuick
import Quickshell
import Quickshell.Io
import qs.components
import qs.config

// The file chooser as a window of its own, with a FilesState of its own: it opens
// whether the file manager is up or not, and neither takes the other's folder or
// selection. A request comes from the file-chooser portal (scripts/files_portal.py)
// or from a setting of the shell ("Choose…"): FilesService.pickAsked. Its size is
// Settings › Picker; its window rule comes from scripts/shellapps.py (apps.json).
FloatingWindow {
  id: root

  title: "Choose file"
  visible: false
  implicitWidth: chooser.pickerDims[0]
  implicitHeight: chooser.pickerDims[1]
  color: Theme.background0

  FilesState {
    id: chooser
    active: root.visible
  }

  function resizeTo(w, h) {
    Hypr.call('hl.dispatch(hl.dsp.window.resize({ x = ' + w + ', y = ' + h + ', window = "title:^(Choose file)$" }))');
  }

  // a request while one is open replaces it: the earlier one is answered as cancelled
  Connections {
    target: FilesService
    function onPickAsked(request, onPick) {
      chooser.begin(request, onPick);
      root.visible = true;
      Qt.callLater(() => root.resizeTo(chooser.pickerDims[0], chooser.pickerDims[1]));
    }
  }

  Connections {
    target: chooser
    function onPickerDone() { root.visible = false; }
  }

  // Hyprland closing the window (Super+C) hides it but leaves FloatingWindow's own
  // visible set: reset it, and answer the request as cancelled
  onVisibleChanged: {
    if (visible) return;
    if (chooser.picker) chooser.finishPick([], 1);
    visible = false;
  }

  Loader {
    anchors.fill: parent
    active: root.visible
    sourceComponent: Component { Files { anchors.fill: parent; svc: chooser; onCloseRequested: root.visible = false } }
  }

  IpcHandler {
    target: "filepicker"
    // opens the chooser for a folder, as any "Choose…" does (nothing is done with the answer)
    function open(): void { FilesService.pickFolder("Choose a folder", "", () => {}); }
  }
}
