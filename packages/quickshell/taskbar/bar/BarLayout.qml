pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Which plugins the bar shows and where: three zones, each in order, plus the
// switched-off ones. Persists in the state dir. Ids that `plugins` no longer
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
    { id: "shell",         label: "Shell",         zone: "right",  icon: "sliders", fixed: true, about: "Shell Manager: options, plugins, layout" },
    { id: "notifications", label: "Notifications", zone: "right",  icon: "bell", about: "History and unseen dot" }
  ]
  readonly property var zones: ["left", "center", "right"]
  // Old ids still found in saved layouts: old -> new.
  readonly property var renamed: ({ claude: "ai", plugins: "shell" })

  readonly property var layout: normalize(state.zones)    // {left: [ids], center, right}
  readonly property var hidden: state.hidden.map(id => renamed[id] ?? id)
  readonly property bool customized: state.zones !== null || hidden.length > 0

  // Fixed plugins can move but not be switched off (the manager's own button).
  function fixed(id) { return plugins.find(p => p.id === id)?.fixed ?? false; }
  function icon(id) { return plugins.find(p => p.id === id)?.icon ?? ""; }
  function about(id) { return plugins.find(p => p.id === id)?.about ?? ""; }
  function label(id) { return plugins.find(p => p.id === id)?.label ?? id; }
  function visibleIn(zone) { return layout[zone].filter(id => !hidden.includes(id)); }

  function move(id, zone, index) {
    const z = {};
    for (const name of zones) z[name] = layout[name].filter(x => x !== id);
    z[zone].splice(Math.max(0, Math.min(index, z[zone].length)), 0, id);
    state.zones = z;
  }

  function setEnabled(id, on) {
    if (fixed(id)) return;
    state.hidden = on ? hidden.filter(x => x !== id) : hidden.concat(id);
  }

  function reset() {
    state.zones = null;
    state.hidden = [];
  }

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
    }
  }
}
