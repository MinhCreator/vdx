import QtQuick

// Keeps the wheel inside a list that scrolls within the scrolling page: over
// `flick` the wheel moves only it, also at its ends — the page doesn't take
// over halfway. A list with nothing to scroll lets the wheel through. Clicks
// pass to the rows (no buttons accepted).
MouseArea {
  required property Flickable flick

  anchors.fill: flick
  acceptedButtons: Qt.NoButton

  onWheel: wheel => {
    if (!flick.interactive) { wheel.accepted = false; return; }
    const delta = wheel.pixelDelta.y !== 0 ? wheel.pixelDelta.y : wheel.angleDelta.y / 120 * 48;
    flick.contentY = Math.max(0, Math.min(flick.contentHeight - flick.height, flick.contentY - delta));
  }
}
