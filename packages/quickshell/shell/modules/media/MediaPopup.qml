import QtQuick
import qs.config
import qs.kit
import qs.modules.music
import qs.modules.player

// Media: what plays in other apps (MPRIS). The same track card as the music
// popup, for the app picked here; several apps: a list of them at the foot.
KitFrame {
  id: root

  readonly property var media: PlayerService.media

  KitHeader {
    icon: "play"
    iconColor: root.media.hasMedia ? Theme.foreground0 : Theme.muted
    title: "Media"
    subtitle: !root.media.hasMedia ? "NOTHING PLAYING"
      : (root.media.playing ? "PLAYING" : "PAUSED") + " · " + root.media.name.toUpperCase()
  }

  KitLine {}

  MusicNowPlaying {
    player: root.media
    emptyPlayer: false
    emptyText: "Nothing is playing in other apps."
  }

  // several apps: the one to show
  KitSelect {
    visible: PlayerService.externals.length > 1
    width: parent.width
    boxWidth: width
    model: PlayerService.externals.map(s => ({ label: s.name, value: s.key, note: s.playing ? "playing" : "" }))
    current: PlayerService.mediaSource?.key ?? ""
    onPicked: value => PlayerService.mediaPicked = value
  }
}
