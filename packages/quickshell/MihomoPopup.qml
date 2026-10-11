import QtQuick

// Framed content of the mihomo popup — one page, accordion sections.
//
// Layout, top to bottom:
//
//   header    🛡 MIHOMO / connected      [PING] [UPDATE] [gear] [switch]
//   ────────
//   current   CURRENT SERVER · name
//   ────────
//   info      PING      … · PROVIDER  …
//             RECEIVING … · SENDING   …
//             DOWNLOADED… · UPLOADED  …
//             MODE      … · GROUP     …
//   ────────
//   sections  ▶ PROVIDERS      N total
//             ▶ SERVERS        N total
//             ▶ ADD PROVIDER
//
// Header actions use the same glyph size as the Wi-Fi popup's ghost buttons
// so the two bars read at the same visual weight. Ping lives only in the info
// panel; server rows have no state dot.

Item {
  id: root

  readonly property var svc: MihomoService
  readonly property int labelIndent: 8
  readonly property int listHeight: Theme.rowHeight * Theme.visibleRows

  property bool providersOpen: false
  property bool serversOpen: false
  property bool addOpen: false

  QtObject {
    id: accordionGroup
    property var openSection: null
  }

  signal closeRequested()

  implicitWidth: Theme.popupWidth
  implicitHeight: frame.implicitHeight

  // ---- formatting helpers ------------------------------------------------
  function delayText(delay) {
    return delay > 0 ? delay + " ms" : "—";
  }

  function delayColor(delay) {
    if (delay <= 0) return Theme.red;
    if (delay < 150) return Theme.green;
    if (delay < 400) return Theme.yellow;
    return Theme.orange;
  }

  function delayLabel(node) {
    return delayText(node && node.alive ? node.delay : 0);
  }

  function delayTint(node) {
    return delayColor(node && node.alive ? node.delay : 0);
  }

  // ---- section helpers ---------------------------------------------------
  function cancelAddSection() {
    root.svc.closeAddForm();
    root.addOpen = false;
  }

  function openServersFor(name) {
    root.svc.provider = name;
    root.providersOpen = false;
    root.serversOpen = true;
    root.addOpen = false;
  }

  // Two-column info panel — the same data model shape as Wi-Fi uses.
  readonly property var infoLeft: [
    { label: "PING",       value: root.svc.currentDelay > 0
                                     ? Math.round(root.svc.currentDelay) + " ms" : "—",
      color: root.svc.currentDelay > 0
             ? root.delayColor(root.svc.currentDelay) : Theme.muted },
    { label: "RECEIVING",  value: Theme.humanRate(root.svc.down),      color: Theme.foreground0 },
    { label: "DOWNLOADED", value: Theme.humanSize(root.svc.downTotal), color: Theme.foreground0 },
    { label: "MODE",       value: root.svc.mode,                       color: Theme.foreground0 }
  ]

  readonly property var infoRight: [
    { label: "PROVIDER", value: root.svc.currentProvider !== ""
                                   ? root.svc.currentProvider : "—",
      color: root.svc.currentProvider !== "" ? Theme.foreground0 : Theme.muted },
    { label: "SENDING",  value: Theme.humanRate(root.svc.up),      color: Theme.foreground0 },
    { label: "UPLOADED", value: Theme.humanSize(root.svc.upTotal), color: Theme.foreground0 },
    { label: "GROUP",    value: root.svc.group,                    color: Theme.foreground0 }
  ]

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

      // ---- header --------------------------------------------------------
      Item {
        width: parent.width
        height: Math.max(headerIcon.implicitHeight, headerInfo.implicitHeight)

        Text {
          id: headerIcon
          anchors { left: parent.left; verticalCenter: parent.verticalCenter }
          text: Theme.iconMihomo
          color: root.svc.serviceOn ? Theme.green : Theme.muted
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontSize + 6
          font.weight: Theme.fontWeight
        }

        PopupSwitch {
          id: headerSwitch
          anchors { right: parent.right; verticalCenter: parent.verticalCenter }
          checked: root.svc.serviceOn
          onToggled: root.svc.toggleService()
        }

        // One action cluster: PING + UPDATE + gear. All three are glyph-only,
        // frameless, and use the same base glyph size as the Wi-Fi popup's
        // ghost buttons so both headers read at the same visual weight.
        Row {
          id: headerButtons
          anchors {
            right: headerSwitch.left; rightMargin: 8
            verticalCenter: parent.verticalCenter
          }
          spacing: 4

          PopupButton {
            glyph: Theme.iconPing
            glyphSize: Theme.fontSize
            tint: root.svc.serviceOn ? Theme.foreground0 : Theme.muted
            frameless: true
            busy: root.svc.pinging
            status: root.svc.pingStatus
            disabled: !root.svc.serviceOn || root.svc.pinging
            onClicked: root.svc.pingNodes()
          }

          PopupButton {
            glyph: Theme.iconRefresh
            glyphSize: Theme.fontSize
            tint: root.svc.serviceOn ? Theme.foreground0 : Theme.muted
            frameless: true
            busy: root.svc.updating
            status: root.svc.updateStatus
            disabled: !root.svc.serviceOn || root.svc.updating
            onClicked: root.svc.runUpdate()
          }

          PopupButton {
            glyph: Theme.iconSettings
            glyphSize: Theme.fontSize
            tint: Theme.foreground0
            frameless: true
            onClicked: {
              root.closeRequested();
              root.svc.openMihomoConfig();
            }
          }
        }

        Column {
          id: headerInfo
          anchors {
            left: headerIcon.right; leftMargin: 10
            right: headerButtons.left; rightMargin: 10
            verticalCenter: parent.verticalCenter
          }
          spacing: 2

          Text {
            width: parent.width
            text: "MIHOMO"
            color: root.svc.serviceOn ? Theme.foreground0 : Theme.muted
            elide: Text.ElideRight
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
          }

          Text {
            width: parent.width
            text: root.svc.serviceOn ? "connected" : "disconnected"
            color: root.svc.serviceOn ? Theme.green : Theme.muted
            elide: Text.ElideRight
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 3
            font.weight: Theme.fontWeight
          }
        }
      }

      PopupSeparator { width: parent.width }

      // ---- CURRENT SERVER (name only) ------------------------------------
      Item {
        width: parent.width
        visible: root.svc.current !== ""
        height: visible ? 36 : 0

        Rectangle {
          anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
          width: 2
          color: Theme.foreground0
        }

        Text {
          id: currentLabel
          anchors { left: parent.left; leftMargin: root.labelIndent; top: parent.top }
          text: "CURRENT SERVER"
          color: Theme.dim
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontSize - 3
          font.weight: Theme.fontWeight
          font.letterSpacing: 1
        }

        Text {
          id: currentNode
          anchors {
            left: parent.left; leftMargin: root.labelIndent
            right: parent.right; rightMargin: 8
            top: currentLabel.bottom; topMargin: 1
            bottom: parent.bottom
          }
          text: root.svc.current
          elide: Text.ElideRight
          color: Theme.foreground0
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontSize
          font.weight: Theme.fontWeight
        }
      }

      PopupSeparator {
        width: parent.width
        visible: root.svc.current !== ""
      }

      // ---- INFO PANEL ----------------------------------------------------
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
              model: root.infoLeft
              delegate: infoRow
            }
          }

          Column {
            width: (parent.width - parent.spacing) / 2
            spacing: 4

            Repeater {
              model: root.infoRight
              delegate: infoRow
            }
          }
        }
      }

      PopupSeparator { width: parent.width }

      // ---- PROVIDERS -----------------------------------------------------
      PopupAccordion {
        id: providersSection
        width: parent.width
        title: "PROVIDERS"
        badge: root.svc.providers.length + " total"
        expanded: root.providersOpen
        disabled: !root.svc.serviceOn
        group: accordionGroup
        onExpandedChanged: root.providersOpen = expanded

        Item {
          width: parent.width
          height: providerList.height > 0 ? providerList.height : 24

          ListView {
            id: providerList
            width: parent.width
            height: Math.min(root.svc.providers.length * Theme.rowHeight, root.listHeight)
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: root.svc.providers

            delegate: Rectangle {
              id: providerRow
              required property var modelData
              readonly property bool selected: modelData.name === root.svc.provider

              width: providerList.width
              height: Theme.rowHeight
              color: providerArea.containsMouse && !providerRow.selected ? Theme.background2 : "transparent"

              Rectangle {
                visible: providerRow.selected
                width: 2
                height: parent.height
                anchors.left: parent.left
                color: Theme.foreground0
              }

              Text {
                id: providerName
                anchors.left: parent.left
                anchors.leftMargin: root.labelIndent
                anchors.right: providerCount.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: providerRow.modelData.name
                elide: Text.ElideRight
                color: providerRow.selected ? Theme.foreground0 : Theme.dim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Theme.fontWeight
              }

              Text {
                id: providerCount
                anchors.right: providerDots.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 52
                text: providerRow.modelData.nodes + " srv"
                color: Theme.dim
                horizontalAlignment: Text.AlignRight
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 1
                font.weight: Theme.fontWeight
              }

              MouseArea {
                id: providerArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.openServersFor(providerRow.modelData.name)
              }

              Item {
                id: providerDots
                width: 20
                height: parent.height
                anchors.right: parent.right
                anchors.rightMargin: 2

                Text {
                  anchors.centerIn: parent
                  text: Theme.iconDots
                  color: dotsArea.containsMouse ? Theme.foreground0 : Theme.dim
                  font.family: Theme.fontFamily
                  font.pixelSize: Theme.fontSize
                  font.weight: Theme.fontWeight
                }

                MouseArea {
                  id: dotsArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    root.closeRequested();
                    root.svc.openProviderConfig(providerRow.modelData.name);
                  }
                }
              }
            }
          }

          Text {
            anchors.centerIn: parent
            visible: root.svc.providers.length === 0
            text: "No providers"
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
          }
        }
      }

      // ---- SERVERS -------------------------------------------------------
      PopupAccordion {
        id: serversSection
        width: parent.width
        title: "SERVERS"
        badge: root.svc.nodes.length + " total"
        expanded: root.serversOpen
        disabled: !root.svc.serviceOn || root.svc.provider === ""
        group: accordionGroup
        onExpandedChanged: root.serversOpen = expanded

        Item {
          width: parent.width
          height: serverList.height > 0 ? serverList.height : 24

          ListView {
            id: serverList
            width: parent.width
            height: Math.min(root.svc.nodes.length * Theme.rowHeight, root.listHeight)
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: root.svc.nodes

            delegate: Rectangle {
              id: nodeRow
              required property var modelData
              readonly property bool selected: modelData.name === root.svc.current

              width: serverList.width
              height: Theme.rowHeight
              color: nodeArea.containsMouse && !nodeRow.selected ? Theme.background2 : "transparent"

              Rectangle {
                visible: nodeRow.selected
                width: 2
                height: parent.height
                anchors.left: parent.left
                color: Theme.foreground0
              }

              Text {
                id: nodeName
                anchors.left: parent.left
                anchors.leftMargin: root.labelIndent
                anchors.right: nodeDelay.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: nodeRow.modelData.name
                elide: Text.ElideRight
                color: nodeRow.selected ? Theme.foreground0 : Theme.dim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Theme.fontWeight
              }

              Text {
                id: nodeDelay
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                width: 52
                text: root.delayLabel(nodeRow.modelData)
                color: root.delayTint(nodeRow.modelData)
                horizontalAlignment: Text.AlignRight
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 1
                font.weight: Theme.fontWeight
              }

              MouseArea {
                id: nodeArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.svc.selectNode(nodeRow.modelData.name)
              }
            }
          }

          Text {
            anchors.centerIn: parent
            visible: root.svc.nodes.length === 0
            text: "No servers"
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
          }
        }
      }
    }
  }

  // One labelled info row — dim uppercase label on the left, right-aligned
  // value on the right. Two Repeaters share this delegate.
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
}
