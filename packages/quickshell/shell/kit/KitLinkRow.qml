import QtQuick
import Quickshell
import qs.config

// A setting kept on another Shell Manager page, shown where it is also looked
// for: the label names it, the hint says where it is (`In <Page> › <Group>`),
// Open goes there (`shell open <target>`, e.g. "notifications", "appearance:accent"),
// or into an app's window: `app` is its IPC target ("display" → `display toggle`).
KitRow {
  id: root

  property string target: ""
  property string app: ""

  KitButton {
    icon: "arrow-right"
    text: "Open"
    onClicked: Quickshell.execDetached(root.app !== ""
      ? ["qs", "-c", "shell", "ipc", "call", root.app, "toggle"]
      : ["qs", "-c", "shell", "ipc", "call", "shell", "open", root.target])
  }
}
