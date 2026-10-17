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
    Item {
      id: slot
      required property string modelData
      anchors.verticalCenter: parent.verticalCenter
      width: Theme.iconSmall
      height: Theme.iconSmall

      // a custom separator: the same line as the Shell Manager's chip
      Rectangle {
        visible: BarLayout.isSeparator(slot.modelData)
        anchors.centerIn: parent
        width: 2
        height: parent.height
        radius: Theme.pill(width)
        color: Theme.foreground2
      }

      KitIcon {
        visible: !BarLayout.isSeparator(slot.modelData)
        anchors.centerIn: parent
        name: BarLayout.icon(slot.modelData)
        tint: slot.modelData === "clock" && Theme.island ? Theme.foreground0 : Theme.foreground2
        size: Theme.iconSmall
      }
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
