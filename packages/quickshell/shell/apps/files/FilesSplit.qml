import QtQuick
import qs.config

// A strip between two panes or two columns: dragged sideways, it reports the
// pointer's x in `reference` (the owner sets the width or the edge from it,
// clamped); released, the owner keeps the value. Its line shows only while hovered or taken: the panes'
// own edges (a line, a gap, a column's separator) mark where it is.
Item {
  id: root

  property Item reference: parent
  property int stripWidth: Theme.gapWide

  signal dragged(real x)
  signal finished()

  width: stripWidth

  Rectangle {
    anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; bottom: parent.bottom; topMargin: Theme.gapLoose; bottomMargin: Theme.gapLoose }
    width: 2
    color: area.pressed || area.containsMouse ? Theme.foreground2 : Theme.clear
    Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.SplitHCursor
    onPositionChanged: mouse => {
      if (pressed) root.dragged(mapToItem(root.reference, mouse.x, 0).x);
    }
    onReleased: root.finished()
  }
}
