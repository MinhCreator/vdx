import QtQuick
import Quickshell

// Framed content of the mihomo popup — a squared frame (4px border, no radius,
// rofi-like). Two tabs: "PROVIDERS" (proxy-providers) and "SERVERS" (the
// provider's countries). The servers tab only exists when there is at least one
// provider, and pins the current server on top. The gear in the header opens
// mihomo's config; the dots on a provider row open that provider's own file.
// Colors come from the kitty palette, the frame from the hyprland config
// (border_size / active_border).

Item {
  id: root

  readonly property var svc: MihomoService
  readonly property int listHeight: Theme.mihomoRowHeight * Theme.mihomoVisibleRows
  readonly property bool hasProviders: svc.providers.length > 0
  readonly property int footerValue: 82     // left edge shared by the footer values

  // pinned "current server" strip (servers tab only): a 36px row followed by a
  // 6px gap before the list. No separator line — the 2px accent bar already
  // marks the current server.
  readonly property bool showCurrent: tab === 1 && svc.current !== ""
  readonly property real pinnedHeight: showCurrent ? 42 : 0

  property int tab: 0          // 0 = providers, 1 = servers

  // the popup owns the window; ask it to close before we spawn an editor
  signal closeRequested()

  implicitWidth: Theme.popupWidth
  implicitHeight: frame.implicitHeight

  // never stay on the servers tab if its tab ceases to exist
  onHasProvidersChanged: if (!hasProviders) tab = 0

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
      spacing: 8

      // ---- header: title + connection status + config + on/off switch -----
      Item {
        width: parent.width
        height: 20

        Text {
          id: headerIcon
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: Theme.iconMihomo
          color: Theme.foreground0
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontSize
          font.weight: Theme.fontWeight
        }

        Text {
          id: headerTitle
          anchors.left: headerIcon.right
          anchors.leftMargin: 6
          anchors.verticalCenter: parent.verticalCenter
          text: "MIHOMO"
          color: Theme.foreground0
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontSize
          font.weight: Theme.fontWeight
          font.letterSpacing: 1
        }

        Text {
          anchors.left: headerTitle.right
          anchors.leftMargin: 8
          anchors.verticalCenter: parent.verticalCenter
          text: root.svc.serviceOn ? "connected" : "disconnected"
          color: root.svc.serviceOn ? Theme.green : Theme.muted
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontSize - 3
          font.weight: Theme.fontWeight
        }

        Row {
          anchors { right: parent.right; verticalCenter: parent.verticalCenter }
          height: parent.height
          spacing: 6

          PopupButton {
            glyph: Theme.iconSettings
            tint: Theme.dim
            onClicked: {
              root.closeRequested();
              root.svc.openMihomoConfig();
            }
          }

          PopupSwitch {
            checked: root.svc.serviceOn
            onToggled: root.svc.toggleService()
          }
        }
      }

      // ---- divider --------------------------------------------------------
      Rectangle {
        width: parent.width
        height: 2
        color: Theme.dim
      }

      // ---- tabs (left) + actions (right) ----------------------------------
      Item {
        width: parent.width
        height: 20

        Row {
          anchors { left: parent.left; top: parent.top }
          height: parent.height
          spacing: 6

          Rectangle {
            id: providersTab
            width: providersTabText.implicitWidth + 18
            height: parent.height
            color: root.tab === 0 ? Theme.background2 : "transparent"
            border.width: 1
            border.color: root.tab === 0 ? Theme.foreground0 : Theme.frame

            Text {
              id: providersTabText
              anchors.centerIn: parent
              text: "PROVIDERS"
              color: root.tab === 0 ? Theme.foreground0 : Theme.dim
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSize - 2
              font.weight: Theme.fontWeight
              font.letterSpacing: 1
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.tab = 0
            }
          }

          Rectangle {
            id: serversTab
            visible: root.hasProviders
            width: visible ? serversTabText.implicitWidth + 18 : 0
            height: parent.height
            color: root.tab === 1 ? Theme.background2 : "transparent"
            border.width: 1
            border.color: root.tab === 1 ? Theme.foreground0 : Theme.frame

            Text {
              id: serversTabText
              anchors.centerIn: parent
              text: "SERVERS"
              color: root.tab === 1 ? Theme.foreground0 : Theme.dim
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSize - 2
              font.weight: Theme.fontWeight
              font.letterSpacing: 1
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.tab = 1
            }
          }
        }

        // One action per tab, at the far right of the tab bar: ADD + UPDATE
        // belong to the providers list, PING to the servers list, so the row
        // stays clean. While the add form is open both are hidden (the form
        // carries its own SAVE/CANCEL).
        Row {
          anchors { right: parent.right; verticalCenter: parent.verticalCenter }
          spacing: 6

          PopupButton {
            visible: root.tab === 0 && !root.svc.adding
            label: "ADD"
            tint: Theme.foreground0
            onClicked: root.svc.beginAdd()
          }

          PopupButton {
            visible: root.tab === 0 && !root.svc.adding
            label: "UPDATE"
            tint: Theme.foreground0
            busy: root.svc.updating
            status: root.svc.updateStatus
            disabled: root.svc.updating
            onClicked: root.svc.runUpdate()
          }

          PopupButton {
            visible: root.tab === 1
            label: "PING"
            tint: root.svc.serviceOn ? Theme.foreground0 : Theme.muted
            busy: root.svc.pinging
            status: root.svc.pingStatus
            disabled: !root.svc.serviceOn || root.svc.pinging
            onClicked: root.svc.pingNodes()
          }
        }
      }

      // ---- content --------------------------------------------------------
      Item {
        width: parent.width
        height: root.listHeight + root.pinnedHeight

        // pinned current server (servers tab)
        Item {
          id: currentRow
          visible: root.showCurrent
          anchors { top: parent.top; left: parent.left; right: parent.right }
          height: 36

          Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: 2
            color: Theme.foreground0
          }

          Text {
            id: currentLabel
            anchors { left: parent.left; leftMargin: 8; top: parent.top }
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
              left: parent.left; leftMargin: 8
              right: currentDelay.left; rightMargin: 8
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

          // the active server's last measured ping — same look as the list rows
          Text {
            id: currentDelay
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: currentNode.verticalCenter
            width: 52
            text: root.delayText(root.svc.currentDelay)
            color: root.delayColor(root.svc.currentDelay)
            horizontalAlignment: Text.AlignRight
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
            font.weight: Theme.fontWeight
          }
        }

        // providers
        ListView {
          id: providerList
          anchors.fill: parent
          visible: root.tab === 0 && !root.svc.adding
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          model: root.svc.providers

          delegate: Rectangle {
            id: providerRow
            required property var modelData
            readonly property bool selected: modelData.name === root.svc.provider

            width: providerList.width
            height: Theme.mihomoRowHeight
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
              anchors.leftMargin: 8
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
              text: providerRow.modelData.nodes
              color: Theme.dim
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSize - 1
              font.weight: Theme.fontWeight
            }

            MouseArea {
              id: providerArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                root.svc.provider = providerRow.modelData.name;
                root.tab = 1;
              }
            }

            // dots — open this provider's config file (declared last, so it
            // sits above the row MouseArea and swallows its own clicks)
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

        // servers of the selected provider
        ListView {
          id: list
          visible: root.tab === 1
          anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            top: root.showCurrent ? currentRow.bottom : parent.top
            topMargin: root.showCurrent ? 6 : 0
          }
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          model: root.svc.nodes

          delegate: Rectangle {
            id: nodeRow
            required property var modelData
            readonly property bool selected: modelData.name === root.svc.current

            width: list.width
            height: Theme.mihomoRowHeight
            color: nodeArea.containsMouse && !nodeRow.selected ? Theme.background2 : "transparent"

            // accent marker on the active server (square, no radius)
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
              anchors.leftMargin: 8
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width - nodeDelay.width - 18
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

        // empty states
        Text {
          anchors.centerIn: parent
          visible: root.tab === 0 && !root.svc.adding && !root.svc.serviceOn
          text: "mihomo is off"
          color: Theme.muted
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontSize
          font.weight: Theme.fontWeight
        }

        Text {
          anchors.centerIn: parent
          visible: root.tab === 0 && !root.svc.adding && root.svc.serviceOn && !root.hasProviders
          text: "no providers"
          color: Theme.muted
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontSize
          font.weight: Theme.fontWeight
        }

        Text {
          anchors.centerIn: parent
          visible: root.tab === 1 && root.svc.nodes.length === 0
          text: "no servers"
          color: Theme.muted
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontSize
          font.weight: Theme.fontWeight
        }

        // ---- add-provider form (providers tab) ----------------------------
        // Declared last so it overlays the list. SAVE is disabled until both
        // fields are filled; the script's error text is shown beneath.
        Item {
          id: addForm
          z: 2
          anchors.fill: parent
          visible: root.tab === 0 && root.svc.adding

          // Put the caret in the name field as soon as the form appears; the
          // 80ms retry below covers the window activating a beat later.
          property bool pendingFocus: false
          onVisibleChanged: {
            if (visible) {
              nameInput.input.forceActiveFocus();
              pendingFocus = true;
            }
          }

          Column {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            spacing: 8

            PopupInput {
              id: nameInput
              width: parent.width
              label: "PROVIDER NAME"
              placeholder: "my-provider"
              text: root.svc.addName
              onTextEdited: root.svc.addName = text
              onAccepted: urlInput.input.forceActiveFocus()
            }

            PopupInput {
              id: urlInput
              width: parent.width
              label: "SUBSCRIPTION URL"
              placeholder: "https://…"
              text: root.svc.addUrl
              onTextEdited: root.svc.addUrl = text
              onAccepted: root.svc.addProvider()
            }

            Row {
              spacing: 6

              PopupButton {
                label: "CANCEL"
                onClicked: root.svc.closeAddForm()
              }

              PopupButton {
                label: "SAVE"
                tint: Theme.foreground0
                busy: root.svc.addBusy
                status: root.svc.addStatus
                disabled: root.svc.addBusy ||
                          root.svc.addName.trim() === "" ||
                          root.svc.addUrl.trim() === ""
                onClicked: root.svc.addProvider()
              }
            }

            Text {
              width: parent.width
              visible: root.svc.addStatus === "error" && root.svc.addError !== ""
              text: root.svc.addError
              color: Theme.red
              wrapMode: Text.WordWrap
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSize - 2
              font.weight: Theme.fontWeight
            }
          }

          // Escape anywhere in the form cancels (Keys bubble up from the field)
          Keys.onEscapePressed: root.svc.closeAddForm()

          // One retry in case the window only becomes active a beat after the
          // form appears (the first forceActiveFocus then has no effect).
          Timer {
            interval: 80
            running: addForm.pendingFocus
            onTriggered: {
              addForm.pendingFocus = false;
              if (addForm.visible && !nameInput.input.activeFocus &&
                  !urlInput.input.activeFocus) nameInput.input.forceActiveFocus();
            }
          }
        }
      }

      // ---- divider --------------------------------------------------------
      Rectangle {
        width: parent.width
        height: 2
        color: Theme.dim
      }

      // ---- footer: live speed (line 1) + session totals (line 2) ----------
      // Each line is labelled; the values share one left edge (footerValue).
      Column {
        width: parent.width
        spacing: 4

        Item {
          width: parent.width
          height: 18

          Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "SPEED:"
            color: Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
            font.letterSpacing: 1
          }

          Text {
            id: downText
            anchors.left: parent.left
            anchors.leftMargin: root.footerValue
            anchors.verticalCenter: parent.verticalCenter
            text: "↓ " + root.svc.humanRate(root.svc.down)
            color: Theme.foreground0
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
          }

          Text {
            anchors.left: downText.right
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: "↑ " + root.svc.humanRate(root.svc.up)
            color: Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
          }
        }

        Item {
          width: parent.width
          height: 18

          Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "TRAFFIC:"
            color: Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
            font.letterSpacing: 1
          }

          Text {
            id: totalDownText
            anchors.left: parent.left
            anchors.leftMargin: root.footerValue
            anchors.verticalCenter: parent.verticalCenter
            text: "↓ " + root.svc.humanSize(root.svc.downTotal)
            color: Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
          }

          Text {
            anchors.left: totalDownText.right
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: "↑ " + root.svc.humanSize(root.svc.upTotal)
            color: Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
          }
        }
      }
    }
  }
}
