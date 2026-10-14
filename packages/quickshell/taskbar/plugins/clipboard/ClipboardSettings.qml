import QtQuick
import qs.config
import qs.kit

// Clipboard options in the Shell Manager: how many entries to keep (stored
// by scripts/clipboard.sh next to the history).
Column {
  spacing: 14

  KitRow {
    label: "Keep last"
    hint: "older entries drop off"

    KitChoices {
      model: ClipboardService.limits.map(n => ({ label: String(n), value: n }))
      current: ClipboardService.limit
      onPicked: value => ClipboardService.setLimit(value)
    }
  }
}
