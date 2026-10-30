import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import qs.config

// The lock screen (Super+Z, `ipc call lock lock`): a Wayland session lock
// with LockScreen on every monitor (dark but for one, if so set); the password goes through PAM (its
// `login` service). If the shell dies while locked, Hyprland
// keeps the screen locked; the shell started again (scripts/supervise.sh)
// finds the marker it left and locks anew (misc.allow_session_lock_restore).
// Options: Shell Manager › Shell apps › Lock screen (ModuleSettings "lock").
Scope {
  id: root

  readonly property string user: ModuleSettings.get("profile", "name", "") || Quickshell.env("USER")
  readonly property bool busy: authentication.busy || lifecycle.unlocking
  readonly property string error: authentication.error
  // the password typed so far, shared by every monitor: keys go to the one
  // Hyprland focuses, the field may show on another
  property alias typed: authentication.typed
  // the monitor in use when it locked (Monitors › Focused)
  property string focusedScreen: ""

  readonly property string screenOption: ModuleSettings.get("lock", "screen", "all")
  // whether a monitor shows the clock and the field; others stay dark. A
  // monitor named in the option that is not connected falls back to all.
  function shows(name) {
    if (screenOption === "all") return true;
    const want = screenOption === "focused" ? focusedScreen : screenOption;
    if (!Quickshell.screens.some(s => s.name === want)) return true;
    return name === want;
  }

  function tryUnlock(password) { if (!busy) authentication.tryUnlock(password); }

  LockAuthentication {
    id: authentication
    context: pam
    locked: sessionLock.locked
    onVerified: lifecycle.verified()
  }

  LockLifecycle {
    id: lifecycle
    context: sessionLock
    storage: QtObject {
      function readMarker() { readMark.running = true; }
      function writeMarker() { mark.running = true; }
      function clearMarker() { cleanup.running = true; }
    }
    onRetryLock: root.lock()
    onFailed: message => authentication.error = message
  }

  // ---- snapshot ----
  // Blurred background: each monitor as it was, shot by grim just before
  // locking (~60 ms) into the runtime dir, removed on unlock. A failed shot
  // still locks; that monitor gets the plain colour.
  readonly property string snapshotDir: Quickshell.env("XDG_RUNTIME_DIR") + "/shell-lock"

  function snapshot(name) { return name !== "" ? "file://" + snapshotDir + "/" + name + ".jpg" : ""; }

  function lock() {
    console.warn("lock: asked for (ipc call lock lock)" + (sessionLock.locked || preparation.busy ? ", already locking" : ""));
    if (sessionLock.locked || preparation.busy) return;
    if (!lifecycle.requestLock()) return;
    if (ModuleSettings.get("lock", "background", "solid") !== "blur") { sessionLock.locked = true; return; }
    preparation.prepare(snapshotDir, Quickshell.screens.map(s => s.name));
  }

  LockPreparation {
    id: preparation
    onReady: sessionLock.locked = true
  }

  Process {
    id: cleanup
    command: ["rm", "-rf", root.snapshotDir]
    onExited: code => lifecycle.cleared(code === 0)
  }

  // ---- after a crash ----
  // Locked, a marker in the runtime dir holds this Hyprland session's
  // signature (it goes with the dir on unlock). Only a new process reads it:
  // finding it for this session, the shell died while locked and locks again
  // at once (no snapshot: the screen is Hyprland's dead-lock one). A live
  // reload takes the lock state the generation before saw locked / unlocked,
  // so a marker left behind never locks it. Not acted on (another session's, or
  // unlocked after a reload), the dir is removed.
  readonly property string session: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") ?? ""
  readonly property string marker: snapshotDir + "/locked"

  Process {
    id: mark
    command: ["bash", "-c", "umask 077; mkdir -p \"$(dirname \"$1\")\" && printf '%s\\n' \"$2\" > \"$1\"",
              "lock", root.marker, root.session]
    onExited: code => lifecycle.marked(code === 0)
  }

  // exit 0: the marker is this session's
  Process {
    id: readMark
    command: ["bash", "-c", "[ -n \"$2\" ] && [ \"$(cat \"$1\" 2>/dev/null)\" = \"$2\" ]", "lock", root.marker, root.session]
    onExited: code => {
      console.warn("lock: marker of this session " + (code === 0 ? "found, locking again after a restart" : "not found"));
      lifecycle.restored(code === 0);
      persist.locked = sessionLock.locked;
    }
  }

  PersistentProperties {
    id: persist
    reloadableId: "lock"
    property bool started: false
    property bool locked: false

    onLoaded: {
      if (!started) { started = true; lifecycle.restore(); }
      // the flag can outlive an unlock: only the marker (kept while locked) says the screen was
      // really locked, else every reload would lock a free screen again
      else if (locked) lifecycle.restore();
      // not locked before, not now (WlSessionLock is Reloadable: whatever
      // it carried over is put right)
      else { sessionLock.locked = false; lifecycle.cleanup(); }
    }
  }

  // ---- idle ----
  // Auto-lock: the compositor's idle notice (ext-idle-notify), asked for only
  // while a delay is set and the screen is free; it respects what inhibits idle (a video).
  readonly property int autoLockMinutes: ModuleSettings.get("lock", "autoLock", 0)

  IdleMonitor {
    enabled: root.autoLockMinutes > 0 && !sessionLock.locked
    timeout: root.autoLockMinutes * 60
    onIsIdleChanged: if (isIdle) root.lock()
  }

  // ---- lid ----
  // The lid is Hyprland's switch bind (`ipc call lock lid`). Anything but
  // Suspend (logind's own) takes the lid from logind with an inhibitor held
  // while the shell runs; the screen then locks, sleeps or does nothing as set.
  readonly property string lidAction: ModuleSettings.get("power", "lid", "suspend")

  function lid() {
    const a = root.lidAction;
    if (a === "lock") root.lock();
    else if (a === "suspend" || a === "hibernate") { root.lock(); Quickshell.execDetached(["systemctl", a]); }
    else if (a === "poweroff") Quickshell.execDetached(["systemctl", "poweroff"]);
  }

  Process {
    running: root.lidAction !== "suspend"
    command: ["systemd-inhibit", "--what=handle-lid-switch", "--who=shell", "--why=Lid action set in Lock screen", "--mode=block", "sleep", "infinity"]
  }

  // ---- power ----
  function power(action) {
    Quickshell.execDetached(["systemctl", action]);
  }

  // ---- keyboard layout ----
  // the main keyboard's layout name; the initial one from `hyprctl devices`
  // (read again on each lock), changes from the activelayout event
  property string layout: ""
  property string keyboard: ""

  function nextLayout() {
    if (keyboard !== "") Quickshell.execDetached(["hyprctl", "switchxkblayout", keyboard, "next"]);
  }

  Process {
    id: devices
    command: ["hyprctl", "devices", "-j"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          // pseudo-keyboards (power buttons) report a stale keymap
          const keyboards = JSON.parse(text).keyboards ?? [];
          const kb = keyboards.find(k => k.main && k.active_keymap) ?? keyboards.find(k => k.active_keymap);
          if (kb) { root.layout = kb.active_keymap; root.keyboard = kb.name; }
        } catch (e) {}
      }
    }
  }

  Connections {
    target: Hyprland
    // data: "<keyboard>,<layout name>"
    function onRawEvent(event) {
      if (event.name === "activelayout" && event.data)
        root.layout = event.data.slice(event.data.indexOf(",") + 1);
    }
  }

  PamContext {
    id: pam
    onPamMessage: authentication.answer()
    onCompleted: result => authentication.complete(result === PamResult.Success)
    onError: authentication.fail()
  }

  WlSessionLock {
    id: sessionLock

    onLockedChanged: {
      console.warn("lock: sessionLock.locked -> " + locked);
      persist.locked = locked;
      if (!locked) return;
      lifecycle.locked();
      root.focusedScreen = Hyprland.focusedMonitor?.name ?? "";
      devices.running = true;
    }

    WlSessionLockSurface {
      id: surface
      LockScreen { anchors.fill: parent; lock: root; screenName: surface.screen?.name ?? ""; main: root.shows(screenName) }
    }
  }

  IpcHandler {
    target: "lock"
    function lock(): void { root.lock(); }
    function lid(): void { root.lid(); }
  }
}
