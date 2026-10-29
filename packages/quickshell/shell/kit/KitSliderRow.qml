import QtQuick
import qs.config

// A slider with its reading. Two layouts:
//   * `label` set — small-caps "LABEL ......... value" over a full-width slider
//     (`rowStyle`: the label and value as in a KitRow);
//   * `label` empty — icon, slider and value on one line (Strict: the icon and the
//     value sit inside the plate); with `clickable` the
//     icon is a button (mute and the like).
Item {
  id: root

  property string label: ""
  property string accessibleName: label || icon
  property string icon: ""
  property color iconTint: Theme.foreground0
  property bool clickable: false
  property real value: 0
  property string text: ""
  property bool dimmed: false
  property color tint: Theme.foreground0
  property var snaps: []
  property var spectrum: []
  property bool rowStyle: false
  // Strict: the label at the left, a bar with its reading inside at the right
  readonly property bool plate: !Theme.material && spectrum.length === 0

  readonly property bool captioned: label !== ""
  readonly property bool pressed: slider.pressed
  readonly property real dragValue: slider.dragValue

  signal moved(real value)
  signal released(real value)
  signal iconClicked()

  width: parent ? parent.width : 0
  implicitHeight: plate ? slider.implicitHeight + 4 : captioned ? (rowStyle ? rowCaption.implicitHeight + Theme.gapMedium : caption.implicitHeight + 6) + slider.implicitHeight : Math.max(28, slider.implicitHeight + 4)

  KitLabel {
    id: caption
    visible: root.captioned && !root.rowStyle && !root.plate
    text: root.label
    value: root.text
    valueColor: root.dimmed ? Theme.gray : Theme.foreground2
  }

  KitText {
    id: rowCaption
    visible: root.captioned && (root.rowStyle || root.plate)
    anchors.verticalCenter: root.plate ? parent.verticalCenter : undefined
    text: root.label
  }

  KitText {
    visible: rowCaption.visible && !root.plate
    anchors { right: parent.right; baseline: rowCaption.baseline }
    text: root.text
    color: root.dimmed ? Theme.gray : Theme.foreground2
  }

  // ---- inline layout ----
  Item {
    id: iconBox
    visible: !root.captioned
    z: 1                       // a plate carries the icon inside its left end
    anchors { left: parent.left; leftMargin: root.plate ? 2 : 0; verticalCenter: slider.verticalCenter }
    width: Math.max(28, slider.implicitHeight + 4)
    height: Math.max(28, slider.implicitHeight + 4)

    Rectangle {
      anchors.centerIn: parent
      width: parent.width - 4
      height: parent.height - 4
      opacity: root.clickable && iconArea.containsMouse ? 1 : 0
      visible: opacity > 0.001
      Behavior on opacity { enabled: Motion.controls; NumberAnimation { duration: Motion.normal; easing.type: Motion.easing } }
      radius: Theme.radiusFor(height)         // the control's proportion at its own size, not a 36 px button's
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
    visible: !root.captioned && !root.plate
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
      left: root.plate && root.captioned ? undefined : root.captioned || root.plate ? parent.left : iconBox.right
      leftMargin: root.captioned || root.plate ? 0 : 8
      right: root.captioned || root.plate ? parent.right : inlineValue.left
      rightMargin: root.captioned || root.plate ? 0 : 10
      bottom: parent.bottom
      bottomMargin: root.plate ? 2 : root.captioned ? 0 : 4
    }
    width: root.plate && root.captioned ? Math.min(Theme.controlWidth, Math.round(parent.width * 0.58)) : implicitWidth
    plate: root.plate
    text: root.text
    accessibleName: root.accessibleName
    value: root.value
    dimmed: root.dimmed
    tint: root.tint
    snaps: root.snaps
    spectrum: root.spectrum
    onMoved: value => root.moved(value)
    onReleased: value => root.released(value)
  }
}
