import QtQuick
import qs.config
import qs.kit

// The week in the hub: Monday to Sunday, today picked. A click opens the month.
Rectangle {
  id: root

  property date now: new Date()
  signal clicked()

  implicitHeight: 64
  radius: Theme.radiusCard
  color: Theme.controlFill
  border.width: Theme.frameWidth
  border.color: Theme.controlLine

  // the Monday of this week
  readonly property date monday: {
    const d = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    d.setDate(d.getDate() - (d.getDay() + 6) % 7);
    return d;
  }

  Row {
    anchors { fill: parent; margins: Theme.gapSmall }

    Repeater {
      model: 7

      Rectangle {
        required property int index
        readonly property date day: new Date(root.monday.getFullYear(), root.monday.getMonth(), root.monday.getDate() + index)
        readonly property bool today: day.getDate() === root.now.getDate() && day.getMonth() === root.now.getMonth()
        width: parent.width / 7
        height: parent.height
        radius: Theme.radiusControl
        color: today ? Theme.pickFill : Theme.clear

        Column {
          anchors.centerIn: parent
          spacing: Theme.gapTight

          KitText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "MTWTFSS"[index]
            color: Theme.muted
            font.pixelSize: Theme.fontSize - 2
          }
          KitText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: day.getDate()
            font.weight: today ? Theme.pickWeight : Theme.fontWeight
          }
        }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
