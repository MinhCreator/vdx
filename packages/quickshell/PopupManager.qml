pragma Singleton
import QtQuick

// PopupManager — only one popup may be open across the whole bar at a time.
//
// Every popup module (Wifi, Mihomo, …) registers itself when its PopupWindow
// becomes visible and unregisters when it hides. Opening a second popup
// force-closes the previous one; the previous popup's own onVisibleChanged
// then drops its HyprlandFocusGrab and stops whatever streams it started,
// so nothing keeps running behind the new one.

QtObject {
  id: root

  // The PopupWindow currently shown, or null.
  property var current: null

  function open(win) {
    if (current === win) return;
    var prev = current;
    // Flip the pointer first so the closing popup's close() call is a no-op.
    current = win;
    if (prev && prev.visible) prev.visible = false;
  }

  function close(win) {
    if (current === win) current = null;
  }
}
