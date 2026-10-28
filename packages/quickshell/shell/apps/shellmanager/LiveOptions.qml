import QtQuick
import qs.config
import qs.kit

// The options of one live activity, shown under its row in Bar › Live when the row is
// opened (BarLiveSection). Each kind has the few that concern only it; the rules for all
// of them (flash length, the wheel) stay in BEHAVIOUR.
Column {
  id: root

  property string kind: ""

  // what a kind has to set: the rows below read this to know whether to offer the opening
  readonly property bool any: kind === "notice" || kind === "battery" || kind === "music"

  spacing: Theme.settingsRowInset          // the box's own row rhythm: a gap each side of a hairline

  // and one under the activity's own row, so its options read as its own
  Rectangle { width: parent.width; height: Theme.dividerThickness; color: Theme.dividerColor }

  KitRow {
    visible: root.kind === "notice"
    label: "Stays for"
    hint: "How long a message's line holds the slot"
    wide: true
    KitSegments {
      model: [{label: "5 s", value: 5000}, {label: "10 s", value: 10000}, {label: "Until read", value: 0}]
      current: ShellSettings.liveNoticeMs
      onPicked: value => ShellSettings.setLook("liveNoticeMs", value, "island")
    }
  }

  KitRow {
    visible: root.kind === "battery"
    label: "Shows below"
    hint: "The charge at which it takes the pill"
    wide: true
    KitSegments {
      model: [{label: "10%", value: 10}, {label: "15%", value: 15}, {label: "20%", value: 20}, {label: "30%", value: 30}]
      current: ShellSettings.liveBatteryBelow
      onPicked: value => ShellSettings.setLook("liveBatteryBelow", value, "island")
    }
  }

  // a hairline parts the options when a kind has several
  Rectangle { visible: root.kind === "battery"; width: parent.width; height: Theme.dividerThickness; color: Theme.dividerColor }

  KitRow {
    visible: root.kind === "battery"
    label: "Stays for"
    hint: "Until fixed: until the charger is back or the charge recovers"
    wide: true
    KitSegments {
      model: [{label: "5 s", value: "5s"}, {label: "Until fixed", value: "fixed"}]
      current: ShellSettings.liveBatteryStay
      onPicked: value => ShellSettings.setLook("liveBatteryStay", value, "island")
    }
  }

  KitRow {
    visible: root.kind === "music"
    label: "Show on pause"
    hint: "The track stays in the slot while paused"
    KitSwitch { checked: ShellSettings.liveMusicPaused; onToggled: ShellSettings.setLook("liveMusicPaused", !checked, "island") }
  }

  Item { width: 1; height: 1 }                       // the same gap under the last option
}
