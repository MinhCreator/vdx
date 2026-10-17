import QtQuick
import qs.config
import qs.kit

// The monitors as they sit, drawn to scale in logical pixels. Click one to
// select it; drag it to move it, or nudge the selected one with the arrows
// (Shift: 10 px). It snaps to the edges of the others; a place that overlaps
// another one shows red and is not applied (DisplayService.setPosition).
Item {
  id: root

  property string selected: ""
  signal picked(string name)

  readonly property var ds: DisplayService
  readonly property int pad: 16
  readonly property int snapPx: 12                 // how close (on screen) an edge must be to snap

  focus: true
  Keys.onPressed: event => {
    const step = event.modifiers & Qt.ShiftModifier ? 10 : 1;
    const m = ds.monitors.find(o => o.name === selected);
    if (!m) return;
    const d = { [Qt.Key_Left]: [-step, 0], [Qt.Key_Right]: [step, 0],
                [Qt.Key_Up]: [0, -step], [Qt.Key_Down]: [0, step] }[event.key];
    if (!d) return;
    const p = at(m);
    const s = size(m);
    const nx = p.x + d[0], ny = p.y + d[1];
    if (!overlaps(m.name, nx, ny, s.w, s.h)) ds.setPosition(m.name, nx, ny);
    event.accepted = true;
  }

  // where a monitor is drawn: its pending place while it applies, else where it is
  function at(m) {
    return ds.working === "pos:" + m.name && ds.pending ? { x: ds.pending[0], y: ds.pending[1] }
                                                        : { x: m.x, y: m.y };
  }
  function size(m) { return { w: Math.round(m.width / m.scale), h: Math.round(m.height / m.scale) }; }

  // the box all monitors take, in logical pixels, and the screen scale of it
  readonly property real minX: bound(true, false)
  readonly property real minY: bound(false, false)
  readonly property real maxX: bound(true, true)
  readonly property real maxY: bound(false, true)
  readonly property real k: Math.max(0.01, Math.min((width - 2 * pad) / Math.max(1, maxX - minX),
                                                    (height - 2 * pad) / Math.max(1, maxY - minY)))
  readonly property real ox: (width - (maxX - minX) * k) / 2
  readonly property real oy: (height - (maxY - minY) * k) / 2

  function bound(isX, far) {
    let v = far ? -Infinity : Infinity;
    for (const m of ds.monitors) {
      const p = at(m), s = size(m);
      const edge = isX ? (far ? p.x + s.w : p.x) : (far ? p.y + s.h : p.y);
      v = far ? Math.max(v, edge) : Math.min(v, edge);
    }
    return isFinite(v) ? v : 0;
  }

  function overlaps(name, x, y, w, h) {
    for (const o of ds.monitors) {
      if (o.name === name) continue;
      const p = at(o), s = size(o);
      if (x < p.x + s.w && p.x < x + w && y < p.y + s.h && p.y < y + h) return true;
    }
    return false;
  }

  // the nearest edge alignment within snapPx, per axis
  function snap(name, nx, ny, w, h) {
    const tol = snapPx / k;
    let bx = nx, by = ny, dx = tol, dy = tol;
    for (const o of ds.monitors) {
      if (o.name === name) continue;
      const p = at(o), s = size(o);
      const xs = [p.x - w, p.x + s.w, p.x, p.x + s.w - w];
      const ys = [p.y - h, p.y + s.h, p.y, p.y + s.h - h];
      for (const c of xs) if (Math.abs(c - nx) < dx) { dx = Math.abs(c - nx); bx = c; }
      for (const c of ys) if (Math.abs(c - ny) < dy) { dy = Math.abs(c - ny); by = c; }
    }
    return { x: Math.round(bx), y: Math.round(by) };
  }

  Repeater {
    model: root.ds.monitors

    Rectangle {
      radius: Theme.radiusControl
      id: box
      required property var modelData
      readonly property var p: root.at(modelData)
      readonly property var s: root.size(modelData)
      readonly property bool isSelected: root.selected === modelData.name
      property real dx: 0
      property real dy: 0
      property real grabX: 0
      property real grabY: 0
      // where it would be if released now, and whether that place is taken
      readonly property real previewX: Math.round(p.x + dx / root.k)
      readonly property real previewY: Math.round(p.y + dy / root.k)
      readonly property bool clash: (dx !== 0 || dy !== 0)
                                    && root.overlaps(modelData.name, previewX, previewY, s.w, s.h)

      x: root.ox + (p.x - root.minX) * root.k + dx
      y: root.oy + (p.y - root.minY) * root.k + dy
      width: s.w * root.k
      height: s.h * root.k
      color: isSelected ? Theme.background3 : Theme.background2
      border.width: isSelected ? 2 : Theme.frameWidth
      border.color: clash ? Theme.red : isSelected ? Theme.foreground0 : Theme.frame
      z: drag.pressed || isSelected ? 1 : 0

      KitText {
        anchors.centerIn: parent
        text: box.modelData.name + (box.clash ? " · overlap" : "")
        font.pixelSize: Theme.fontSize - 2
        font.weight: box.isSelected ? Font.ExtraBold : Theme.fontWeight
        color: box.clash ? Theme.red : Theme.foreground0
      }

      MouseArea {
        id: drag
        anchors.fill: parent
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        onPressed: mouse => {
          root.picked(box.modelData.name);
          root.forceActiveFocus();
          const q = mapToItem(root, mouse.x, mouse.y);
          box.grabX = q.x;
          box.grabY = q.y;
        }
        onPositionChanged: mouse => {
          if (!pressed) return;
          const q = mapToItem(root, mouse.x, mouse.y);
          box.dx = q.x - box.grabX;
          box.dy = q.y - box.grabY;
        }
        onReleased: {
          const t = root.snap(box.modelData.name, box.previewX, box.previewY, box.s.w, box.s.h);
          box.dx = 0;
          box.dy = 0;
          if (root.overlaps(box.modelData.name, t.x, t.y, box.s.w, box.s.h)) return;
          if (t.x !== box.p.x || t.y !== box.p.y) root.ds.setPosition(box.modelData.name, t.x, t.y);
        }
      }
    }
  }
}
