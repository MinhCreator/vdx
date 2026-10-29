import QtQuick
import Quickshell.Io
import "../../kit/reply.js" as Reply

// File mutations run in order: unlike a directory refresh, no queued copy,
// rename or delete may be replaced by a newer request. Each process gets a
// fresh reply and job; completion runs before the next request is started.
Process {
  id: root

  required property string script
  property var requests: []
  property var asked: null
  property var reply: null
  property var job: null
  property bool cancelling: false
  property bool settling: false
  property bool inFlight: false
  readonly property bool busy: inFlight || settling || requests.length > 0
  readonly property var labels: ({ trashed: "Trashing", pasted: "Copying", moved: "Moving", deleted: "Deleting",
    restored: "Restoring", renamed: "Renaming", created: "Creating", emptied: "Emptying" })

  signal finished(var result, var request, bool cancelled)

  function submit(request, args) {
    requests = requests.concat([{ asked: request, args: args.slice() }]);
    advance();
  }

  function advance() {
    if (inFlight || settling || !requests.length) return;
    const next = requests[0];
    // Keep busy true while transferring a queued request to the process.
    settling = true;
    inFlight = true;
    requests = requests.slice(1);
    asked = next.asked;
    reply = null;
    cancelling = false;
    job = { label: labels[asked.done] ?? "Working", progress: 0, of: next.args.length - 1, name: "" };
    command = ["python3", script].concat(next.args);
    running = true;
    settling = false;
  }

  function cancel() {
    if (!running) return;
    cancelling = true;
    running = false;
  }

  stdout: SplitParser {
    onRead: line => {
      if (!line.trim()) return;
      const result = Reply.parse(line, "files.py");
      if (result.progress !== undefined) {
        if (root.job) root.job = { label: root.job.label, progress: result.progress, of: result.of, name: result.name };
      } else root.reply = result;
    }
  }

  onExited: code => {
    settling = true;
    inFlight = false;
    let result = reply ?? { ok: false, error: "no answer from files.py" };
    if (code !== 0 && result.ok) result = Object.assign({}, result, { ok: false, error: "files.py exited with " + code });
    job = null;
    finished(result, asked, cancelling);
    cancelling = false;
    Qt.callLater(() => { root.settling = false; root.advance(); });
  }
}
