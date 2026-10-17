import QtQuick
import qs.config
import qs.kit

// The restore guide: the same text `backup guide` prints. Numbered headings
// stand out, indented lines are commands and sit in the foreground.
Item {
  id: root

  readonly property var bs: BackupService

  Flickable {
    anchors.fill: parent
    bottomMargin: Theme.gapGroup
    contentHeight: column.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height

    Column {
      id: column
      width: parent.width
      spacing: Theme.gapTight

      KitLabel { text: "HOW TO GET EVERYTHING BACK"; value: "ALSO: backup guide" }

      Item { width: 1; height: Theme.gapSmall }

      Repeater {
        model: root.bs.guideLines

        KitText {
          required property string modelData
          required property int index

          width: column.width
          wrapMode: Text.WordWrap
          text: modelData === "" ? " " : modelData
          font.pixelSize: Theme.fontSize - 1
          font.weight: /^\d\./.test(modelData) ? Font.ExtraBold : Font.Normal
          color: /^\d\./.test(modelData) ? Theme.foreground0 : modelData.startsWith("   ") ? Theme.foreground1 : Theme.muted
          topPadding: /^\d\./.test(modelData) && index > 0 ? Theme.gapSmall : 0
        }
      }
    }
  }
}
