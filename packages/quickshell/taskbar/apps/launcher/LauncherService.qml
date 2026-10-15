pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The system menu's lists (Launcher.qml shows them): installed apps, files
// in ~ (fd), the shell's own actions, power. Every item is
// { icon | image, title, hint, keys, run() }.
Singleton {
  id: root

  // ---- state ----
  property bool open: false
  property var files: []                    // [path] of the last search
  property bool searching: false

  readonly property string home: Quickshell.env("HOME")

  function ipc(target, fn, arg) {
    const c = ["qs", "-c", "taskbar", "ipc", "call", target, fn];
    return arg ? c.concat([arg]) : c;
  }
  function exec(command) { Quickshell.execDetached(command); }
  function sh(script) { exec(["bash", "-c", script]); }

  // ---- apps ----
  function apps(q) {
    return DesktopEntries.applications.values
      .filter(e => !e.noDisplay && (q === "" || (e.name + " " + e.genericName + " " + (e.keywords ?? []).join(" ")).toLowerCase().includes(q)))
      .sort((a, b) => a.name.localeCompare(b.name))
      .map(e => ({ image: Quickshell.iconPath(e.icon, true), icon: "app-window", title: e.name,
                   hint: e.comment || e.genericName, run: () => e.execute() }));
  }

  // ---- files ----
  function searchFiles(q) {
    if (q.length < 2) { files = []; return; }
    filesProc.running = false;
    filesProc.command = ["fd", "--max-results", "60", "--ignore-case", "--hidden", "--exclude", ".git", "--exclude", ".cache", q, home];
    searching = true;
    filesProc.running = true;
  }
  function fileItems() {
    return files.map(p => ({ icon: p.endsWith("/") ? "folder" : "file", title: p.replace(/\/$/, "").split("/").pop(),
                             hint: p.replace(home, "~"), run: () => root.exec(["xdg-open", p]) }));
  }

  Process {
    id: filesProc
    stdout: StdioCollector { onStreamFinished: { root.files = text.split("\n").filter(l => l !== ""); root.searching = false; } }
  }

  // ---- the shell's own actions ----
  readonly property var shellItems: [
    { icon: "sliders", title: "Shell Manager", hint: "Settings of the shell", keys: "Super+S", run: () => exec(ipc("shell", "toggle")) },
    { icon: "sun", title: "Appearance", hint: "Theme, wallpaper, font, cursor", run: () => exec(ipc("shell", "open", "appearance")) },
    { icon: "layout", title: "Bar", hint: "Monitors, layout, modules", run: () => exec(ipc("shell", "open", "bar")) },
    { icon: "columns", title: "Windows", hint: "Window mode, gaps, dock", run: () => exec(ipc("shell", "open", "windows")) },
    { icon: "keyboard", title: "Binds", hint: "Every keybind", run: () => exec(ipc("shell", "open", "binds")) },
    { icon: "grid", title: "Overview", hint: "Every workspace at once", keys: "Super+Tab", run: () => exec(ipc("overview", "toggle")) },
    { icon: "activity", title: "Task manager", hint: "Processes, CPU, memory", keys: "Super+D", run: () => exec(ipc("taskmanager", "toggle")) },
    { icon: "brush", title: "Cleaner", hint: "Caches, trash, the system", keys: "Super+X", run: () => exec(ipc("cleaner", "toggle")) },
    { icon: "camera", title: "Capture", hint: "Screenshot or recording", keys: "Super+Shift+S", run: () => exec(ipc("capture", "open")) },
    { icon: "clipboard", title: "Clipboard", hint: "History", keys: "Super+B", run: () => exec(ipc("clipboard", "toggle")) },
    { icon: "tiling", title: "Tiling", hint: "Window mode", run: () => exec(ipc("windowmode", "set", "tiling")) },
    { icon: "app-window", title: "Floating", hint: "Window mode", run: () => exec(ipc("windowmode", "set", "floating")) },
    { icon: "columns", title: "Scrolling", hint: "Window mode", run: () => exec(ipc("windowmode", "set", "scrolling")) }
  ]

  // ---- power ----
  readonly property var powerItems: [
    { icon: "lock", title: "Lock", hint: "The lock screen", keys: "Super+Z", run: () => exec(ipc("lock", "lock")) },
    { icon: "moon", title: "Suspend", hint: "Sleep, locked", run: () => sh("qs -c taskbar ipc call lock lock; sleep 0.5; systemctl suspend") },
    { icon: "log-out", title: "Log out", hint: "End the Hyprland session", run: () => exec(["hyprctl", "eval", "hl.dispatch(hl.dsp.exit())"]) },
    { icon: "refresh", title: "Reboot", hint: "Restart the computer", run: () => exec(["systemctl", "reboot"]) },
    { icon: "cpu", title: "Reboot to firmware", hint: "UEFI setup", run: () => exec(["systemctl", "reboot", "--firmware-setup"]) },
    { icon: "power", title: "Shut down", hint: "Power off", run: () => exec(["systemctl", "poweroff"]) }
  ]

  function filter(list, q) {
    return q === "" ? list : list.filter(i => (i.title + " " + i.hint).toLowerCase().includes(q));
  }

  IpcHandler {
    target: "launcher"
    function toggle(): void { root.open = !root.open; }
  }
}
