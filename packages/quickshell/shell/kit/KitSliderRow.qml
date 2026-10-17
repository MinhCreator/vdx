import QtQuick
import qs.config

// A slider with its reading. Two layouts:
//   * `label` set — small-caps "LABEL ......... value" over a full-width slider;
//   * `label` empty — icon, slider and value on one line; with `clickable` the
//     icon is a button (mute and the like).
Item {
  id: root

  property string label: ""
  property string icon: ""
  property color iconTint: Theme.foreground0
  property bool clickable: false
  property real value: 0
  property string text: ""
  property bool dimmed: false
  property color tint: Theme.foreground0
  property var snaps: []

  readonly property bool captioned: label !== ""
  readonly property bool pressed: slider.pressed
  readonly property real dragValue: slider.dragValue

  signal moved(real value)
  signal released(real value)
  signal iconClicked()

  width: parent ? parent.width : 0
  implicitHeight: captioned ? caption.implicitHeight + 6 + slider.implicitHeight : 26

  KitLabel {
    id: caption
    visible: root.captioned
    text: root.label
    value: root.text
    valueColor: root.dimmed ? Theme.gray : Theme.foreground2
  }

  // ---- inline layout ----
  Item {
    id: iconBox
    visible: !root.captioned
    anchors { left: parent.left; verticalCenter: slider.verticalCenter }
    width: 26
    height: 26

    Rectangle {
      anchors.fill: parent
      visible: root.clickable && iconArea.containsMouse
      color: Theme.background1
    }

    KitIcon {
      anchors.centerIn: parent
      name: root.icon
      tint: root.iconTint
      size: 16
    }

    MouseArea {
      id: iconArea
      anchors.fill: parent
      enabled: root.clickable
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.iconClicked()
    }
  }

  FontMetrics { id: metrics; font: inlineValue.font }

  KitText {
    id: inlineValue
    visible: !root.captioned
    anchors { right: parent.right; verticalCenter: slider.verticalCenter }
    width: metrics.advanceWidth("150%")
    horizontalAlignment: Text.AlignRight
    text: root.text
    color: root.dimmed ? Theme.gray : Theme.foreground2
    font.pixelSize: Theme.fontSize - 1
  }

  KitSlider {
    id: slider
    anchors {
      left: root.captioned ? parent.left : iconBox.right
      leftMargin: root.captioned ? 0 : 8
      right: root.captioned ? parent.right : inlineValue.left
      rightMargin: root.captioned ? 0 : 10
      bottom: parent.bottom
      bottomMargin: root.captioned ? 0 : 4
    }
    value: root.value
    dimmed: root.dimmed
    tint: root.tint
    snaps: root.snaps
    onMoved: value => root.moved(value)
    onReleased: value => root.released(value)
  }
}
