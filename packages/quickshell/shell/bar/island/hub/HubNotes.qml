import QtQuick
import qs.bar.island
import qs.config
import qs.kit
import qs.modules.notifications

// The notifications block: a head with "Clear all", the newest as a card, the
// rest of its app counted under it, two cards peeking out behind.
Column {
  id: root

  readonly property var items: NotificationsService.items
  readonly property var first: items[0] ?? null
  readonly property int more: first ? items.filter(n => n.app === first.app).length - 1 : 0

  spacing: 10

  function ago(ms) {
    const m = Math.max(0, Math.floor((Date.now() - ms) / 60000));
    return m < 1 ? "now" : m < 60 ? m + "m" : m < 1440 ? Math.floor(m / 60) + "h" : Math.floor(m / 1440) + "d";
  }

  Item {
    width: parent.width
    height: 22
    KitText { anchors.verticalCenter: parent.verticalCenter; text: "Notifications"; font.pixelSize: 15; font.weight: Font.Medium }
    KitText {
      anchors { right: parent.right; verticalCenter: parent.verticalCenter }
      visible: root.first !== null
      text: "Clear all"
      color: Theme.muted
      font.pixelSize: 12
      MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: NotificationsService.clear() }
    }
  }

  KitText {
    visible: root.first === null
    text: "Nothing new"
    color: Theme.dim
    font.pixelSize: 12
  }

  Item {
    width: parent.width
    height: root.first ? 92 : 0
    visible: root.first !== null

    Rectangle { x: 26; y: 10; width: parent.width - 52; height: 70; radius: 20; color: Theme.background0; opacity: 0.9; visible: root.items.length > 2 }
    Rectangle { x: 13; y: 5; width: parent.width - 26; height: 72; radius: 20; color: Theme.background1; opacity: 0.7; visible: root.items.length > 1 }

    Rectangle {
      width: parent.width
      height: 82
      radius: 20
      color: Theme.background2

      Rectangle {
        id: avatar
        anchors { left: parent.left; leftMargin: 12; top: parent.top; topMargin: 12 }
        width: 36; height: 36; radius: 11
        color: Theme.background3
        KitText { anchors.centerIn: parent; text: (root.first?.app ?? "").slice(0, 1).toUpperCase(); font.weight: Font.Medium }
      }
      Column {
        anchors { left: avatar.right; leftMargin: 12; right: time.left; rightMargin: 8; top: parent.top; topMargin: 12 }
        spacing: 1
        KitText { width: parent.width; text: root.first ? root.first.app + (root.first.summary ? " · " + root.first.summary : "") : ""; font.pixelSize: 13; font.weight: Font.Medium; elide: Text.ElideRight; textFormat: Text.PlainText }
        KitText { width: parent.width; text: root.first?.body ?? ""; color: Theme.foreground2; font.pixelSize: 12; elide: Text.ElideRight; textFormat: Text.PlainText }
        KitText { visible: root.more > 0; text: "+" + root.more + " more from " + (root.first?.app ?? ""); color: Theme.muted; font.pixelSize: 11 }
      }
      KitText {
        id: time
        anchors { right: parent.right; rightMargin: 14; top: parent.top; topMargin: 12 }
        text: root.first ? root.ago(root.first.time) : ""
        color: Theme.muted
        font.pixelSize: 11
      }
      MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: IslandService.activate(root.first) }
    }
  }
}
