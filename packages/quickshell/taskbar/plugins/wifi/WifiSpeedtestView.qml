import QtQuick
import qs.components
import qs.config

Column {
  id: root

  readonly property var result: WifiService.speedtest

  function format(value, unit, digits) {
    return root.result ? value.toFixed(digits) + " " + unit : "—";
  }

  spacing: Theme.popupPadding

  Row {
    width: parent.width
    spacing: 16

    Repeater {
      model: [
        { label: Theme.iconArrowDown + " DOWNLOAD", value: root.format(root.result?.down, "Mbps", 2) },
        { label: Theme.iconArrowUp + " UPLOAD",   value: root.format(root.result?.up, "Mbps", 2) }
      ]

      Column {
        required property var modelData

        width: (root.width - 16) / 2
        spacing: 4

        ThemeText {
          text: modelData.label
          color: Theme.dim
          font.pixelSize: Theme.fontSize - 2
          font.letterSpacing: 1
        }

        ThemeText {
          text: modelData.value
          font.pixelSize: Theme.fontSize + 3
        }
      }
    }
  }

  PopupSeparator { width: parent.width }

  PopupInfoList {
    width: parent.width
    model: [
      { label: "LATENCY",   value: root.format(root.result?.ping, "ms", 0) },
      { label: "JITTER",    value: root.format(root.result?.jitter, "ms", 1) },
      { label: "DURATION",  value: root.format(root.result?.duration, "s", 1) },
      { label: "SERVER",    value: root.result?.server || "—" },
      { label: "PUBLIC IP", value: root.result?.ip || "—" }
    ]
  }

  PopupSeparator { width: parent.width }

  Item {
    width: parent.width
    height: 20

    ThemeText {
      anchors { left: parent.left; verticalCenter: parent.verticalCenter }
      text: "STATUS"
      color: Theme.dim
      font.pixelSize: Theme.fontSize - 2
      font.letterSpacing: 1
    }

    PopupSpinner {
      anchors { right: statusText.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
      visible: WifiService.speedtestBusy
      tint: Theme.foreground0
    }

    ThemeText {
      id: statusText
      anchors { right: parent.right; verticalCenter: parent.verticalCenter }
      text: WifiService.speedtestBusy ? "measuring…" : WifiService.speedtestError || (root.result ? "done" : "—")
      color: WifiService.speedtestBusy ? Theme.dim
           : WifiService.speedtestError ? Theme.red
           : root.result ? Theme.green : Theme.muted
      font.pixelSize: Theme.fontSize - 1
    }
  }
}
