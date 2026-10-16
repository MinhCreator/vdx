import QtQuick
import qs.config

// A group of outlined buttons, one per choice; the one matching `current` is
// filled (a row of tabs, scale or orientation pickers). Model:
// [{label, value, icon?}]. `busyValue` spins that button while it applies;
// `stretch` makes the buttons share the full width.
Row {
  id: root

  property var model: []
  property var current: null
  property var busyValue: null
  property bool disabled: false
  property bool stretch: false

  signal picked(var value)

  spacing: Theme.gapSmall

  Repeater {
    model: root.model

    KitButton {
      required property var modelData

      width: root.stretch ? (root.width - root.spacing * (root.model.length - 1)) / root.model.length : implicitWidth
      icon: modelData.icon ?? ""
      text: modelData.label
      selected: modelData.value === root.current
      busy: root.busyValue !== null && modelData.value === root.busyValue
      disabled: root.disabled
      onClicked: if (!selected) root.picked(modelData.value)
    }
  }
}
