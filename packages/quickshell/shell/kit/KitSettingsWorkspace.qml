import QtQuick
import QtQuick.Controls as Controls
import qs.config

// A full-width settings viewport. Section buttons live in the window header.
Item {
  id: root
  readonly property alias viewport: controls
  property bool showScrollBar: true
  property var sections: []
  property string current: ""
  property Component settings
  signal picked(string value)
  onCurrentChanged: controls.contentY = 0

  Flickable {
    id: controls
    anchors.fill: parent
    contentHeight: Math.max(height, settingsLoader.height)
    flickableDirection: Flickable.VerticalFlick
    interactive: contentHeight > height + 1
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    Controls.ScrollBar.vertical: KitScrollBar { visible: root.showScrollBar }
    Loader {
      id: settingsLoader
      width: controls.width - Theme.gapMedium
      sourceComponent: root.settings
      height: item ? item.implicitHeight : 0
    }
  }
}
