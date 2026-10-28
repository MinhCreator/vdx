import QtQuick
import qs.config
import qs.kit
import "../../kit/markup.js" as Markup

// Notification history, newest first, a card each: the app's avatar in its colour
// rule, app and time, summary, body. Unread ones carry a red dot; critical
// summaries are red.
KitFrame {
  id: root

  readonly property var items: NotificationsService.items
  // a notification that comes in while it is open eases in
  property KitSeen seen: KitSeen {}
  readonly property int fresh: items.filter(n => NotificationsService.isFresh(n)).length

  signal closeRequested()

  function when(time) {
    const d = new Date(time);
    const today = d.toDateString() === new Date().toDateString();
    return Qt.formatDateTime(d, today ? "HH:mm" : "dd.MM HH:mm");
  }

  // ---- header ----
  KitHeader {
    icon: "bell"
    iconColor: root.items.length > 0 ? Theme.foreground0 : Theme.muted
    title: "Notifications"
    subtitle: root.items.length === 0 ? "ALL CAUGHT UP" : root.items.length + " IN HISTORY"

    KitBadge {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.fresh > 0
      text: root.fresh + " NEW"
      tint: Theme.red
    }

    KitButton {
      icon: "trash"
      text: "Clear"
      disabled: root.items.length === 0
      onClicked: {
        NotificationsService.clear();
        if (ModuleSettings.get("notifications", "closeOnClear", false)) root.closeRequested();
      }
    }
  }

  KitLine {}

  KitText {
    visible: root.items.length === 0
    text: "Nothing here yet."
    color: Theme.muted
    font.pixelSize: Theme.fontSize - 1
  }

  Flickable {
    width: parent.width
    visible: root.items.length > 0
    height: Math.min(contentHeight, ModuleSettings.get("notifications", "rows", 6) * 82)
    contentHeight: rows.implicitHeight
    interactive: contentHeight > height
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
      id: rows
      width: parent.width
      spacing: Theme.gapMedium

      Repeater {
        model: root.items

        // a card: the app's avatar in its colour rule (Notifications › App colours), a click
        // brings up the app's window, a hover lights it up
        Item {
          id: item

          required property var modelData
          required property int index

          readonly property bool fresh: NotificationsService.isFresh(modelData)
          readonly property bool critical: modelData.urgency === "critical"
          readonly property color tone: critical ? Theme.red : Theme.appColour(modelData.app)

          KitAppear { target: item; seen: root.seen; key: item.modelData.key }

          HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
          // none open: nothing
          TapHandler {
            onTapped: if (NotificationsService.focusApp(item.modelData)) root.closeRequested()
          }

          width: rows.width
          height: Math.max(badge.height, content.implicitHeight) + 2 * Theme.gapLoose

          Rectangle {
            anchors.fill: parent
            radius: Theme.radiusCard
            color: hover.hovered ? Theme.controlHover : Theme.controlFill
            border.width: Theme.frameWidth
            border.color: hover.hovered ? Theme.controlLineHover : Theme.controlLineRest
            Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }
          }

          Rectangle {
            id: badge
            anchors { left: parent.left; leftMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }
            width: 40
            height: 40
            radius: Theme.pill(height)
            color: Theme.mix(Theme.background0, item.tone, 0.18)
            border.width: Theme.hairline
            border.color: Theme.mix(Theme.background0, item.tone, 0.45)

            KitText {
              anchors.centerIn: parent
              text: (item.modelData.app || "?").slice(0, 1).toUpperCase()
              color: item.tone
              font.pixelSize: Theme.fontSize + 3
              font.weight: Font.Medium
            }
          }

          Column {
            id: content
            anchors {
              left: badge.right; leftMargin: Theme.gapWide
              right: parent.right; rightMargin: Theme.gapLoose
              verticalCenter: parent.verticalCenter
            }
            spacing: 2

            Item {
              width: parent.width
              height: app.implicitHeight

              Rectangle {
                id: dot
                visible: item.fresh
                anchors.verticalCenter: parent.verticalCenter
                width: visible ? 6 : 0
                height: 6
                color: Theme.red
                radius: Theme.pill(height)
              }

              KitText {
                id: app
                anchors { left: dot.right; leftMargin: dot.visible ? 8 : 0; right: time.left; rightMargin: Theme.gapMedium }
                text: (item.modelData.app || "—").toUpperCase()
                elide: Text.ElideRight
                color: Theme.muted
                font.pixelSize: Theme.fontSize - 2
                font.letterSpacing: 1
              }

              KitText {
                id: time
                anchors.right: parent.right
                text: root.when(item.modelData.time)
                color: Theme.muted
                font.pixelSize: Theme.fontSize - 2
              }
            }

            KitText {
              width: parent.width
              text: Markup.plain(item.modelData.summary)
              textFormat: Text.PlainText
              elide: Text.ElideRight
              color: item.critical ? Theme.red : Theme.foreground0
              font.weight: Font.Bold
            }

            KitText {
              width: parent.width
              visible: item.modelData.body !== ""
              text: Markup.plain(item.modelData.body)
              textFormat: Text.PlainText
              wrapMode: Text.Wrap
              maximumLineCount: 2
              elide: Text.ElideRight
              color: Theme.foreground2
              font.pixelSize: Theme.fontSize - 1
            }
          }
        }
      }
    }
  }
}
