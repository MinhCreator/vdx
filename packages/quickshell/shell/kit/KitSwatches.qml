import QtQuick
import qs.config

// A dot per choice, pushed to the right edge: `colours(name)` gives its
// [from, to] gradient (one colour twice), the picked one carries a ring. Laid
// out right to left, so the model runs backwards. `exclude` leaves names out.
// `add` is a choice that is empty until something is saved in it: while
// `addEmpty`, its dot is hollow with a plus (choose it to type one).
Row {
  id: root

  property var model: []
  property var exclude: []
  property string picked: ""
  property var colours: name => [Theme.frame, Theme.frame]
  property string add: ""
  property bool addEmpty: false
  property bool alignLeft: false
  property bool disabled: false               // dimmed, and no click (a choice made elsewhere)

  signal chosen(string name)

  spacing: Theme.gapMedium
  layoutDirection: alignLeft ? Qt.LeftToRight : Qt.RightToLeft
  opacity: disabled ? 0.4 : 1

  Repeater {
    model: root.model.filter(name => root.exclude.indexOf(name) < 0)

    Rectangle {
      id: swatch
      required property string modelData
      readonly property bool hollow: modelData === root.add && root.addEmpty
      readonly property bool picked: root.picked === modelData
      readonly property var pair: hollow ? [Theme.clear, Theme.clear] : root.colours(modelData)

      anchors.verticalCenter: parent.verticalCenter
      width: 18
      height: 18
      radius: Theme.pill(height)
      border.width: picked ? Theme.ring : hollow ? Theme.hairline : 0
      border.color: picked ? Theme.foreground0 : Theme.gray
      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0; color: swatch.pair[0] }
        GradientStop { position: 1; color: swatch.pair[1] }
      }

      KitIcon {
        anchors.centerIn: parent
        visible: swatch.hollow
        name: "plus"
        tint: Theme.foreground2
        size: Theme.iconSmall
      }

      MouseArea {
        anchors.fill: parent
        enabled: !root.disabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.chosen(swatch.modelData)
      }
    }
  }
}
