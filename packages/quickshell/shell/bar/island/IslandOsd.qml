import QtQuick
import qs.config
import qs.kit

// A volume or brightness change: icon, level line, percent.
Item {
  id: root

  readonly property real level: Math.max(0, Math.min(1, IslandService.osdLevel))

  KitIcon {
    id: icon
    anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
    name: IslandService.osdIcon
    size: Theme.iconSmall + 2
    tint: IslandService.osdMuted ? Theme.gray : Theme.foreground0
  }

  Rectangle {
    anchors { left: icon.right; right: value.left; leftMargin: Theme.gapLoose; rightMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }
    height: 4
    radius: Theme.pill(height)
    color: Theme.background2

    Rectangle {
      width: parent.width * root.level
      height: parent.height
      radius: Theme.pill(height)
      // past 100 % the sink is boosted: attention
      color: IslandService.osdMuted ? Theme.gray : IslandService.osdLevel > 1 ? Theme.yellow : Theme.foreground0
      Behavior on width { enabled: Motion.controls; NumberAnimation { duration: Motion.quick; easing.type: Motion.easing } }
    }
  }

  KitText {
    id: value
    anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
    width: 34
    horizontalAlignment: Text.AlignRight
    text: IslandService.osdMuted ? "off" : Math.round(IslandService.osdLevel * 100) + "%"
    color: Theme.gray
  }
}
