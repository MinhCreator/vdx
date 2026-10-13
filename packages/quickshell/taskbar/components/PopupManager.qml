pragma Singleton
import QtQuick

// Keeps at most one popup open across the bar: opening one hides the previous.
QtObject {
  property var current: null

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
