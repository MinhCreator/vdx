pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import "../../kit/reply.js" as Reply

// The VirusTotal lookup (scripts/virustotal.py), shared by its window and its
// bar module. Scan asks what VirusTotal knows about a hash, a URL or a file
// path; a file it has never seen goes up only when Upload is pressed. Recent
// lookups are kept for the window, and between runs when the option is on.
// Options: Shell Manager › Shell apps (ModuleSettings "virustotal").
Singleton {
  id: root

  readonly property string script: Theme.scriptsDir + "/virustotal.py"

  // ---- options ----
  function opt(key, fallback) { return ModuleSettings.get("virustotal", key, fallback); }
  readonly property int historyKeep: opt("historyKeep", 20)
  readonly property bool keepHistory: opt("keepHistory", false)
  readonly property int waitSeconds: opt("waitSeconds", 90)
  readonly property string reportAction: opt("reportAction", "browser")
  readonly property bool clipboardOn: opt("clipboard", false)

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
    proc.command = ["python3", script, "scan", t, String(waitSeconds)];
    proc.running = true;
  }

  function upload() {
    if (busy || !canUpload) return;
    busy = true;
    uploading = true;
    error = "";
    proc.command = ["python3", script, "upload", result.target, String(waitSeconds)];
    proc.running = true;
  }

  // the report: the browser, or the link copied to the clipboard
  function openLink() {
    if (!result?.link) return;
    if (reportAction === "copy") Quickshell.execDetached(["wl-copy", result.link]);
    else Quickshell.execDetached(["xdg-open", result.link]);
  }

  // the clipboard's text, if it is a hash or a URL, goes into the popup's
  // field (never scanned by itself): `into` is the field's owner, prefill(text)
  property var into: null
  function readClipboard(owner) {
    into = owner;
    clipProc.running = true;
  }

  function parse(text) {
    return Reply.parse(text, "virustotal.py");
  }

  // the history: newest first, the option's length; written only when kept
  onKeepHistoryChanged: persist()

  function persist() {
    state.history = keepHistory ? history : [];
    stateFile.writeAdapter();
  }

  function remember(r) {
    history = [{ target: r.target, verdict: verdictOf(r) }]
      .concat(history.filter(h => h.target !== r.target)).slice(0, historyKeep);
    persist();
  }

  FileView {
    id: stateFile
    path: Quickshell.statePath("virustotal.json")
    printErrors: false
    onLoaded: if (root.keepHistory) root.history = state.history.slice(0, root.historyKeep)
    onLoadFailed: stateFile.writeAdapter()

    JsonAdapter {
      id: state
      property var history: []
    }
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
        root.remember(r);
      }
    }
  }

  // the clipboard: a hash (64 hex digits) or an http(s) URL
  Process {
    id: clipProc
    command: ["wl-paste", "--no-newline"]
    stdout: StdioCollector {
      onStreamFinished: {
        const t = text.trim();
        if (root.into && (/^[0-9a-fA-F]{64}$/.test(t) || /^https?:\/\/\S+$/i.test(t)))
          root.into.prefill(t);
      }
    }
  }
}
