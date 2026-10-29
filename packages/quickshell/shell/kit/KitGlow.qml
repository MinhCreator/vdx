import QtQuick
import QtQuick.Effects
import qs.config

// A soft halo of `tint` behind a bright element (Appearance › Glow): put it
// first in the element's parent, fill it over the element, and give it the
// element's `radius`. `target` is the Glow target key (switches, sliders,
// workspaces, live, dots); the halo is not drawn while that target or Glow is off.
// Two layers, as a real light falls off: a tight, brighter one close to the
// element and a wide, faint one. RectangularShadow draws only the shadow (never
// a copy of the element) and follows the corners, so a thin bar stays thin.
Item {
  id: root

  property string target: ""
  property color tint: Theme.foreground0
  property real radius: 0
  property bool lit: true                 // false: the element is off, no halo

  // 0..1: the halo fades in and out as the element lights, or Glow is switched
  property real amount: lit && Theme.glowOn(target) ? 1 : 0
  Behavior on amount { enabled: Motion.controls; NumberAnimation { duration: Motion.slow; easing.type: Motion.easing } }

  visible: amount > 0.001

  RectangularShadow {
    anchors.fill: parent
    radius: root.radius
    blur: 12 + 14 * Theme.glowLevel
    color: root.tint
    opacity: 0.3 * Theme.glowLevel * root.amount
  }

  RectangularShadow {
    anchors.fill: parent
    radius: root.radius
    blur: 4 + 4 * Theme.glowLevel
    color: root.tint
    opacity: 0.55 * Theme.glowLevel * root.amount
  }
}
