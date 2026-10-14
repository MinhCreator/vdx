import QtQuick
import qs.config

// "Label            value" line: the label dim on the left, the value on the
// right; the value elides before it reaches the label.
Item {
  id: root

  property string label: ""
  property string value: ""
  property color valueColor: Theme.foreground0

  width: parent ? parent.width : 0
  implicitHeight: valueText.implicitHeight

  KitText {
    id: labelText
    text: root.label
    color: Theme.foreground2
    font.pixelSize: Theme.fontSize - 1
  }

  TextMetrics { id: metrics; font: valueText.font; text: root.value }

  KitText {
    id: valueText
    anchors.right: parent.right
    width: Math.min(Math.ceil(metrics.advanceWidth) + 1, root.width - labelText.implicitWidth - 16)
    horizontalAlignment: Text.AlignRight
    text: root.value
    color: root.valueColor
    elide: Text.ElideRight
    font.pixelSize: Theme.fontSize - 1
  }
}
