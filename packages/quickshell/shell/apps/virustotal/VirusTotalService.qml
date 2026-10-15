pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// The VirusTotal lookup (scripts/virustotal.py), shared by its window and its
// bar module. Scan asks what VirusTotal knows about a hash, a URL or a file
// path; a file it has never seen goes up only when Upload is pressed. The
// last lookups are kept for the session.
Singleton {
  id: root

  readonly property string script: Theme.scriptsDir + "/virustotal.py"

  property string target: ""                // what was asked
  property bool busy: false
  property bool uploading: false            // the busy lookup is an upload
  property var result: null                 // the script's reply, known or not
  property string error: ""
  property var history: []                  // [{target, verdict}], newest first

  // "malicious" | "suspicious" | "clean" | "unknown" | ""
  readonly property string verdict: verdictOf(result)
  readonly property bool canUpload: !!result && !result.known && result.kind === "file"
                                    && result.target !== result.sha256

  function verdictOf(r) {
    if (!r) return "";
    if (!r.known) return "unknown";
    if (r.stats.malicious > 0) return "malicious";
    if (r.stats.suspicious > 0) return "suspicious";
    return "clean";
  }

  function verdictWord(v) {
    return ({ malicious: "MALICIOUS", suspicious: "SUSPICIOUS", clean: "CLEAN", unknown: "NOT SEEN BEFORE" })[v] ?? "NO SCAN YET";
  }

  function count(key) { return result?.stats?.[key] ?? 0; }

  function scan(text) {
    const t = text.trim();
    if (busy || t === "") return;
    target = t;
    busy = true;
    uploading = false;
    error = "";
    result = null;
    proc.command = ["python3", script, "scan", t];
    proc.running = true;
  }

  function upload() {
    if (busy || !canUpload) return;
    busy = true;
    uploading = true;
    error = "";
    proc.command = ["python3", script, "upload", result.target];
    proc.running = true;
  }

  function openLink() {
    if (result?.link) Quickshell.execDetached(["xdg-open", result.link]);
  }

  function parse(text) {
    try { return JSON.parse(text); } catch (e) { return { ok: false, error: "bad reply from virustotal.py" }; }
  }

  Process {
    id: proc
    stdout: StdioCollector {
      onStreamFinished: {
        const r = root.parse(text);
        root.busy = false;
        root.uploading = false;
        if (!r.ok) { root.error = r.error; return; }
        root.result = r;
        root.history = [{ target: r.target, verdict: root.verdictOf(r) }]
          .concat(root.history.filter(h => h.target !== r.target)).slice(0, 20);
      }
    }
  }
}
