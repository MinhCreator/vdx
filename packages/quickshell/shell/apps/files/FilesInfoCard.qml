import QtQuick
import qs.config
import qs.kit

// The properties of a file or a device (Menu › Properties): the service's panel as label / value rows.
KitFrame {
  id: root

  required property var svc

  KitHeader {
    icon: "info"
    title: root.svc.panel ? root.svc.panel.title : ""
    subtitle: root.svc.panel ? root.svc.panel.subtitle : ""
  }

  KitLine {}

  Repeater {
    model: root.svc.panel ? root.svc.panel.rows : []

    Row {
      required property var modelData
      width: root.width - 2 * root.padding
      spacing: Theme.gapMedium

      KitText {
        width: 96
        text: modelData.label
        color: Theme.muted
        font.pixelSize: Theme.fontSize - 1
      }

      KitText {
        width: parent.width - 96 - parent.spacing
        text: modelData.value
        wrapMode: Text.WrapAnywhere
        font.pixelSize: Theme.fontSize - 1
      }
    }
  }
}
