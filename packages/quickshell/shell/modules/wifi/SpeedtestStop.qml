import QtQuick
import qs.config
import qs.kit

// A stop on the speed test path: icon, name, address under it. `naturalWidth`
// fits the text, `nameWidth` the name alone; between them the address ends in ….
Column {
  id: root

  property string icon: ""
  property string name: ""
  property string hint: ""

  readonly property real nameWidth: Math.ceil(Math.max(18, nameMetrics.advanceWidth)) + 1
  readonly property real naturalWidth: Math.max(nameWidth, Math.ceil(hintMetrics.advanceWidth) + 1)

  spacing: 4

  TextMetrics { id: nameMetrics; font: nameText.font; text: root.name }
  TextMetrics { id: hintMetrics; font: hintText.font; text: root.hint }

  KitIcon {
    anchors.horizontalCenter: parent.horizontalCenter
    name: root.icon
    size: 18
  }

  KitText {
    id: nameText
    width: root.width
    horizontalAlignment: Text.AlignHCenter
    text: root.name
    elide: Text.ElideRight
    font.pixelSize: Theme.fontSize - 1
  }

  KitText {
    id: hintText
    width: root.width
    horizontalAlignment: Text.AlignHCenter
    text: root.hint
    color: Theme.muted
    elide: Text.ElideMiddle
    font.pixelSize: Theme.fontSize - 2
  }
}
