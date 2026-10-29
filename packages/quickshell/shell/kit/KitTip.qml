import QtQuick
import QtQuick.Controls as Controls
import qs.config

// An info mark for a long or rare explanation (a title's, a page's): the text is a tooltip, under the mark, while the
// pointer is on it, so the row stays one line.
// `level` is the kind of note and the only place the colours come in: "info" (neutral, the
// default), "ok" (green: what is safe or done), "warn" (yellow: a caveat, a restart, a
// side effect), "danger" (red: it cannot be undone). Use a colour only when the reader
// should act differently; most notes are "info".
Item {
  id: root

  property string text: ""
  property string level: "info"
  property int size: Theme.fontSize

  readonly property color accent: level === "ok" ? Theme.green
    : level === "warn" ? Theme.yellow
    : level === "danger" ? Theme.red : Theme.muted

  implicitWidth: icon.implicitWidth
  implicitHeight: icon.implicitHeight

  Accessible.role: Accessible.StaticText
  Accessible.name: text

  KitIcon {
    id: icon
    anchors.centerIn: parent
    name: root.level === "ok" ? "check" : "info"
    size: root.size
    tint: root.level !== "info" ? root.accent
      : area.containsMouse ? Theme.foreground0 : Theme.muted
  }

  MouseArea {
    id: area
    anchors.fill: parent
    anchors.margins: -Theme.gapSmall
    hoverEnabled: true
  }

  Controls.ToolTip {
    visible: area.containsMouse && root.text !== ""
    delay: 300
    text: root.text
    x: -Theme.gapSmall
    y: root.height + Theme.gapSmall
    padding: Theme.gapMedium
    width: Math.min(implicitContentWidth + leftPadding + rightPadding, 320)

    contentItem: KitText {
      text: root.text
      color: Theme.foreground0
      wrapMode: Text.WordWrap
      font.pixelSize: Theme.fontSize - 1
    }
    background: Rectangle {
      color: Theme.surfaceHighest
      radius: Theme.radiusControl
      border { width: Theme.frameWidth; color: root.level === "info" ? Theme.popupFrame : root.accent }
    }
  }
}
