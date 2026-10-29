import QtQuick

// An undo/redo entry changes stacks only after its asynchronous operation
// succeeds. A failure or cancellation keeps the entry available for retry.
QtObject {
  property var undos: []
  property var redos: []
  property var pending: null
  property bool busy: false
  readonly property bool canUndo: undos.length > 0 && !busy && pending === null
  readonly property bool canRedo: redos.length > 0 && !busy && pending === null

  function record(entry) {
    undos = undos.concat([entry]);
    redos = [];
  }

  function undo() {
    if (!canUndo) return;
    const entry = undos[undos.length - 1];
    pending = { direction: "undo", entry: entry };
    entry.undo();
  }

  function redo() {
    if (!canRedo) return;
    const entry = redos[redos.length - 1];
    pending = { direction: "redo", entry: entry };
    entry.redo();
  }

  function complete(success) {
    if (pending === null) return;
    const step = pending;
    if (success) {
      if (step.direction === "undo") {
        undos = undos.slice(0, -1);
        redos = redos.concat([step.entry]);
      } else {
        redos = redos.slice(0, -1);
        undos = undos.concat([step.entry]);
      }
    }
    pending = null;
  }
}
