import QtQuick
import Quickshell
import qs.config

// A setting kept on another Shell Manager page, shown where it is also looked
// for: the label names it, the hint says where it is (`In <Page> › <Group>`),
// Open goes there (`shell open <target>`, e.g. "notifications", "appearance:accent").
KitRow {
  id: root

  property string target: ""

  KitButton {
    icon: "arrow-right"
    text: "Open"
    onClicked: Quickshell.execDetached(["qs", "-c", "shell", "ipc", "call", "shell", "open", root.target])
  }
}
