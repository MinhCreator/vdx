import QtQuick
import qs.config

// Row of equal-width buttons, one per choice; the one matching `current` is
// selected. `busyValue` shows a spinner on that button while it applies.
Row {
  id: root

  property var model: []                // [{label, value}]
  property var current: null
  property var busyValue: null
  property bool disabled: false

  signal picked(var value)

  spacing: 6

  Repeater {
    model: root.model

    PopupButton {
      required property var modelData

      width: (root.width - root.spacing * (root.model.length - 1)) / root.model.length
      label: modelData.label
      tint: Theme.foreground0
      active: modelData.value === root.current
      busy: modelData.value === root.busyValue
      disabled: root.disabled
      onClicked: if (!active) root.picked(modelData.value)
    }
  }
}
