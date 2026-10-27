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

  readonly property string user: Quickshell.env("USER")
  property bool busy: false
  property string error: ""
  property string pending: ""
  // the password typed so far, shared by every monitor: keys go to the one
  // Hyprland focuses, the field may show on another
  property string typed: ""
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

  function tryUnlock(password) {
    if (busy || password === "") return;
    busy = true;
    error = "";
    pending = password;
    pam.start();
  }

  // ---- snapshot ----
  // Blurred background: each monitor as it was, shot by grim just before
  // locking (~60 ms) into the runtime dir, removed on unlock. A failed shot
  // still locks; that monitor gets the plain colour.
  readonly property string snapshotDir: Quickshell.env("XDG_RUNTIME_DIR") + "/shell-lock"

  function snapshot(name) { return name !== "" ? "file://" + snapshotDir + "/" + name + ".jpg" : ""; }

  function lock() {
    console.warn("lock: asked for (ipc call lock lock)" + (sessionLock.locked || shot.running ? ", already locking" : ""));
    if (sessionLock.locked || shot.running) return;
    if (ModuleSettings.get("lock", "background", "solid") !== "blur") { sessionLock.locked = true; return; }
    shot.command = ["bash", "-c", "umask 077; d=$1; shift; mkdir -p \"$d\"; for m; do grim -t jpeg -q 85 -o \"$m\" \"$d/$m.jpg\" & done; wait",
                    "lock", snapshotDir].concat(Quickshell.screens.map(s => s.name));
    shot.running = true;
  }

  Process {
    id: shot
    onExited: sessionLock.locked = true
  }

  Process { id: cleanup; command: ["rm", "-rf", root.snapshotDir] }

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
  }

  // exit 0: the marker is this session's
  Process {
    id: readMark
    command: ["bash", "-c", "[ -n \"$2\" ] && [ \"$(cat \"$1\" 2>/dev/null)\" = \"$2\" ]", "lock", root.marker, root.session]
    onExited: code => {
      console.warn("lock: marker of this session " + (code === 0 ? "found, locking again after a restart" : "not found"));
      if (code === 0) sessionLock.locked = true;
      else { persist.locked = false; cleanup.running = true; }
    }
  }

  PersistentProperties {
    id: persist
    reloadableId: "lock"
    property bool started: false
    property bool locked: false

    onLoaded: {
      if (!started) { started = true; readMark.running = true; }
      // the flag can outlive an unlock: only the marker (kept while locked) says the screen was
      // really locked, else every reload would lock a free screen again
      else if (locked) readMark.running = true;
      // not locked before, not now (WlSessionLock is Reloadable: whatever
      // it carried over is put right)
      else { sessionLock.locked = false; cleanup.running = true; }
    }
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
    onPamMessage: {
      if (responseRequired) { respond(root.pending); root.pending = ""; }
    }
    onCompleted: result => {
      root.busy = false;
      // the marker goes before the unlock, detached: a shell that dies right after
      // unlocking must not leave one behind (the next start would lock again)
      if (result === PamResult.Success) {
        Quickshell.execDetached(["rm", "-rf", root.snapshotDir]);
        sessionLock.locked = false;
        root.error = "";
      }
      else root.error = "Wrong password";
    }
    onError: e => { root.busy = false; root.error = "PAM error"; }
  }

  WlSessionLock {
    id: sessionLock

    onLockedChanged: {
      console.warn("lock: sessionLock.locked -> " + locked);
      persist.locked = locked;
      if (!locked) { cleanup.running = true; return; }
      mark.running = true;
      root.focusedScreen = Hyprland.focusedMonitor?.name ?? "";
      root.typed = "";
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
  }
}
