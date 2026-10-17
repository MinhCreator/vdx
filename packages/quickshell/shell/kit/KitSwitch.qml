import QtQuick
import qs.config

// Rectangular switch with a square knob (round corners: a pill and a disc):
// dim on the left when off, bright on the right when on. With the accent on
// Switches (Appearance › Accent), an on switch fills with the accent,
// a gradient from its first colour to its second.
Rectangle {
  id: root

  property bool checked: false
  property bool disabled: false
  property color trackColor: Theme.background3   // darker on a filled (selected) row
  readonly property bool accented: checked && Theme.accentOn("switches")

  signal toggled()

  implicitWidth: 36
  implicitHeight: 20
  radius: Theme.pill(height)
  border.width: area.containsMouse && !disabled ? Theme.frameWidth : 0
  border.color: Theme.foreground2
  opacity: disabled ? 0.4 : 1

  gradient: Gradient {
    orientation: Gradient.Horizontal
    GradientStop {
      position: 0
      color: root.accented ? Theme.accent : root.trackColor
      Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }
    }
    GradientStop {
      position: 1
      color: root.accented ? Theme.accentEnd : root.trackColor
      Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }
    }
  }

  Rectangle {
    width: 14
    height: 14
    radius: Theme.pill(height)
    anchors.verticalCenter: parent.verticalCenter
    x: root.checked ? root.width - width - 3 : 3
    color: root.accented ? Theme.background0 : root.checked ? Theme.foreground0 : Theme.gray

    Behavior on x { enabled: Motion.controls; NumberAnimation { duration: Motion.quick; easing.type: Motion.easing } }
    Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: if (!root.disabled) root.toggled()
  }
}
