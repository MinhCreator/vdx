pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.apps.shellmanager
import qs.modules.windows

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
    const c = ["qs", "-c", "shell", "ipc", "call", target, fn];
    return arg ? c.concat([arg]) : c;
  }
  function exec(command) { Quickshell.execDetached(command); }
  function sh(script) { exec(["bash", "-c", script]); }

  // ---- apps ----
  function apps(q) {
    return filter(shellApps, q).concat(DesktopEntries.applications.values
      .filter(e => !e.noDisplay && (q === "" || (e.name + " " + e.genericName + " " + (e.keywords ?? []).join(" ")).toLowerCase().includes(q)))
      .map(e => ({ image: Quickshell.iconPath(e.icon, true), icon: "app-window", title: e.name,
                   hint: e.comment || e.genericName, run: () => e.execute() })))
      .sort((a, b) => a.title.localeCompare(b.title));
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

  // ---- the shell's own apps (apps/apps.json, not the menu itself) and the ----
  // clipboard, listed with the installed ones; keys from the live binds ----
  function keysOf(bind) { return BindsService.keysFor(bind).join(" + "); }
  readonly property var shellApps: ShellAppsService.entries.filter(e => e.id !== "launcher")
    .map(e => ({ icon: e.icon, title: e.label, hint: e.about, keys: keysOf(e.bind), run: () => ShellAppsService.run(e) }))
    .concat([{ icon: "clipboard", title: "Clipboard", hint: "History", keys: keysOf("Clipboard history"),
               run: () => exec(ipc("clipboard", "toggle")) }])

  // ---- the shell's own actions ----
  // the window modes come from WindowsService, as in its popup and page
  readonly property var shellItems: modeItems.concat([
    { icon: "sun", title: "Appearance", hint: "Theme, wallpaper, font, cursor", run: () => exec(ipc("shell", "open", "appearance")) },
    { icon: "layout", title: "Bar", hint: "Monitors, layout, modules", run: () => exec(ipc("shell", "open", "bar")) },
    { icon: "app-window", title: "Windows", hint: "Window mode, gaps, taskbar", run: () => exec(ipc("shell", "open", "windows")) },
    { icon: "keyboard", title: "Binds", hint: "Every keybind", run: () => exec(ipc("shell", "open", "binds")) }
  ])


  readonly property var modeItems: WindowsService.modes.map(m => ({ icon: m.icon, title: m.label, hint: "Window mode",
                                                                   run: () => WindowsService.setMode(m.value) }))

  // ---- power ----
  readonly property var powerItems: [
    { icon: "lock", title: "Lock", hint: "The lock screen", keys: keysOf("Lock the screen"), run: () => exec(ipc("lock", "lock")) },
    { icon: "moon", title: "Suspend", hint: "Sleep, locked", run: () => sh("qs -c shell ipc call lock lock; sleep 0.5; systemctl suspend") },
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
    function toggle(): void { root.open = !root.open; if (root.open) BindsService.refresh(); }
  }
}
