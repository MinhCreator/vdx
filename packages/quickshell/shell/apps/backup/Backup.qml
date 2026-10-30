import QtQuick
import qs.config
import qs.kit

// The backups' content: a header with the three tabs (Overview, Snapshots,
// Setup), the page under it, and a foot with what the last action did — or
// the running backup, with its cancel.
Rectangle {
  id: root

  color: Theme.background0

  readonly property var bs: BackupService
  property string tab: bs.configured ? "overview" : "setup"

  // a shell part (the bar module's Guide button) asks for a tab
  Connections {
    target: BackupService
    function onTabRequestChanged() { if (BackupService.tabRequest !== "") root.tab = BackupService.tabRequest; }
  }

  function subtitle() {
    if (bs.loadError !== "") return "STATUS UNAVAILABLE";
    if (!bs.loaded) return "LOADING…";
    if (!bs.resticFound) return "RESTIC IS NOT INSTALLED";
    if (!bs.configured) return "NOT SET UP";
    return "LAST " + bs.agoText(bs.last?.ts).toUpperCase() + (bs.last && !bs.last.ok ? " · FAILED" : "");
  }

  // ---- header ----
  Column {
    id: head
    anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.windowPadding; topMargin: Theme.windowPadding - Theme.headerInset }
    spacing: Theme.sectionGap

    KitHeader {
      icon: "shield"
      title: "Backups"
      subtitle: root.subtitle()

      KitChoices {
        model: [{ label: "Overview", value: "overview" }, { label: "Snapshots", value: "snapshots" }, { label: "Setup", value: "setup" }, { label: "Restore", value: "restore" }]
        current: root.tab
        onPicked: value => root.tab = value
      }
    }

    KitLine {}
  }

  // ---- pages ----
  BackupOverview {
    anchors { left: parent.left; right: parent.right; top: head.bottom; bottom: foot.top; leftMargin: Theme.windowPadding; rightMargin: Theme.windowPadding; topMargin: Theme.gapGroup }
    visible: root.tab === "overview"
    onOpenSetup: root.tab = "setup"
  }

  BackupSnapshots {
    anchors { left: parent.left; right: parent.right; top: head.bottom; bottom: foot.top; leftMargin: Theme.windowPadding; rightMargin: Theme.windowPadding; topMargin: Theme.gapGroup }
    visible: root.tab === "snapshots"
  }

  BackupRestore {
    anchors { left: parent.left; right: parent.right; top: head.bottom; bottom: foot.top; leftMargin: Theme.windowPadding; rightMargin: Theme.windowPadding; topMargin: Theme.gapGroup }
    visible: root.tab === "restore"
  }

  BackupSetup {
    anchors { left: parent.left; right: parent.right; top: head.bottom; bottom: foot.top; leftMargin: Theme.windowPadding; rightMargin: Theme.windowPadding; topMargin: Theme.gapGroup }
    visible: root.tab === "setup"
  }

  // ---- foot ----
  Column {
    id: foot
    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Theme.windowPadding; bottomMargin: Theme.windowPadding }
    spacing: Theme.sectionGap

    KitLine {}

    Item {
      width: parent.width
      height: cancel.visible ? cancel.height : msg.implicitHeight

      KitText {
        id: msg
        anchors { left: parent.left; right: cancel.visible ? cancel.left : parent.right; rightMargin: Theme.gapWide; verticalCenter: parent.verticalCenter }
        elide: Text.ElideRight
        font.pixelSize: Theme.fontSize - 2
        color: root.bs.status === "error" ? Theme.red : root.bs.status === "ok" ? Theme.green : root.bs.loaded && !root.bs.resticFound ? Theme.yellow : Theme.muted
        text: root.bs.busy
          ? (root.bs.jobKind === "run" ? "Backing up · " + (root.bs.progress >= 0 ? root.bs.progress + "%" : "starting") : "Working…")
          : root.bs.message !== "" ? root.bs.message
          : root.bs.loaded && !root.bs.resticFound ? "restic is not installed: pacman -S restic"
          : "the last action's result shows here"
      }

      KitButton {
        width: Theme.buttonWidth
        id: cancel
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        visible: root.bs.busy && root.bs.jobKind === "run"
        text: "Cancel"
        onClicked: root.bs.cancel()
      }
    }
  }
}
