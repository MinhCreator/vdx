pragma Singleton
import QtQuick
import Quickshell.Hyprland
import qs.config

// Keeps at most one popup open across the bar: opening one hides the previous.
// `holding` keeps an open popup while the capture overlay takes the focus;
// `frozen` hides it once the overlay shows a still copy of the screen with it.
QtObject {
  property var current: null
  property bool holding: false
  property bool frozen: false
  // where the last open popup's bar underline stood: { bar, x, width, at }
  property var lastLine: null
  // screen -> the height of the extra bars at its bottom (they set it): the
  // catcher leaves them uncovered
  property var bottomBars: ({})
  function setBottomBar(screen, height) {
    const m = Object.assign({}, bottomBars);
    if (height > 0) m[screen] = Math.max(m[screen] ?? 0, height); else delete m[screen];
    bottomBars = m;
  }
  onHoldingChanged: if (!holding) frozen = false

  // ---- ipc ----
  // Every bar has its own popup per module, but an IPC target answers once:
  // the popup on the focused monitor's bar, else the first one there is.
  property var ipcPopups: ({})               // target -> [BarPopup]
  property int ipcRevision: 0                // bumped on every change: owner() bindings follow

  function addIpc(target, popup) {
    ipcPopups[target] = (ipcPopups[target] ?? []).concat([popup]);
    ipcRevision++;
  }

  function removeIpc(target, popup) {
    ipcPopups[target] = (ipcPopups[target] ?? []).filter(p => p !== popup);
    ipcRevision++;
  }

  function ipcOwner(target) {
    if (ipcRevision < 0) return null;        // read: a dependency of the caller's binding
    const list = ipcPopups[target] ?? [];
    return list.find(p => p.bar.screen?.name === Hyprland.focusedMonitor?.name) ?? list[0] ?? null;
  }

  function open(win) {
    if (current === win) return;
    const prev = current;
    current = win;                   // first, so prev's close() is a no-op
    if (prev?.visible) prev.visible = false;
  }

  function close(win) {
    if (current === win) current = null;
  }

  // An app's window opened from its bar module closes that module's popup.
  function closeModule(id) {
    if (current?.moduleId === id && ModuleSettings.get(id, "closeOnOpen", true)) current.visible = false;
  }
}
