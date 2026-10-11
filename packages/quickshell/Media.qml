import QtQuick
import Quickshell
import Quickshell.Io

// custom/media_title (gruvbox): JSON exec `media.sh --listen` (one line per
// MPD event), max-length 60, color gray (media.css).
//   on-click       -> media.sh --toggle
//   on-click-right -> kitty --class ncmpcpp -e ncmpcpp

Item {
  id: root

  property string rawText: ""

  // waybar sets max-length + Pango ELLIPSIZE_END: text longer than 60 chars is
  // shown as the first 59 chars plus a trailing ellipsis.
  readonly property string label: root.rawText.length > Theme.mediaMaxLength
      ? root.rawText.slice(0, Theme.mediaMaxLength - 1) + Theme.ellipsis
      : root.rawText

  Text {
    id: labelText
    text: root.label
    color: Theme.gray
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.weight: Theme.fontWeight
    verticalAlignment: Text.AlignVCenter
  }

  implicitWidth: labelText.implicitWidth
  implicitHeight: labelText.implicitHeight

  Process {
    id: mediaProc
    command: ["bash", Theme.mediaScript, "--listen"]
    running: true

    stdout: SplitParser {
      onRead: (data) => {
        data = data.trim()
        if (data === "") return
        try {
          const obj = JSON.parse(data)
          root.rawText = obj.text !== undefined ? obj.text : ""
        } catch (e) {
          // ignore non-json output
        }
      }
    }

    stderr: SplitParser {
      onRead: (data) => console.warn("media.sh:", data)
    }

    onExited: restartTimer.start() // waybar restart-interval: 5
  }

  Timer {
    id: restartTimer
    interval: Theme.mediaRestartMs
    onTriggered: mediaProc.running = true
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor // waybar: HAND2 when the module has events
    onClicked: (mouse) => {
      if (mouse.button === Qt.RightButton)
        Quickshell.execDetached(["kitty", "--class", "ncmpcpp", "-e", "ncmpcpp"])
      else
        Quickshell.execDetached(["bash", Theme.mediaScript, "--toggle"])
    }
  }
}