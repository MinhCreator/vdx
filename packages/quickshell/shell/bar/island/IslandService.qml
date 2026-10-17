pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.components
import qs.config
import qs.modules.audio
import qs.modules.brightness
import qs.modules.mpd
import qs.modules.music
import qs.modules.notifications

// What the island shows, for every bar's island (Bar › Style island): the
// track (MPD first, else an MPRIS player), passing flashes (a volume or
// brightness change, a new notification) and the power actions. The wave is
// the Equalizer module's.
// Each island keeps its own view; this only tells them what happened.
//
// IPC: `qs -c shell ipc call island hub|media|power|collapse` (the focused
// monitor's island answers).
Singleton {
  id: root

  // ---- tuning ----
  readonly property int osdMs: 1600            // a volume / brightness flash
  readonly property int noticeMs: 5000         // a notification flash
  readonly property int quietStartMs: 3000     // values read at startup are not news

  // a flash: "osd" or "notice"; `requested`: a view asked for over IPC
  signal flashed(string kind, int ms)
  signal requested(string view, string screen)

  property bool ready: false
  Timer { running: true; interval: root.quietStartMs; onTriggered: root.ready = true }

  // ---- media ----
  readonly property bool mpd: !MpdService.stopped
  readonly property var mpris: {
    const list = Mpris.players.values;
    return list.find(p => p.isPlaying) ?? list[0] ?? null;
  }
  readonly property bool hasMedia: mpd || mpris !== null
  readonly property bool playing: mpd ? MpdService.playing : (mpris?.isPlaying ?? false)
  readonly property bool radio: mpd && MpdService.source === "radio"
  readonly property string title: mpd ? (MpdService.player.title || MpdService.player.station
                                         || MpdService.file.split("/").pop())
                                      : (mpris?.trackTitle ?? "")
  readonly property string artist: mpd ? (radio ? MpdService.player.station : MpdService.player.artist)
                                       : (mpris?.trackArtist ?? "")
  readonly property string cover: mpd ? MusicService.cover : (mpris?.trackArtUrl ?? "")
  readonly property real position: mpd ? MpdService.elapsed : (mpris?.position ?? 0)
  readonly property real length: mpd ? MpdService.duration : (mpris?.length ?? 0)

  function togglePlay() {
    if (mpd) MpdService.toggle();
    else if (mpris?.canTogglePlaying) mpris.togglePlaying();
    else MusicService.setActive(true);          // nothing queued: the likes
  }
  function next() { if (mpd) MpdService.next(); else if (mpris?.canGoNext) mpris.next(); }
  function prev() { if (mpd) MpdService.prev(); else if (mpris?.canGoPrevious) mpris.previous(); }
  function seek(fraction) {
    if (length <= 0) return;
    if (mpd) MpdService.seek(fraction);
    else if (mpris?.canSeek) mpris.position = fraction * length;
  }

  // an MPRIS position is read, not pushed: ask for it while playing
  Timer {
    running: !root.mpd && root.playing
    interval: 1000
    repeat: true
    onTriggered: root.mpris?.positionChanged()
  }

  // ---- osd ----
  property string osdKind: ""                  // volume | brightness
  readonly property real osdLevel: osdKind === "volume" ? AudioService.volume / 100 : BrightnessService.brightness / 100
  readonly property bool osdMuted: osdKind === "volume" && AudioService.muted
  readonly property string osdIcon: osdKind === "brightness" ? "sun" : osdMuted || AudioService.volume === 0 ? "volume-x" : "volume"

  function osd(kind) {
    if (!ready) return;
    // a volume change made in the open volume popup shows in the popup, not as a flash
    if (kind === "volume" && PopupManager.current?.ipcTarget === "audio") return;
    osdKind = kind;
    flashed("osd", osdMs);
  }

  Connections {
    target: AudioService
    function onVolumeChanged() { root.osd("volume"); }
    function onMutedChanged() { root.osd("volume"); }
  }
  Connections {
    target: BrightnessService
    function onBrightnessChanged() { root.osd("brightness"); }
  }

  // ---- notice ----
  readonly property int noticeMax: 3         // notices stacked at once, newest on top
  property var notices: []                     // [{key, app, summary, body, urgency, time}]
  property int noticeMore: 0                   // fresh ones past the stack: "N more notifications"
  property real noticeTime: 0                 // the newest one taken: later ones are news

  Connections {
    target: NotificationsService
    function onItemsChanged() {
      if (!root.ready) return;
      const now = Date.now();
      const fresh = NotificationsService.items.filter(n => n.time > root.noticeTime && now - n.time <= 10000);
      if (fresh.length === 0) return;
      root.noticeTime = fresh[0].time;
      root.notices = fresh.concat(root.notices).slice(0, root.noticeMax);
      root.noticeMore = Math.max(0, fresh.length - root.noticeMax);
      const critical = fresh.some(n => n.urgency === "critical");
      root.flashed("notice", critical ? root.noticeMs * 2 : root.noticeMs);
    }
  }

  function dismissNotice(key) {
    root.notices = root.notices.filter(n => n.key !== key);
    if (root.notices.length === 0) {
      root.noticeMore = 0;
      // closed on the island: no unseen dot left behind on the compact island
      NotificationsService.markSeen();
    }
  }

  // mako's `island` mode (themes/*/mako/config) keeps notifications off screen
  // while the island shows them; they still reach its history
  readonly property bool island: Theme.island
  onIslandChanged: makoMode()
  Component.onCompleted: makoMode()
  function makoMode() {
    Quickshell.execDetached(["makoctl", "mode", island ? "-a" : "-r", "island"]);
  }

  function openNotifications() {
    Quickshell.execDetached(["qs", "-c", "shell", "ipc", "call", "notifications", "toggle"]);
  }

  // ---- power ----
  readonly property var powerActions: [
    { id: "poweroff",  icon: "power",      label: "Power off", confirm: true },
    { id: "reboot",    icon: "refresh",    label: "Reboot",    confirm: true },
    { id: "lock",      icon: "lock",       label: "Lock",      confirm: false },
    { id: "hibernate", icon: "info",       label: "Hibernate", confirm: true },
    { id: "suspend",   icon: "moon",       label: "Suspend",   confirm: false }
  ]

  function power(action) {
    if (action === "lock") Quickshell.execDetached(["qs", "-c", "shell", "ipc", "call", "lock", "lock"]);
    else if (action === "suspend") Quickshell.execDetached(["sh", "-c", "qs -c shell ipc call lock lock; sleep 0.5; systemctl suspend"]);
    else Quickshell.execDetached(["systemctl", action]);
  }

  IpcHandler {
    target: "island"
    enabled: Theme.island
    function hub(): void { root.requested("hub", Hyprland.focusedMonitor?.name ?? ""); }
    function media(): void { root.requested("media", Hyprland.focusedMonitor?.name ?? ""); }
    function power(): void { root.requested("power", Hyprland.focusedMonitor?.name ?? ""); }
    function collapse(): void { root.requested("compact", ""); }
  }
}
