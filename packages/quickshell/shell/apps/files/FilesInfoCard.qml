import QtQuick
import qs.config
import qs.kit

// The properties of a file or a device (Menu › Properties): the service's panel as label / value rows.
KitFrame {
  id: root

  KitHeader {
    icon: "info"
    title: FilesService.panel ? FilesService.panel.title : ""
    subtitle: FilesService.panel ? FilesService.panel.subtitle : ""
  }

  KitLine {}

  Repeater {
    model: FilesService.panel ? FilesService.panel.rows : []

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
