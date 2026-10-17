import QtQuick
import qs.config
import qs.kit

// AI module options in the Shell Manager: which plan limit its bar item shows.
KitColumn {
  spacing: Theme.gapGroup

  KitLabel { text: "BAR" }

  KitOptionRow {
    module: "ai"; key: "limit"; fallback: "session"
    label: "Limit"; hint: "Its percent is shown in the bar"
    model: [{ label: "5 h", value: "session" }, { label: "Week", value: "weekly_all" }]
  }
}
