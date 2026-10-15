import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland

// The lock screen (Super+Z, `ipc call lock lock`): a Wayland session lock
// with LockScreen on every monitor; the password goes through PAM (the
// `login` service, as swaylock's). If the shell dies while locked, Hyprland
// keeps the screen locked; `qs -c taskbar` started again locks it anew
// (misc.allow_session_lock_restore).
Scope {
  id: root

  readonly property string user: Quickshell.env("USER")
  property bool busy: false
  property string error: ""
  property string pending: ""

  function tryUnlock(password) {
    if (busy || password === "") return;
    busy = true;
    error = "";
    pending = password;
    pam.start();
  }

  PamContext {
    id: pam
    onPamMessage: {
      if (responseRequired) { respond(root.pending); root.pending = ""; }
    }
    onCompleted: result => {
      root.busy = false;
      if (result === PamResult.Success) { sessionLock.locked = false; root.error = ""; }
      else root.error = "Wrong password";
    }
    onError: e => { root.busy = false; root.error = "PAM error"; }
  }

  WlSessionLock {
    id: sessionLock

    WlSessionLockSurface {
      LockScreen { anchors.fill: parent; lock: root }
    }
  }

  IpcHandler {
    target: "lock"
    function lock(): void { sessionLock.locked = true; }
  }
}
