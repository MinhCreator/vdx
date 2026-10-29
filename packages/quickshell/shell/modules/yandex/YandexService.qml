pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.modules.mpd

// Yandex Music likes on top of MpdService: covers, library sync (yandex-music-cli)
// and likes (scripts/yandex.py). The music module, its popup and the Music app
// read MpdService for playback (and its queue) and this service for the rest.
Singleton {
  id: root

  // ---- tuning ----
  readonly property int coverSize: 64
  readonly property string script: Paths.scriptsDir + "/yandex.py"

  readonly property bool active: MpdService.source === "likes" && !MpdService.stopped

  property string cover: ""                    // file:// url of the cached cover
  property string parkedCover: ""              // and of the music a station put aside (MpdService.parkedTrack)

  property var liked: []                       // Yandex ids of liked tracks
  property var fileIds: ({})                   // file -> Yandex id (state.json)
  readonly property string trackId: fileIds[MpdService.file] ?? ""
  readonly property bool isLiked: liked.includes(trackId)
  onTrackIdChanged: refreshCover()          // also when the library map arrives after the file
  readonly property string parkedId: fileIds[MpdService.parkedTrack?.file ?? ""] ?? ""
  onParkedIdChanged: {
    parkedCover = "";
    if (parkedId === "") return;
    parkedCoverProc.command = ["uv", "run", "--script", root.script, "--cover", parkedId];
    parkedCoverProc.running = true;
  }
  // Yandex id -> file, for the tracks the library has downloaded (playable)
  readonly property var localIds: {
    const map = {};
    for (const file in fileIds) map[fileIds[file]] = file;
    return map;
  }

  property bool updating: false

  function popupShown() {
    MpdService.error = "";
    if (!likesProc.running) likesProc.running = true;
  }

  // the Music window refreshes the queue as it opens (see MpdService.refreshQueue)
  function setWindowOpen(on) { if (on) MpdService.refreshQueue(); }

  // the playing track's cover from Yandex Music (cached by yandex.py)
  function refreshCover() {
    cover = "";
    if (MpdService.source !== "likes" || trackId === "") return;
    coverProc.command = ["uv", "run", "--script", root.script, "--cover", trackId];
    coverProc.running = true;
  }

  function refreshLikes() {
    if (!likesProc.running) likesProc.running = true;
  }

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

  // The like of track `id` (the playing one when none is given). One at a time.
  function toggleLike(id) {
    const target = id || trackId;
    if (target === "" || likeProc.running) return;
    const like = !liked.includes(target);
    liked = like ? liked.concat(target) : liked.filter(i => i !== target);   // optimistic
    likeProc.command = ["uv", "run", "--script", root.script, like ? "--like" : "--unlike", target];
    likeProc.running = true;
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
    id: parkedCoverProc
    stdout: StdioCollector {
      onStreamFinished: {
        const o = MpdService.parse(text);
        root.parkedCover = o?.ok ? "file://" + o.path : "";
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
        // the queue is MPD's, built once: the new tracks join it here
        if (o?.ok && !rebuildProc.running) MpdService.run(rebuildProc, ["--likes-refresh"]);
        likesProc.running = true;
      }
    }
  }

  Process {
    id: rebuildProc
    stdout: StdioCollector {
      onStreamFinished: {
        const o = MpdService.parse(text);
        if (!o?.ok) MpdService.error = o?.error || "could not refresh the queue";
        MpdService.refreshQueue();
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
    command: ["uv", "run", "--script", root.script, "--likes"]
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
