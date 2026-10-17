import QtQuick
import qs.bar
import qs.config
import qs.kit

// A row of module icons for BarPreview, ending in +N for those left out.
Row {
  id: root

  property var ids: []
  property int more: 0

  spacing: Theme.gapLoose

  Repeater {
    model: root.ids
    KitIcon {
      required property string modelData
      anchors.verticalCenter: parent.verticalCenter
      name: BarLayout.icon(modelData)
      tint: modelData === "clock" && Theme.island ? Theme.foreground0 : Theme.foreground2
      size: Theme.iconSmall
    }
  }

  KitText {
    anchors.verticalCenter: parent.verticalCenter
    visible: root.more > 0
    text: "+" + root.more
    color: Theme.muted
    font.pixelSize: Theme.fontSize - 2
  }
}
