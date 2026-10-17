import QtQuick
import qs.config
import qs.kit

// A row of the file manager's sidebar: an icon, a name and a hint at the
// right; the current place is filled. A left click opens it, a right click
// reports where it was (scene coordinates) so Files can open its menu.
Rectangle {
  id: root

  property string icon: ""
  property string text: ""
  property string hint: ""
  property bool current: false

  signal clicked()
  signal rightClicked(point at)

  width: parent ? parent.width : 0
  height: 28
  radius: Theme.radiusControl
  color: current ? Theme.background3 : area.containsMouse ? Theme.controlHover : Theme.clear
  Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }

  KitIcon {
    id: glyph
    anchors { left: parent.left; leftMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }
    name: root.icon
    size: Theme.iconSmall
  }

  KitText {
    anchors { left: glyph.right; leftMargin: Theme.gapMedium; right: hintText.left; rightMargin: Theme.gapSmall; verticalCenter: parent.verticalCenter }
    text: root.text
    elide: Text.ElideRight
    font.weight: root.current ? Font.ExtraBold : Theme.fontWeight
  }

  KitText {
    id: hintText
    anchors { right: parent.right; rightMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }
    visible: root.hint !== ""
    text: root.hint
    color: Theme.muted
    font.pixelSize: Theme.fontSize - 2
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onClicked: mouse => {
      if (mouse.button === Qt.RightButton) root.rightClicked(root.mapToItem(null, mouse.x, mouse.y));
      else root.clicked();
    }
  }
}
