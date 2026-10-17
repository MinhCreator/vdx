import QtQuick
import qs.config
import qs.kit

// "Custom colour" row, one look wherever a colour is typed in (wallpaper,
// cursor): a swatch of what is typed and a field taking #rrggbb (the # may be
// left out). Enter hands the colour over as "#rrggbb" when it is valid.
KitRow {
  id: root

  property string value: ""                 // what the field shows
  readonly property bool valid: /^#?[0-9a-fA-F]{6}$/.test(value.trim())
  readonly property string colour: valid ? "#" + value.trim().replace(/^#/, "").toLowerCase() : ""

  signal edited(string text)
  signal accepted(string colour)

  label: "Custom colour"
  hint: valid ? "Press Enter to apply" : "Six hex digits, like #32302f"
  wide: true

  Row {
    spacing: Theme.gapMedium

    Rectangle {
      radius: Theme.radiusControl
      id: swatch
      anchors.verticalCenter: parent.verticalCenter
      width: field.height
      height: field.height
      color: root.valid ? root.colour : "transparent"
      border.width: Theme.frameWidth
      border.color: Theme.gray
    }

    KitInput {
      id: field
      width: parent.width - swatch.width - parent.spacing
      placeholder: "#32302f"
      text: root.value
      onTextEdited: root.edited(text)
      onAccepted: if (root.valid) root.accepted(root.colour)
    }
  }
}
