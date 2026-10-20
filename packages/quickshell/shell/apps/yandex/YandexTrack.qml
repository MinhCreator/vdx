import QtQuick
import qs.config
import qs.kit
import qs.modules.yandex

// One track: title, then artist · album; its length and a ⋮ button on the right.
// The track playing now is lit. A click plays a downloaded track (the rest say
// they are not downloaded yet); ⋮ opens its menu (`menuRequested`, with the
// button as the anchor).
Item {
  id: root

  required property var track
  property int index: 0

  readonly property bool playable: YandexLibrary.playable(track.id)
  readonly property bool playing: YandexService.trackId === track.id

  signal activated()
  signal menuRequested(var anchor)

  function clock(seconds) {
    const s = Math.max(0, Math.floor(seconds));
    return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
  }

  width: parent ? parent.width : 0
  implicitHeight: Math.max(caption.implicitHeight, more.height) + 2 * Theme.gapTight

  // hover lights a row; the playing one stays lit
  Rectangle {
    anchors.fill: parent
    radius: Theme.radiusControl
    color: root.playing ? Theme.background3 : area.containsMouse ? Theme.background1 : Theme.clear
    Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: root.playable ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: if (root.playable) root.activated()
  }

  Column {
    id: caption
    anchors {
      left: parent.left; leftMargin: Theme.gapMedium
      right: length.left; rightMargin: Theme.gapMedium
      verticalCenter: parent.verticalCenter
    }
    spacing: Theme.gapHair

    KitText {
      width: parent.width
      text: root.track.title
      elide: Text.ElideRight
      font.weight: root.playing ? Font.ExtraBold : Font.DemiBold
    }

    KitText {
      width: parent.width
      text: [root.track.artist, root.track.album, root.playable ? "" : "not downloaded yet"].filter(s => s).join(" · ")
      elide: Text.ElideRight
      color: Theme.muted
      font.pixelSize: Theme.fontSize - 2
    }
  }

  KitText {
    id: length
    anchors { right: more.left; rightMargin: Theme.gapSmall; verticalCenter: parent.verticalCenter }
    text: root.clock(root.track.duration)
    color: Theme.muted
    font.pixelSize: Theme.fontSize - 2
  }

  KitButton {
    id: more
    anchors { right: parent.right; rightMargin: Theme.gapSmall; verticalCenter: parent.verticalCenter }
    icon: "more"
    onClicked: root.menuRequested(more)
  }
}
