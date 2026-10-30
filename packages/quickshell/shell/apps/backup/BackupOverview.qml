import QtQuick
import qs.config
import qs.kit

// Overview: the last run, a backup now (with its progress), a check of the
// repository, what goes in and the timed runs. Before a repository is set,
// it is the three steps to the first backup.
Item {
  id: root

  signal openSettings()

  readonly property var bs: BackupService
  readonly property bool running: bs.busy && bs.jobKind === "run"
  readonly property bool timerOn: bs.config.schedule ? bs.config.schedule.mode !== "off" : false
  readonly property string scheduleText: !root.timerOn ? "Off, only when you press Back up"
    : (bs.config.schedule.mode === "weekly" ? "Every Monday" : "Every day") + " at " + bs.config.schedule.time

  // the steps show until the first backup exists
  readonly property bool guided: bs.loaded && (!bs.configured || !bs.last)

  function bytes(n) { return Format.humanSize(n); }

  function source(key) { return bs.config.sources ? bs.config.sources[key] === true : false; }

  Flickable {
    anchors.fill: parent
    bottomMargin: Theme.gapGroup
    contentHeight: column.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight + bottomMargin > height

    KitColumn {
      id: column
      width: parent.width
      spacing: Theme.sectionGap

      // ---- the first run: three steps, until a backup has been made ----
      KitLabel {
        visible: root.guided
        text: "GET STARTED"
        value: bs.configured ? "STEP 2 OF 3" : "STEP 1 OF 3"
      }

      KitRow {
        visible: root.guided
        label: bs.configured ? "1 · Place chosen" : "1 · Choose where to save"
        hint: bs.configured ? (bs.config.repo ?? "") : "Another disk or a NAS, not this computer's own disk"
        labelColor: bs.configured ? Theme.green : Theme.foreground0

        KitButton {
          width: Theme.buttonWidth
          anchors.verticalCenter: parent.verticalCenter
          visible: !bs.configured
          icon: "folder"
          text: "Choose…"
          busy: bs.busy && bs.jobKind === "pick"
          disabled: bs.busy
          onClicked: bs.pick()
        }
      }

      KitInput {
        visible: root.guided && !bs.configured
        placeholder: "or type a folder · sftp:user@host:/path · Enter sets it"
        onAccepted: bs.init(text.trim())
      }

      KitRow {
        visible: root.guided
        label: "2 · Keep the password"
        hint: bs.configured ? "Without it nothing can be restored: copy it somewhere safe" : "It is made for you in step 1"
        opacity: bs.configured ? 1 : 0.5

        KitButton {
          width: Theme.buttonWidth
          anchors.verticalCenter: parent.verticalCenter
          visible: bs.configured
          icon: bs.copied ? "check" : "clipboard"
          text: bs.copied ? "Copied" : "Copy"
          busy: bs.busy && bs.jobKind === "password"
          disabled: bs.busy
          onClicked: bs.revealed !== "" ? bs.copyPassword() : bs.showPassword()
        }
      }

      KitInput {
        visible: root.guided && bs.revealed !== ""
        text: bs.revealed
        input.readOnly: true
        input.font.pixelSize: Theme.fontSize - 1
      }

      KitRow {
        visible: root.guided
        label: "3 · Make the first backup"
        hint: bs.configured ? "Takes a while the first time" : "Once the place is chosen"
        opacity: bs.configured ? 1 : 0.5

        KitButton {
          width: Theme.buttonWidth
          anchors.verticalCenter: parent.verticalCenter
          icon: "download"
          text: "Back up"
          busy: root.running
          disabled: !bs.configured || bs.busy || !bs.resticFound
          onClicked: bs.runNow()
        }
      }

      KitLine { visible: root.guided && bs.configured }

      // ---- the last run and a backup now ----
      KitLabel {
        visible: bs.configured
        text: "LAST RUN"
        value: bs.last ? bs.agoText(bs.last.ts).toUpperCase() : "NEVER"
      }

      KitRow {
        visible: bs.configured
        label: bs.last ? (bs.last.ok ? "Saved" : "Failed") : "Not run yet"
        hint: bs.last ? bs.last.message + (bs.last.auto ? " · timed" : "") : "Back up once to see it here"
        labelColor: bs.last && !bs.last.ok ? Theme.red : Theme.foreground0
      }

      KitRow {
        visible: bs.configured
        label: "On disk"
        hint: bs.onDisk >= 0 ? root.bytes(bs.onDisk) + " for all snapshots together" : "counting…"
      }

      KitRow {
        visible: bs.configured
        label: "Restores to"
        hint: bs.restoreSize >= 0 ? root.bytes(bs.restoreSize) + " from the newest" : "counting…"
      }

      KitLine { visible: bs.configured }

      KitRow {
        visible: bs.configured
        label: "Back up now"
        hint: root.running ? "Backing up · " + (bs.progress >= 0 ? bs.progress + "%" : "starting") : "Everything below, once a root pass"

        KitButton {
          width: Theme.buttonWidth
          anchors.verticalCenter: parent.verticalCenter
          icon: "download"
          text: "Back up"
          busy: root.running
          disabled: bs.busy || !bs.resticFound
          onClicked: bs.runNow()
        }
      }

      KitRow {
        visible: bs.configured
        label: "Check the repository"
        hint: "Reads its index, not the data"

        KitButton {
          width: Theme.buttonWidth
          anchors.verticalCenter: parent.verticalCenter
          icon: "shield"
          text: "Check"
          busy: bs.busy && bs.jobKind === "verify"
          disabled: bs.busy
          onClicked: bs.verify(false)
        }
      }

      KitLine { visible: bs.configured }

      // ---- what goes in ----
      KitLabel {
        visible: bs.configured
        text: "WHAT GOES IN"
        value: [root.source("home"), root.source("etc"), root.source("packages"), root.source("root")].filter(on => on).length + " OF 4"
      }

      KitRow {
        visible: bs.configured
        label: "Home"
        hint: "Your files, without the caches"

        KitSwitch {
          anchors.verticalCenter: parent.verticalCenter
          checked: root.source("home")
          disabled: bs.busy
          onToggled: bs.setConfig({ "sources": { "home": !checked } })
        }
      }

      KitRow {
        visible: bs.configured
        label: "System config"
        hint: "/etc · root-only files are skipped"

        KitSwitch {
          anchors.verticalCenter: parent.verticalCenter
          checked: root.source("etc")
          disabled: bs.busy
          onToggled: bs.setConfig({ "sources": { "etc": !checked } })
        }
      }

      KitRow {
        visible: bs.configured
        label: "Root-only files"
        hint: "Wi-Fi, logins, Bluetooth · asks once"

        KitSwitch {
          anchors.verticalCenter: parent.verticalCenter
          checked: root.source("root")
          disabled: bs.busy
          onToggled: bs.setConfig({ "sources": { "root": !checked } })
        }
      }

      KitRow {
        visible: bs.configured
        label: "Packages and services"
        hint: "Pacman list, services, groups"

        KitSwitch {
          anchors.verticalCenter: parent.verticalCenter
          checked: root.source("packages")
          disabled: bs.busy
          onToggled: bs.setConfig({ "sources": { "packages": !checked } })
        }
      }

      KitLine { visible: bs.configured }

      KitRow {
        visible: bs.configured
        label: "Automatic"
        hint: root.scheduleText
      }

      KitGrouper {}
    }
  }
}
