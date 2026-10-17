import QtQuick
import Quickshell
import qs.apps.cleaner
import qs.config
import qs.kit

// The cleaner in brief: what can go, by category (the system ones marked
// root), Clean safe — your caches, thumbnails and Trash at once — and a
// button to the full window for the rest and the AI mode.
KitFrame {
  id: root

  readonly property var cs: CleanerService
  property bool armed: false

  signal openWindow()

  function act() {
    if (cs.confirm && !armed) { armed = true; disarm.restart(); return; }
    armed = false;
    cs.cleanSafe();
  }

  Timer { id: disarm; interval: 3000; onTriggered: root.armed = false }

  KitHeader {
    icon: "brush"
    title: "Cleaner"
    subtitle: root.cs.categories.length === 0 ? "SCANNING…" : Format.shortSize(root.cs.total).toUpperCase() + " CAN GO"

    KitButton {
      icon: "external"
      onClicked: {
        root.openWindow();
        Quickshell.execDetached(["qs", "-c", "shell", "ipc", "call", "cleaner", "open"]);
      }
    }
  }

  KitLine {}

  Column {
    width: parent.width
    spacing: Theme.gapSmall

    KitLabel { text: "BIGGEST"; value: root.cs.scanning ? "SCANNING" : "" }

    Repeater {
      model: root.cs.categories.filter(c => c.size > 0).sort((a, b) => b.size - a.size).slice(0, ModuleSettings.get("cleaner", "biggest", 6))

      Item {
        required property var modelData

        width: parent.width
        height: 24

        KitText {
          anchors { left: parent.left; right: sizeText.left; rightMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }
          text: modelData.label
          elide: Text.ElideRight
          color: modelData.root ? Theme.foreground2 : Theme.foreground0
        }

        KitText {
          id: sizeText
          anchors { right: parent.right; verticalCenter: parent.verticalCenter }
          text: (modelData.root ? "root · " : "") + Format.shortSize(modelData.size)
          color: modelData.root ? Theme.muted : Theme.foreground2
        }
      }
    }
  }

  KitLine {}

  Item {
    width: parent.width
    height: cleanButton.height

    Column {
      anchors { left: parent.left; right: cleanButton.left; rightMargin: Theme.gapWide; verticalCenter: parent.verticalCenter }
      spacing: Theme.gapTight

      KitText {
        width: parent.width
        elide: Text.ElideRight
        font.weight: Font.ExtraBold
        text: Format.shortSize(root.cs.safeSize) + " safe to clean"
      }

      KitText {
        width: parent.width
        elide: Text.ElideRight
        font.pixelSize: Theme.fontSize - 2
        color: root.cs.status === "error" ? Theme.red : root.cs.status === "ok" ? Theme.green : Theme.muted
        text: root.cs.message !== "" ? root.cs.message : "caches, thumbnails, Trash"
      }
    }

    KitButton {
      id: cleanButton
      anchors { right: parent.right; verticalCenter: parent.verticalCenter }
      icon: root.armed ? "check" : "brush"
      text: root.armed ? "Sure?" : "Clean safe"
      selected: root.armed
      busy: root.cs.busy
      disabled: root.cs.safeSize <= 0
      onClicked: root.act()
    }
  }
}
