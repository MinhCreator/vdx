import QtQuick
import qs.config
import qs.kit

// The week strip: Monday to Sunday, today as a white card with a dot.
Rectangle {
  id: root

  property date now: new Date()

  implicitHeight: 72
  radius: 22
  color: Theme.background1

  // the Monday of this week
  readonly property date monday: {
    const d = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    d.setDate(d.getDate() - (d.getDay() + 6) % 7);
    return d;
  }

  Row {
    anchors { fill: parent; margins: 6 }

    Repeater {
      model: 7

      Item {
        required property int index
        readonly property date day: new Date(root.monday.getFullYear(), root.monday.getMonth(), root.monday.getDate() + index)
        readonly property bool today: day.getDate() === root.now.getDate() && day.getMonth() === root.now.getMonth()
        width: parent.width / 7
        height: parent.height

        Rectangle {
          anchors.fill: parent
          radius: 16
          color: Theme.foreground1
          visible: parent.today
        }

        Column {
          anchors.centerIn: parent
          spacing: 3

          KitText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "MTWTFSS"[index]
            color: today ? Theme.background1 : Theme.muted
            font.pixelSize: 11
          }
          KitText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: day.getDate()
            color: today ? Theme.background0 : Theme.foreground0
            font.pixelSize: 17
            font.weight: Font.Medium
          }
          Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 4; height: 4; radius: 2
            color: today ? Theme.background0 : "transparent"
          }
        }
      }
    }
  }
}
