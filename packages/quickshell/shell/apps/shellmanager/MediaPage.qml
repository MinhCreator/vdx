import QtQuick
import qs.config
import qs.kit

// Media: what the shell does with the music — MPD pauses while another app
// plays sound (a video in the browser) and resumes once that sound stops.
// A group's one-line intro sits under its label; rows keep short hints.
Column {
  id: root

  // the window's fixed header shows these; the page under it scrolls
  readonly property string icon: "music"
  readonly property string title: "Media"
  readonly property string subtitle: "PAUSE ON OTHER SOUND · " + (ShellSettings.pauseMusic ? "ON" : "OFF")

  // one group only: no sidebar links
  readonly property var jumps: []

  spacing: 14

  KitLabel { text: "MUSIC" }

  KitText {
    width: parent.width
    color: Theme.muted
    font.pixelSize: Theme.fontSize - 2
    text: "Any player that reports playing over MPRIS: browsers, mpv, Spotify."
  }

  KitRow {
    label: "Pause on other sound"
    hint: "Pauses MPD while a player plays"

    KitSwitch {
      checked: ShellSettings.pauseMusic
      onToggled: ShellSettings.set("pauseMusic", !checked)
    }
  }

  KitRow {
    visible: ShellSettings.pauseMusic
    label: "Resume when it stops"
    hint: "Only music the shell paused"

    KitSwitch {
      checked: ShellSettings.resumeMusic
      onToggled: ShellSettings.set("resumeMusic", !checked)
    }
  }
}
