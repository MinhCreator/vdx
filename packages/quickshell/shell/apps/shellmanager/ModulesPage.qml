import QtQuick
import Quickshell
import qs.bar
import qs.config
import qs.kit

// Modules: the list on the left, the chosen one's options on the right —
// its own <Name>Settings.qml (the registry's `settings`), values kept in
// ModuleSettings, Reset to the defaults. Each pane scrolls on its own. Where a
// module sits is set on the Bar page.
Column {
  id: root

  // the window's fixed header shows these; the page under it scrolls
  readonly property string icon: "puzzle"
  readonly property string title: "Modules"
  readonly property string subtitle: own.length + " MODULES · " + own.filter(p => p.settings).length + " WITH OPTIONS · " + (BarLayout.modules.length - own.length) + " OF APPS"

  // its own list does the job of the sidebar's group links
  readonly property var jumps: []

  signal navigate(string tab, string target)

  // another page names a module (Media's pause is Audio's): it is chosen here
  function jump(id) { if (own.some(p => p.id === id)) selected = id; }

  // the app a module belongs to (apps/apps.json), if any: such a module is set
  // with its app, in Shell apps, and listed here as a link there
  function appOf(id) { return ShellAppsService.entries.find(a => a.module === id) ?? null; }

  readonly property var own: BarLayout.modules.filter(p => !root.appOf(p.id))
  property string selected: (own.find(p => p.settings) ?? own[0])?.id ?? ""
  readonly property var module: own.find(p => p.id === selected) ?? null

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
      model: BarLayout.modules.map(p => Object.assign({ link: !!root.appOf(p.id), off: !BarLayout.installed(p.id) }, p))
      selected: root.selected
      onPicked: id => {
        if (root.appOf(id)) root.navigate("apps", id);
        else root.selected = id;
      }
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

          KitButton {
            id: resetButton
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            visible: !!root.module?.settings
            icon: "rotate-ccw"
            text: "Reset"
            disabled: !ModuleSettings.changed(root.selected)
            onClicked: ModuleSettings.reset(root.selected)
          }
        }

        KitLine {}

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
          active: !!root.module?.settings && BarLayout.installed(root.selected)
          source: active ? Quickshell.shellPath(root.module.settings.includes("/") ? root.module.settings
                                                 : "modules/" + root.module.id + "/" + root.module.settings) : ""
        }

        // a module without options gets a row in their place, like one
        KitRow {
          visible: !root.module?.settings && BarLayout.installed(root.selected)
          label: "No options"
          hint: "Nothing to set for this module"
          labelColor: Theme.foreground2
        }
      }
    }
  }

  onSelectedChanged: pane.contentY = 0
}
