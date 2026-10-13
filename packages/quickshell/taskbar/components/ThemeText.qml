import QtQuick
import qs.config

// Text in the shared font, used by bar labels and popups alike. Override color,
// font.pixelSize or letterSpacing per use.
Text {
  color: Theme.foreground0
  verticalAlignment: Text.AlignVCenter
  font.family: Theme.fontFamily
  font.pixelSize: Theme.fontSize
  font.weight: Theme.fontWeight
}
