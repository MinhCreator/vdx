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
  readonly property string description: "The panel that opens from the island's clock: what it holds, how wide it is and when it opens."
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

  Column {
    width: parent.width
    spacing: Theme.sectionGap
    visible: Theme.island

    KitLabel { text: "HUB"; about: "The panel that opens from the clock" }
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
    KitSliderRow {
      label: "Hub width"
      snaps: [0, 0.25, 0.5, 0.75, 1]
      value: (ModuleSettings.get("hub", "width", 400) - 320) / 160
      text: Math.round(320 + (pressed ? dragValue : value) * 160) + " px"
      onMoved: value => ModuleSettings.set("hub", "width", Math.round(320 + value * 160))
    }
    KitRow {
      label: "Picture"
      hint: ModuleSettings.get("hub", "avatar", "").split("/").pop() || "None: your initial"
      KitButton { text: "Choose…"; onClicked: FilesService.pick("Choose a hub picture", FilesService.home, false, ["image/*"], path => { if (path) ModuleSettings.set("hub", "avatar", path); }) }
      KitButton { visible: ModuleSettings.get("hub", "avatar", "") !== ""; icon: "x"; Accessible.name: "Clear the picture"; onClicked: ModuleSettings.set("hub", "avatar", "") }
    }
    KitGrouper {}
  }

  KitLine { visible: Theme.island }

  Column {
    width: parent.width
    spacing: Theme.sectionGap
    visible: Theme.island

    KitLabel { text: "CONTENT"; about: "What the hub holds. Modules are placed in the Hub row of the bar's Layout" }
    KitOptionRow {
      needs: root.tileCount === 0 ? "Put Wi-Fi, Bluetooth, VPN, Focus or Dark mode in the Hub row" : ""
      needsAction: "Arrange"
      onNeedsActed: root.navigate("bar", "hubzone")
      module: "hub"; key: "tileColumns"; fallback: 2
      label: "Tiles per row"; hint: "Wi-Fi, Bluetooth, VPN, Focus, Dark mode"
      model: [{ label: "2 ×", value: 2 }, { label: "4 ×", value: 4 }]
    }
    KitRow {
      label: "Player card"
      hint: "Shows with nothing playing too"
      KitSwitch { checked: ShellSettings.look("hubPlayer", "island"); onToggled: ShellSettings.setLook("hubPlayer", !checked, "island") }
    }
    // the four quick sliders in one row: a picked one shows in the hub
    KitRow {
      label: "Sliders"
      hint: "The ones you drag in the hub"
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
      label: "Modules in the hub"
      hint: "Placed in the Hub row of Layout: " + BarLayout.islandIn("hub", BarLayout.mainScreen()).length
      KitButton { text: "Arrange…"; onClicked: root.navigate("bar", "hubzone") }
    }
    KitGrouper {}
  }

  KitGrouper {}
}
