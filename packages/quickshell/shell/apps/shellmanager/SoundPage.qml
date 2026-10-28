import QtQuick
import qs.config
import qs.kit

// Sound: what the shell does with sound. For now the music that pauses while another app
// plays sound (it was Bar modules › Audio › AUTO-PAUSE, same keys); the volume itself
// is the Audio bar module's popup.
Column {
  id: root
  readonly property Item previewItem: null

  readonly property string icon: "volume"
  readonly property string title: "Sound"
  readonly property string description: "What the shell does with sound."
  readonly property string subtitle: ShellSettings.pauseMusic ? "MUSIC PAUSES FOR OTHER SOUND" : "MUSIC KEEPS PLAYING"
  readonly property var jumps: []

  readonly property var resetKeys: ["pauseMusic", "resumeMusic"]
  readonly property bool changed: ShellSettings.changed(resetKeys)
  function reset() { ShellSettings.reset(resetKeys); }

  KitLabel { text: "MUSIC"; about: "Any player that reports playing over MPRIS counts: browsers, mpv, Spotify" }

  KitRow {
    label: "Pause on other sound"
    hint: "Pauses the local music (MPD) while another app plays"

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

  KitGrouper {}
}
