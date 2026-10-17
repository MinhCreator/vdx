import QtQuick
import qs.config
import qs.kit

// A colour setting, one control wherever a colour is typed or picked (wallpaper,
// cursor, accent): a colour field (chip, hex, chevron), and under it, when open,
// the picker (palette dots, saturation and brightness, hue). `open` is toggled
// by the chip or the chevron; `chipClicked` lets the owner close the others.
// `live`: every valid typed or dragged colour is handed over at once.
KitRow {
  id: root

  property string value: ""                 // the colour the field shows
  property string example: "#32302f"       // the placeholder
  property bool live: false
  property bool open: false
  property var palette: []                  // palette names for the dots (none: no dots)
  property string picked: ""                // the palette name in use
  property var colours: name => [Theme.frame, Theme.frame]
  property string note: ""                  // the hint (a stop's name, say)

  signal edited(string text)
  signal accepted(string colour)
  signal chosen(string name)
  signal chipClicked()

  label: "Custom colour"
  hint: note
  wide: true

  Column {
    spacing: 0

    KitColourField {
      width: parent.width
      value: root.value
      placeholder: root.example
      live: root.live
      open: root.open
      onEdited: text => root.edited(text)
      onAccepted: colour => root.accepted(colour)
      onChipClicked: {
        root.open = !root.open;
        root.chipClicked();
      }
    }

    KitColourPicker {
      visible: root.open
      width: parent.width
      colour: root.value
      palette: root.palette
      picked: root.picked
      colours: root.colours
      onMoved: hex => { root.edited(hex); if (root.live) root.accepted(hex) }
      onReleased: hex => { root.edited(hex); root.accepted(hex) }
      onChosen: name => root.chosen(name)
    }
  }
}
