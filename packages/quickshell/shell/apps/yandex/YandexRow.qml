import QtQuick
import qs.config
import qs.kit

// A full-width row of a list or an action pane: the label on the left, a muted
// note on the right, a hover fill. `danger` reds the label (a removal),
// `disabled` greys it and ignores the click.
Item {
  id: root

  property string label: ""
  property string note: ""
  property bool danger: false
  property bool disabled: false

  signal activated()

  width: parent ? parent.width : 0
  implicitHeight: labelText.implicitHeight + 2 * Theme.gapTight

  Rectangle {
    anchors.fill: parent
    radius: Theme.radiusControl
    color: !root.disabled && area.containsMouse ? Theme.background1 : Theme.clear
    Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    enabled: !root.disabled
    cursorShape: root.disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
    onClicked: root.activated()
  }

  KitText {
    id: labelText
    anchors {
      left: parent.left; leftMargin: Theme.gapMedium
      right: noteText.left; rightMargin: Theme.gapMedium
      verticalCenter: parent.verticalCenter
    }
    text: root.label
    elide: Text.ElideRight
    color: root.disabled ? Theme.muted : root.danger ? Theme.red : Theme.foreground0
    font.weight: Font.DemiBold
  }

  KitText {
    id: noteText
    anchors { right: parent.right; rightMargin: Theme.gapMedium; verticalCenter: parent.verticalCenter }
    text: root.note
    color: Theme.muted
    font.pixelSize: Theme.fontSize - 2
  }
}
