import QtQuick
import qs.config

// Stack of PopupInfoRows from a model of { label, value, color? }.
Column {
  id: root

  property var model: []

  spacing: 4

  Repeater {
    model: root.model

    PopupInfoRow {
      required property var modelData

      width: root.width
      label: modelData.label
      value: modelData.value
      valueColor: modelData.color ?? Theme.foreground0
    }
  }
}
