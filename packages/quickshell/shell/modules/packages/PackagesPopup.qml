import QtQuick
import Quickshell
import qs.components
import qs.apps.packages
import qs.config
import qs.kit

// The package manager in brief: what is pending (the first few), Update all,
// Roll back the last upgrade, and a button to the full window.
KitFrame {
  id: root

  readonly property var ps: PackagesService
  readonly property var pending: ps.pacman.concat(ps.aur)

  signal openWindow()

  KitHeader {
    icon: "package"
    title: "Updates"
    subtitle: ps.stage === "downloading" ? "DOWNLOADING " + Math.round(ps.stagePercent * 100) + "%"
        : ps.stage === "installing" ? "INSTALLING"
        : ps.checking ? "CHECKING…" : ps.count > 0 ? ps.count + " PENDING" : "UP TO DATE"

    KitButton {
      icon: "external"
      onClicked: {
        root.openWindow();
        ShellIpc.call("packages", "open");
      }
    }
  }

  KitLine {}

  // the download, then the install: the green line runs along (full while installing)
  KitBar {
    visible: root.ps.stage !== ""
    value: root.ps.stage === "downloading" ? root.ps.stagePercent : 1
    tint: Theme.green
  }

  Column {
    width: parent.width
    spacing: Theme.gapSmall

    KitLabel { text: "PENDING"; value: root.ps.aurError !== "" ? "AUR UNAVAILABLE" : "" }

    Repeater {
      model: root.pending.slice(0, root.ps.opt("popupRows", 5))

      Item {
        required property var modelData

        width: parent.width
        height: 24

        KitText {
          anchors { left: parent.left; right: versions.left; rightMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }
          elide: Text.ElideRight
          text: modelData.name
        }

        KitText {
          id: versions
          anchors { right: parent.right; verticalCenter: parent.verticalCenter }
          text: modelData.to
          color: Theme.foreground2
        }
      }
    }

    KitText {
      visible: root.ps.count > root.ps.opt("popupRows", 5)
      color: Theme.muted
      text: "+ " + (root.ps.count - root.ps.opt("popupRows", 5)) + " more in the window"
    }

    KitText {
      visible: root.ps.count === 0 && !root.ps.checking
      color: Theme.muted
      text: "Nothing to update."
    }
  }

  KitLine {}

  KitRow {
    label: "Update all"
    hint: "Download, then install, in the panel"

    KitButton {
      anchors.verticalCenter: parent.verticalCenter
      icon: "download"
      text: "Update"
      disabled: root.ps.repoPending.length === 0 || root.ps.stage !== ""
      onClicked: root.ps.updateAll()
    }
  }

  KitRow {
    visible: root.ps.opt("popupRollback", true)
    label: "Roll back"
    hint: root.ps.rollbackCount > 0 ? root.ps.rollbackCount + " packages from the last upgrade"
        : "No upgrade in the log"

    KitButton {
      anchors.verticalCenter: parent.verticalCenter
      icon: "rotate-ccw"
      text: "Roll back"
      disabled: root.ps.rollbackCount === 0 || root.ps.busy
      onClicked: root.ps.rollbackLast()
    }
  }

  KitText {
    visible: root.ps.message !== ""
    width: parent.width
    elide: Text.ElideRight
    font.pixelSize: Theme.fontSize - 2
    color: root.ps.status === "error" ? Theme.red : root.ps.status === "ok" ? Theme.green : Theme.muted
    text: root.ps.message
  }
}
