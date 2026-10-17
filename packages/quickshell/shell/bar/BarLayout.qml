pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Which modules the bar shows and where, per monitor: three zones, each in
// order, the folder and the switched-off ones. Persists in the state dir. Ids
// that `modules` no longer knows are dropped; a new module joins its default
// zone on the Main bar and stays hidden on the Extra one.
Singleton {
  id: root

  // Registry, in default order. A new module: an entry here + its Component in
  // ModuleFaces.qml. `icon` names a kit/icons SVG, `about` is the manager's one-liner,
  // `settings` its options page in the module's folder (Shell Manager › Modules),
  // `island` its place in the island while that is not arranged (else the hub).
  readonly property var modules: [
    { id: "workspaces",    label: "Workspaces",    zone: "left",   icon: "layout", settings: "WorkspacesSettings.qml", about: "Hyprland workspaces" },
    { id: "music",         label: "Music",         zone: "left",   icon: "music", settings: "MusicSettings.qml", about: "Liked tracks from Yandex Music" },
    { id: "radio",         label: "Radio",         zone: "left",   icon: "radio", settings: "RadioSettings.qml", about: "Internet radio stations" },
    { id: "themes",        label: "Themes",        zone: "right",  icon: "brush", settings: "ThemesSettings.qml", about: "Switch the dotfiles theme from a strip of cards" },
    { id: "wallpapers",    label: "Wallpapers",    zone: "right",  icon: "image", settings: "WallpapersSettings.qml", about: "Pick the picture of the theme from a strip of cards" },
    { id: "equalizer",     label: "Equalizer",     zone: "center", island: "end", icon: "activity", settings: "EqualizerSettings.qml", about: "The sound as bars while a track plays" },
    { id: "clock",         label: "Clock",         zone: "center", icon: "clock", settings: "ClockSettings.qml", about: "Time, click for the date" },
    { id: "brightness",    label: "Brightness",    zone: "right",  icon: "sun", settings: "BrightnessSettings.qml", about: "Backlight, dimming, night light" },
    { id: "audio",         label: "Audio",         zone: "right",  icon: "volume", settings: "AudioSettings.qml", about: "Devices, volumes, app streams" },
    { id: "wifi",          label: "Wi-Fi",         zone: "right",  icon: "wifi", settings: "WifiSettings.qml", about: "Networks, DNS, speed test" },
    { id: "mihomo",        label: "Mihomo",        zone: "right",  icon: "shield", about: "Proxy service and servers" },
    { id: "battery",       label: "Battery",       zone: "right",  icon: "battery-full", settings: "BatterySettings.qml", about: "Charge, limit, power profile, GPU" },
    { id: "language",      label: "Language",      zone: "right",  icon: "keyboard", about: "Keyboard layout" },
    { id: "ai",            label: "AI",            zone: "right",  icon: "bot", settings: "AiSettings.qml", about: "Claude Code limits, local Ollama models" },
    { id: "shell",         label: "Shell",         zone: "right",  icon: "sliders", about: "Shell Manager: options, modules, layout" },
    { id: "notifications", label: "Notifications", zone: "right",  icon: "bell", settings: "NotificationsSettings.qml", about: "History of notifications" },
    { id: "capture",       label: "Capture",       zone: "right",  icon: "camera", settings: "CaptureSettings.qml", about: "Screenshots and screen recording" },
    { id: "clipboard",     label: "Clipboard",     zone: "right",  icon: "clipboard", about: "Copy history, images to drag out" },
    { id: "sysmon",        label: "System",        zone: "right",  icon: "cpu", settings: "SysmonSettings.qml", about: "CPU, memory, GPU, disks, network, sensors" },
    { id: "taskmanager",   label: "Task Manager",  zone: "right",  icon: "activity", about: "Load and the busiest programs · Super + D: the full window" },
    { id: "cleaner",       label: "Cleaner",       zone: "right",  icon: "brush", about: "What can go, the safe part in one click · Super + X: the full window" },
    { id: "backup",        label: "Backups",       zone: "right",  icon: "shield", about: "Last backup, back up now, the restore guide · the full window" },
    { id: "virustotal",    label: "VirusTotal",    zone: "right",  icon: "scan", about: "A hash, URL or file checked against VirusTotal" },
    { id: "packages",      label: "Packages",      zone: "right",  icon: "package", about: "Pending updates, one click to update · the full window" },
    { id: "display",       label: "Display",       zone: "right",  icon: "monitor", about: "Monitor scale, position and text size · the full window" },
    { id: "windows",       label: "Windows",       zone: "right",  icon: "app-window", settings: "WindowsSettings.qml", about: "Window mode: tiling, floating, scrolling" },
    { id: "chat",          label: "Chat",          zone: "right",  icon: "message", settings: "ChatSettings.qml", about: "A chat with a free opencode model" },
    { id: "folder",        label: "Folder",        zone: "right",  icon: "folder", about: "Modules tucked away, one click from the bar" }
  ]
  readonly property var zones: ["left", "center", "right"]

  // Old ids still found in saved layouts: old -> new.
  readonly property var renamed: ({ claude: "ai", plugins: "shell" })

  // Modules whose components are off on this machine (`./install.py
  // components`), id -> the components that would bring it: kept off every
  // bar and shown as not installed in the Shell Manager; the saved layout
  // keeps their place for when they come back.
  property var notInstalled: ({})
  function installed(id) { return !(id in notInstalled); }

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
      .filter(id => known.includes(id) && id !== "folder" && !off.includes(id) && installed(id) && !taken(id, screen));
  }
  function customized(screen) {
    const e = entry(screen);
    return e !== null ? (e.zones !== null || e.hidden.length > 0 || (e.folder ?? []).length > 0)
                      : (state.zones !== null || state.hidden.length > 0);
  }

  function icon(id) { return modules.find(p => p.id === id)?.icon ?? ""; }

  // ---- separators ----
  // Custom "|" lines: they sit in a zone like a module and move the same way
  // (the island's in its LEFT / RIGHT sides). Shell Manager › Bar › Layout: the
  // ADD tray's chip, dragged into place or clicked (end of RIGHT); a chip's
  // cross or a drop on HIDDEN removes one.
  function isSeparator(id) { return String(id).startsWith("sep-"); }
  function newSeparator() { return "sep-" + Date.now().toString(36); }

  function addSeparator(screen) {
    const id = newSeparator();
    if (Theme.island) { islandMove(id, "end", islandIn("end", screen).length, screen); return id; }
    const z = {};
    for (const name of zones) z[name] = layout(screen)[name].slice();
    z.right.push(id);
    update(screen, { zones: z });
    return id;
  }

  function removeSeparator(id, screen) {
    if (Theme.island) { islandMove(id, "hidden", 0, screen); return; }
    const z = {};
    for (const name of zones) z[name] = layout(screen)[name].filter(x => x !== id);
    update(screen, { zones: z });
  }

  function visibleIn(zone, screen) {
    const off = hidden(screen).concat(inFolder(screen));
    return layout(screen)[zone].filter(id => !off.includes(id) && installed(id) && !taken(id, screen));
  }

  // on, but not placed on this monitor's bar
  function unplaced(screen) {
    const off = hidden(screen);
    return modules.map(p => p.id).filter(id => off.includes(id) && installed(id) && !taken(id, screen));
  }

  // Writes the monitor's entry, starting from what it shows now. Only the
  // two roles are kept.
  function update(screen, change) {
    const e = Object.assign({ zones: entry(screen)?.zones ?? state.zones, hidden: hidden(screen),
                              folder: inFolder(screen), off: !barOn(screen),
                              island: entry(screen)?.island ?? null,
                              islandClock: islandClock(screen), bars: entry(screen)?.bars ?? [] }, change);
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
    syncFolderDot(id, false);
  }

  // place on / take off one monitor's bar
  function setEnabled(id, on, screen) {
    const off = hidden(screen);
    update(screen, { hidden: on ? off.filter(x => x !== id) : off.concat(id),
                     folder: inFolder(screen).filter(x => x !== id) });
    syncFolderDot(id, false);
  }

  // into the folder at `index` (off the strip, out of HIDDEN)
  function setFolder(id, index, screen) {
    if (id === "folder") return;
    const f = inFolder(screen).filter(x => x !== id);
    f.splice(Math.max(0, Math.min(index, f.length)), 0, id);
    update(screen, { folder: f, hidden: hidden(screen).filter(x => x !== id) });
    syncFolderDot(id, true);
  }

  // the notifications dot follows the notifications module's place: in the folder
  // (or the island's hub) it shows, on the bar it doesn't. A manual switch (Bar ›
  // Notifications dot) holds until the module moves again.
  function syncFolderDot(id, inTheFolder) {
    if (id === "notifications") ShellSettings.set("barFolderDot", inTheFolder);
  }

  function setBarOn(screen, on) { update(screen, { off: !on }); }

  // this bar takes another one's layout (Extra copying Main)
  function copyLayout(from, to) { update(to, { zones: layout(from), hidden: hidden(from), folder: inFolder(from) }); }

  function reset(screen) { update(screen, { zones: null, hidden: [], folder: [] }); }

  // ---- island (Bar › Style island) ----
  // Its own layout per role, apart from the strip's: start / end — beside the
  // clock in the resting pill; hub — the chips when it opens; the rest hidden.
  // Never arranged, it follows the strip: workspaces at the start, every other
  // placed module (the folder's too) in the hub.
  readonly property var islandZones: ["start", "end", "hub"]
  readonly property var islandOwn: ["clock", "folder"]   // the island shows the time; it needs no folder

  function islandLayout(screen) {
    const known = modules.map(p => p.id);
    const usable = id => (known.includes(id) || isSeparator(id)) && installed(id) && !islandOwn.includes(id) && !taken(id, screen);
    const saved = entry(screen)?.island ?? null;
    if (!saved) {
      const placed = zones.reduce((all, z) => all.concat(visibleIn(z, screen)), []).concat(inFolder(screen)).filter(id => !isSeparator(id) && usable(id));
      const at = id => id === "workspaces" ? "start" : modules.find(p => p.id === id)?.island ?? "hub";
      return { start: placed.filter(id => at(id) === "start"), end: placed.filter(id => at(id) === "end"),
               hub: placed.filter(id => at(id) === "hub") };
    }
    const z = { start: [], end: [], hub: [] };
    const seen = new Set();
    for (const name of islandZones)
      for (const old of saved[name] ?? []) {
        const id = renamed[old] ?? old;
        if (!seen.has(id)) { z[name].push(id); seen.add(id); }
      }
    // a module new since it was arranged takes its place (`island`), else the hub
    const off = (saved.hidden ?? []).map(id => renamed[id] ?? id);
    for (const p of modules) if (!seen.has(p.id) && !off.includes(p.id)) z[p.island ?? "hub"].push(p.id);
    for (const name of islandZones) z[name] = z[name].filter(usable);
    return z;
  }
  function islandIn(zone, screen) { return islandLayout(screen)[zone] ?? []; }
  function islandHidden(screen) {
    const l = islandLayout(screen);
    const placed = l.start.concat(l.end, l.hub);
    return modules.map(p => p.id).filter(id => !placed.includes(id) && installed(id) && !islandOwn.includes(id) && !taken(id, screen));
  }
  // zone: start | end | hub | hidden
  function islandMove(id, zone, index, screen) {
    const l = islandLayout(screen);
    const z = {};
    for (const name of islandZones) z[name] = l[name].filter(x => x !== id);
    if (zone !== "hidden") z[zone].splice(Math.max(0, Math.min(index, z[zone].length)), 0, id);
    const placed = z.start.concat(z.end, z.hub);
    z.hidden = modules.map(p => p.id).filter(x => !placed.includes(x) && !islandOwn.includes(x));
    update(screen, { island: z });
    syncFolderDot(id, zone === "hub");
  }
  // the clock in the resting island; off with nothing beside it, the island
  // hides on that monitor until it has something to show
  function islandClock(screen) { return entry(screen)?.islandClock ?? true; }
  function setIslandClock(screen, on) { update(screen, { islandClock: on }); }

  function islandCustomized(screen) { return !!entry(screen)?.island; }
  function islandReset(screen) { update(screen, { island: null }); }
  function islandCopy(from, to) { update(to, { island: islandLayout(from) }); }

  // ---- child bars ----
  // Small bars that belong to a monitor's main bar (Shell Manager › Bar: the
  // + by its preview, placed by dragging there): in its row, on a side
  // (left | right), at the screen's edge or stuck to the centre (place:
  // edge | island), with their own modules in order. A module is in one bar
  // only: given to a child bar it leaves that main bar and its island.
  function barsOn(screen) {
    return (entry(screen)?.bars ?? []).map(b => Object.assign({ side: "right", place: "island", modules: [] }, b));
  }
  function taken(id, screen) { return barsOn(screen).some(b => b.modules.includes(id)); }
  function barModules(screen, id) {
    return (barsOn(screen).find(b => b.id === id)?.modules ?? []).filter(m => installed(m) && modules.some(p => p.id === m));
  }

  function addBar(screen) {
    const id = "bar" + Date.now().toString(36);
    update(screen, { bars: barsOn(screen).concat([{ id: id, side: "right", place: "island", modules: [] }]) });
    return id;
  }
  function updateBar(screen, id, change) {
    update(screen, { bars: barsOn(screen).map(b => b.id === id ? Object.assign({}, b, change) : b) });
  }
  function removeBar(screen, id) { update(screen, { bars: barsOn(screen).filter(b => b.id !== id) }); }

  // a module into a child bar at `index` (out of any other), or back to the
  // main bar (barId "")
  function moveToBar(screen, moduleId, barId, index) {
    update(screen, { bars: barsOn(screen).map(b => {
      const list = b.modules.filter(m => m !== moduleId);
      if (b.id === barId) list.splice(Math.max(0, Math.min(index, list.length)), 0, moduleId);
      return Object.assign({}, b, { modules: list });
    }) });
  }

  function normalize(saved) {
    const known = new Set(modules.map(p => p.id));
    const seen = new Set();
    const z = { left: [], center: [], right: [] };
    for (const name of zones)
      for (const old of saved?.[name] ?? []) {
        const id = renamed[old] ?? old;
        if ((known.has(id) || isSeparator(id)) && !seen.has(id)) { z[name].push(id); seen.add(id); }
      }
    for (const p of modules)
      if (!seen.has(p.id)) z[p.zone].push(p.id);
    return z;
  }

  // written by `./install.py link`; no file: every module is there
  FileView {
    path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/dotfiles/components.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try { root.notInstalled = JSON.parse(text()).off ?? {}; } catch (e) { root.notInstalled = {}; }
    }
    onLoadFailed: root.notInstalled = {}
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
      property var screens: ({})      // role (main | extra) -> {zones, hidden, folder, off, island, islandClock, bars}
      property bool shared: false
    }
  }
}
