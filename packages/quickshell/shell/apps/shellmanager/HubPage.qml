import QtQuick
import qs.apps.files
import qs.bar
import qs.config
import qs.kit

// Hub (the Island style): the panel that opens from the clock — when it opens, how wide it
// is, its tiles and what it holds. It was the Bar page's Hub tab; its keys are the same.
Column {
  id: root
  readonly property Item previewItem: null
  signal navigate(string tab, string target)

  readonly property string icon: "layout"
  readonly property string title: "Hub"
  readonly property string description: "The panel that opens from the island's clock."
  readonly property string subtitle: Theme.island ? "ISLAND · " + ModuleSettings.get("hub", "tileColumns", 2) + " TILES PER ROW" : "ISLAND STYLE ONLY"
  readonly property var jumps: []

  // the hub's own keys, and the two looks it keeps beside them
  readonly property bool changed: ModuleSettings.changed("hub") || ShellSettings.looksTouched(["clockOpens", "hubPlayer"])
  function reset() { ModuleSettings.reset("hub"); ShellSettings.looksReset(["clockOpens", "hubPlayer"]); }

  // the tile modules in the hub row: what Tiles per row is for
  readonly property int tileCount: BarLayout.islandIn("hub", BarLayout.mainScreen()).filter(id => BarLayout.isTile(id)).length

  spacing: Theme.sectionGap

  KitNotice {
    visible: !Theme.island
    title: "The hub belongs to the Island style"
    text: "The island is one pill with a hub and live activities. The strip has neither: these settings wait until you switch."
    action: "Use Island"
    onActed: ShellSettings.set("barStyle", "island")
  }

  KitNotice {
    visible: Theme.island && HubBlocks.shown("tiles") && root.tileCount === 0
    title: "No tile in the Hub row"
    text: "Put Wi-Fi, Bluetooth, VPN, Focus or Dark mode there."
    action: "Arrange"
    onActed: root.navigate("bar", "hubzone")
  }

  Column {
    width: parent.width
    spacing: Theme.sectionGap
    visible: Theme.island

    KitLabel { text: "SIZE" }
    KitSliderRow {
      label: "Hub width"
      snaps: [0, 0.25, 0.5, 0.75, 1]
      value: (ModuleSettings.get("hub", "width", 400) - 320) / 160
      text: Math.round(320 + (pressed ? dragValue : value) * 160) + " px"
      onMoved: value => ModuleSettings.set("hub", "width", Math.round(320 + value * 160))
    }
    KitGrouper {}
  }

  KitLine { visible: Theme.island }

  Column {
    width: parent.width
    spacing: Theme.sectionGap
    visible: Theme.island

    KitLabel { text: "BEHAVIOUR" }
    KitRow {
      label: "Opens on"
      hint: "Hover the clock, or click it"
      wide: true
      KitSegments {
        model: [{label: "Hover", value: "hover"}, {label: "Click", value: "click"}]
        current: ShellSettings.look("clockOpens", "island")
        onPicked: value => ShellSettings.setLook("clockOpens", value, "island")
      }
    }
    KitToggleRow { module: "hub"; key: "autoClose"; fallback: true; label: "Close when the pointer leaves"; hint: "Off: it stays until Escape or a click away" }
    KitSliderRow {
      visible: ModuleSettings.get("hub", "autoClose", true)
      label: "Close delay"
      snaps: [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1]
      value: (ModuleSettings.get("hub", "closeDelay", 500) - 200) / 1000
      text: ((pressed ? 200 + Math.round(dragValue * 10) * 100 : ModuleSettings.get("hub", "closeDelay", 500)) / 1000).toFixed(1) + " s"
      onMoved: value => ModuleSettings.set("hub", "closeDelay", 200 + Math.round(value * 10) * 100)
    }
    KitGrouper {}
  }

  KitLine { visible: Theme.island }

  Column {
    width: parent.width
    spacing: Theme.sectionGap
    visible: Theme.island

    KitLabel { text: "LOOK" }
    KitRow {
      label: "Picture"
      hint: ModuleSettings.get("hub", "avatar", "").split("/").pop() || "None: your initial"
      KitButton { text: "Choose…"; onClicked: FilesService.pick("Choose a hub picture", FilesService.home, false, ["image/*"], path => { if (path) ModuleSettings.set("hub", "avatar", path); }) }
      KitButton { visible: ModuleSettings.get("hub", "avatar", "") !== ""; icon: "x"; Accessible.name: "Clear the picture"; onClicked: ModuleSettings.set("hub", "avatar", "") }
    }
    KitGrouper {}
  }

  KitLine { visible: Theme.island }

  HubBlocksList { width: parent.width; visible: Theme.island; onArrange: root.navigate("bar", "hubzone") }

  KitLine { visible: Theme.island }

  KitGrouper {}
}
