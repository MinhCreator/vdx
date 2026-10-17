import QtQuick
import qs.config
import qs.kit

// A key as a keycap: Keybinds lists binds with them, Shell apps the key that
// opens each app.
Rectangle {
  radius: Theme.radiusControl
  property alias text: keyText.text

  width: Math.max(26, keyText.implicitWidth + 14)
  height: 24
  color: Theme.background1
  border.width: Theme.frameWidth
  border.color: Theme.gray

  KitText {
    id: keyText
    anchors.centerIn: parent
    font.pixelSize: Theme.fontSize - 2
    font.weight: Font.ExtraBold
  }
}
