import QtQuick

// Framed content of the wifi popup — a squared frame (4px border, no radius,
// rofi-like), same grid as the mihomo popup. Layout, top to bottom:
//
//   header    wifi icon · name / device · [speedtest | QR] · switch
//   ────────
//   info      two columns: ping/receiving/downloaded/ip · loss/sending/uploaded/gateway
//   ────────
//   dns       DHCP / Cloudflare / Google / Custom pills, stretched full width
//   ────────
//   networks  KNOWN NETWORKS (saved, in range) + OTHER (visible only)
//
// Overlays (password / QR / speedtest / custom DNS) replace the body area
// beneath the header. Inside its own overlay each action button turns into a
// home glyph that closes that overlay; the slots never reflow.
//
// Every horizontal separator is a PopupSeparator — one component, one look,
// impossible to make two of them differ.

Item {
  id: root

  readonly property var svc: WifiService
  readonly property int labelIndent: 8
  readonly property int netsMaxHeight: Theme.rowHeight * Theme.visibleRows
  readonly property int netsMinHeight: 60
  // One space in JetBrainsMono at Theme.fontSize — the gap between a network
  // name and its lock glyph.
  readonly property int lockGap: 4

  signal closeRequested()

  implicitWidth: Theme.popupWidth
  implicitHeight: frame.implicitHeight

  function signalText(signal) {
    return signal > 0 ? signal + "%" : "—";
  }

  function signalColor(signal) {
    if (signal <= 0) return Theme.muted;
    if (signal >= 60) return Theme.green;
    if (signal >= 30) return Theme.yellow;
    return Theme.orange;
  }

  function pingColor() {
    if (!root.svc.connected || root.svc.pingMs <= 0) return Theme.muted;
    if (root.svc.pingMs < 60) return Theme.green;
    if (root.svc.pingMs < 150) return Theme.yellow;
    return Theme.orange;
  }

  function lossColor() {
    if (!root.svc.connected) return Theme.muted;
    if (root.svc.packetLoss <= 0) return Theme.green;
    if (root.svc.packetLoss <= 5) return Theme.yellow;
    return Theme.orange;
  }

  Rectangle {
    id: frame
    anchors.fill: parent
    color: Theme.background1
    border.width: Theme.popupFrameWidth
    border.color: Theme.frame
    implicitHeight: col.implicitHeight + 2 * (frame.border.width + Theme.popupPadding)

    Column {
      id: col
      anchors {
        top: parent.top
        left: parent.left
        right: parent.right
        margins: frame.border.width + Theme.popupPadding
      }
      spacing: Theme.popupPadding

      // ---- header ---------------------------------------------------------
      Item {
        width: parent.width
        height: Math.max(headerIcon.implicitHeight, headerInfo.implicitHeight)

        Text {
          id: headerIcon
          anchors { left: parent.left; verticalCenter: parent.verticalCenter }
          text: Theme.iconWifi
          color: root.svc.connected ? Theme.green : Theme.muted
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontSize + 6
          font.weight: Theme.fontWeight
        }

        PopupSwitch {
          id: headerSwitch
          anchors { right: parent.right; verticalCenter: parent.verticalCenter }
          checked: root.svc.radioOn
          onToggled: root.svc.toggleRadio()
        }

        Row {
          id: ghostButtons
          anchors {
            right: headerSwitch.left; rightMargin: 8
            verticalCenter: parent.verticalCenter
          }
          spacing: 4

          PopupButton {
            glyph: root.svc.view === "speedtest" ? Theme.iconHome : Theme.iconSpeedtest
            glyphSize: Theme.fontSize + 6
            tint: root.svc.connected || root.svc.view === "speedtest"
                  ? Theme.foreground0 : Theme.muted
            frameless: true
            disabled: !root.svc.connected && root.svc.view !== "speedtest"
            onClicked: {
              if (root.svc.view === "speedtest") root.svc.closeSpeedtest();
              else root.svc.openSpeedtest();
            }
          }

          PopupButton {
            glyph: root.svc.view === "qr" ? Theme.iconHome : Theme.iconQr
            glyphSize: Theme.fontSize + 6
            tint: root.svc.connected || root.svc.view === "qr"
                  ? Theme.foreground0 : Theme.muted
            frameless: true
            disabled: !root.svc.connected && root.svc.view !== "qr"
            onClicked: {
              if (root.svc.view === "qr") root.svc.closeQr();
              else root.svc.openQr();
            }
          }
        }

        Column {
          id: headerInfo
          anchors {
            left: headerIcon.right; leftMargin: 10
            right: ghostButtons.left; rightMargin: 10
            verticalCenter: parent.verticalCenter
          }
          spacing: 2

          Text {
            width: parent.width
            text: root.svc.connected ? root.svc.ssid : "Disconnected"
            color: root.svc.connected ? Theme.foreground0 : Theme.muted
            elide: Text.ElideRight
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
          }

          Text {
            width: parent.width
            text: root.svc.device !== "" ? root.svc.device
                : root.svc.connected ? "wifi" : "—"
            color: Theme.dim
            elide: Text.ElideRight
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 3
            font.weight: Theme.fontWeight
          }
        }
      }

      PopupSeparator { width: parent.width }

      // ---- body -----------------------------------------------------------
      Item {
        id: body
        width: parent.width
        implicitHeight: listView.visible ? listView.implicitHeight
                      : passwordView.visible ? passwordView.implicitHeight
                      : qrView.visible ? qrView.implicitHeight
                      : speedtestView.visible ? speedtestView.implicitHeight
                      : customDnsView.implicitHeight

        // ---- list -------------------------------------------------------
        Column {
          id: listView
          width: parent.width
          visible: root.svc.view === "list"
          spacing: Theme.popupPadding

          // ---- info panel: two labelled columns of small values --------
          Item {
            width: parent.width
            height: 84

            Row {
              anchors.fill: parent
              spacing: 16

              Column {
                width: (parent.width - parent.spacing) / 2
                spacing: 4

                Repeater {
                  model: [
                    { label: "PING",       value: root.svc.pingText(),        color: root.pingColor() },
                    { label: "RECEIVING",  value: Theme.humanRate(root.svc.down),      color: Theme.foreground0 },
                    { label: "DOWNLOADED", value: Theme.humanSize(root.svc.downTotal), color: Theme.foreground0 },
                    { label: "IP",         value: root.svc.ipAddress !== "" ? root.svc.ipAddress : "—", color: Theme.foreground0 }
                  ]
                  delegate: infoRow
                }
              }

              Column {
                width: (parent.width - parent.spacing) / 2
                spacing: 4

                Repeater {
                  model: [
                    { label: "LOSS",      value: root.svc.lossText(),             color: root.lossColor() },
                    { label: "SENDING",   value: Theme.humanRate(root.svc.up),    color: Theme.foreground0 },
                    { label: "UPLOADED",  value: Theme.humanSize(root.svc.upTotal), color: Theme.foreground0 },
                    { label: "GATEWAY",   value: root.svc.gateway !== "" ? root.svc.gateway : "—", color: Theme.foreground0 }
                  ]
                  delegate: infoRow
                }
              }
            }
          }

          PopupSeparator { width: parent.width }

          Column {
            width: parent.width
            spacing: 6

            Item {
              width: parent.width; height: 22
              Text {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text: "DNS PROVIDER"
                color: Theme.foreground0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Theme.fontWeight
                font.letterSpacing: 1
              }
            }

            Row {
              width: parent.width
              spacing: 4

              PopupButton {
                width: (parent.width - 3 * parent.spacing) / 4
                label: "DHCP"
                tint: Theme.foreground0
                active: root.svc.dnsMode === "dhcp"
                disabled: !root.svc.connected || root.svc.dnsBusy
                onClicked: root.svc.setDns("dhcp")
              }
              PopupButton {
                width: (parent.width - 3 * parent.spacing) / 4
                label: "CLOUDFLARE"
                tint: Theme.foreground0
                active: root.svc.dnsMode === "cloudflare"
                disabled: !root.svc.connected || root.svc.dnsBusy
                onClicked: root.svc.setDns("cloudflare")
              }
              PopupButton {
                width: (parent.width - 3 * parent.spacing) / 4
                label: "GOOGLE"
                tint: Theme.foreground0
                active: root.svc.dnsMode === "google"
                disabled: !root.svc.connected || root.svc.dnsBusy
                onClicked: root.svc.setDns("google")
              }
              PopupButton {
                width: (parent.width - 3 * parent.spacing) / 4
                label: "CUSTOM"
                tint: Theme.foreground0
                active: root.svc.dnsMode === "custom"
                busy: root.svc.dnsBusy && root.svc.view === "list"
                status: root.svc.view === "list" ? root.svc.dnsStatus : ""
                disabled: !root.svc.connected || root.svc.dnsBusy
                onClicked: root.svc.setDns("custom")
              }
            }
          }

          PopupSeparator { width: parent.width }

          // ---- networks: KNOWN + OTHER, double section ---------------
          Item {
            width: parent.width
            height: Math.max(root.netsMinHeight,
                             Math.min(netsContent.implicitHeight, root.netsMaxHeight))

            Flickable {
              anchors.fill: parent
              contentHeight: netsContent.implicitHeight
              clip: true
              boundsBehavior: Flickable.StopAtBounds

              Column {
                id: netsContent
                width: parent.width
                spacing: 0

                Item {
                  width: parent.width
                  height: root.svc.radioOn ? 22 : 0
                  visible: root.svc.radioOn
                  Text {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    text: "KNOWN NETWORKS"
                    color: Theme.foreground0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.weight: Theme.fontWeight
                    font.letterSpacing: 1
                  }
                }

                Item {
                  width: parent.width
                  height: (root.svc.radioOn && root.svc.knownNetworks.length === 0) ? 24 : 0
                  visible: root.svc.radioOn && root.svc.knownNetworks.length === 0
                  Text {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    text: "NO KNOWN NETWORKS FOUND"
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                    font.weight: Theme.fontWeight
                    font.letterSpacing: 1
                  }
                }

                Repeater {
                  model: root.svc.knownNetworks
                  delegate: netRowDelegate
                }

                // Breathing room between the KNOWN and OTHER sections.
                Item {
                  width: parent.width
                  height: root.svc.radioOn ? Theme.popupPadding : 0
                }

                Item {
                  width: parent.width
                  height: root.svc.radioOn ? 22 : 0
                  visible: root.svc.radioOn
                  Text {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    text: "OTHER"
                    color: Theme.foreground0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.weight: Theme.fontWeight
                    font.letterSpacing: 1
                  }
                }

                Item {
                  width: parent.width
                  height: (root.svc.radioOn && root.svc.otherNetworks.length === 0) ? 24 : 0
                  visible: root.svc.radioOn && root.svc.otherNetworks.length === 0
                  Text {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    text: "NO OTHER NETWORKS FOUND"
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                    font.weight: Theme.fontWeight
                    font.letterSpacing: 1
                  }
                }

                Repeater {
                  model: root.svc.otherNetworks
                  delegate: netRowDelegate
                }
              }
            }

            Text {
              anchors.centerIn: parent
              visible: !root.svc.radioOn
              text: "Wi-Fi is off"
              color: Theme.muted
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSize
              font.weight: Theme.fontWeight
            }
          }
        }

        // ---- password overlay -------------------------------------------
        Column {
          id: passwordView
          width: parent.width
          visible: root.svc.view === "password"
          spacing: Theme.popupPadding

          onVisibleChanged: if (visible) passwordInput.input.forceActiveFocus()

          Column {
            width: parent.width
            spacing: 1

            Text {
              text: "CONNECT TO"
              color: Theme.dim
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSize - 3
              font.weight: Theme.fontWeight
              font.letterSpacing: 1
            }

            Text {
              width: parent.width
              text: root.svc.target
              elide: Text.ElideRight
              color: Theme.foreground0
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSize
              font.weight: Theme.fontWeight
            }
          }

          PopupInput {
            id: passwordInput
            width: parent.width
            label: "PASSWORD"
            placeholder: "••••••••"
            text: root.svc.password
            onTextEdited: root.svc.password = text
            onAccepted: root.svc.submitPassword()
            Component.onCompleted: input.echoMode = TextInput.Password
          }

          Item {
            width: parent.width
            height: 20

            Row {
              anchors { right: parent.right; verticalCenter: parent.verticalCenter }
              spacing: 6

              PopupButton {
                label: "CANCEL"
                tint: Theme.foreground0
                onClicked: root.svc.closeView()
              }

              PopupButton {
                label: "CONNECT"
                tint: Theme.foreground0
                busy: root.svc.connectingSsid !== ""
                status: root.svc.connectStatus
                disabled: root.svc.connectingSsid !== "" || root.svc.password === ""
                onClicked: root.svc.submitPassword()
              }
            }
          }

          Text {
            width: parent.width
            visible: root.svc.connectStatus === "error" && root.svc.connectError !== ""
            text: root.svc.connectError
            color: Theme.red
            wrapMode: Text.WordWrap
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 2
            font.weight: Theme.fontWeight
          }

          Keys.onEscapePressed: root.svc.closeView()
        }

        // ---- QR overlay -------------------------------------------------
        // The code is the hero: centred on its own quiet zone, with the
        // credentials spelled out underneath for anyone typing them by hand.
        Column {
          id: qrView
          width: parent.width
          visible: root.svc.view === "qr"
          spacing: Theme.popupPadding

          Text {
            width: parent.width
            horizontalAlignment: Text.AlignLeft
            text: "SCAN TO JOIN"
            color: Theme.foreground0
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
            font.letterSpacing: 1
          }

          Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 200
            height: 200

            Image {
              anchors.fill: parent
              visible: root.svc.qrData !== ""
              source: root.svc.qrData !== ""
                    ? "data:image/png;base64," + root.svc.qrData
                    : ""
              smooth: false
              fillMode: Image.PreserveAspectFit
              sourceSize.width: 200
              sourceSize.height: 200
            }

            Text {
              anchors.centerIn: parent
              visible: root.svc.qrData === "" && !root.svc.qrBusy && root.svc.qrError !== ""
              text: root.svc.qrError
              color: Theme.red
              wrapMode: Text.WordWrap
              width: parent.width
              horizontalAlignment: Text.AlignHCenter
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSize - 2
              font.weight: Theme.fontWeight
            }

            PopupSpinner {
              anchors.centerIn: parent
              visible: root.svc.qrBusy
              tint: Theme.foreground0
            }
          }

          // A one-line caption for the code, then the credentials in the clear
          // for anyone typing them by hand.
          Text {
            width: parent.width
            visible: root.svc.qrData !== ""
            horizontalAlignment: Text.AlignHCenter
            text: "Scan with your camera to connect"
            color: Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
            font.weight: Theme.fontWeight
          }

          PopupSeparator {
            width: parent.width
            visible: root.svc.qrData !== ""
          }

          Column {
            width: parent.width
            spacing: 4
            visible: root.svc.qrData !== ""

            Repeater {
              model: [
                { label: "NETWORK",  value: root.svc.qrSsid !== "" ? root.svc.qrSsid : "—",
                  color: Theme.foreground0 },
                { label: "PASSWORD", value: root.svc.qrPassword !== "" ? root.svc.qrPassword : "—",
                  color: Theme.foreground0 }
              ]
              delegate: infoRow
            }
          }

          Item {
            width: parent.width
            height: 20
            visible: root.svc.qrData !== "" && root.svc.qrPassword !== ""

            PopupButton {
              anchors.right: parent.right
              label: "COPY PASSWORD"
              tint: Theme.foreground0
              status: root.svc.qrCopyStatus
              onClicked: root.svc.copyCredentials()
            }
          }

          Keys.onEscapePressed: root.svc.closeQr()
        }

        // ---- speedtest overlay ------------------------------------------
        Column {
          id: speedtestView
          width: parent.width
          visible: root.svc.view === "speedtest"
          spacing: Theme.popupPadding

          Text {
            width: parent.width
            horizontalAlignment: Text.AlignLeft
            text: "SPEED TEST"
            color: Theme.foreground0
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
            font.letterSpacing: 1
          }

          Row {
            width: parent.width
            spacing: 16

            Column {
              width: (parent.width - parent.spacing) / 2
              spacing: 4

              Text {
                text: "↓ DOWNLOAD"
                color: Theme.dim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 2
                font.weight: Theme.fontWeight
                font.letterSpacing: 1
              }
              Text {
                text: root.svc.speedDownText()
                color: Theme.foreground0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 3
                font.weight: Theme.fontWeight
              }
            }

            Column {
              width: (parent.width - parent.spacing) / 2
              spacing: 4

              Text {
                text: "↑ UPLOAD"
                color: Theme.dim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 2
                font.weight: Theme.fontWeight
                font.letterSpacing: 1
              }
              Text {
                text: root.svc.speedUpText()
                color: Theme.foreground0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 3
                font.weight: Theme.fontWeight
              }
            }
          }

          PopupSeparator { width: parent.width }

          Column {
            width: parent.width
            spacing: 3

            Item {
              width: parent.width; height: 18
              Text {
                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                text: "LATENCY"; color: Theme.dim
                font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize - 2
                font.weight: Theme.fontWeight; font.letterSpacing: 1
              }
              Text {
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                text: root.svc.speedPingText(); color: Theme.foreground0
                elide: Text.ElideRight; horizontalAlignment: Text.AlignRight
                font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize - 1
                font.weight: Theme.fontWeight
              }
            }

            Item {
              width: parent.width; height: 18
              Text {
                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                text: "JITTER"; color: Theme.dim
                font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize - 2
                font.weight: Theme.fontWeight; font.letterSpacing: 1
              }
              Text {
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                text: root.svc.speedJitterText(); color: Theme.foreground0
                elide: Text.ElideRight; horizontalAlignment: Text.AlignRight
                font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize - 1
                font.weight: Theme.fontWeight
              }
            }

            Item {
              width: parent.width; height: 18
              Text {
                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                text: "DURATION"; color: Theme.dim
                font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize - 2
                font.weight: Theme.fontWeight; font.letterSpacing: 1
              }
              Text {
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                text: root.svc.speedDurationText(); color: Theme.foreground0
                elide: Text.ElideRight; horizontalAlignment: Text.AlignRight
                font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize - 1
                font.weight: Theme.fontWeight
              }
            }

            Item {
              width: parent.width; height: 18
              Text {
                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                text: "SERVER"; color: Theme.dim
                font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize - 2
                font.weight: Theme.fontWeight; font.letterSpacing: 1
              }
              Text {
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                text: root.svc.speedtestServer !== "" ? root.svc.speedtestServer : "—"
                color: Theme.foreground0
                elide: Text.ElideRight; horizontalAlignment: Text.AlignRight
                font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize - 1
                font.weight: Theme.fontWeight
              }
            }

            Item {
              width: parent.width; height: 18
              Text {
                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                text: "PUBLIC IP"; color: Theme.dim
                font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize - 2
                font.weight: Theme.fontWeight; font.letterSpacing: 1
              }
              Text {
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                text: root.svc.speedtestIp !== "" ? root.svc.speedtestIp : "—"
                color: Theme.foreground0
                elide: Text.ElideRight; horizontalAlignment: Text.AlignRight
                font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize - 1
                font.weight: Theme.fontWeight
              }
            }
          }

          PopupSeparator { width: parent.width }

          Item {
            width: parent.width
            height: 20

            Text {
              anchors { left: parent.left; verticalCenter: parent.verticalCenter }
              text: "TESTING STATUS:"
              color: Theme.dim
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSize - 2
              font.weight: Theme.fontWeight
              font.letterSpacing: 1
            }

            PopupSpinner {
              anchors {
                right: statusText.left; rightMargin: 6
                verticalCenter: parent.verticalCenter
              }
              visible: root.svc.speedtestBusy
              tint: Theme.foreground0
            }

            Text {
              id: statusText
              anchors { right: parent.right; verticalCenter: parent.verticalCenter }
              text: root.svc.speedtestBusy ? "measuring…"
                  : root.svc.speedtestError !== "" ? root.svc.speedtestError
                  : (root.svc.speedtestDown > 0 || root.svc.speedtestUp > 0) ? "done"
                  : "—"
              color: root.svc.speedtestBusy ? Theme.dim
                   : root.svc.speedtestError !== "" ? Theme.red
                   : (root.svc.speedtestDown > 0 || root.svc.speedtestUp > 0) ? Theme.green
                   : Theme.muted
              elide: Text.ElideRight
              horizontalAlignment: Text.AlignRight
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSize - 1
              font.weight: Theme.fontWeight
            }
          }

          Keys.onEscapePressed: root.svc.closeSpeedtest()
        }

        // ---- custom DNS overlay -----------------------------------------
        Column {
          id: customDnsView
          width: parent.width
          visible: root.svc.view === "dns-custom"
          spacing: Theme.popupPadding

          onVisibleChanged: if (visible) dnsInput.input.forceActiveFocus()

          Item {
            width: parent.width; height: 22
            Text {
              anchors { left: parent.left; verticalCenter: parent.verticalCenter }
              text: "CUSTOM DNS"
              color: Theme.foreground0
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSize
              font.weight: Theme.fontWeight
              font.letterSpacing: 1
            }
          }

          PopupInput {
            id: dnsInput
            width: parent.width
            label: "SERVERS"
            placeholder: "1.1.1.1, 1.0.0.1"
            text: root.svc.dnsFormValue
            onTextEdited: root.svc.dnsFormValue = text
            onAccepted: root.svc.submitCustomDns()
          }

          Item {
            width: parent.width
            height: 20

            Row {
              anchors { right: parent.right; verticalCenter: parent.verticalCenter }
              spacing: 6

              PopupButton {
                label: "CANCEL"
                tint: Theme.foreground0
                onClicked: root.svc.closeView()
              }

              PopupButton {
                label: "APPLY"
                tint: Theme.foreground0
                busy: root.svc.dnsBusy
                status: root.svc.dnsStatus
                disabled: root.svc.dnsBusy || root.svc.dnsFormValue.trim() === ""
                onClicked: root.svc.submitCustomDns()
              }
            }
          }

          Text {
            width: parent.width
            visible: root.svc.dnsError !== ""
            text: root.svc.dnsError
            color: Theme.red
            wrapMode: Text.WordWrap
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 2
            font.weight: Theme.fontWeight
          }

          Keys.onEscapePressed: root.svc.closeView()
        }
      }
    }
  }

  // One labelled info row in the two-column info panel. Values live in the
  // model, so the row itself is a single piece of chrome.
  Component {
    id: infoRow
    Item {
      id: row
      required property var modelData

      width: parent.width
      height: 18

      Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: row.modelData.label
        color: Theme.dim
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize - 2
        font.weight: Theme.fontWeight
        font.letterSpacing: 1
      }

      Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: row.modelData.value
        color: row.modelData.color
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignRight
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize - 1
        font.weight: Theme.fontWeight
      }
    }
  }

  // One network row (KNOWN and OTHER share it — the only difference is which
  // model feeds the Repeater). Current network: accent bar left + full-bright
  // name; connecting: spinner instead of the name; locked: lock glyph.
  Component {
    id: netRowDelegate
    Rectangle {
      id: netRow
      required property var modelData

      readonly property bool isCurrent:
        root.svc.connected && modelData.ssid === root.svc.ssid
      readonly property bool connecting:
        root.svc.connectingSsid === modelData.ssid
      readonly property bool locked:
        modelData.secure && !netRow.connecting
      // Width the name may occupy before the trailing signal readout; when the
      // row is locked the lock glyph claims its slot first, so the name and the
      // lock always sit together (the name hugs its text, it does not stretch).
      readonly property real nameMaxWidth: Math.max(0,
        width - root.labelIndent - 8 - netSignal.width - 8
        - (netRow.locked ? (netLock.implicitWidth + root.lockGap) : 0))

      width: netsContent.width
      height: Theme.rowHeight
      color: netArea.containsMouse && !netRow.isCurrent ? Theme.background2 : "transparent"

      Rectangle {
        visible: netRow.isCurrent
        width: 2
        height: parent.height
        anchors.left: parent.left
        color: Theme.foreground0
      }

      Text {
        id: netSignal
        anchors { right: parent.right; rightMargin: root.labelIndent; verticalCenter: parent.verticalCenter }
        width: 40
        text: root.signalText(netRow.modelData.signal)
        color: root.signalColor(netRow.modelData.signal)
        horizontalAlignment: Text.AlignRight
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize - 1
        font.weight: Theme.fontWeight
      }

      Text {
        id: netName
        anchors {
          left: parent.left
          leftMargin: root.labelIndent
          verticalCenter: parent.verticalCenter
        }
        width: Math.min(implicitWidth, netRow.nameMaxWidth)
        text: netRow.modelData.ssid
        elide: Text.ElideRight
        color: netRow.isCurrent ? Theme.foreground0 : Theme.dim
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.weight: Theme.fontWeight
      }

      Text {
        id: netLock
        visible: netRow.locked
        width: visible ? implicitWidth : 0
        anchors {
          left: netName.right
          leftMargin: netRow.locked ? root.lockGap : 0
          verticalCenter: parent.verticalCenter
        }
        text: Theme.iconLock
        color: Theme.dim
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize - 1
        font.weight: Theme.fontWeight
      }

      PopupSpinner {
        anchors { left: parent.left; leftMargin: root.labelIndent; verticalCenter: parent.verticalCenter }
        visible: netRow.connecting
        tint: Theme.foreground0
      }

      MouseArea {
        id: netArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.svc.connectTo(netRow.modelData.ssid,
                                      netRow.modelData.secure,
                                      netRow.modelData.saved)
      }
    }
  }
}