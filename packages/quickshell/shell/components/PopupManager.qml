pragma Singleton
import QtQuick

// Keeps at most one popup open across the bar: opening one hides the previous.
// `holding` keeps an open popup while the capture overlay takes the focus;
// `frozen` hides it once the overlay shows a still copy of the screen with it.
QtObject {
  property var current: null
  property bool holding: false
  property bool frozen: false
  // where the last open popup's bar underline stood: { bar, x, width, at }
  property var lastLine: null
  onHoldingChanged: if (!holding) frozen = false

  function open(win) {
    if (current === win) return;
    const prev = current;
    current = win;                   // first, so prev's close() is a no-op
    if (prev?.visible) prev.visible = false;
  }

  function close(win) {
    if (current === win) current = null;
  }
}
