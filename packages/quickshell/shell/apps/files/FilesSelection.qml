import QtQuick

// Selection and keyboard cursor, independent of directory I/O. `anchor` is
// the current row (the views scroll to it); `rangeStart` stays at the start
// of a Shift gesture while the current row moves in either direction.
QtObject {
  id: root

  property var rows: []
  property bool single: false
  property var selection: []
  property string anchor: ""
  property string rangeStart: ""
  readonly property var paths: rows.map(e => e.path)

  onSelectionChanged: if (selection.length === 0) rangeStart = ""
  onAnchorChanged: rangeStart = ""
  onSingleChanged: if (single && selection.length > 1) selection = selection.slice(0, 1)
  onPathsChanged: {
    const available = new Set(paths);
    const kept = selection.filter(p => available.has(p));
    if (kept.length !== selection.length) selection = kept;
    if (!available.has(anchor)) anchor = "";
    if (!available.has(rangeStart)) rangeStart = "";
  }

  function select(path, mode) {
    if (!paths.includes(path)) return;
    if (single) mode = "single";
    let start = "";
    if (mode === "range") {
      start = paths.includes(rangeStart || anchor) ? rangeStart || anchor : path;
      const a = paths.indexOf(start), b = paths.indexOf(path);
      selection = paths.slice(Math.min(a, b), Math.max(a, b) + 1);
    } else {
      rangeStart = "";
      selection = mode === "toggle"
        ? selection.includes(path) ? selection.filter(p => p !== path) : selection.concat([path])
        : [path];
    }
    anchor = path;
    rangeStart = start;
  }

  function selectAll() {
    rangeStart = "";
    selection = single ? paths.slice(0, 1) : paths.slice();
    if (!selection.includes(anchor)) anchor = selection[0] ?? "";
  }

  function step(delta, extend) {
    if (!paths.length) return;
    const current = paths.indexOf(anchor);
    const next = current < 0 ? 0 : Math.max(0, Math.min(paths.length - 1, current + delta));
    select(paths[next], extend ? "range" : "single");
  }
}
