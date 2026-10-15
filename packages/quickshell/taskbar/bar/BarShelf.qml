import QtQuick
import Quickshell
import qs.config
import qs.kit

// The edit panel under a bar while the layout is edited in place: the shelf of
// plugins that are not on this bar (drag one up onto the strip; drag a module
// down here to take it off) and the actions. `bar` (Bar.qml) owns the drag.
Item {
  id: root

  required property var bar

  readonly property string screenName: bar.screenName
  readonly property var ids: BarLayout.unplaced(screenName)
  readonly property bool target: bar.dragId !== "" && bar.dropZone === "shelf"
  // a monitor with the other role, whose layout this one can copy
  readonly property string other: Quickshell.screens.map(s => s.name)
    .find(n => BarLayout.roleOf(n) !== BarLayout.roleOf(screenName)) ?? ""

  implicitHeight: 72
  Rectangle {
    anchors.fill: parent
    color: root.target ? Theme.background1 : "transparent"
  }

  Rectangle {
    width: parent.width
    height: 2
    color: Theme.frame
  }

  Rectangle {
    y: parent.height - height
    width: parent.width
    height: 2
    color: Theme.frame
  }

  KitText {
    x: Theme.edgeMargin
    y: 10
    text: "NOT ON THIS BAR · " + root.ids.length
    color: root.target ? Theme.foreground0 : Theme.muted
    font.pixelSize: Theme.fontSize - 3
    font.letterSpacing: 1
  }

  Row {
    x: Theme.edgeMargin
    y: 28
    spacing: 4

    Repeater {
      model: root.ids

      Rectangle {
        id: chip

        required property string modelData

        width: 30
        height: 30
        color: area.containsMouse ? Theme.background3 : "transparent"
        border.width: 1
        border.color: area.containsMouse ? Theme.foreground2 : Theme.background3
        opacity: root.bar.dragId === modelData ? 0.25 : 1

        KitIcon {
          anchors.centerIn: parent
          name: BarLayout.icon(chip.modelData)
          solid: ShellSettings.solidIcons
          size: 16
        }

        MouseArea {
          id: area
          anchors.fill: parent
          hoverEnabled: true
          preventStealing: true
          cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
          onPressed: mouse => {
            root.bar.dragId = chip.modelData;
            const p = mapToItem(root.bar.dragLayer, mouse.x, mouse.y);
            root.bar.track(p.x, p.y);
          }
          onPositionChanged: mouse => {
            if (root.bar.dragId === "") return;
            const p = mapToItem(root.bar.dragLayer, mouse.x, mouse.y);
            root.bar.track(p.x, p.y);
          }
          onReleased: root.bar.drop()
        }
      }
    }
  }

  KitText {
    visible: root.ids.length === 0
    x: Theme.edgeMargin
    y: 28
    height: 30
    text: root.bar.dragId !== "" ? "drop here to take it off this bar" : "everything is on the bar"
    color: Theme.muted
    font.pixelSize: Theme.fontSize - 2
  }

  Row {
    anchors { right: parent.right; rightMargin: Theme.edgeMargin; verticalCenter: parent.verticalCenter }
    spacing: 6

    KitButton {
      visible: root.other !== ""
      icon: BarLayout.isInternal(root.other) ? "laptop" : "monitor"
      text: "Same as other"
      onClicked: BarLayout.copyLayout(root.other, root.screenName)
    }

    KitButton {
      icon: "rotate-ccw"
      text: "Reset"
      disabled: !BarLayout.customized(root.screenName)
      onClicked: BarLayout.reset(root.screenName)
    }

    KitButton {
      icon: "check"
      text: "Done"
      selected: true
      onClicked: BarLayout.editing = false
    }
  }
}
