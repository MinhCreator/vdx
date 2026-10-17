import QtQuick
import qs.bar
import qs.config
import qs.kit

// The backups' bar module options (Shell apps › BAR): the face shows the name or nothing.
Column {
  spacing: Theme.gapGroup

  KitLabel { text: "BAR" }
  BarTextRow { module: "backup"; hasContent: false }
}
