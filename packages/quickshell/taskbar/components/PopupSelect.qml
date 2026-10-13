import QtQuick

// Dropdown that picks one value: "LABEL: <current>" header, one item per choice.
// Spins while `busyValue` (one of the choices) is being applied.
PopupDropdown {
  id: root

  property string label: ""
  property var model: []                // [{label, value}]
  property var current: null
  property var busyValue: null

  readonly property var selected: model.find(c => c.value === current) ?? null

  signal picked(var value)

  title: label + ": " + (selected?.label ?? "—")
  busy: model.some(c => c.value === busyValue)
  disabled: model.length === 0

  Repeater {
    model: root.model

    PopupDropdownItem {
      required property var modelData

      label: modelData.label
      active: modelData.value === root.current
      onClicked: {
        if (!active) root.picked(modelData.value);
        root.expanded = false;
      }
    }
  }
}
