import QtQuick
import qs.config
import qs.kit

// Notification history, newest first: app and time, summary, body. Unread
// ones carry a red square; critical summaries are red.
KitFrame {
  id: root

  readonly property var items: NotificationsService.items
  readonly property int fresh: items.filter(n => NotificationsService.isFresh(n)).length

  function when(time) {
    const d = new Date(time);
    const today = d.toDateString() === new Date().toDateString();
    return Qt.formatDateTime(d, today ? "HH:mm" : "dd.MM HH:mm");
  }

  // ---- header ----------------------------------------------------------------
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
      onClicked: NotificationsService.clear()
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
    height: Math.min(contentHeight, PluginSettings.get("notifications", "rows", 6) * 66)
    contentHeight: rows.implicitHeight
    interactive: contentHeight > height
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
      id: rows
      width: parent.width
      spacing: 10

      Repeater {
        model: root.items

        Column {
          id: item

          required property var modelData
          required property int index

          readonly property bool fresh: NotificationsService.isFresh(modelData)

          width: rows.width
          spacing: 3

          KitLine { visible: item.index > 0 }

          Item { width: 1; height: item.index > 0 ? 6 : 0 }

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
            }

            KitText {
              id: app
              anchors { left: dot.right; leftMargin: dot.visible ? 8 : 0; right: time.left; rightMargin: 8 }
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
            text: item.modelData.summary
            elide: Text.ElideRight
            color: item.modelData.urgency === "critical" ? Theme.red : Theme.foreground0
            font.weight: Font.ExtraBold
          }

          KitText {
            width: parent.width
            visible: item.modelData.body !== ""
            // bodies may carry markup (<b>…</b> from Telegram); show the text only
            text: item.modelData.body.replace(/<[^>]*>/g, "")
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
