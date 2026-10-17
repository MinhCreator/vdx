pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.components
import qs.config
import qs.modules.battery

// Screen capture: the state of the overlay (CaptureOverlay) and the recording
// (CaptureRecording). Super+Shift+S calls `qs -c shell ipc call capture open`;
// while recording the same call stops it.
//
// Opening is staged so nothing flickers: `armed` creates the overlays, which
// grab a still of every screen with the pointer while still transparent. A
// Hyprland screen copy is the last frame it drew, software pointer included,
// so the pointer is hidden and every overlay redraws itself each frame, so
// Hyprland keeps recomposing. Hyprland applies the hiding late (next key
// event or a 500 ms tick), so each overlay checks its plain still where the
// pointer is and retakes it until the pointer is gone. When all are in, the
// pointer is back, `shown` makes the overlays opaque and, a frame later, open
// bar popups hide behind their own picture (PopupManager.frozen). Closing runs
// the other way round.
Singleton {
  id: root

  // ---- overlay ----
  property bool armed: false
  property bool shown: false
  property bool closing: false        // the dim fades out, then the overlay goes
  property int cursorStills: 0
  property int plainStills: 0
  property bool pointerHidden: false
  property bool redraw: false         // overlays redraw until their plain stills are in
  property bool plainCapture: false   // overlays take (and check) their plain stills
  // Hyprland windows on the shown workspaces, layout coordinates, topmost first:
  // [{x, y, width, height}]
  property var windows: []
  property point pointerAt: Qt.point(-1, -1)   // layout coordinates at open

  // ---- this capture ----
  property bool cursor: false         // the pointer in the shot / recording

  // ---- saved choices ----
  // the last picked, kept across restarts: a bar click can start it at once
  readonly property string mode: settings.mode          // region | window | screen
  readonly property string kind: settings.kind          // shot | record
  readonly property string audio: settings.audio        // off | system | mic
  readonly property int fps: settings.fps
  readonly property string quality: settings.quality    // low | medium | high
  // auto | igpu | gpu | cpu. Auto keeps the discrete GPU asleep on battery:
  // the recorder then sees only Mesa (the integrated GPU) and never loads NVIDIA.
  readonly property string encoder: settings.encoder
  readonly property string encoderInUse: encoder !== "auto" ? encoder : BatteryService.plugged ? "gpu" : "igpu"
  // auto | h264 | hevc. Auto is HEVC on the GPU and H.264 on the CPU (x264 has no HEVC here).
  // H.264 on the GPU tints the faint greys of a flat wallpaper; HEVC keeps them.
  readonly property string codec: settings.codec
  readonly property string codecInUse: encoderInUse === "cpu" ? "h264" : codec !== "auto" ? codec : "hevc"
  // the problems the codec and quality can cause here, most important first:
  // {title, text, warn}; Shell Manager lists them all, the panel shows codecNote
  readonly property var codecIssues: {
    const issues = [];
    if (codec === "hevc" && encoderInUse === "cpu")
      issues.push({ title: "CPU has no HEVC", text: "The CPU encoder writes H.264, so the choice does not apply.", warn: false });
    if (codecInUse === "h264" && (encoderInUse !== "cpu" || quality !== "high"))
      issues.push({ title: "Flat greys can tint", text: "Plain backgrounds may show coloured blocks. HEVC avoids it.", warn: true });
    if (codecInUse === "hevc" && quality === "low")
      issues.push({ title: "Low quality tints", text: "Even HEVC shows coloured blocks at Low. Use Medium or High.", warn: true });
    if (codecInUse === "hevc")
      issues.push({ title: "Not every player plays HEVC", text: "Firefox and some older players refuse it. H.264 plays anywhere.", warn: false });
    return issues;
  }
  // the first warning, else the first note; null when there is nothing to say
  readonly property var codecNote: codecIssues.find(i => i.warn) ?? codecIssues[0] ?? null

  // ---- recording ----
  readonly property bool recording: recorder.running
  property string recordFile: ""
  property real recordStarted: 0
  // gpu-screen-recorder presets behind the panel's Low / Medium / High
  readonly property var presets: ({ low: "medium", medium: "high", high: "very_high" })
  readonly property string mesaOnly: "/usr/share/glvnd/egl_vendor.d/50_mesa.json"

  // ---- output ----
  // folders from Shell Manager › Apps › Capture; empty: the defaults
  readonly property string shotDir: ModuleSettings.get("capture", "shotDir", "") || Quickshell.env("HOME") + "/Pictures/Screenshots"
  // after a shot: folder | ask (a Save as window) | clipboard (nothing on disk);
  // after a recording: folder | ask. Shell Manager › Apps › Capture, and the panel.
  readonly property string shotTarget: ModuleSettings.get("capture", "shotTarget", "folder")
  readonly property string videoTarget: ModuleSettings.get("capture", "videoTarget", "folder")
  readonly property string cacheDir: Quickshell.env("HOME") + "/.cache/quickshell-capture"
  // a capture waiting for its Save as answer: {kind: shot | video, tmp, path}
  property var pending: null
  property bool recordAsk: false      // the running recording waits for Save as
  readonly property string videoDir: ModuleSettings.get("capture", "videoDir", "") || Quickshell.env("HOME") + "/Videos/Recordings"

  function stamp() { return Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss"); }

  // Super+Shift+S, as Apps › Capture › Shortcut opens says:
  //   popup     — the panel from the focused bar's Capture module; with no module
  //               there, from the centre of that bar (CaptureFallback);
  //   else-last — the panel from the module; with no module there, the selection
  //               at once with the last picked mode;
  //   last      — the selection at once with the last picked mode, no panel.
  function open() {
    if (recording) { stopRecording(); return; }
    if (armed) return;
    const how = ModuleSettings.get("capture", "shortcut", "popup");
    if (how === "last") { startSelection(); return; }
    // the hub is open on the focused screen: the panel would replace it, so the
    // selection starts at once with the last mode and the hub stays in the still
    if (PopupManager.hubScreen !== "" && PopupManager.hubScreen === Hyprland.focusedMonitor?.name) { startSelection(); return; }
    panelHandled = false;
    panelRequested();
    if (panelHandled) return;
    if (how === "else-last") startSelection();
    else panelFallbackRequested();
  }

  // no bar's module answered: the focused bar's CaptureFallback shows the panel
  signal panelFallbackRequested();

  // the selection on screen, with the choices the panel holds
  function startSelection() {
    if (recording || armed) return;
    closing = false;
    cursorStills = 0;
    plainStills = 0;
    redraw = false;
    plainCapture = false;
    run(["sh", "-c", 'mkdir -p "$1" "$2"; find "$2" -name "Screenshot_*" -mmin +60 -delete', "sh", shotDir, cacheDir]);
    pointerAt = Qt.point(-1, -1);
    windowsProc.running = true;
    PopupManager.holding = true;
    armed = true;
  }

  // the focused bar's capture module answers by showing its panel
  property bool panelHandled: false
  signal panelRequested()

  function setPointerHidden(hidden) {
    pointerHidden = hidden;
    const command = ["hyprctl", "eval", "hl.config({cursor = {invisible = " + hidden + "}})"];
    if (hidden) {
      hideProc.command = command;
      hideProc.running = true;
    } else {
      run(command);
    }
  }

  // Every screen has its still with the pointer: hide it (hideProc goes on).
  function cursorStillReady() {
    cursorStills += 1;
    if (cursorStills < Quickshell.screens.length || !armed) return;
    setPointerHidden(true);
  }

  // Every screen has its plain still: the pointer is back, show the overlays.
  function plainStillReady() {
    plainStills += 1;
    if (plainStills < Quickshell.screens.length || !armed || shown) return;
    setPointerHidden(false);
    shown = true;
    freezeTimer.restart();
  }

  function close() {
    if (!armed || closing) return;
    closing = true;
    freezeTimer.stop();
    if (pointerHidden) setPointerHidden(false);
    PopupManager.frozen = false;
    closeTimer.restart();
  }

  function setMode(value) { settings.mode = value; }
  function setKind(value) { settings.kind = value; }
  function setAudio(value) { settings.audio = value; }
  function setFps(value) { settings.fps = value; }
  function setQuality(value) { settings.quality = value; }
  function setCursor(value) { cursor = value; }
  function setEncoder(value) { settings.encoder = value; }
  function setCodec(value) { settings.codec = value; }

  // where a new shot is written first: its folder, or the cache until Save as / never
  function shotPath() {
    return (shotTarget === "folder" ? shotDir : cacheDir) + "/Screenshot_" + stamp() + ".png";
  }

  // A cropped still from an overlay, already written to `path`; it always
  // goes to the clipboard, then to wherever shotTarget says.
  function shotSaved(path) {
    close();
    const copy = 'wl-copy --type image/png < "$1" && notify-send -a Capture -i "$1" "$2" "$3"';
    if (shotTarget === "ask") {
      run(["sh", "-c", 'wl-copy --type image/png < "$1"', "sh", path]);
      pending = { kind: "shot", tmp: path, path: shotDir + "/" + path.split("/").pop() };
    } else {
      run(["sh", "-c", copy, "sh", path, "Screenshot copied", shotTarget === "folder" ? path : "clipboard only"]);
    }
  }

  // Save as answered: move the capture there (a leading ~ is the home folder)
  function confirmSave(path) {
    if (!pending) return;
    const p = pending;
    pending = null;
    const target = path.trim().replace(/^~(?=\/|$)/, Quickshell.env("HOME"));
    run(["sh", "-c", 'mkdir -p "$(dirname "$2")" && mv "$1" "$2" && notify-send -a Capture "$3" "$2" || notify-send -a Capture -u critical "Could not save" "$2"',
         "sh", p.tmp, target, p.kind === "shot" ? "Screenshot saved" : "Recording saved"]);
  }

  // Save as dismissed: a shot stays on the clipboard only; a recording is
  // never thrown away — it goes to its default folder
  function dismissSave() {
    if (!pending) return;
    if (pending.kind === "shot") {
      run(["rm", "-f", pending.tmp]);
      pending = null;
    } else {
      confirmSave(pending.path);
    }
  }

  // rect in layout coordinates (logical pixels across all monitors);
  // gpu-screen-recorder scales them to the output itself
  function startRecording(rect) {
    close();
    recordAsk = videoTarget === "ask";
    const folder = recordAsk ? cacheDir : videoDir;
    const file = folder + "/Recording_" + stamp() + ".mp4";
    const args = ["gpu-screen-recorder", "-w", "region",
                  "-region", Math.round(rect.width) + "x" + Math.round(rect.height) + "+" + Math.round(rect.x) + "+" + Math.round(rect.y),
                  "-f", String(fps), "-q", presets[quality] ?? "high", "-cursor", cursor ? "yes" : "no",
                  "-ac", "aac", "-fallback-cpu-encoding", "yes", "-o", file];
    if (audio === "system") args.push("-a", "default_output");
    else if (audio === "mic") args.push("-a", "default_input");
    if (codecInUse === "hevc") args.push("-k", "hevc");
    if (encoderInUse === "cpu") args.push("-encoder", "cpu");
    if (encoderInUse === "igpu") args.unshift("env", "__EGL_VENDOR_LIBRARY_FILENAMES=" + mesaOnly);
    recordFile = file;
    // start after the overlay is gone, so it is not in the first frames
    recordStart.args = ["sh", "-c", 'mkdir -p "$1" && shift && exec "$@"', "sh", folder].concat(args);
    recordStart.restart();
  }

  function stopRecording() {
    if (recorder.running) recorder.signal(2);
  }

  function run(command) { Quickshell.execDetached(command); }

  function fail(title, message) {
    run(["notify-send", "-a", "Capture", "-u", "critical", title, message]);
  }

  // the pointer is hidden once hyprctl returns; then the overlays redraw
  Process {
    id: hideProc
    onExited: if (root.armed && !root.closing && root.pointerHidden) {
      root.redraw = true;
      root.plainCapture = true;
    }
  }

  Timer {
    id: freezeTimer
    interval: 32      // a couple of frames: the overlay is up before popups hide
    onTriggered: PopupManager.frozen = true
  }

  Timer {
    id: closeTimer
    interval: 180     // the fade-out; popups are back before the overlay goes
    onTriggered: {
      root.shown = false;
      root.armed = false;
      root.closing = false;
      PopupManager.holding = false;
    }
  }

  Timer {
    id: recordStart
    property var args: []
    interval: closeTimer.interval + 60   // after the overlay is gone, not while it fades
    onTriggered: {
      recorder.command = args;
      recorder.running = true;
      root.recordStarted = Date.now();
    }
  }

  // ---- hyprland windows ----
  Process {
    id: windowsProc
    command: ["sh", "-c", "hyprctl -j monitors; echo ---; hyprctl -j clients; echo ---; hyprctl -j cursorpos"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const [m, c, p] = text.split("---");
          const pos = JSON.parse(p);
          root.pointerAt = Qt.point(pos.x, pos.y);
          const monitors = JSON.parse(m);
          const shownWs = monitors.reduce((ids, x) => ids.concat([x.activeWorkspace?.id, x.specialWorkspace?.id]), []).filter(id => id);
          root.windows = JSON.parse(c)
            .filter(w => w.mapped && !w.hidden && shownWs.includes(w.workspace?.id))
            .sort((a, b) => a.focusHistoryID - b.focusHistoryID)
            .map(w => ({ x: w.at[0], y: w.at[1], width: w.size[0], height: w.size[1] }));
        } catch (e) {
          root.windows = [];
        }
      }
    }
  }

  // ---- recording ----
  Process {
    id: recorder
    stderr: StdioCollector { id: recorderErr }
    onExited: code => {
      if (root.recordFile === "") return;
      if (code === 0 || code === 130 || code === 2) {
        if (root.recordAsk)
          root.pending = { kind: "video", tmp: root.recordFile, path: root.videoDir + "/" + root.recordFile.split("/").pop() };
        else
          root.run(["notify-send", "-a", "Capture", "Recording saved", root.recordFile]);
      } else
        root.fail("Recording failed", recorderErr.text.trim().split("\n").pop() || "gpu-screen-recorder exited with " + code);
      root.recordFile = "";
    }
  }

  // ---- settings ----
  FileView {
    path: Quickshell.statePath("capture.json")
    printErrors: false
    onAdapterUpdated: writeAdapter()
    onLoadFailed: writeAdapter()

    JsonAdapter {
      id: settings
      property string mode: "region"
      property string kind: "shot"
      property string audio: "off"
      property int fps: 60
      property string quality: "medium"
      property string encoder: "auto"
      property string codec: "auto"
    }
  }

  IpcHandler {
    target: "capture"
    function open(): void { root.open(); }
    function stop(): void { root.stopRecording(); }
    function close(): void { root.close(); }
  }
}
