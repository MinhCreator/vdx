import QtQuick
import qs.config

// Busy indicator in the popup's square style: a Nerd Font spinner glyph that
// rotates in place. Used by UPDATE and PING while their action runs, so the
// whole popup keeps one visual language (same font, same tint, no radius).
Item {
  id: root

  property color tint: Theme.dim

  implicitWidth: 14
  implicitHeight: 14
  width: implicitWidth
  height: implicitHeight
  transformOrigin: Item.Center

  Text {
    anchors.centerIn: parent
    text: Theme.iconSpinner
    color: root.tint
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize - 1
    font.weight: Theme.fontWeight
  }

  // Runs only while shown; a still frame when hidden.
  RotationAnimator on rotation {
    running: root.visible
    from: 0
    to: 360
    duration: 800
    loops: Animation.Infinite
  }
}
