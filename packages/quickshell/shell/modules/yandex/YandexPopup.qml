import QtQuick
import qs.config
import qs.kit
import qs.modules.mpd

// Music (Yandex likes over MPD): the playing track or the queue. The app's
// button opens the same player as a window (Yandex Music).
KitFrame {
  id: root

  property string tab: "playing"

  signal openWindow()

  // ---- header ----
  KitHeader {
    icon: "music"
    iconColor: YandexService.active ? Theme.foreground0 : Theme.muted
    title: "Yandex Music"
    subtitle: !YandexService.active ? (MpdService.busy === "likes" ? "LOADING LIKES…" : "OFF")
      : (MpdService.playing ? "PLAYING" : "PAUSED") + " · " + MpdService.player.pos + " / " + MpdService.player.length

    KitButton {
      anchors.verticalCenter: parent.verticalCenter
      icon: "external"
      onClicked: {
        root.openWindow();
        YandexService.openApp();
      }
    }

    KitSwitch {
      anchors.verticalCenter: parent.verticalCenter
      checked: YandexService.active
      disabled: MpdService.busy === "likes"
      onToggled: YandexService.setActive(!YandexService.active)
    }
  }

  KitChoices {
    visible: YandexService.active
    model: [
      { label: "Now playing", value: "playing", icon: "music" },
      { label: "Queue (" + YandexService.queue.length + ")", value: "queue", icon: "list" }
    ]
    current: root.tab
    onPicked: value => root.tab = value
  }

  KitLine {}

  KitText {
    visible: !YandexService.active
    text: "Likes are not playing. Switch them on to start."
    color: Theme.muted
    font.pixelSize: Theme.fontSize - 1
  }

  YandexNowPlaying {
    visible: YandexService.active && root.tab === "playing"
  }

  YandexQueue {
    width: parent.width
    visible: YandexService.active && root.tab === "queue"
  }

  KitText {
    width: parent.width
    visible: MpdService.error !== ""
    text: MpdService.error
    color: Theme.red
    wrapMode: Text.WordWrap
    font.pixelSize: Theme.fontSize - 1
  }
}
