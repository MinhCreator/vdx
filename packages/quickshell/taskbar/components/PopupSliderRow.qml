import QtQuick
import qs.config

// A slider with its value. Two layouts:
//   * `label` set   — "LABEL ........ value" caption, full-width slider below;
//   * `label` empty — icon, slider and value on one line. With `clickable` the
//                     icon is a button (mute and the like).
// The slider reports moved(0..1).
Item {
  id: root

  property string label: ""
  property string glyph: ""
  property color glyphTint: Theme.foreground0
  property bool clickable: false
  property real value: 0
  property string text: ""
  property bool dimmed: false

  readonly property bool captioned: label !== ""
  readonly property color valueColor: dimmed ? Theme.muted : Theme.foreground0

  signal moved(real value)
  signal iconClicked()

  implicitHeight: captioned ? caption.implicitHeight + slider.implicitHeight : Theme.rowHeight

  // ---- captioned layout ------------------------------------------------------
  ThemeText {
    id: caption
    visible: root.captioned
    text: root.label
    color: Theme.dim
    font.pixelSize: Theme.fontSize - 2
    font.letterSpacing: 1
  }

  ThemeText {
    visible: root.captioned
    anchors { right: parent.right; verticalCenter: caption.verticalCenter }
    text: root.text
    color: root.valueColor
    font.pixelSize: Theme.fontSize - 1
  }

  // ---- inline layout ---------------------------------------------------------
  Item {
    id: icon
    visible: !root.captioned
    anchors { left: parent.left; verticalCenter: slider.verticalCenter }
    width: Theme.fontSize + 7
    height: width

    PopupButton {
      anchors.centerIn: parent
      visible: root.clickable
      glyph: root.glyph
      tint: root.glyphTint
      glyphSize: Theme.fontSize
      frameless: true
      hoverBackground: false
      onClicked: root.iconClicked()
    }

    ThemeText {
      anchors.centerIn: parent
      visible: !root.clickable
      text: root.glyph
      color: root.glyphTint
    }
  }

  // Sized to the widest value ("150%"), so the gap to the slider stays small.
  FontMetrics {
    id: metrics
    font: inlineValue.font
  }

  ThemeText {
    id: inlineValue
    visible: !root.captioned
    anchors { right: parent.right; verticalCenter: slider.verticalCenter }
    width: metrics.advanceWidth("150%")
    horizontalAlignment: Text.AlignRight
    text: root.text
    color: root.valueColor
    font.pixelSize: Theme.fontSize - 1
  }

  // ---- slider ----------------------------------------------------------------
  PopupSlider {
    id: slider
    anchors {
      left: root.captioned ? parent.left : icon.right
      leftMargin: root.captioned ? 0 : 6
      right: root.captioned ? parent.right : inlineValue.left
      rightMargin: root.captioned ? 0 : 8
      bottom: parent.bottom
    }
    height: Theme.rowHeight
    value: root.value
    dimmed: root.dimmed
    onMoved: value => root.moved(value)
  }
}
