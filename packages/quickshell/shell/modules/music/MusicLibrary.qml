import QtQuick
import Quickshell
import qs.bar
import qs.config
import qs.kit
import qs.modules.mpd
import qs.modules.radio
import qs.modules.yandex

// Quick picks as tiles, only the sources installed: Yandex Music's likes (one wide
// tile), the local folders of Modules › Music (a click plays the folder, recursively)
// and the favourite radio stations (starred in the Music window), two to a row.
// "Open Music" at the foot opens the window for the rest (playlists, every station).
Column {
  id: root

  signal openWindow()

  readonly property bool yandexOn: BarLayout.installed("yandex")
  readonly property bool filesOn: BarLayout.installed("files")
  readonly property bool radioOn: BarLayout.installed("radio")
  readonly property var folders: ModuleSettings.get("music", "folders", ["~/Music"])
  readonly property real half: Math.floor((width - Theme.gapMedium) / 2)

  // a folder's path with ~ as the home folder, and its name
  function home(path) { return path.replace(/^~(?=\/|$)/, Quickshell.env("HOME")); }
  function nameOf(path) { return path.split("/").filter(s => s !== "").pop() ?? path; }

  spacing: Theme.gapWide

  KitText {
    visible: !root.yandexOn && !root.filesOn && !root.radioOn
    width: parent.width
    text: "Install mpd to play music here"
    color: Theme.muted
    wrapMode: Text.WordWrap
    font.pixelSize: Theme.fontSize - 1
  }

  // ---- Yandex Music ----
  Column {
    visible: root.yandexOn
    width: parent.width
    spacing: Theme.gapMedium

    KitLabel { text: "YANDEX MUSIC" }

    MusicTile {
      width: parent.width
      icon: "heart-filled"
      iconTint: Theme.red
      text: "Likes"
      caption: YandexService.liked.length + " tracks"
      current: MpdService.source === "likes" && !MpdService.stopped
      busy: MpdService.busy === "likes"
      onClicked: if (!current) MpdService.load("likes", ["--likes"])
    }
  }

  // ---- files ----
  Column {
    visible: root.filesOn
    width: parent.width
    spacing: Theme.gapMedium

    KitLabel { text: "FILES" }

    KitText {
      visible: root.folders.length === 0
      width: parent.width
      text: "No folders. Add some in Modules › Music."
      color: Theme.muted
      wrapMode: Text.WordWrap
      font.pixelSize: Theme.fontSize - 1
    }

    Flow {
      width: parent.width
      spacing: Theme.gapMedium

      Repeater {
        model: root.filesOn ? root.folders : []

        MusicTile {
          required property var modelData
          readonly property string path: root.home(modelData)
          width: root.half
          icon: "folder"
          text: root.nameOf(path)
          caption: "Folder"
          current: MpdService.source === "files" && !MpdService.stopped && MpdService.file.startsWith(path + "/")
          busy: MpdService.busy === path
          onClicked: if (!current) MpdService.playFolder(path)
        }
      }
    }
  }

  // ---- radio: the favourites ----
  Column {
    visible: root.radioOn
    width: parent.width
    spacing: Theme.gapMedium

    KitLabel {
      text: "RADIO"
      value: RadioService.favoriteStations.length > 0 ? "FAVOURITES" : ""
    }

    KitText {
      visible: RadioService.favoriteStations.length === 0
      width: parent.width
      text: "Star stations in the Music window"
      color: Theme.muted
      wrapMode: Text.WordWrap
      font.pixelSize: Theme.fontSize - 1
    }

    Flow {
      width: parent.width
      spacing: Theme.gapMedium

      Repeater {
        model: root.radioOn ? RadioService.favoriteStations : []

        MusicTile {
          required property var modelData
          width: root.half
          icon: "radio"
          text: modelData.name
          caption: modelData.genre ?? ""
          current: RadioService.active && RadioService.stationKey === modelData.key
          busy: MpdService.busy === modelData.key
          onClicked: if (!current) RadioService.play(modelData.key)
        }
      }
    }
  }

  KitButton {
    visible: root.yandexOn || root.filesOn || root.radioOn
    width: parent.width
    icon: "external"
    text: "Open Music"
    onClicked: root.openWindow()
  }
}
