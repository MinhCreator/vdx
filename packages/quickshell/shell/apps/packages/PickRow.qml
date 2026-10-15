import QtQuick
import qs.kit

// A KitRow with its checkbox on the left, so the boxes line up down a list.
// The row's controls (children) go on the right, as in any KitRow.
Row {
  id: root

  property alias label: row.label
  property alias hint: row.hint
  property alias labelColor: row.labelColor
  property bool checked: false
  default property alias trailing: row.trailing
  signal toggled()

  width: parent ? parent.width : 0
  spacing: 12

  PackageCheck {
    anchors.verticalCenter: parent.verticalCenter
    checked: root.checked
    onToggled: root.toggled()
  }

  KitRow {
    id: row
    width: root.width - root.spacing - 16
  }
}
