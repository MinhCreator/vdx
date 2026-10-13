import QtQuick
import qs.components
import qs.config

// Mute button, volume slider and percentage for one Pipewire node.
PopupSliderRow {
  id: root

  property var node: null
  property string icon: Theme.iconVolume
  property string mutedIcon: Theme.iconMuted

  readonly property var audio: node?.audio ?? null
  readonly property bool muted: audio?.muted ?? false

  enabled: !!audio
  clickable: true
  glyph: muted ? mutedIcon : icon
  glyphTint: muted ? Theme.red : Theme.foreground0
  value: audio?.volume ?? 0
  text: audio ? Math.round(audio.volume * 100) + "%" : "—"
  dimmed: muted
  onMoved: value => AudioService.setVolume(node, value)
  onIconClicked: AudioService.toggleMute(node)
}
