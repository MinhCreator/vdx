pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.modules.mpd

// Yandex Music likes on top of MpdService: the queue, covers, library sync
// (yandex-music-cli) and likes (yandex_likes.py). The bar module and the popup
// read MpdService for playback and this service for the rest.
Singleton {
  id: root

  // ---- tuning ----
  readonly property int coverSize: 64
  readonly property int upNext: 9  // queue rows visible before scrolling
  readonly property string likesScript: Paths.scriptsDir + "/yandex_likes.py"

  readonly property bool active: MpdService.source === "likes" && !MpdService.stopped

  property var queue: []                       // [{pos, artist, title}]
  property string cover: ""                    // file:// url of the cached cover

  property var liked: []                       // Yandex ids of liked tracks
  property var fileIds: ({})                   // file -> Yandex id (state.json)
  readonly property string trackId: fileIds[MpdService.file] ?? ""
  readonly property bool isLiked: liked.includes(trackId)

  property bool popupOpen: false
  property bool updating: false

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
    MpdService.error = "";
    MpdService.run(updateProc, ["--update"]);
  }

  function toggleLike() {
    if (trackId === "" || likeProc.running) return;
    const id = trackId;
    const like = !isLiked;
    liked = like ? liked.concat(id) : liked.filter(i => i !== id);   // optimistic
    likeProc.command = ["uv", "run", "--script", root.likesScript, like ? "--like" : "--unlike", id];
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
        if (!o?.ok) MpdService.error = o?.error || "update failed";
        root.refreshQueue();
        likesProc.running = true;
      }
    }
  }

  // file -> id straight from yandex-music-cli's state.json: known at once and
  // without the network, so the like button shows for every library track
  FileView {
    path: Quickshell.env("HOME") + "/.config/scripts/yandex-music/state.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try {
        const ids = JSON.parse(text()).ids ?? {};
        const map = {};
        for (const id in ids) map[ids[id].file] = id;
        root.fileIds = map;
      } catch (e) {}
    }
  }

  // the last known likes, so the heart is right before the network answers
  FileView {
    path: Quickshell.statePath("music-likes.json")
    printErrors: false
    onAdapterUpdated: writeAdapter()
    onLoaded: if (root.liked.length === 0) root.liked = likedCache.liked

    JsonAdapter {
      id: likedCache
      property var liked: []
    }
  }

  Process {
    id: likesProc
    command: ["uv", "run", "--script", root.likesScript, "--likes"]
    stdout: StdioCollector {
      onStreamFinished: {
        const o = MpdService.parse(text);
        if (!o?.ok) return;
        root.liked = o.liked;
        root.fileIds = o.files;
        likedCache.liked = o.liked;
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
