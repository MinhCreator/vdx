import QtQuick
import qs.components
import qs.config

PopupFrame {
  id: root

  readonly property var items: NotificationsService.items
  readonly property int fresh: items.filter(n => NotificationsService.isFresh(n)).length

  function when(time) {
    const d = new Date(time);
    const today = d.toDateString() === new Date().toDateString();
    return Qt.formatDateTime(d, today ? "HH:mm" : "dd.MM HH:mm");
  }

  implicitWidth: Theme.popupWidth

  PopupHeader {
    width: parent.width
    glyph: Theme.iconBell
    title: "NOTIFICATIONS"
    subtitle: root.items.length === 0 ? "EMPTY"
      : root.fresh > 0 ? root.fresh + " NEW · " + root.items.length + " TOTAL"
      : root.items.length + " TOTAL"
    subtitleColor: root.fresh > 0 ? Theme.green : Theme.muted

    PopupButton {
      anchors.verticalCenter: parent.verticalCenter
      glyph: Theme.iconClearAll
      glyphSize: Theme.headerButtonSize
      tint: Theme.foreground0
      frameless: true
      hoverBackground: false
      disabled: root.items.length === 0
      onClicked: NotificationsService.clear()
    }
  }

  PopupSeparator { width: parent.width }

  ThemeText {
    visible: root.items.length === 0
    text: "NO NOTIFICATIONS"
    color: Theme.muted
    font.letterSpacing: 1
  }

  Flickable {
    id: list
    width: parent.width
    visible: root.items.length > 0
    height: Math.min(contentHeight, Theme.notificationsVisible * 58)
    contentHeight: rows.implicitHeight
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

          width: rows.width
          spacing: 2

          Item {
            width: parent.width
            height: app.implicitHeight

            Rectangle {
              id: dot
              visible: NotificationsService.isFresh(item.modelData)
              anchors.verticalCenter: parent.verticalCenter
              width: visible ? 6 : 0
              height: 6
              radius: 3
              color: Theme.red
            }

            ThemeText {
              id: app
              anchors { left: dot.right; leftMargin: dot.visible ? 6 : 0; right: time.left; rightMargin: 8 }
              text: (item.modelData.app || "—").toUpperCase()
              elide: Text.ElideRight
              color: Theme.dim
              font.pixelSize: Theme.fontSize - 2
              font.letterSpacing: 1
            }

            ThemeText {
              id: time
              anchors.right: parent.right
              text: root.when(item.modelData.time)
              color: Theme.dim
              font.pixelSize: Theme.fontSize - 2
            }
          }

          ThemeText {
            width: parent.width
            text: item.modelData.summary
            elide: Text.ElideRight
            color: item.modelData.urgency === "critical" ? Theme.red : Theme.foreground0
          }

          ThemeText {
            width: parent.width
            visible: item.modelData.body !== ""
            text: item.modelData.body
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
