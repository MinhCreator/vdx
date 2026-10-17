import QtQuick
import QtQuick.Effects
import qs.config

// An SVG icon from kit/icons (Material Symbols), recoloured to `tint`. The
// files are drawn in white, so colorization maps them to any theme colour.
// `solid` (the user's icon style, Shell Manager › Appearance, unless set) picks
// the filled variant from icons/solid; round corners (Appearance › Corners) the
// Rounded set in icons/round (names: icons/material.txt).
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
