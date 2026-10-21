import QtQuick
import qs.config
import qs.kit

// Clock options in the Shell Manager: what the bar shows.
Column {
  spacing: Theme.gapGroup

  KitLabel { text: "BAR" }

  KitOptionRow {
    module: "clock"; key: "twelveHour"; fallback: false
    label: "Clock format"; hint: "14:05 or 2:05 PM"
    model: [{ label: "24h", value: false }, { label: "12h", value: true }]
  }
  KitToggleRow { module: "clock"; key: "seconds";    fallback: false; label: "Show seconds"; hint: "14:05:32" }
  KitToggleRow { module: "clock"; key: "date";       fallback: false; label: "Show date";    hint: "Wed 15 · 14:05" }

  KitGrouper {}
}
