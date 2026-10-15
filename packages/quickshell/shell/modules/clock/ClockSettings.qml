import QtQuick
import qs.config
import qs.kit

// Clock options in the Shell Manager: what the bar shows.
Column {
  spacing: 14

  KitLabel { text: "BAR" }

  KitToggleRow { module: "clock"; key: "twelveHour"; fallback: false; label: "12-hour clock"; hint: "2:05 PM instead of 14:05" }
  KitToggleRow { module: "clock"; key: "seconds";    fallback: false; label: "Seconds";       hint: "14:05:32" }
  KitToggleRow { module: "clock"; key: "date";       fallback: false; label: "Date";          hint: "Wed 15 · 14:05" }
}
