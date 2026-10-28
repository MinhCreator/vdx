import QtQuick
import qs.bar.island
import qs.config
import qs.kit
import qs.modules.notifications

// The notifications block of the hub: a head with "Clear all", the newest as a
// card with the rest of its app counted under it, two cards peeking out behind.
// A click on the card focuses its app, else opens the centre; on the count, the centre.
Column {
  id: root

  readonly property var items: NotificationsService.items
  readonly property var first: items[0] ?? null
  readonly property int more: first ? items.filter(n => n.app === first.app).length - 1 : 0

  // an opaque plate (Strict has no fill at rest, and the cards overlap)
  readonly property color plate: Theme.material ? Theme.controlFill : Theme.background0

  spacing: Theme.gapLoose

  function ago(ms) {
    const m = Math.max(0, Math.floor((Date.now() - ms) / 60000));
    return m < 1 ? "now" : m < 60 ? m + "m" : m < 1440 ? Math.floor(m / 60) + "h" : Math.floor(m / 1440) + "d";
  }

  Item {
    width: parent.width
    height: 22

    KitText { anchors { left: parent.left; verticalCenter: parent.verticalCenter } text: "Notifications"; font.weight: Font.Bold }
    KitText {
      anchors { right: parent.right; verticalCenter: parent.verticalCenter }
      visible: root.first !== null
      text: "Clear all"
      color: Theme.muted
      font.pixelSize: Theme.fontSize - 1
      MouseArea { anchors { fill: parent; margins: -4 } cursorShape: Qt.PointingHandCursor; onClicked: NotificationsService.clear() }
    }
  }

  KitText {
    visible: root.first === null
    text: "Nothing new"
    color: Theme.dim
    font.pixelSize: Theme.fontSize - 1
  }

  // the stack: the newest on top, the ones behind a step narrower and lower
  Item {
    width: parent.width
    height: root.first ? card.height + (root.items.length > 2 ? 12 : root.items.length > 1 ? 7 : 0) : 0
    visible: root.first !== null

    Rectangle {
      visible: root.items.length > 2
      x: 24; y: 10
      width: parent.width - 48; height: card.height
      radius: Theme.radiusCard
      color: root.plate
      border.width: Theme.frameWidth
      border.color: Theme.controlLine
    }
    Rectangle {
      visible: root.items.length > 1
      x: 12; y: 5
      width: parent.width - 24; height: card.height
      radius: Theme.radiusCard
      color: root.plate
      border.width: Theme.frameWidth
      border.color: Theme.controlLine
    }

    Rectangle {
      id: card
      width: parent.width
      height: body.implicitHeight + 2 * Theme.gapLoose
      radius: Theme.radiusCard
      color: root.plate
      border.width: Theme.frameWidth
      border.color: Theme.controlLine

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: IslandService.activate(root.first)
      }

      Rectangle {
        id: avatar
        anchors { left: parent.left; leftMargin: Theme.gapLoose; top: parent.top; topMargin: Theme.gapLoose }
        width: 36
        height: 36
        radius: Theme.radiusFor(height)
        color: Theme.pickFill
        KitText { anchors.centerIn: parent; text: (root.first?.app ?? "").slice(0, 1).toUpperCase(); font.weight: Font.Medium }
      }

      Column {
        id: body
        anchors { left: avatar.right; leftMargin: Theme.gapWide; right: time.left; rightMargin: Theme.gapMedium; top: parent.top; topMargin: Theme.gapLoose }
        spacing: Theme.gapTight

        KitText {
          width: parent.width
          text: root.first ? root.first.app + (root.first.summary ? " · " + root.first.summary : "") : ""
          font.weight: Font.Bold
          elide: Text.ElideRight
          textFormat: Text.PlainText
        }
        KitText {
          width: parent.width
          visible: text !== ""
          text: root.first?.body ?? ""
          color: Theme.foreground2
          elide: Text.ElideRight
          textFormat: Text.PlainText
        }
        KitText {
          visible: root.more > 0
          text: "+" + root.more + " more from " + (root.first?.app ?? "")
          color: Theme.muted
          font.pixelSize: Theme.fontSize - 2
          MouseArea { anchors { fill: parent; margins: -3 } cursorShape: Qt.PointingHandCursor; onClicked: IslandService.openNotifications() }
        }
      }

      KitText {
        id: time
        anchors { right: parent.right; rightMargin: Theme.gapLoose; top: parent.top; topMargin: Theme.gapLoose }
        text: root.first ? root.ago(root.first.time) : ""
        color: Theme.muted
        font.pixelSize: Theme.fontSize - 2
      }
    }
  }
}
