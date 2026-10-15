pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Which modules the bar shows and where, per monitor: three zones, each in
// order, plus the switched-off ones. Persists in the state dir. Ids that `modules` no longer
// knows are dropped; a new module joins its default zone on the Main bar and
// sits on the shelf of the Extra one.
Singleton {
  id: root

  // Registry, in default order. A new module: an entry here + its Component in
  // Bar.qml. `icon` names a kit/icons SVG, `about` is the manager's one-liner,
  // `settings` its options page in the module's folder (Shell Manager › Modules).
  readonly property var modules: [
    { id: "workspaces",    label: "Workspaces",    zone: "left",   icon: "layout", settings: "WorkspacesSettings.qml", about: "Hyprland workspaces" },
    { id: "music",         label: "Music",         zone: "left",   icon: "music", settings: "MusicSettings.qml", about: "Liked tracks from Yandex Music" },
    { id: "radio",         label: "Radio",         zone: "left",   icon: "radio", settings: "RadioSettings.qml", about: "Internet radio stations" },
    { id: "clock",         label: "Clock",         zone: "center", icon: "clock", settings: "ClockSettings.qml", about: "Time, click for the date" },
    { id: "brightness",    label: "Display",       zone: "right",  icon: "sun", settings: "BrightnessSettings.qml", about: "Backlight, dimming, night light" },
    { id: "audio",         label: "Audio",         zone: "right",  icon: "volume", settings: "AudioSettings.qml", about: "Devices, volumes, app streams" },
    { id: "wifi",          label: "Wi-Fi",         zone: "right",  icon: "wifi", settings: "WifiSettings.qml", about: "Networks, DNS, speed test" },
    { id: "mihomo",        label: "Mihomo",        zone: "right",  icon: "shield", about: "Proxy service and servers" },
    { id: "battery",       label: "Battery",       zone: "right",  icon: "battery", settings: "BatterySettings.qml", about: "Charge, limit, power profile, GPU" },
    { id: "language",      label: "Language",      zone: "right",  icon: "keyboard", about: "Keyboard layout" },
    { id: "ai",            label: "AI",            zone: "right",  icon: "bot", about: "Claude Code limits, local Ollama models" },
    { id: "shell",         label: "Shell",         zone: "right",  icon: "sliders", about: "Shell Manager: options, modules, layout" },
    { id: "notifications", label: "Notifications", zone: "right",  icon: "bell", settings: "NotificationsSettings.qml", about: "History and unseen dot" },
    { id: "capture",       label: "Capture",       zone: "right",  icon: "camera", about: "Screenshots and screen recording" },
    { id: "clipboard",     label: "Clipboard",     zone: "right",  icon: "clipboard", settings: "ClipboardSettings.qml", about: "Copy history, images to drag out" },
    { id: "sysmon",        label: "System",        zone: "right",  icon: "cpu", settings: "SysmonSettings.qml", about: "CPU, memory, GPU, disks, network, sensors" },
    { id: "taskmanager",   label: "Task manager",  zone: "right",  icon: "activity", about: "Load and the busiest programs · Super + D: the full window" },
    { id: "cleaner",       label: "Cleaner",       zone: "right",  icon: "brush", about: "What can go, the safe part in one click · Super + X: the full window" },
    { id: "windows",       label: "Windows",       zone: "right",  icon: "app-window", about: "Window mode: tiling, floating, scrolling" },
    { id: "chat",          label: "Chat",          zone: "right",  icon: "message", settings: "ChatSettings.qml", about: "A chat with a free opencode model" },
    { id: "folder",        label: "Folder",        zone: "right",  icon: "folder", about: "Modules tucked away, one click from the bar" }
  ]
  readonly property var zones: ["left", "center", "right"]


  // Old ids still found in saved layouts: old -> new.
  readonly property var renamed: ({ claude: "ai", plugins: "shell" })

  // Every function takes the screen name, but settings belong to its role:
  // "main" — the external monitor when one is connected, else the only one
  // (the laptop takes over the main bar when undocked); "extra" — the laptop
  // panel and any further monitor while docked. A role never set up uses the
  // shared layout (the one saved before per-monitor layouts).
  function isInternal(name) { return /^(eDP|LVDS|DSI)/.test(name); }
  function mainScreen() {
    const names = Quickshell.screens.map(s => s.name);
    return names.find(n => !isInternal(n)) ?? names[0] ?? "";
  }
  // `shared`: every monitor shows the main bar
  readonly property bool shared: state.shared
  function setShared(on) { state.shared = on; }
  function roleOf(screen) { return shared || screen === mainScreen() ? "main" : "extra"; }
  function entry(screen) { return state.screens?.[roleOf(screen)] ?? null; }
  function layout(screen) { return normalize(entry(screen)?.zones ?? state.zones); }
  // Not on this bar: what was put away, and — on the Extra bar — what the
  // saved layout has never seen (a new module joins the Main bar only).
  function hidden(screen) {
    const e = entry(screen);
    const off = (e?.hidden ?? state.hidden).map(id => renamed[id] ?? id);
    if (roleOf(screen) !== "extra" || !e?.zones) return off;
    const known = zones.reduce((all, z) => all.concat(e.zones[z] ?? []), e.folder ?? []).map(id => renamed[id] ?? id);
    return off.concat(modules.map(p => p.id).filter(id => !known.includes(id) && !off.includes(id)));
  }
  function barOn(screen) { return !(entry(screen)?.off ?? false); }

  // In the folder (the Folder module's popup) on this bar, in order: off the
  // strip but still there, one click away.
  function inFolder(screen) {
    const known = modules.map(p => p.id);
    const off = hidden(screen);
    return (entry(screen)?.folder ?? []).map(id => renamed[id] ?? id)
      .filter(id => known.includes(id) && id !== "folder" && !off.includes(id));
  }
  function customized(screen) {
    const e = entry(screen);
    return e !== null ? (e.zones !== null || e.hidden.length > 0 || (e.folder ?? []).length > 0)
                      : (state.zones !== null || state.hidden.length > 0);
  }

  function icon(id) { return modules.find(p => p.id === id)?.icon ?? ""; }
  // A module not placed on a monitor's bar is HIDDEN there (`hidden`).

  function visibleIn(zone, screen) {
    const off = hidden(screen).concat(inFolder(screen));
    return layout(screen)[zone].filter(id => !off.includes(id));
  }

  // on, but not placed on this monitor's bar
  function unplaced(screen) {
    const off = hidden(screen);
    return modules.map(p => p.id).filter(id => off.includes(id));
  }

  // Writes the monitor's entry, starting from what it shows now. Only the
  // two roles are kept.
  function update(screen, change) {
    const e = Object.assign({ zones: entry(screen)?.zones ?? state.zones, hidden: hidden(screen),
                              folder: inFolder(screen), off: !barOn(screen) }, change);
    const all = {};
    for (const role of ["main", "extra"])
      if (state.screens?.[role]) all[role] = state.screens[role];
    all[roleOf(screen)] = e;
    state.screens = all;
  }

  function move(id, zone, index, screen) {
    const current = layout(screen);
    const z = {};
    for (const name of zones) z[name] = current[name].filter(x => x !== id);
    z[zone].splice(Math.max(0, Math.min(index, z[zone].length)), 0, id);
    update(screen, { zones: z, folder: inFolder(screen).filter(x => x !== id) });
  }

  // place on / take off one monitor's bar
  function setEnabled(id, on, screen) {
    const off = hidden(screen);
    update(screen, { hidden: on ? off.filter(x => x !== id) : off.concat(id),
                     folder: inFolder(screen).filter(x => x !== id) });
  }

  // into the folder at `index` (off the strip, out of HIDDEN)
  function setFolder(id, index, screen) {
    if (id === "folder") return;
    const f = inFolder(screen).filter(x => x !== id);
    f.splice(Math.max(0, Math.min(index, f.length)), 0, id);
    update(screen, { folder: f, hidden: hidden(screen).filter(x => x !== id) });
  }

  function setBarOn(screen, on) { update(screen, { off: !on }); }

  // this bar takes another one's layout (Extra copying Main)
  function copyLayout(from, to) { update(to, { zones: layout(from), hidden: hidden(from), folder: inFolder(from) }); }

  function reset(screen) { update(screen, { zones: null, hidden: [], folder: [] }); }

  function normalize(saved) {
    const known = new Set(modules.map(p => p.id));
    const seen = new Set();
    const z = { left: [], center: [], right: [] };
    for (const name of zones)
      for (const old of saved?.[name] ?? []) {
        const id = renamed[old] ?? old;
        if (known.has(id) && !seen.has(id)) { z[name].push(id); seen.add(id); }
      }
    for (const p of modules)
      if (!seen.has(p.id)) z[p.zone].push(p.id);
    return z;
  }


  FileView {
    path: Quickshell.statePath("layout.json")
    printErrors: false
    onAdapterUpdated: writeAdapter()
    onLoadFailed: writeAdapter()
    onLoaded: {
      const keys = Object.keys(state.screens ?? {});
      if (keys.some(k => k !== "main" && k !== "extra")) {
        const kept = {};
        for (const role of ["main", "extra"])
          if (state.screens[role]) kept[role] = state.screens[role];
        state.screens = kept;
      }
    }

    JsonAdapter {
      id: state
      property var zones: null
      property var hidden: []
      property var screens: ({})      // role (main | extra) -> {zones, hidden, off}
      property bool shared: false
    }
  }
}
