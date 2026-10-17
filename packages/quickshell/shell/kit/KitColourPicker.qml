import QtQuick
import qs.config
import "colour.js" as Colour

// The picker under a colour field, on demand, in the settings' own rows: the
// palette dots (when there is one), then Hue, Saturation and Brightness as
// sliders with their reading; each track is the colours it would give. It keeps
// its own hue, so a grey or black colour does not lose it. `moved(hex)` while
// dragging, `released(hex)` when let go, `chosen(name)` for a palette dot.
Column {
  id: root

  property string colour: ""
  property var palette: []
  property string picked: ""
  property var colours: name => [Theme.frame, Theme.frame]

  property real hue: 0
  property real sat: 1
  property real val: 1
  property string lastOut: ""

  signal moved(string hex)
  signal released(string hex)
  signal chosen(string name)

  spacing: Theme.gapMedium
  topPadding: Theme.gapGroup

  // a colour from outside (typed, or a palette dot): the picker follows it
  function follow(text) {
    if (text.trim().toLowerCase() === lastOut) return;
    const c = Colour.hsvOf(text);
    if (!c) return;
    if (c.h >= 0) hue = c.h;
    sat = c.s;
    val = c.v;
  }

  function emitColour(done) {
    const hex = Colour.hexOf(hue, sat, val);
    lastOut = hex;
    if (done) released(hex); else moved(hex);
  }

  // 48 steps along a track, from `at(t)` for t in 0..1
  function ramp(at) {
    const out = [];
    for (let i = 0; i < 48; i++) out.push(at(i / 47));
    return out;
  }
  readonly property var hueRamp: ramp(t => Qt.hsva(t, 1, 1, 1))
  readonly property var satRamp: ramp(t => Qt.hsva(hue, t, val, 1))
  readonly property var valRamp: ramp(t => Qt.hsva(hue, sat, t, 1))

  onColourChanged: follow(colour)
  Component.onCompleted: follow(colour)

  KitSwatches {
    visible: root.palette.length > 0
    width: parent.width
    model: root.palette
    picked: root.picked
    colours: root.colours
    alignLeft: true
    onChosen: name => root.chosen(name)
  }

  KitSliderRow {
    label: "Hue"
    text: Math.round(root.hue * 360) + "°"
    value: root.hue
    spectrum: root.hueRamp
    onMoved: v => { root.hue = v; root.emitColour(false) }
    onReleased: v => { root.hue = v; root.emitColour(true) }
  }

  KitSliderRow {
    label: "Saturation"
    text: Math.round(root.sat * 100) + "%"
    value: root.sat
    spectrum: root.satRamp
    onMoved: v => { root.sat = v; root.emitColour(false) }
    onReleased: v => { root.sat = v; root.emitColour(true) }
  }

  KitSliderRow {
    label: "Brightness"
    text: Math.round(root.val * 100) + "%"
    value: root.val
    spectrum: root.valRamp
    onMoved: v => { root.val = v; root.emitColour(false) }
    onReleased: v => { root.val = v; root.emitColour(true) }
  }
}
