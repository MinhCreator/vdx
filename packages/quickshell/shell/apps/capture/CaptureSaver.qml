import QtQuick
import Quickshell
import Quickshell.Io
import "../../kit/reply.js" as Reply

// Save as stays open until the backend succeeds. Errors preserve the source
// and the request; overwriting needs a second confirmation for the same path.
Scope {
  id: root

  required property string script
  property string home: Quickshell.env("HOME")
  property var pending: null
  property var queue: []
  property bool busy: false
  property string error: ""
  property string overwritePath: ""
  readonly property bool replacing: overwritePath !== ""
  property string target: ""
  property string operation: ""

  signal saved(var capture, string path)

  function offer(capture) {
    const request = Object.assign({}, capture);
    if (pending) queue = queue.concat([request]);
    else { pending = request; error = request.error ?? ""; }
  }

  function edited() { error = ""; overwritePath = ""; }

  function takeNext() {
    const capture = pending;
    pending = queue[0] ?? null;
    queue = queue.slice(1);
    overwritePath = "";
    error = pending?.error ?? "";
    return capture;
  }

  function confirm(path) {
    if (!pending || busy) return;
    target = path.trim().replace(/^~(?=\/|$)/, home);
    if (!target || !target.startsWith("/") || target.endsWith("/")) {
      edited();
      error = "Enter an absolute file path, including the file name";
      return;
    }
    const replace = target === overwritePath;
    error = "";
    operation = "save";
    busy = true;
    worker.command = ["python3", script, "save", pending.tmp, target].concat(replace ? ["replace"] : []);
    worker.running = true;
  }

  function dismiss() {
    if (!pending || busy) return;
    if (pending.kind === "video") {
      // Escape chooses the default path; it never confirms replacement.
      overwritePath = "";
      confirm(pending.path);
      return;
    }
    // On clipboard failure, keep the cached screenshot for recovery rather
    // than deleting the only remaining copy. Normal cache cleanup owns it.
    if (pending.copyFailed) { takeNext(); return; }
    edited();
    operation = "discard";
    busy = true;
    worker.command = ["python3", script, "discard", pending.tmp];
    worker.running = true;
  }

  Process {
    id: worker
    stdout: StdioCollector { id: output }
    onExited: code => {
      const result = Reply.parse(output.text, "capture.py");
      if (code === 0 && result.ok) {
        const capture = root.takeNext();
        const path = root.target;
        const saved = root.operation === "save";
        root.busy = false;
        if (saved) root.saved(capture, path);
      } else {
        root.overwritePath = result.exists ? root.target : "";
        root.error = result.exists ? "File already exists. Choose another path or press Replace."
          : result.error || "Could not save the capture";
        root.busy = false;
      }
    }
  }
}
