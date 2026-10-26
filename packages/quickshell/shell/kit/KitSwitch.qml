import QtQuick
import qs.config

// A switch. Material: the Material 3 switch, 52 × 32 — off, a surfaceContainerHighest
// track with a 2 px outline and a 16 px handle in the outline colour; on, a primary
// track and a 24 px primaryText handle with a check; the handle grows to 28 while
// pressed, a state layer rings it under the pointer. Strict (the boards): 44 × 26, a
// 20 px knob 3 px in; on, a primary track and a surface-coloured knob; off, a quiet
// track and a dim knob (Outlined: the off track framed). No check, no halo.
// With the accent on Switches (Appearance › Accent) an on track is a gradient from
// the accent's first colour to its second. Square: a square track and knob.
Rectangle {
  id: root

  property bool checked: false
  property bool disabled: false
  property color trackColor: Theme.m3 ? Theme.surfaceHighest : Theme.filled ? Theme.surfaceHighest : Theme.clear
  readonly property bool accented: checked && Theme.accentOn("switches")
  readonly property bool m3: Theme.m3
  readonly property bool hovered: area.containsMouse && !disabled
  readonly property color onTrack: Theme.primary

  signal toggled()

  implicitWidth: Theme.switchWidth
  implicitHeight: Theme.switchHeight
  radius: Theme.pill(height)
  border.width: checked ? 0 : m3 ? 2 : Theme.filled ? 0 : 1
  border.color: m3 ? Theme.outline : hovered ? Theme.outlineActive : Theme.outline
  opacity: disabled ? Theme.disabledOpacity : 1

  gradient: Gradient {
    orientation: Gradient.Horizontal
    GradientStop {
      position: 0
      color: root.checked ? (root.accented ? Theme.accent : root.onTrack) : root.trackColor
      Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }
    }
    GradientStop {
      position: 1
      color: root.checked ? (root.accented ? Theme.accentEnd : root.onTrack) : root.trackColor
      Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }
    }
  }

  // material: the state layer round the handle (40 px)
  Rectangle {
    visible: root.m3
    anchors.centerIn: knob
    width: 40
    height: width
    radius: width / 2
    color: root.checked ? Theme.primary : Theme.surfaceText
    opacity: area.pressed ? Theme.statePressed : root.hovered ? Theme.stateHover : 0
    Behavior on opacity { enabled: Motion.controls; NumberAnimation { duration: Motion.quick } }
  }

  Rectangle {
    id: knob

    property int size: !root.m3 ? root.height - 6
                     : area.pressed && !root.disabled ? 28
                     : root.checked ? 24 : 16
    readonly property real centreOff: root.height / 2
    readonly property real centreOn: root.width - root.height / 2

    width: size
    height: size
    radius: Theme.pill(height)
    anchors.verticalCenter: parent.verticalCenter
    x: (root.checked ? centreOn : centreOff) - size / 2
    color: root.checked ? (root.m3 ? Theme.primaryText : Theme.surface)
         : root.m3 ? (root.hovered ? Theme.surfaceVariantText : Theme.outline)
         : root.hovered ? Theme.foreground2 : Theme.gray

    Behavior on x { enabled: Motion.controls; NumberAnimation { duration: Motion.quick; easing.type: Motion.easing } }
    Behavior on size { enabled: Motion.controls; NumberAnimation { duration: Motion.quick; easing.type: Motion.easing } }
    Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }

    KitIcon {
      anchors.centerIn: parent
      visible: root.m3 && root.checked
      name: "check"
      tint: root.accented ? Theme.accent : Theme.primaryContainerText
      size: 16
    }
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: if (!root.disabled) root.toggled()
  }
}
