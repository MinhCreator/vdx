import QtQuick
import qs.config

// Red message line; hidden while `text` is empty.
ThemeText {
  width: parent.width
  visible: text !== ""
  color: Theme.red
  wrapMode: Text.WordWrap
  font.pixelSize: Theme.fontSize - 2
}
