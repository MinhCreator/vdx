pragma Singleton

import Quickshell

// The shell's own IPC from inside it, as a key bind calls it: another
// window's or app's IpcHandler (`qs -c shell ipc call <target> <fn> [args]`).
Singleton {
  function command(target, fn, args) { return ["qs", "-c", "shell", "ipc", "call", target, fn].concat(args ?? []); }
  function call(target, fn, args) { Quickshell.execDetached(command(target, fn, args)); }
}
