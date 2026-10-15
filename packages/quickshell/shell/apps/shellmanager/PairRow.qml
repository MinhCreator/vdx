import QtQuick
import qs.config
import qs.kit

// A setting of two numbers (width × height, x, y): two fields side by side
// in a wide row, `separator` between them. Enter in either hands both over
// when they are whole numbers.
KitRow {
  id: root

  property string first: ""
  property string second: ""
  property string separator: "×"

  readonly property bool valid: /^\d+$/.test(first.trim()) && /^\d+$/.test(second.trim())

  signal edited(string first, string second)
  signal accepted(int first, int second)

  wide: true

  Row {
    spacing: 8

    KitInput {
      width: (parent.width - sep.width - 2 * parent.spacing) / 2
      text: root.first
      onTextEdited: root.edited(text, root.second)
      onAccepted: if (root.valid) root.accepted(+root.first.trim(), +root.second.trim())
    }

    KitText {
      id: sep
      anchors.verticalCenter: parent.verticalCenter
      text: root.separator
      color: Theme.muted
    }

    KitInput {
      width: (parent.width - sep.width - 2 * parent.spacing) / 2
      text: root.second
      onTextEdited: root.edited(root.first, text)
      onAccepted: if (root.valid) root.accepted(+root.first.trim(), +root.second.trim())
    }
  }
}
