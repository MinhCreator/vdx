import QtQuick
import qs.config

// Body text of the kit: the shared monospace at a regular weight. Titles set
// `font.weight: Font.ExtraBold`; small caps captions use KitLabel.
Text {
  color: Theme.foreground0
  verticalAlignment: Text.AlignVCenter
  font.family: Theme.fontFamily
  font.pixelSize: Theme.fontSize
  font.weight: Font.DemiBold
}
