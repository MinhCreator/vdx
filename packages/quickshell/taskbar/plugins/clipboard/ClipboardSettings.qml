import QtQuick
import qs.config
import qs.kit

// Clipboard options in the Shell Manager: how many entries to keep (stored
// by scripts/clipboard.sh next to the history).
Column {
  spacing: 14

  KitLabel { text: "HISTORY" }

  KitRow {
    wide: true
    label: "Keep last"
    hint: "Older entries drop off"

    KitChoices {
      stretch: true
      model: ClipboardService.limits.map(n => ({ label: String(n), value: n }))
      current: ClipboardService.limit
      onPicked: value => ClipboardService.setLimit(value)
    }
  }
}
