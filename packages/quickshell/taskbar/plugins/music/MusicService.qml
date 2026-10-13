pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.plugins.mpd

// Yandex Music likes on top of MpdService: the queue, covers, library sync
// (yandex-music-cli) and likes (yandex_likes.py). The bar module and the popup
// read MpdService for playback and this service for the rest.
Singleton {
  id: root

  readonly property bool active: MpdService.source === "likes" && !MpdService.stopped

  property var queue: []                       // [{pos, artist, title}]
  property string cover: ""                    // file:// url of the cached cover

  property var liked: []                       // Yandex ids of liked tracks
  property var fileIds: ({})                   // file -> Yandex id (state.json)
  readonly property string trackId: fileIds[MpdService.file] ?? ""
  readonly property bool isLiked: liked.includes(trackId)

  property bool popupOpen: false
  property bool updating: false
  property string updateStatus: ""             // "" | ok | error

  function popupShown() {
    popupOpen = true;
    MpdService.error = "";
    refreshQueue();
    if (!likesProc.running) likesProc.running = true;
  }

  function popupHidden() { popupOpen = false; }

  // Header switch: resume the likes queue, load it, or stop.
  function setActive(on) {
    if (!on) MpdService.stop();
    else if (MpdService.source === "likes") MpdService.play();
    else MpdService.load("likes", ["--likes"]);
  }

  function runUpdate() {
    if (updating) return;
    updating = true;
    updateStatus = "";
    MpdService.error = "";
    MpdService.run(updateProc, ["--update"]);
  }

  function toggleLike() {
    if (trackId === "" || likeProc.running) return;
    const id = trackId;
    const like = !isLiked;
    liked = like ? liked.concat(id) : liked.filter(i => i !== id);   // optimistic
    likeProc.command = ["uv", "run", "--script", Theme.likesScript, like ? "--like" : "--unlike", id];
    likeProc.running = true;
  }

  function refreshQueue() {
    if (popupOpen && !queueProc.running) MpdService.run(queueProc, ["--queue"]);
  }

  Connections {
    target: MpdService
    function onQueueChanged() { root.refreshQueue(); }
    function onFileChanged() {
      root.cover = "";
      if (MpdService.source === "likes") MpdService.run(coverProc, ["--cover", MpdService.file]);
    }
  }

  Timer {
    id: updateClear
    interval: Theme.popupStatusMs
    onTriggered: root.updateStatus = ""
  }

  Process {
    id: queueProc
    stdout: StdioCollector {
      onStreamFinished: root.queue = MpdService.parse(text) ?? []
    }
  }

  Process {
    id: coverProc
    stdout: StdioCollector {
      onStreamFinished: {
        const o = MpdService.parse(text);
        root.cover = o?.ok ? "file://" + o.path : "";
      }
    }
  }

  Process {
    id: updateProc
    stdout: StdioCollector {
      onStreamFinished: {
        const o = MpdService.parse(text);
        root.updating = false;
        root.updateStatus = o?.ok ? "ok" : "error";
        if (!o?.ok) MpdService.error = o?.error || "update failed";
        updateClear.restart();
        root.refreshQueue();
        likesProc.running = true;
      }
    }
  }

  Process {
    id: likesProc
    command: ["uv", "run", "--script", Theme.likesScript, "--likes"]
    stdout: StdioCollector {
      onStreamFinished: {
        const o = MpdService.parse(text);
        if (!o?.ok) return;
        root.liked = o.liked;
        root.fileIds = o.files;
      }
    }
  }

  Process {
    id: likeProc
    stdout: StdioCollector {
      onStreamFinished: {
        const o = MpdService.parse(text);
        if (o?.ok) return;
        MpdService.error = o?.error ?? "could not change the like";
        likesProc.running = true;               // roll back to the real state
      }
    }
  }
}
