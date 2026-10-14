import QtQuick
import qs.config
import qs.kit

// Speed test result: download / upload in large type, the details under them.
Column {
  id: root

  readonly property var result: WifiService.speedtest

  function format(value, unit, digits) {
    return root.result ? value.toFixed(digits) + " " + unit : "—";
  }

  spacing: 14

  KitLine {}

  Row {
    width: parent.width

    Repeater {
      model: [
        { label: "DOWNLOAD", value: root.result?.down },
        { label: "UPLOAD",   value: root.result?.up }
      ]

      Column {
        required property var modelData

        width: root.width / 2
        spacing: 4

        KitLabel { text: modelData.label }

        Row {
          spacing: 6

          KitText {
            text: root.result ? modelData.value.toFixed(1) : "—"
            color: root.result ? Theme.foreground0 : Theme.gray
            font.pixelSize: Theme.fontSize + 9
            font.weight: Font.Bold
          }

          KitText {
            anchors.baseline: parent.children[0].baseline
            text: "Mbps"
            color: Theme.muted
            font.pixelSize: Theme.fontSize - 1
          }
        }
      }
    }
  }

  KitLine {}

  Column {
    width: parent.width
    spacing: 6

    KitInfo { label: "Latency";   value: root.format(root.result?.ping, "ms", 0) }
    KitInfo { label: "Jitter";    value: root.format(root.result?.jitter, "ms", 1) }
    KitInfo { label: "Duration";  value: root.format(root.result?.duration, "s", 1) }
    KitInfo { label: "Server";    value: root.result?.server || "—" }
    KitInfo { label: "Public IP"; value: root.result?.ip || "—" }

    KitText {
      width: parent.width
      visible: WifiService.speedtestError !== "" && !WifiService.speedtestBusy
      text: WifiService.speedtestError
      color: Theme.red
      wrapMode: Text.WordWrap
      font.pixelSize: Theme.fontSize - 1
    }
  }

  KitLine {}

  KitButton {
    icon: "refresh"
    text: "Run again"
    busy: WifiService.speedtestBusy
    onClicked: WifiService.showSpeedtest()
  }
}
