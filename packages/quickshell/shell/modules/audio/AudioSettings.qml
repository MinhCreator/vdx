import QtQuick
import qs.config
import qs.kit

// Audio options in the Shell Manager: the bar's volume, then the music that
// AudioPause.qml pauses while another app plays sound (the shell's own
// options, kept in ShellSettings).
Column {
  spacing: 14

  KitLabel { text: "BAR" }

  KitToggleRow { module: "audio"; key: "percent"; label: "Volume in the bar"; hint: "Off: the icon alone" }

  KitLine {}

  KitLabel { text: "MUSIC" }

  KitText {
    width: parent.width
    wrapMode: Text.WordWrap
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
