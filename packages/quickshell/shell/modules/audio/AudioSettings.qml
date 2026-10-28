import QtQuick
import qs.bar
import qs.config
import qs.kit

// Audio options in the Shell Manager: the bar's volume. Pausing music for other sound
// (AudioPause.qml) is the Sound page.
KitColumn {
  spacing: Theme.sectionGap

  KitLabel { text: "BAR" }
  BarTextRow { module: "audio" }

  KitToggleRow { visible: ModuleSettings.get("audio", "text", "content") === "content"; module: "audio"; key: "percent"; label: "Show volume"; hint: "Off: icon only" }

  KitGrouper {}
}
