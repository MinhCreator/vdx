import QtQuick
import qs.config
import qs.kit

// The Shell Manager's own options in Shell apps (ShellSettings, not a module's).
Column {
  spacing: Theme.gapGroup

  KitLabel { text: "OPENING" }

  KitRow {
    wide: true
    label: "Opens on"
    hint: "The first page, or the last one"

    KitSegments {
      model: [
        { label: "Main page", value: "main" },
        { label: "Last page", value: "last" }
      ]
      current: ShellSettings.managerStart
      onPicked: value => ShellSettings.set("managerStart", value)
    }
  }

  KitGrouper {}
}
