import QtQuick
import qs.config

// A colour ramp shared by hue, saturation and brightness controls.
Item {
  id: ramp
  property real value: 0
  property var spectrum: []
  property string label: ""
  property string description: ""
  property real step: 0.01
  property int trackHeight: 14
  signal moved(real value)
  signal released(real value)
  implicitHeight: 28
  activeFocusOnTab: true
  Accessible.role: Accessible.Slider
  Accessible.name: label
  Accessible.description: description
  function setAt(position, done) {
    const next = Math.max(0, Math.min(1, position));
    if (done) released(next); else moved(next);
  }
  function adjust(delta) { setAt(value + delta, true); }
  Keys.onLeftPressed: event => adjust(event.modifiers & Qt.ShiftModifier ? -step * 10 : -step)
  Keys.onRightPressed: event => adjust(event.modifiers & Qt.ShiftModifier ? step * 10 : step)
  Keys.onPressed: event => {
    if (event.key === Qt.Key_Home || event.key === Qt.Key_End) {
      setAt(event.key === Qt.Key_Home ? 0 : 1, true);
      event.accepted = true;
    }
  }
  Accessible.onIncreaseAction: adjust(step)
  Accessible.onDecreaseAction: adjust(-step)
  Rectangle {
    anchors { fill: parent; margins: -3 }
    radius: Theme.radiusControl
    visible: ramp.activeFocus
    color: Theme.clear
    border.width: Theme.focusWidth
    border.color: Theme.focusRing
  }
  Rectangle {
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width
    height: ramp.trackHeight
    radius: Theme.radiusFor(height)
    gradient: Gradient {
      orientation: Gradient.Horizontal
      GradientStop { position: 0; color: ramp.spectrum[0] ?? "black" }
      GradientStop { position: 1/6; color: ramp.spectrum[1] ?? "black" }
      GradientStop { position: 2/6; color: ramp.spectrum[2] ?? "black" }
      GradientStop { position: 3/6; color: ramp.spectrum[3] ?? "black" }
      GradientStop { position: 4/6; color: ramp.spectrum[4] ?? "black" }
      GradientStop { position: 5/6; color: ramp.spectrum[5] ?? "black" }
      GradientStop { position: 1; color: ramp.spectrum[6] ?? "black" }
    }
    border.width: Theme.hairline
    border.color: Theme.controlLine
  }
  Rectangle {
    x: ramp.value * Math.max(0, ramp.width - width)
    anchors.verticalCenter: parent.verticalCenter
    width: 8; height: ramp.trackHeight + 8
    radius: Theme.radiusFor(height)
    color: Theme.clear
    border.width: 2
    border.color: "white"
    Rectangle { anchors { fill: parent; margins: -1 } radius: parent.radius; color: Theme.clear; border.width: 1; border.color: "#80000000" }
  }
  MouseArea {
    anchors.fill: parent
    preventStealing: true
    cursorShape: Qt.PointingHandCursor
    function pick(mouse, done) { ramp.setAt((mouse.x - 4) / Math.max(1, width - 8), done); }
    onPressed: mouse => { ramp.forceActiveFocus(Qt.MouseFocusReason); pick(mouse, false); }
    onPositionChanged: mouse => { if (pressed) pick(mouse, false); }
    onReleased: mouse => pick(mouse, true)
  }
}
