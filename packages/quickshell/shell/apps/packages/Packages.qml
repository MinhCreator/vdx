import QtQuick
import qs.config
import qs.kit

// The package manager, three tabs, each a list under a toolbar or a header:
//   UPDATES    every pending update with a short description; boxes pick
//              which to install (Select all first), Update picked or all.
//   INSTALLED  one toolbar: search, the type of package, the order; boxes pick
//              what to remove with pacman -Rns.
//   CACHE      the last upgrade as one block to roll back, then the cached
//              versions (old ones by default), each with its own Roll back.
Rectangle {
  id: root

  color: Theme.background0

  readonly property var ps: PackagesService
  property string tab: "updates"

  // installed
  property string filter: "all"             // all | apps | repo | aur
  property string sortBy: PackagesService.opt("sortBy", "name")   // name | size | date; the option is the start
  readonly property string query: field.text.trim().toLowerCase()
  readonly property var shown: ps.installed.filter(p =>
      (filter === "all" || (filter === "apps" && p.apps.length > 0)
       || (filter === "repo" && !p.aur) || (filter === "aur" && p.aur))
      && (query === "" || p.name.toLowerCase().includes(query) || p.desc.toLowerCase().includes(query)
          || p.apps.some(a => a.toLowerCase().includes(query))))
      .sort((a, b) => sortBy === "size" ? b.size - a.size
                    : sortBy === "date" ? b.date - a.date
                    : a.name.localeCompare(b.name))
  readonly property int shownPicked: shown.filter(p => ps.picked[p.name] === true).length

  // cache
  property string cacheView: PackagesService.opt("cacheView", "old")   // old | all
  readonly property var cacheRows: {
    const out = [];
    for (const g of ps.cache)
      for (const v of g.versions)
        if (cacheView === "all" || v.version !== g.installed)
          out.push({ name: g.name, installed: g.installed, version: v.version, file: v.file, size: v.size, date: v.date });
    return out.sort((a, b) => a.name.localeCompare(b.name) || b.date - a.date);
  }
  readonly property real cacheSize: cacheRows.reduce((s, r) => s + r.size, 0)

  // the uninstall button asks once more, like the cleaner's
  property bool armed: false
  onTabChanged: armed = false

  Timer { id: disarm; interval: 3000; onTriggered: root.armed = false }

  // list columns: name + hint (hint() keeps it to ~36 chars), source,
  // version (takes what is left, so no gap opens in the middle), size
  readonly property int nameWidth: 250
  readonly property int sourceWidth: 72
  readonly property int sizeWidth: 90
  readonly property real versionWidth: list.width - 28 - nameWidth - 12 - sourceWidth - sizeWidth - 16

  // where a package comes from: its repo (core, extra, …) or AUR
  function source(p) {
    return p.aur ? "AUR" : (p.repo || "—");
  }

  // a row's hint, per the shell's rules: sentence case, no full stop, short
  function hint(text) {
    let t = (text ?? "").trim().replace(/\.$/, "");
    if (t === "") return "";
    t = t.charAt(0).toUpperCase() + t.slice(1);
    return t.length > 36 ? t.slice(0, 35).replace(/\s+\S*$/, "") + "…" : t;
  }

  function day(epoch) { return Qt.formatDate(new Date(epoch * 1000), "yyyy-MM-dd"); }

  function uninstall() {
    if (ps.pickedNames.length === 0) return;
    if (ps.confirm && !armed) { armed = true; disarm.restart(); return; }
    armed = false;
    ps.removePicked();
  }

  function subtitle() {
    if (tab === "installed")
      return shown.length + " OF " + ps.installed.length + " SHOWN · " + Theme.shortSize(ps.installed.reduce((s, p) => s + p.size, 0)) + " INSTALLED";
    if (tab === "cache") return ps.cache.length + " PACKAGES CACHED";
    if (ps.checking) return "CHECKING…";
    return ps.count > 0 ? ps.count + " UPDATES · " + ps.pickedUpdates.length + " PICKED" : "UP TO DATE";
  }

  // ---- header ----
  Column {
    id: head
    anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.windowPadding; topMargin: Theme.windowPadding - Theme.headerInset }
    spacing: Theme.gapGroup

    KitHeader {
      icon: "package"
      title: "Packages"
      subtitle: root.subtitle()

      KitChoices {
        model: [
          { label: "Updates", value: "updates", icon: "download" },
          { label: "Installed", value: "installed", icon: "list" },
          { label: "Cache", value: "cache", icon: "folder" }
        ]
        current: root.tab
        onPicked: value => root.tab = value
      }

      KitButton {
        icon: "refresh"
        busy: root.ps.checking || root.ps.loading
        onClicked: root.ps.freshen(true)
      }
    }

    KitLine {}
  }

  // ---- list ----
  Flickable {
    id: list
    anchors { left: parent.left; right: parent.right; top: head.bottom; bottom: foot.top; leftMargin: 24; rightMargin: 24; topMargin: 14; bottomMargin: 14 }
    contentHeight: (root.tab === "updates" ? updates : root.tab === "installed" ? installed : cacheList).implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height

    // -- updates
    Column {
      id: updates
      width: list.width
      visible: root.tab === "updates"
      spacing: Theme.gapGroup

      KitText {
        visible: root.ps.aurError !== ""
        width: parent.width
        wrapMode: Text.WordWrap
        color: Theme.muted
        text: "AUR: " + root.ps.aurError
      }

      // the download, then the install: their progress, under the notice
      Column {
        visible: root.ps.stage !== ""
        width: parent.width
        spacing: Theme.gapSmall

        KitLabel {
          text: root.ps.stage === "downloading" ? "DOWNLOADING" : "INSTALLING"
          value: root.ps.stage === "downloading"
              ? Math.round(root.ps.stagePercent * 100) + "% · " + Theme.shortSize(root.ps.stageDone) + " OF " + Theme.shortSize(root.ps.stageBytes)
              : ""
        }

        KitBar {
          value: root.ps.stage === "downloading" ? root.ps.stagePercent : 1
          tint: Theme.green
        }
      }

      // the group's header: a box for the whole list, then its caption
      Row {
        visible: root.ps.count > 0
        width: parent.width
        spacing: 12

        PackageCheck {
          anchors.verticalCenter: parent.verticalCenter
          checked: root.ps.pickedUpdates.length === root.ps.count
          partial: root.ps.pickedUpdates.length > 0 && root.ps.pickedUpdates.length < root.ps.count
          onToggled: root.ps.pickAllUpdates(!checked)
        }

        KitLabel {
          width: parent.width - 28
          text: "SELECT ALL"
          value: root.ps.pickedUpdates.length + " OF " + root.ps.count + " · " + Theme.shortSize(root.ps.repoPickedSize)
        }
      }

      Repeater {
        model: root.ps.pending

        PickRow {
          required property var modelData

          label: modelData.name
          hint: root.hint(modelData.desc)
          checked: root.ps.updPicked[modelData.name] === true
          onToggled: root.ps.pickUpdate(modelData.name, !checked)

          KitText {
            anchors.verticalCenter: parent.verticalCenter
            width: root.sourceWidth
            text: root.source(modelData)
            color: modelData.aur ? Theme.foreground2 : Theme.muted
          }

          KitText {
            anchors.verticalCenter: parent.verticalCenter
            width: root.versionWidth
            elide: Text.ElideLeft
            text: modelData.from + " → " + modelData.to
            color: Theme.foreground2
          }

          // what the repo update downloads; AUR builds have no download size
          KitText {
            anchors.verticalCenter: parent.verticalCenter
            width: root.sizeWidth
            horizontalAlignment: Text.AlignRight
            text: modelData.aur ? "—" : Theme.shortSize(modelData.size)
            color: Theme.muted
          }
        }
      }

      KitText {
        visible: root.ps.count === 0 && !root.ps.checking
        width: parent.width
        color: Theme.muted
        text: "Nothing to update"
      }
    }

    // -- installed
    Column {
      id: installed
      width: list.width
      visible: root.tab === "installed"
      spacing: Theme.gapGroup

      // one toolbar: search, then the two dropdowns on the right
      Row {
        width: parent.width
        spacing: Theme.gapMedium

        KitInput {
          id: field
          width: parent.width - filterBox.width - sortBox.width - 16
          placeholder: "Search by name, description or program"
        }

        KitSelect {
          id: filterBox
          width: 150
          boxWidth: 150
          overlay: true
          model: [{ label: "All types", value: "all" }, { label: "Apps", value: "apps" },
                  { label: "Pacman", value: "repo" }, { label: "AUR", value: "aur" }]
          current: root.filter
          onPicked: value => root.filter = value
        }

        KitSelect {
          id: sortBox
          width: 150
          boxWidth: 150
          overlay: true
          model: [{ label: "By name", value: "name" }, { label: "By size", value: "size" }, { label: "By date", value: "date" }]
          current: root.sortBy
          onPicked: value => root.sortBy = value
        }
      }

      Row {
        visible: root.shown.length > 0
        width: parent.width
        spacing: 12

        PackageCheck {
          anchors.verticalCenter: parent.verticalCenter
          checked: root.shown.length > 0 && root.shownPicked === root.shown.length
          partial: root.shownPicked > 0 && root.shownPicked < root.shown.length
          onToggled: root.ps.pickMany(root.shown.map(p => p.name), !checked)
        }

        KitLabel {
          width: parent.width - 28
          text: "SELECT ALL SHOWN"
          value: root.shownPicked + " PICKED"
        }
      }

      Repeater {
        model: root.shown

        PickRow {
          required property var modelData

          label: modelData.name
          hint: root.hint(modelData.desc)
          checked: root.ps.picked[modelData.name] === true
          onToggled: root.ps.pick(modelData.name, !checked)

          KitText {
            anchors.verticalCenter: parent.verticalCenter
            width: root.sourceWidth
            text: root.source(modelData)
            color: modelData.aur ? Theme.foreground2 : Theme.muted
          }

          KitText {
            anchors.verticalCenter: parent.verticalCenter
            width: root.versionWidth
            elide: Text.ElideLeft
            text: modelData.version
            color: Theme.foreground2
          }

          KitText {
            anchors.verticalCenter: parent.verticalCenter
            width: root.sizeWidth
            horizontalAlignment: Text.AlignRight
            text: root.sortBy === "date" ? root.day(modelData.date) : Theme.shortSize(modelData.size)
            color: Theme.foreground2
          }
        }
      }

      KitText {
        visible: root.shown.length === 0
        width: parent.width
        color: Theme.muted
        text: "Nothing matches"
      }
    }

    // -- cache
    Column {
      id: cacheList
      width: list.width
      visible: root.tab === "cache"
      spacing: Theme.gapGroup

      KitLabel {
        text: "LAST UPGRADE"
        value: root.ps.rollbackCount > 0 ? root.ps.rollbackCount + " PACKAGES" : ""
      }

      KitText {
        visible: root.ps.rollbackCount === 0
        width: parent.width
        color: Theme.muted
        text: "No upgrade in the log has its old version cached"
      }

      KitRow {
        visible: root.ps.rollbackCount > 0
        label: "Roll back the whole upgrade"
        hint: "From " + (root.ps.lastUpdate?.date ?? "").slice(0, 16).replace("T", " ")

        KitButton {
          anchors.verticalCenter: parent.verticalCenter
          icon: "rotate-ccw"
          text: "Roll back"
          disabled: root.ps.busy
          onClicked: root.ps.rollbackLast()
        }
      }

      Repeater {
        model: root.ps.lastUpdate?.packages ?? []

        KitRow {
          required property var modelData

          label: modelData.name

          KitText {
            anchors.verticalCenter: parent.verticalCenter
            width: 260
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideLeft
            text: modelData.from + " → " + modelData.to
            color: Theme.foreground2
          }
        }
      }

      KitText {
        visible: (root.ps.lastUpdate?.missing?.length ?? 0) > 0
        width: parent.width
        wrapMode: Text.WordWrap
        color: Theme.muted
        text: "Not cached, so not rolled back: " + (root.ps.lastUpdate?.missing ?? []).map(m => m.name).join(", ")
      }

      KitLabel {
        text: "CACHED VERSIONS"
        value: root.cacheRows.length + " · " + Theme.shortSize(root.cacheSize)
      }

      KitSelect {
        width: 200
        boxWidth: 200
        overlay: true
        anchors.right: parent.right
        model: [{ label: "Old versions", value: "old" }, { label: "All versions", value: "all" }]
        current: root.cacheView
        onPicked: value => root.cacheView = value
      }

      Repeater {
        model: root.cacheRows

        KitRow {
          required property var modelData

          readonly property bool current: modelData.version === modelData.installed

          label: modelData.name + "  " + modelData.version
          hint: (current ? "Installed" : "Old") + " · " + root.day(modelData.date)
          labelColor: current ? Theme.foreground0 : Theme.foreground2

          KitText {
            anchors.verticalCenter: parent.verticalCenter
            width: 80
            horizontalAlignment: Text.AlignRight
            text: Theme.shortSize(modelData.size)
            color: Theme.muted
          }

          KitButton {
            anchors.verticalCenter: parent.verticalCenter
            icon: "rotate-ccw"
            text: "Roll back"
            disabled: current || root.ps.busy
            onClicked: root.ps.rollback([modelData.file])
          }
        }
      }

      KitText {
        visible: root.cacheRows.length === 0
        width: parent.width
        color: Theme.muted
        text: root.cacheView === "old" ? "No old versions cached" : "The cache is empty"
      }
    }
  }

  // ---- foot ----
  Column {
    id: foot
    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Theme.windowPadding; bottomMargin: Theme.windowPadding }
    spacing: 12

    KitLine {}

    Item {
      width: parent.width
      // the actions row is empty (zero high) on the cache tab: the text sets the height then
      height: Math.max(actions.height, info.height)

      Column {
        id: info
        anchors { left: parent.left; right: actions.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
        spacing: Theme.gapTight

        KitText {
          width: parent.width
          elide: Text.ElideRight
          font.weight: Font.ExtraBold
          text: root.tab === "installed"
              ? (root.ps.pickedNames.length > 0 ? root.ps.pickedNames.length + " picked · " + Theme.shortSize(root.ps.pickedSize) : "Nothing picked")
              : root.tab === "cache"
              ? (root.ps.rollbackCount > 0 ? root.ps.rollbackCount + " to roll back" : "Nothing to roll back")
              : (root.ps.pickedUpdates.length > 0
                  ? root.ps.pickedUpdates.length + " picked" + (root.ps.repoPickedSize > 0 ? " · " + Theme.shortSize(root.ps.repoPickedSize) : "")
                  : "Nothing picked")
        }

        KitText {
          width: parent.width
          elide: Text.ElideRight
          font.pixelSize: Theme.fontSize - 2
          color: root.ps.status === "error" ? Theme.red : root.ps.status === "ok" ? Theme.green
               : root.tab === "updates" && root.ps.pickedUpdates.length > 0 && root.ps.pickedUpdates.length < root.ps.count ? Theme.yellow
               : Theme.muted
          text: root.ps.message !== "" ? root.ps.message
              : root.tab === "installed" ? "Removes what only they need (pacman -Rns)"
              : root.tab === "cache" ? "Installs the cached file with pacman -U"
              : root.ps.pickedUpdates.length > 0 && root.ps.pickedUpdates.length < root.ps.count
                ? "A partial update can break things: pick all if unsure"
              : root.ps.aurPicked.length > 0 ? "AUR packages build in a terminal"
              : "Download, then install: each asks in the panel"
        }
      }

      Row {
        id: actions
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        spacing: Theme.gapMedium

        KitButton {
          visible: root.tab === "updates"
          icon: "download"
          text: "Update picked"
          busy: root.ps.busy
          disabled: root.ps.repoPicked.length === 0 || root.ps.stage !== ""
          onClicked: root.ps.updatePicked()
        }

        KitButton {
          visible: root.tab === "updates"
          icon: "download"
          text: "Update all"
          disabled: root.ps.repoPending.length === 0 || root.ps.stage !== ""
          onClicked: root.ps.updateAll()
        }

        KitButton {
          visible: root.tab === "updates" && root.ps.aurPicked.length > 0
          icon: "external"
          text: "Build AUR"
          disabled: root.ps.stage !== ""
          onClicked: root.ps.updateAur()
        }

        KitButton {
          visible: root.tab === "installed"
          icon: root.armed ? "check" : "trash"
          text: root.armed ? "Sure?" : "Uninstall"
          selected: root.armed
          busy: root.ps.busy
          disabled: root.ps.pickedNames.length === 0
          onClicked: root.uninstall()
        }
      }
    }
  }
}
