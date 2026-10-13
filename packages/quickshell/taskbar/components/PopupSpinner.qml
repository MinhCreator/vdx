import QtQuick
import qs.config

// Rotating nerd-font spinner; animates only while visible.
ThemeText {
  property color tint: Theme.dim

  text: Theme.iconSpinner
  color: tint
  font.pixelSize: Theme.fontSize - 1

  RotationAnimator on rotation {
    running: visible
    from: 0
    to: 360
    duration: 800
    loops: Animation.Infinite
  }
}
