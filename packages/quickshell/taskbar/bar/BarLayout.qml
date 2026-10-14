pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Which plugins the bar shows and where, per monitor: three zones, each in
// order, plus the switched-off ones. Persists in the state dir. Ids that `plugins` no longer
// knows are dropped; new plugins join their default zone.
Singleton {
  id: root

  // Registry, in default order. A new plugin: an entry here + its Component in
  // Bar.qml. `icon` names a kit/icons SVG and `about` is the manager's one-liner.
  readonly property var plugins: [
    { id: "workspaces",    label: "Workspaces",    zone: "left",   icon: "layout", about: "Hyprland workspaces" },
    { id: "music",         label: "Music",         zone: "left",   icon: "music", about: "Liked tracks from Yandex Music" },
    { id: "radio",         label: "Radio",         zone: "left",   icon: "radio", about: "Internet radio stations" },
    { id: "clock",         label: "Clock",         zone: "center", icon: "clock", about: "Time, click for the date" },
    { id: "brightness",    label: "Display",       zone: "right",  icon: "sun", about: "Backlight, dimming, night light" },
    { id: "audio",         label: "Audio",         zone: "right",  icon: "volume", about: "Devices, volumes, app streams" },
    { id: "wifi",          label: "Wi-Fi",         zone: "right",  icon: "wifi", about: "Networks, DNS, speed test" },
    { id: "mihomo",        label: "Mihomo",        zone: "right",  icon: "shield", about: "Proxy service and servers" },
    { id: "battery",       label: "Battery",       zone: "right",  icon: "battery", about: "Charge, limit, power profile, GPU" },
    { id: "language",      label: "Language",      zone: "right",  icon: "keyboard", about: "Keyboard layout" },
    { id: "ai",            label: "AI",            zone: "right",  icon: "bot", about: "Claude Code limits, local Ollama models" },
    { id: "shell",         label: "Shell",         zone: "right",  icon: "sliders", about: "Shell Manager: options, plugins, layout" },
    { id: "notifications", label: "Notifications", zone: "right",  icon: "bell", about: "History and unseen dot" },
    { id: "capture",       label: "Capture",       zone: "right",  icon: "camera", about: "Screenshots and screen recording" },
    { id: "clipboard",     label: "Clipboard",     zone: "right",  icon: "clipboard", about: "Copy history, images to drag out" },
    { id: "sysmon",        label: "System",        zone: "right",  icon: "cpu", about: "CPU, memory, GPU, disks, network, sensors" }
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
  function hidden(screen) { return (entry(screen)?.hidden ?? state.hidden).map(id => renamed[id] ?? id); }
  function barOn(screen) { return !(entry(screen)?.off ?? false); }
  function customized(screen) {
    const e = entry(screen);
    return e !== null ? (e.zones !== null || e.hidden.length > 0)
                      : (state.zones !== null || state.hidden.length > 0);
  }

  function icon(id) { return plugins.find(p => p.id === id)?.icon ?? ""; }
  function about(id) { return plugins.find(p => p.id === id)?.about ?? ""; }
  function label(id) { return plugins.find(p => p.id === id)?.label ?? id; }
  function visibleIn(zone, screen) {
    const off = hidden(screen);
    return layout(screen)[zone].filter(id => !off.includes(id));
  }

  // Writes the monitor's entry, starting from what it shows now.
  function update(screen, change) {
    const e = Object.assign({ zones: entry(screen)?.zones ?? state.zones, hidden: hidden(screen), off: !barOn(screen) }, change);
    const all = Object.assign({}, state.screens ?? {});
    all[roleOf(screen)] = e;
    state.screens = all;
  }

  function move(id, zone, index, screen) {
    const current = layout(screen);
    const z = {};
    for (const name of zones) z[name] = current[name].filter(x => x !== id);
    z[zone].splice(Math.max(0, Math.min(index, z[zone].length)), 0, id);
    update(screen, { zones: z });
  }

  function setEnabled(id, on, screen) {
    const off = hidden(screen);
    update(screen, { hidden: on ? off.filter(x => x !== id) : off.concat(id) });
  }

  function setBarOn(screen, on) { update(screen, { off: !on }); }

  // An empty bar: every plugin off (Super+S still opens the Shell Manager).
  function clear(screen) { update(screen, { hidden: plugins.map(p => p.id) }); }

  function reset(screen) { update(screen, { zones: null, hidden: [] }); }

  function normalize(saved) {
    const known = new Set(plugins.map(p => p.id));
    const seen = new Set();
    const z = { left: [], center: [], right: [] };
    for (const name of zones)
      for (const old of saved?.[name] ?? []) {
        const id = renamed[old] ?? old;
        if (known.has(id) && !seen.has(id)) { z[name].push(id); seen.add(id); }
      }
    for (const p of plugins)
      if (!seen.has(p.id)) z[p.zone].push(p.id);
    return z;
  }

  FileView {
    path: Quickshell.statePath("layout.json")
    printErrors: false
    onAdapterUpdated: writeAdapter()
    onLoadFailed: writeAdapter()

    JsonAdapter {
      id: state
      property var zones: null
      property var hidden: []
      property var screens: ({})      // role (main | extra) -> {zones, hidden, off}
      property bool shared: false
    }
  }
}
