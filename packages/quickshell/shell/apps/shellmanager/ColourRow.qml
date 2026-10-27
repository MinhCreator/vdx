import QtQuick
import qs.config
import qs.kit

// A colour setting, one control wherever a colour is typed or picked (cursor): a
// colour field (chip, hex, chevron), and under it, when open, the picker
// (palette dots, saturation and brightness, hue). `open` is toggled by the chip
// or the chevron; `chipClicked` lets the owner close the others.
// `live`: every valid typed or dragged colour is handed over at once.
Column {
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

  width: parent ? parent.width : 0
  spacing: Theme.gapMedium

  KitColourPicker {
    width: parent.width
    palette: root.palette
    picked: root.picked
    colours: root.colours
    onChosen: name => root.chosen(name)
  }
  KitGrouper {}
}
