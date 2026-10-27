import QtQuick
import qs.config
import qs.kit
import "../../kit/markup.js" as Markup

// Notification history, newest first: app and time, summary, body. Unread
// ones carry a red square; critical summaries are red.
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
    height: Math.min(contentHeight, ModuleSettings.get("notifications", "rows", 6) * 66)
    contentHeight: rows.implicitHeight
    interactive: contentHeight > height
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
      id: rows
      width: parent.width
      spacing: Theme.gapLoose

      Repeater {
        model: root.items

        // a row: a click brings up the app's window, a hover lights it up
        Item {
          id: item

          required property var modelData
          required property int index

          readonly property bool fresh: NotificationsService.isFresh(modelData)

          KitAppear { target: item; seen: root.seen; key: item.modelData.key }

          HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
          // none open: nothing
          TapHandler {
            onTapped: if (NotificationsService.focusApp(item.modelData)) root.closeRequested()
          }

          width: rows.width
          height: content.height + 2 * Theme.gapTight

          Rectangle {
            anchors.fill: parent
            radius: Theme.radiusControl
            color: hover.hovered ? Theme.controlHover : Theme.clear
            Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }
          }

          // the row's content: a column, the gaps inside the lit box
          Column {
            id: content
            anchors {
              left: parent.left; right: parent.right; top: parent.top
              leftMargin: Theme.gapMedium; rightMargin: Theme.gapMedium; topMargin: Theme.gapTight
            }
            spacing: Theme.sectionGap

            KitLine { visible: item.index > 0 }

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
              color: item.modelData.urgency === "critical" ? Theme.red : Theme.foreground0
              font.weight: Font.ExtraBold
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
