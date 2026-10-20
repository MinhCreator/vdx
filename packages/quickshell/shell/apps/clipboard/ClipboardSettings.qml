import QtQuick
import qs.config
import qs.kit

// Clipboard options in the Shell Manager (Shell apps › Clipboard): how many
// entries to keep (stored by scripts/clipboard.sh next to the history).
Column {
  spacing: Theme.gapGroup

  KitLabel { text: "HISTORY" }

  KitRow {
    wide: true
    label: "Entries kept"
    hint: "Older ones drop off"

    KitSegments {
      model: ClipboardService.limits.map(n => ({ label: String(n), value: n }))
      current: ClipboardService.limit
      onPicked: value => ClipboardService.setLimit(value)
    }
  }

  KitLine {}

  KitLabel { text: "SAFETY" }

  KitToggleRow { module: "clipboard"; key: "confirm"; label: "Ask before clearing"; hint: "Clear asks “Sure?” once" }

  KitGrouper {}
}
