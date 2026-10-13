import QtQuick
import qs.components
import qs.config

Column {
  id: root

  spacing: 4

  PopupDropdown {
    id: dropdown
    width: parent.width
    title: "DNS PROVIDER: " + (WifiService.connected ? WifiService.dnsLabel : "—")
    disabled: !WifiService.connected
    busy: WifiService.dnsBusy
    status: WifiService.dnsStatus

    Repeater {
      model: WifiService.dnsProviders

      PopupDropdownItem {
        required property var modelData

        label: modelData.label
        active: WifiService.dnsLabel === modelData.label
        enabled: !WifiService.dnsBusy
        onClicked: {
          if (!active) WifiService.setDns(modelData.servers);
          dropdown.expanded = false;
        }
      }
    }
  }

  PopupError { text: WifiService.dnsError }
}
