import QtQuick
import Quickshell
import qs.bar
import qs.config
import qs.kit

// Bar modules: every bar module in a list on the left, the chosen one's options
// on the right — its own <Name>Settings.qml (the registry's `settings`, or its
// app's `moduleSettings` in apps/apps.json), values kept in ModuleSettings,
// Reset to the defaults (an app's module shares its id with the app: Reset
// brings back both). Notifications has a page of its own: a link there. Each
// pane scrolls on its own. Where a module sits is set on the Bar page.
Column {
  id: root

  // the window's fixed header shows these; the page under it scrolls
  readonly property string icon: "puzzle"
  readonly property string title: "Bar modules"
  readonly property string subtitle: BarLayout.modules.length + " MODULES · " + BarLayout.modules.filter(p => !!optionsOf(p)).length + " WITH OPTIONS"

  // its own list does the job of the sidebar's group links
  readonly property var jumps: []

  signal navigate(string tab, string target)

  // another page names a module (Media's pause is Audio's): it is chosen here
  function jump(id) {
    if (pages[id]) navigate(pages[id], "");
    else if (BarLayout.modules.some(p => p.id === id)) selected = id;
  }

  // modules whose options live on a page of their own: the list links there
  readonly property var pages: ({ notifications: "notifications" })

  // the app a module belongs to (apps/apps.json), if any: its options page is the app's `moduleSettings`
  function appOf(id) { return ShellAppsService.entries.find(a => a.module === id) ?? null; }
  // a module's options page as a shell path, "" without one
  function optionsOf(p) {
    const app = appOf(p.id);
    if (app) return app.moduleSettings ?? "";
    if (!p.settings) return "";
    return p.settings.includes("/") ? p.settings : "modules/" + p.id + "/" + p.settings;
  }

  property string selected: BarLayout.modules[0]?.id ?? ""
  readonly property var module: BarLayout.modules.find(p => p.id === selected) ?? null
  readonly property string options: module ? optionsOf(module) : ""

  spacing: Theme.gapGroup

  Row {
    width: parent.width
    height: root.height
    spacing: 18

    // ---- list: like the theme list — title, search, a framed list ----
    EntryList {
      id: list
      width: Theme.sideWidth
      height: parent.height
      title: "MODULES"
      model: BarLayout.modules.map(p => Object.assign({ link: !!root.pages[p.id], off: !BarLayout.installed(p.id) }, p))
      selected: root.selected
      onPicked: id => root.jump(id)
    }

    // ---- the chosen module: its name and options, scrolling on their own ----
    Flickable {
      id: pane
      width: parent.width - list.width - parent.spacing
      height: parent.height
      contentHeight: details.implicitHeight
      interactive: contentHeight > height
      clip: true
      boundsBehavior: Flickable.StopAtBounds

      Column {
        id: details
        width: pane.width
        spacing: Theme.gapGroup

        // heading: icon, name and about; Reset brings the options' defaults back
        Item {
          width: parent.width
          height: Math.max(heading.implicitHeight, resetButton.height)

          Row {
            id: heading
            anchors { left: parent.left; right: resetButton.left; rightMargin: Theme.gapWide; verticalCenter: parent.verticalCenter }
            spacing: Theme.gapLoose

            KitIcon {
              id: headingIcon
              anchors.verticalCenter: parent.verticalCenter
              name: root.module?.icon ?? ""
              size: 18
            }

            Column {
              anchors.verticalCenter: parent.verticalCenter
              width: heading.width - headingIcon.width - heading.spacing
              spacing: Theme.gapTight

              KitText {
                text: root.module?.label ?? ""
                font.weight: Font.ExtraBold
              }

              KitText {
                width: parent.width
                text: root.module?.about ?? ""
                elide: Text.ElideRight
                color: Theme.muted
                font.pixelSize: Theme.fontSize - 2
              }
            }
          }

          KitResetButton {
            id: resetButton
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            visible: root.options !== ""
            changed: ModuleSettings.changed(root.selected)
            onReset: ModuleSettings.reset(root.selected)
          }
        }

        KitLine {}

        // an app's module: the app's own options are with the app
        KitLinkRow {
          visible: root.module !== null && !!root.appOf(root.selected) && BarLayout.installed(root.selected)
          label: "The app"
          hint: "In Apps › " + (root.appOf(root.selected)?.label ?? "")
          target: "apps:" + (root.appOf(root.selected)?.id ?? "")
        }

        // its components are off on this machine: nothing to set until installed
        KitRow {
          visible: root.module !== null && !BarLayout.installed(root.selected)
          label: "Not installed"
          hint: "components add " + (BarLayout.notInstalled[root.selected] ?? []).join(" or ")
          labelColor: Theme.foreground2
        }

        // hidden when off: a zero-height item still takes a Column gap
        Loader {
          width: parent.width
          visible: active
          active: root.options !== "" && BarLayout.installed(root.selected)
          source: active ? Quickshell.shellPath(root.options) : ""
        }

        // a module without options gets a row in their place, like one
        KitRow {
          visible: root.options === "" && BarLayout.installed(root.selected)
          label: "No options"
          hint: "Nothing to set here"
          labelColor: Theme.foreground2
        }
      }
    }
  }

  onSelectedChanged: pane.contentY = 0
}
