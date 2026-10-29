import QtQuick
import Quickshell
import Quickshell.Io
import "../../kit/reply.js" as Reply

// A screenshot must reach wl-copy before Save as can move or discard its
// source. Keep the capture's destination and notification choices with it.
Scope {
  id: root
  required property string script
  property var request: null
  readonly property bool busy: request !== null
  signal completed(var capture, var result)

  function copy(capture) {
    if (busy) return false;
    request = Object.assign({}, capture);
    worker.command = ["python3", script, "clipboard", request.file];
    worker.running = true;
    return true;
  }

  Process {
    id: worker
    stdout: StdioCollector { id: output }
    onExited: code => {
      const capture = root.request;
      let result = Reply.parse(output.text, "capture.py");
      if (code !== 0 && result.ok) result = { ok: false, error: "Could not copy screenshot" };
      root.request = null;
      root.completed(capture, result);
    }
  }
}
