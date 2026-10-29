import QtQuick
import qs.config

// A list row's icon: plain, or in a framed tile when Appearance › Icons › Framed icons is on
// (lists and menus only; the bar, the hub and chips keep bare icons). `active`: the open row.
Rectangle {
  id: root

  property string name: ""
  property color tint: Theme.foreground2
  property bool active: false
  property bool hovered: false
  property int glyph: Theme.iconSmall
  readonly property bool framed: ShellSettings.iconTiles

  width: framed ? glyph + 10 : glyph
  height: width
  radius: Theme.radiusFor(height)
  color: !framed ? Theme.clear : active ? Theme.mix(Theme.background0, Theme.foreground0, 0.2) : Theme.fillOn(true)
  border.width: framed ? Theme.hairline : 0
  border.color: active || hovered ? Theme.controlLineHover : Theme.controlLine
  Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }

  KitIcon {
    anchors.centerIn: parent
    name: root.name
    tint: root.tint
    size: root.glyph
  }
}
