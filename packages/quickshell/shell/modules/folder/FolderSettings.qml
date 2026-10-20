import QtQuick
import qs.bar
import qs.config
import qs.kit

// Folder options in the Shell Manager: the bar face's text.
Column {
  spacing: Theme.gapGroup

  KitLabel { text: "BAR" }
  BarTextRow { module: "folder" }

  KitLine {}

  KitLinkRow {
    label: "Unseen dot"
    hint: "In Notifications › Bar"
    target: "notifications"
  }

  KitGrouper {}
}
