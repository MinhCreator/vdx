import QtQuick
import qs.config

// A button: an optional icon and a label; an icon alone is a square (a circle when round).
// The kind (`variant`): "filled" (the primary action: the primary colour, its text on it),
// "tonal", "outlined", "text"; empty follows Appearance › Controls (Filled: tonal,
// Outlined: outlined). `primary` is "filled", `danger` the error container.
// `selected` (one of a group of choices) takes the language's picked fill.
// Material: 40 px, labelLarge, the M3 state layers. Strict: 36 px, 13 px, quiet fills.
// `busy` swaps the icon for a spinner.
Rectangle {
  id: root

  property string icon: ""               // kit/icons name
  property string text: ""
  property string variant: ""
  property bool primary: false
  property bool danger: false
  property bool selected: false
  property bool busy: false
  property bool disabled: false

  readonly property bool hovered: area.containsMouse && !disabled
  readonly property string kind: primary ? "filled" : danger ? "danger" : variant !== "" ? variant
                                : Theme.filled ? "tonal" : "outlined"
  readonly property color base: selected ? Theme.selectedFill
    : kind === "filled" ? Theme.primary
    : kind === "danger" ? Theme.errorContainer
    : kind === "tonal" ? (Theme.m3 ? Theme.secondaryContainer : Theme.surfaceHigh)
    : Theme.clear
  readonly property color content: selected ? Theme.selectedText
    : kind === "filled" ? Theme.primaryText
    : kind === "danger" ? Theme.errorContainerText
    : kind === "tonal" ? (Theme.m3 ? Theme.secondaryContainerText : Theme.surfaceText)
    : Theme.m3 ? Theme.primary : Theme.surfaceText
  property color iconTint: content

  signal clicked()

  implicitWidth: text !== "" ? content_.implicitWidth + 2 * Theme.buttonPad - (icon !== "" ? 8 : 0) : Theme.controlHeight
  implicitHeight: Theme.controlHeight
  radius: Theme.radiusControl
  // set once: whether it sits in a Settings box (a walk up, not a binding)
  property bool boxed: false
  Component.onCompleted: boxed = Theme.boxed(parent)
  color: area.pressed && hovered ? Theme.layer(base, content, Theme.statePressed)
       : hovered ? Theme.layer(base, content, Theme.stateHover) : base
  border.width: kind === "outlined" && !selected ? 1 : 0
  border.color: hovered && Theme.strict ? Theme.outlineActive : Theme.outline
  opacity: disabled ? Theme.disabledOpacity : 1

  Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }
  Behavior on border.color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }

  Row {
    id: content_
    anchors.centerIn: parent
    spacing: Theme.gapMedium

    KitIcon {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.icon !== "" && !root.busy
      name: root.icon
      tint: root.iconTint
      size: Theme.iconControl
    }

    KitSpinner {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.busy
    }

    KitText {
      visible: root.text !== ""
      text: root.text
      color: root.content
      font.pixelSize: Theme.textControl
      font.weight: Theme.controlWeight
    }
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: root.disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
    onClicked: if (!root.disabled && !root.busy) root.clicked()
  }
}
