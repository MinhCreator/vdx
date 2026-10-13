import QtQuick
import qs.components

// Dropdown of Pipewire devices with the current default marked.
PopupDropdown {
  id: root

  property string kind: ""
  property var nodes: []
  property var current: null

  signal selected(var node)

  title: kind + ": " + (current ? AudioService.deviceName(current, nodes) : "—")
  disabled: nodes.length === 0

  Repeater {
    model: root.nodes

    PopupDropdownItem {
      required property var modelData

      label: AudioService.deviceName(modelData, root.nodes)
      active: modelData === root.current
      onClicked: {
        if (!active) root.selected(modelData);
        root.expanded = false;
      }
    }
  }
}
