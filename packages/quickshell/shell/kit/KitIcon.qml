import QtQuick
import QtQuick.Effects
import qs.config

// An SVG icon from kit/icons, recoloured to `tint`. The files are drawn in
// white, so colorization maps them to any theme colour. The set is the user's
// (Shell Manager › Appearance › Icons): Material Symbols, where `solid` (the
// user's style unless set) picks the filled variant from icons/solid and round
// corners (Appearance › Corners) the Rounded set in icons/round (names:
// icons/material.txt); Phosphor in icons/phosphor, `solid` from phosphor/solid,
// one set for both corners (icons/phosphor.txt); or Lucide in icons/lucide,
// outline only (icons/lucide.txt).
Item {
  id: root

  property string name: ""
  property color tint: Theme.foreground0
  property int size: Theme.fontSize + 3
  property bool solid: ShellSettings.solidIcons

  // the battery glyphs are wide and short, so drawn alone they look smaller
  // than the others: their box is a third larger, the glyph's height matches
  readonly property real optical: name.startsWith("battery-") ? 1.35 : 1

  implicitWidth: size * optical
  implicitHeight: size * optical

  Image {
    id: image
    anchors.fill: parent
    source: root.name === "" ? ""
      : ShellSettings.iconSet === "lucide" ? Qt.resolvedUrl("icons/lucide/" + root.name + ".svg")
      : ShellSettings.iconSet === "phosphor" ? Qt.resolvedUrl("icons/phosphor/" + (root.solid ? "solid/" : "") + root.name + ".svg")
      : Qt.resolvedUrl("icons/" + (Theme.round ? "round/" : "") + (root.solid ? "solid/" : "") + root.name + ".svg")
    sourceSize { width: root.implicitWidth * 2; height: root.implicitHeight * 2 }
    smooth: true
    visible: false
  }

  MultiEffect {
    anchors.fill: parent
    source: image
    colorization: 1
    colorizationColor: root.tint
  }
}
