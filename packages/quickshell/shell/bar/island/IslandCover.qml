import QtQuick
import Quickshell.Widgets
import qs.config
import qs.kit

// The track's cover, rounded; a note on a dim square while there is none.
ClippingRectangle {
  id: root

  property int size: 20

  implicitWidth: size
  implicitHeight: size
  radius: Theme.coverRadius(size)
  color: Theme.background2

  KitIcon {
    anchors.centerIn: parent
    visible: art.status !== Image.Ready
    name: "music"
    size: Math.round(root.size * 0.55)
    tint: Theme.gray
  }

  Image {
    id: art
    anchors.fill: parent
    source: IslandService.cover
    sourceSize { width: root.size * 2; height: root.size * 2 }
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    smooth: true
  }
}
