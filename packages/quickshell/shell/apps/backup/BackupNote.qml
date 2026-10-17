import QtQuick
import qs.config
import qs.kit

// A note under a group or a row of the backups: muted, one size, wrapped.
// Every note of the backups is this one, so they all look alike.
KitText {
  width: parent ? parent.width : 0
  wrapMode: Text.WordWrap
  color: Theme.muted
  font.pixelSize: Theme.fontSize - 2
}
