import QtQuick
import QtQuick.Controls as Controls
import Quickshell
import qs.apps.files
import qs.bar
import qs.config
import qs.kit

// Keep the live result, placed modules and the module catalogue distinct.
KitSettingsWorkspace {
  id: root
  readonly property bool fillsViewport: true
  showScrollBar: false
  readonly property Item previewItem: null
  readonly property var tabs: sections
  readonly property string icon: "layout"
  readonly property string title: "Bar"
  readonly property string subtitle: "Arrange your desktop controls"
  property string tab: "layout"
  property string screenName: BarLayout.mainScreen()
  property string selectedModule: ""
  property string activeZone: island ? "start" : "left"
  property string availableQuery: ""
  property bool arranging: false
  property var undoStack: []
  function remember() {
    undoStack = undoStack.concat([{screen: screenName, layout: BarLayout.snapshot(screenName), dot: ShellSettings.barFolderDot}]).slice(-30);
  }
  function undo() {
    if (!undoStack.length) return;
    const previous = undoStack[undoStack.length - 1];
    undoStack = undoStack.slice(0, -1);
    BarLayout.update(previous.screen, previous.layout);
    ShellSettings.set("barFolderDot", previous.dot);
    layoutError = "";
  }
  readonly property bool island: Theme.island
  readonly property bool barOn: BarLayout.barOn(screenName)
  readonly property var roles: Quickshell.screens.map(s => s.name)
    .sort((a, b) => (BarLayout.roleOf(a) === "main" ? 0 : 1) - (BarLayout.roleOf(b) === "main" ? 0 : 1))
    .filter((n, i, all) => all.findIndex(o => BarLayout.roleOf(o) === BarLayout.roleOf(n)) === i)
  readonly property string other: roles.find(n => n !== screenName) ?? ""
  readonly property var layout: BarLayout.layout(screenName)
  readonly property var children: BarLayout.barsOn(screenName)
  readonly property var columnZones: (island ? ["start", "end", "hub"] : ["left", "center", "right", "folder"])
    .concat(children.map(b => "bar:" + b.id), ["hidden"])
  function childOf(zone) { return zone.startsWith("bar:") ? zone.slice(4) : ""; }
  readonly property string selectedZone: columnZones.find(z => ids(z).includes(selectedModule)) ?? ""
  readonly property int selectedIndex: selectedZone ? ids(selectedZone).indexOf(selectedModule) : -1
  readonly property var available: ids("hidden").filter(id => canPlace(id, activeZone)
    && (module(id)?.label ?? "").toLowerCase().includes(availableQuery.trim().toLowerCase()))
  onScreenNameChanged: { selectedModule = ""; undoStack = []; }
  onIslandChanged: { undoStack = []; selectedModule = ""; activeZone = island ? "start" : "left"; }
  onColumnZonesChanged: if (!columnZones.includes(activeZone)) activeZone = island ? "start" : "left"
  readonly property var resetKeys: ["barStyle", "looks", "barRightSettings"]
  readonly property bool changed: ShellSettings.changed(resetKeys) || ModuleSettings.changed("hub")
  function reset() { ShellSettings.reset(resetKeys); ModuleSettings.reset("hub"); }
  readonly property var jumps: [
    { key: "layout", label: "Layout", y: 0 },
    { key: "look", label: "Look", y: 0 },
    { key: "behaviour", label: "Behaviour", y: 0 },
    { key: "hub", label: "Hub", y: 0 },
    { key: "profile", label: "Profile", y: 0 },
    { key: "sliders", label: "Content", y: 0 },
    { key: "live", label: "Live", y: 0 },
    { key: "monitor", label: "Monitor", y: 0 }
  ]
  function jump(key) {
    tab = ["look", "behaviour", "appearance"].includes(key) ? "appearance"
      : ["hub", "profile", "sliders"].includes(key) ? "hub" : key === "live" ? "live" : key === "monitor" ? "monitor" : "layout";
  }
  function zoneLabel(zone) {
    return childOf(zone) ? "Bar " + (children.findIndex(b => b.id === childOf(zone)) + 2)
      : ({left: "Left", center: "Centre", right: "Right", start: "Left of clock", end: "Right of clock", hub: "Hub", folder: "Folder", hidden: "Not on the bar"})[zone] ?? zone;
  }
  function chooseZone(zone) { activeZone = zone; }
  function selectModule(id) {
    selectedModule = id;
    const zone = columnZones.find(z => z !== "hidden" && ids(z).includes(id));
    if (zone) activeZone = zone;
  }
  function nudgeModule(step) {
    if (selectedIndex < 0) return;
    drop(selectedModule, selectedZone, selectedIndex + (step > 0 ? 2 : -1));
  }
  function addModule(id) { drop(id, activeZone, ids(activeZone).length); selectedModule = id; }
  function removeModule(id) {
    remember();
    if (BarLayout.isSeparator(id)) BarLayout.removeSeparator(id, screenName);
    else applyDrop(id, "hidden", 0);
    if (selectedModule === id) selectedModule = "";
  }
  function module(id) { return BarLayout.modules.find(p => p.id === id) ?? null; }
  function ids(zone) {
    if (!zone) return [];
    if (["start", "end", "hub"].includes(zone)) return BarLayout.islandIn(zone, screenName);
    if (childOf(zone) !== "") return BarLayout.barModules(screenName, childOf(zone));
    if (island) return zone === "hidden" ? BarLayout.islandHidden(screenName) : BarLayout.islandIn(zone, screenName);
    return zone === "hidden" ? BarLayout.unplaced(screenName)
         : zone === "folder" ? BarLayout.inFolder(screenName)
         : ["left", "center", "right"].includes(zone) ? BarLayout.visibleIn(zone, screenName) : [];
  }

  // A new separator is created only after a valid destination is chosen.
  readonly property string newSeparator: "sep-new"
  // the bands show placed modules only; the stored order holds the rest too,
  // so the slot is translated through its visible neighbours
  property string layoutError: ""
  function canPlace(id, zone) {
    if (id === "folder") return ["left", "center", "right"].includes(zone) || childOf(zone) !== "";
    if (BarLayout.isSeparator(id)) return !["folder", "hub"].includes(zone) && childOf(zone) === "";
    return columnZones.includes(zone);
  }
  function drop(id, zone, index) {
    if (!canPlace(id, zone)) return;
    remember();
    applyDrop(id, zone, index);
    selectedModule = id === newSeparator ? "" : id;
  }
  function applyDrop(id, zone, index) {
    if (!canPlace(id, zone)) { layoutError = "This module cannot be placed in that zone"; return; }
    layoutError = "";
    // a separator sits in the main bar's sides only: HIDDEN removes it, the rest
    // refuse it; the tray's chip becomes a new one where it lands
    if (BarLayout.isSeparator(id)) {
      if (zone === "folder" || childOf(zone) !== "" || zone === "hub") return;
      if (zone === "hidden") { if (id !== newSeparator) BarLayout.removeSeparator(id, screenName); return; }
      if (id === newSeparator) id = BarLayout.newSeparator();
    }
    const child = childOf(zone);
    if (child !== "") {
      const current = BarLayout.barModules(screenName, child).indexOf(id);
      BarLayout.moveToBar(screenName, id, child, current >= 0 && index > current ? index - 1 : index);
      return;
    }
    // out of a child bar first: back on the main bar where it was
    if (BarLayout.taken(id, screenName)) BarLayout.moveToBar(screenName, id, "", 0);
    if (island) {
      // a slot among the band's chips is a slot in its list: no hidden ones in between
      const current = BarLayout.islandIn(zone, screenName).indexOf(id);
      BarLayout.islandMove(id, zone, current >= 0 && index > current ? index - 1 : index, screenName);
    } else if (zone === "hidden") {
      BarLayout.setEnabled(id, false, screenName);
    } else if (zone === "folder") {
      BarLayout.setFolder(id, index, screenName);
    } else {
      if (BarLayout.unplaced(screenName).includes(id)) BarLayout.setEnabled(id, true, screenName);
      const visible = BarLayout.visibleIn(zone, screenName);
      const current = visible.indexOf(id);
      const slot = current >= 0 && index > current ? index - 1 : index;
      const others = visible.filter(v => v !== id);
      const full = layout[zone].filter(v => v !== id);
      const at = slot < others.length ? full.indexOf(others[slot])
               : others.length > 0 ? full.indexOf(others[others.length - 1]) + 1
               : full.length;
      BarLayout.move(id, zone, at, screenName);
    }
  }


  sections: [{label: "Layout", value: "layout"}, {label: "Appearance", value: "appearance"},
    {label: "Hub", value: "hub"}, {label: "Live", value: "live"}, {label: "Monitors", value: "monitor"}]
  current: tab
  onPicked: value => tab = value

  settings: Component {
    Column {
      width: parent.width
      KitSelect {
        visible: root.roles.length > 1 && !BarLayout.shared
        label: "Editing monitor"
        model: root.roles.map(n => ({label: (BarLayout.roleOf(n) === "main" ? "Main · " : "Extra · ") + n, value: n}))
        current: root.screenName
        onPicked: value => root.screenName = value
      }
      Column {
        property bool kitUnboxed: true
        width: parent.width
        spacing: 12
        visible: root.tab === "layout"
        KitRow {
          visible: root.island
          label: "Clock"
          hint: "Off and nothing beside it: hidden"
          KitSwitch { checked: BarLayout.islandClock(root.screenName); onToggled: BarLayout.setIslandClock(root.screenName, !checked) }
        }
        Item {
          width: parent.width
          height: 44
          Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            KitText { text: "Layout"; font.weight: Font.Medium }
            KitText { text: "Drag modules between rows."; color: Theme.muted; font.pixelSize: Theme.fontSize - 2 }
          }
          Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: 8
            KitButton { text: "Undo"; visible: root.undoStack.length > 0; onClicked: root.undo() }
            KitButton { icon: "plus"; text: "Separator"; onClicked: { const zone = root.island ? "end" : "right"; root.drop(root.newSeparator, zone, root.ids(zone).length); } }
            KitResetButton {
              changed: root.island ? BarLayout.islandCustomized(root.screenName) : BarLayout.customized(root.screenName)
              onReset: { root.remember(); root.island ? BarLayout.islandReset(root.screenName) : BarLayout.reset(root.screenName); }
            }
          }
        }
        BarArrangement {
          id: editor
          showOverview: false
          showAvailable: true
          width: parent.width
          scope: root.screenName
          island: root.island
          clockVisible: BarLayout.islandClock(root.screenName)
          extraZones: root.children.map(b => "bar:" + b.id)
          extraBars: root.children
          onDraggingChanged: root.arranging = dragging
          selectedId: root.selectedModule
          idsOf: zone => root.ids(zone)
          labelOf: id => BarLayout.isSeparator(id) ? "Separator" : root.module(id)?.label ?? id
          iconOf: id => BarLayout.isSeparator(id) ? "layout" : BarLayout.icon(id)
          tileOf: id => root.island && BarLayout.isTile(id)
          accepts: (id, zone) => root.canPlace(id, zone)
          zoneLabel: zone => root.zoneLabel(zone)
          scrollViewport: root.viewport
          onSelected: id => root.selectModule(id)
          onMoved: (id, zone, index) => root.drop(id, zone, index)
          onRemoved: id => root.removeModule(id)
        }
      }
      Column {
  spacing: Theme.sectionGap

        width: parent.width
        visible: root.tab === "appearance"
        KitLabel { text: "LOOK" }
        KitRow {
          label: "Bar style"
          hint: "Each style remembers its own layout"
          wide: true
          KitSegments {
            model: [{label: "Solid", value: "solid"}, {label: "Island", value: "island"}]
            current: ShellSettings.barStyle
            onPicked: value => ShellSettings.set("barStyle", value)
          }
        }
        KitRow {
          label: "Icon size"
          wide: true
          KitSegments { model: [{label: "Small", value: 0}, {label: "Medium", value: 2}, {label: "Large", value: 4}]; current: ShellSettings.barIconGrow; onPicked: value => ShellSettings.setLook("barIconGrow", value) }
        }
        KitRow {
          label: "Module gap"
          wide: true
          KitSegments { model: [{label: "Tight", value: 2}, {label: "Normal", value: 5}, {label: "Wide", value: 8}]; current: ShellSettings.barGap; onPicked: value => ShellSettings.setLook("barGap", value) }
        }
        KitRow {
          label: "Separators"
          hint: "Lines between neighbouring modules"
          KitSwitch { checked: ShellSettings.barSeparators; onToggled: ShellSettings.setLook("barSeparators", !checked) }
        }
        KitLine {}
        KitLabel { text: "BEHAVIOUR" }
        KitRow {
          label: "Right click opens options"
          hint: "Open a bar module's settings"
          KitSwitch { checked: ShellSettings.barRightSettings; onToggled: ShellSettings.set("barRightSettings", !checked) }
        }
        KitRow {
          visible: root.island
          label: "Island clock"
          hint: "Keep the clock visible in the resting bar"
          KitSwitch { checked: BarLayout.islandClock(root.screenName); onToggled: BarLayout.setIslandClock(root.screenName, !checked) }
        }
        KitGrouper {}
      }
      Column {
        width: parent.width
        visible: root.tab === "live"
        KitRow {
          visible: !root.island
          label: "Enable Island"
          hint: "Live activities run in the island's live slot"
          KitButton { text: "Use Island"; onClicked: ShellSettings.set("barStyle", "island") }
        }
        // without the island there is no slot: the options stay, dimmed and out of reach
        BarLive { width: parent.width; enabled: root.island; opacity: root.island ? 1 : 0.4 }
        KitGrouper {}
      }
      Column {
        width: parent.width
        visible: root.tab === "monitor"
        KitLabel { text: "MONITOR" }
        KitRow {
          label: "Show bar"
          hint: root.screenName
          KitSwitch { checked: root.barOn; onToggled: BarLayout.setBarOn(root.screenName, !checked) }
        }
        KitRow {
          visible: Quickshell.screens.length > 1
          label: "Same bar everywhere"
          hint: "Share the main monitor's layout"
          KitSwitch { checked: BarLayout.shared; onToggled: { BarLayout.setShared(!checked); root.screenName = BarLayout.mainScreen(); } }
        }
        KitSelect {
          visible: Quickshell.screens.length > 1
          label: "Main monitor"
          hint: "Automatic prefers an external monitor"
          model: [{label: "Automatic", value: ""}].concat(Quickshell.screens.map(s => ({label: s.name, value: s.name})))
          current: BarLayout.mainPick
          onPicked: value => { BarLayout.setMainPick(value); root.screenName = BarLayout.mainScreen(); }
        }
        KitText {
          property bool kitUnboxed: true
          width: parent.width
          text: Quickshell.screens.length > 1 ? "Choose the monitor above before editing a separate layout." : "Connect another monitor to configure a separate bar."
          color: Theme.muted
          wrapMode: Text.WordWrap
        }
        KitRow {
          visible: root.other !== "" && !BarLayout.shared
          label: "Copy layout"
          KitButton { text: "From " + root.other; onClicked: { root.remember(); root.island ? BarLayout.islandCopy(root.other, root.screenName) : BarLayout.copyLayout(root.other, root.screenName); } }
        }
        KitGrouper {}
      }
      Column {
  spacing: Theme.sectionGap

        width: parent.width
        visible: root.tab === "hub"
        KitLabel { text: "HUB" }
        KitRow {
          visible: !root.island
          label: "Enable Island"
          hint: "The hub opens from the island clock"
          KitButton { text: "Use Island"; onClicked: ShellSettings.set("barStyle", "island") }
        }
        KitRow {
          enabled: root.island; dimmed: !root.island
          label: "Open the hub"
          wide: true
          KitSegments {
            model: [{label: "Hover", value: "hover"}, {label: "Click", value: "click"}]
            current: ShellSettings.look("clockOpens", "island")
            onPicked: value => ShellSettings.setLook("clockOpens", value, "island")
          }
        }
        KitSliderRow {
          id: hubWidth
          enabled: root.island; opacity: root.island ? 1 : 0.4
          label: "Hub width"
          snaps: [0, 0.25, 0.5, 0.75, 1]
          value: (ModuleSettings.get("hub", "width", 400) - 320) / 160
          text: Math.round(320 + (pressed ? dragValue : value) * 160) + " px"
          onMoved: value => ModuleSettings.set("hub", "width", Math.round(320 + value * 160))
        }
        KitOptionRow {
          enabled: root.island; dimmed: !root.island
          module: "hub"; key: "tileColumns"; fallback: 2
          label: "Tiles per row"; hint: "Hub row modules that can be tiles: Wi-Fi, Bluetooth, VPN, Focus, Dark mode"
          model: [{ label: "2 ×", value: 2 }, { label: "4 ×", value: 4 }]
        }
        KitRow {
          enabled: root.island; dimmed: !root.island
          label: "Avatar"
          hint: ModuleSettings.get("hub", "avatar", "").split("/").pop() || "Your initial"
          KitButton { text: "Choose…"; onClicked: FilesService.pick("Choose a hub avatar", FilesService.home, false, ["image/*"], path => { if (path) ModuleSettings.set("hub", "avatar", path); }) }
          KitButton { visible: ModuleSettings.get("hub", "avatar", "") !== ""; icon: "x"; Accessible.name: "Clear avatar"; onClicked: ModuleSettings.set("hub", "avatar", "") }
        }
        KitLine {}
        KitLabel { text: "CONTENT" }
        KitRow {
          enabled: root.island; dimmed: !root.island
          label: "Media player"
          hint: "Shown when media is available"
          KitSwitch { checked: ShellSettings.look("hubPlayer", "island"); onToggled: ShellSettings.setLook("hubPlayer", !checked, "island") }
        }
        // the four quick sliders in one row: a picked one shows in the hub
        KitRow {
          enabled: root.island; dimmed: !root.island
          label: "Sliders"
          hint: "Pick the ones the hub shows"
          Repeater {
            model: [
              {key: "volume", label: "Volume", fallback: true},
              {key: "microphone", label: "Microphone", fallback: false},
              {key: "brightness", label: "Brightness", fallback: true},
              {key: "dimming", label: "Dimming", fallback: false}
            ]
            KitButton {
              id: sliderChip
              required property var modelData
              readonly property bool on: ModuleSettings.get("hub", modelData.key, modelData.fallback)
              text: modelData.label
              selected: on
              Accessible.role: Accessible.CheckBox
              Accessible.checked: on
              onClicked: ModuleSettings.set("hub", modelData.key, !on)
            }
          }
        }
        KitRow {
          enabled: root.island; dimmed: !root.island
          label: "Hub modules"
          hint: BarLayout.islandIn("hub", root.screenName).length + " modules"
          KitButton { text: "Arrange…"; onClicked: { root.tab = "layout"; if (root.island) root.chooseZone("hub"); } }
        }
        KitGrouper {}
      }
      KitText { width: parent.width; visible: root.layoutError !== ""; text: root.layoutError; color: Theme.red; wrapMode: Text.WordWrap }
      KitGrouper {}
    }
  }

}
