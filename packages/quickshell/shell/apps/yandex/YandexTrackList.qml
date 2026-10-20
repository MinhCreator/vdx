import QtQuick
import qs.config

// The tracks as rows (YandexTrack), scrolling inside the height `room` it is
// given. `activated(track)` and `menu(track, index, anchor)` pass the rows'
// clicks on (anchor: the ⋮ button the menu opens at).
Flickable {
  id: root

  property var tracks: []
  property real room: 0

  signal activated(var track)
  signal menu(var track, int index, var anchor)

  width: parent ? parent.width : 0
  visible: tracks.length > 0
  height: Math.min(contentHeight, room)
  contentHeight: rows.implicitHeight
  interactive: contentHeight > height
  clip: true
  boundsBehavior: Flickable.StopAtBounds

  Column {
    id: rows
    width: parent.width
    spacing: Theme.gapHair

    Repeater {
      model: root.tracks

      YandexTrack {
        required property var modelData
        required property int index

        track: modelData
        index: index
        onActivated: root.activated(modelData)
        onMenuRequested: anchor => root.menu(modelData, index, anchor)
      }
    }
  }
}
