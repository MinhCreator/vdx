import QtQuick
import qs.config

// A ring that empties as a countdown runs out: `progress` 0 is full, 1 is gone.
Canvas {
  id: root

  property real progress: 0
  property real thickness: 2.5
  property color tint: Theme.orange
  property color track: Theme.background3

  implicitWidth: 18
  implicitHeight: 18
  onProgressChanged: requestPaint()
  onTintChanged: requestPaint()
  onTrackChanged: requestPaint()
  onWidthChanged: requestPaint()

  onPaint: {
    const c = getContext("2d");
    c.reset();
    const r = (Math.min(width, height) - thickness) / 2;
    const cx = width / 2, cy = height / 2;
    c.lineWidth = thickness;
    c.lineCap = "round";
    c.strokeStyle = track;
    c.beginPath();
    c.arc(cx, cy, r, 0, 2 * Math.PI);
    c.stroke();
    const left = 1 - Math.min(1, Math.max(0, progress));
    if (left <= 0) return;
    c.strokeStyle = tint;
    c.beginPath();
    c.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * left);
    c.stroke();
  }
}
