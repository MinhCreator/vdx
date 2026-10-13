import QtQuick
import qs.components
import qs.config

PopupFrame {
  id: root

  readonly property bool listed: MihomoService.serviceOn && MihomoService.providers.length > 0

  signal closeRequested()

  function openServersFor(name) {
    MihomoService.provider = name;
    providers.expanded = false;
    servers.expanded = true;
  }

  // ---- header ----------------------------------------------------------------
  PopupHeader {
    width: parent.width
    glyph: Theme.iconMihomo
    title: "MIHOMO"
    subtitle: MihomoService.serviceOn ? "CONNECTED" : "DISCONNECTED"
    subtitleColor: MihomoService.serviceOn ? Theme.green : Theme.muted

    Row {
      anchors.verticalCenter: parent.verticalCenter
      spacing: 4

      PopupButton {
        glyph: Theme.iconPing
        glyphSize: Theme.headerButtonSize
        tint: Theme.foreground0
        frameless: true
        hoverBackground: false
        busy: MihomoService.pinging
        status: MihomoService.pingStatus
        disabled: !MihomoService.serviceOn
        onClicked: MihomoService.pingNodes()
      }

      PopupButton {
        glyph: Theme.iconRefresh
        glyphSize: Theme.headerButtonSize
        tint: Theme.foreground0
        frameless: true
        hoverBackground: false
        busy: MihomoService.updating
        status: MihomoService.updateStatus
        disabled: !MihomoService.serviceOn
        onClicked: MihomoService.runUpdate()
      }

      PopupButton {
        glyph: Theme.iconSettings
        glyphSize: Theme.headerButtonSize
        tint: Theme.foreground0
        frameless: true
        hoverBackground: false
        onClicked: {
          root.closeRequested();
          MihomoService.openMihomoConfig();
        }
      }
    }

    PopupSwitch {
      anchors.verticalCenter: parent.verticalCenter
      checked: MihomoService.serviceOn
      onToggled: MihomoService.toggleService()
    }
  }

  PopupSeparator { width: parent.width }

  // ---- current server --------------------------------------------------------
  Column {
    width: parent.width
    visible: MihomoService.current !== ""
    spacing: 1

    ThemeText {
      text: "CURRENT SERVER"
      color: Theme.dim
      font.pixelSize: Theme.fontSize - 2
      font.letterSpacing: 1
    }

    ThemeText {
      width: parent.width
      text: MihomoService.current
      elide: Text.ElideRight
    }
  }

  PopupSeparator {
    width: parent.width
    visible: MihomoService.current !== ""
  }

  // ---- info ------------------------------------------------------------------
  Row {
    id: info
    width: parent.width
    spacing: 16

    readonly property real columnWidth: (width - spacing) / 2

    PopupInfoList {
      width: info.columnWidth
      model: [
        { label: "PING",
          value: MihomoService.currentDelay > 0 ? MihomoService.currentDelay + " ms" : "—",
          color: Theme.pingColor(MihomoService.currentDelay) },
        { label: "RECEIVING",  value: Theme.humanRate(MihomoService.down) },
        { label: "DOWNLOADED", value: Theme.humanSize(MihomoService.downTotal) },
        { label: "MODE",       value: MihomoService.mode }
      ]
    }

    PopupInfoList {
      width: info.columnWidth
      model: [
        { label: "PROVIDER", value: MihomoService.currentProvider || "—",
          color: MihomoService.currentProvider ? Theme.foreground0 : Theme.muted },
        { label: "SENDING",  value: Theme.humanRate(MihomoService.up) },
        { label: "UPLOADED", value: Theme.humanSize(MihomoService.upTotal) },
        { label: "GROUP",    value: MihomoService.group }
      ]
    }
  }

  PopupSeparator { width: parent.width }

  // ---- providers / servers -------------------------------------------------
  ThemeText {
    visible: !root.listed
    text: MihomoService.serviceOn ? "NO PROVIDERS" : "MIHOMO IS OFF"
    color: Theme.muted
    font.letterSpacing: 1
  }

  Column {
    width: parent.width
    visible: root.listed
    spacing: 4

    PopupDropdown {
      id: providers
      width: parent.width
      title: "PROVIDERS"
      onExpandedChanged: if (expanded) servers.expanded = false

      Repeater {
        model: MihomoService.providers

        PopupDropdownItem {
          id: providerItem
          required property var modelData

          label: modelData.name
          active: modelData.name === MihomoService.provider
          onClicked: root.openServersFor(modelData.name)

          trailing: PopupButton {
            glyph: Theme.iconDots
            tint: Theme.foreground0
            frameless: true
            hoverBackground: false
            onClicked: {
              root.closeRequested();
              MihomoService.openProviderConfig(providerItem.modelData.name);
            }
          }
        }
      }
    }

    PopupDropdown {
      id: servers
      width: parent.width
      title: "SERVERS"
      disabled: MihomoService.nodes.length === 0
      onExpandedChanged: if (expanded) providers.expanded = false

      Repeater {
        model: MihomoService.nodes

        PopupDropdownItem {
          id: serverItem
          required property var modelData

          readonly property int delay: modelData.alive ? modelData.delay : 0

          label: modelData.name
          active: modelData.name === MihomoService.current
          onClicked: MihomoService.selectNode(modelData.name)

          trailing: ThemeText {
            text: serverItem.delay > 0 ? serverItem.delay + " ms" : "—"
            color: Theme.pingColor(serverItem.delay)
            font.pixelSize: Theme.fontSize - 1
          }
        }
      }
    }
  }

  PopupError { text: MihomoService.error }
}
