import QtQuick
import Quickshell
import qs.apps.keybinds
import qs.bar
import qs.config
import qs.kit

// Shell apps: the shell's own apps (ShellAppsService.entries) — the list on
// the left, the chosen one on the right: its name, what it is and the key
// that opens it; then its own options page (values in ModuleSettings, Reset
// brings the defaults back), how its window opens (one line; the options in
// WindowDialog, for the apps with a window of their own) and its module in
// the bar (shown, where, its own options). Each pane scrolls on its own.
Column {
  id: root

  // the window's fixed header shows these; the page under it scrolls
  readonly property string icon: "grid"
  readonly property string title: "Apps"
  readonly property string subtitle: listed.length + " APPS · "
                                     + ShellAppsService.windows.length + " WITH A WINDOW"

  // its own list does the job of the sidebar's group links
  readonly property var jumps: []

  // an app with a page of its own (Lock screen) is set there, not here
  readonly property var listed: ShellAppsService.entries.filter(e => !e.page)
  property string selected: listed[0]?.id ?? ""
  readonly property var entry: listed.find(e => e.id === selected) ?? null
  // its window's settings (shellapps.py), when it has one
  readonly property var window: entry?.window ? (ShellAppsService.windows.find(a => a.id === entry.window.id) ?? null) : null

  // the tab: the app or its bar module (an app with a module only)
  readonly property bool hasModule: !!entry?.module

  // where its bar module stands on the main bar: hidden | folder | a zone
  readonly property string screen: BarLayout.mainScreen()
  readonly property string place: {
    const id = entry?.module ?? "";
    if (id === "" || BarLayout.hidden(screen).includes(id)) return "hidden";
    if (BarLayout.inFolder(screen).includes(id)) return "folder";
    const l = BarLayout.layout(screen);
    return BarLayout.zones.find(z => (l[z] ?? []).includes(id)) ?? "hidden";
  }

  // another page, scrolled to one of its groups (ShellManager.navigate)
  signal navigate(string tab, string target)
  // how its window opens: the dialog over the Shell Manager
  signal windowSetup(string id)

  // another page (or `ipc call shell open apps`) may name an app, or its
  // bar module's id; a module's id opens the app on its bar-module tab.
  // "<id>:bar" (Modules' Open) names the bar-module tab even when the module
  // has the app's id
  function jump(key) {
    const bar = key.endsWith(":bar");
    const id = bar ? key.slice(0, -4) : key;
    const e = ShellAppsService.entries.find(e => e.id === id || e.module === id);
    if (e?.page) { navigate(e.page, ""); return; }
    if (e && bar && e.module) { navigate("modules", e.module); return; }
    if (e) selected = e.id;
  }

  spacing: Theme.gapGroup

  onVisibleChanged: if (visible) { ShellAppsService.refresh(); KeybindsService.refresh(); }

  Row {
    width: parent.width
    height: root.height
    spacing: 18

    EntryList {
      id: list
      width: Theme.sideWidth
      height: parent.height
      title: "APPS"
      model: root.listed.map(e => Object.assign({ off: !ShellAppsService.installed(e) }, e))
      selected: root.selected
      onPicked: id => root.selected = id
    }

    // ---- the chosen app: its name, key, window and options, scrolling on their own ----
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

        // heading: icon, name and about; the key that opens it; Reset
        Item {
          width: parent.width
          height: Math.max(heading.implicitHeight, trailing.height)

          Row {
            id: heading
            anchors { left: parent.left; right: trailing.left; rightMargin: Theme.gapWide; verticalCenter: parent.verticalCenter }
            spacing: Theme.gapLoose

            KitIcon {
              id: headingIcon
              anchors.verticalCenter: parent.verticalCenter
              name: root.entry?.icon ?? ""
              size: 18
            }

            Column {
              anchors.verticalCenter: parent.verticalCenter
              width: heading.width - headingIcon.width - heading.spacing
              spacing: Theme.gapTight

              KitText {
                text: root.entry?.label ?? ""
                font.weight: Font.ExtraBold
              }

              KitText {
                width: parent.width
                text: root.entry?.about ?? ""
                elide: Text.ElideRight
                color: Theme.muted
                font.pixelSize: Theme.fontSize - 2
              }
            }
          }

          Row {
            id: trailing
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: Theme.gapSmall

            Repeater {
              model: KeybindsService.keysFor(root.entry?.bind ?? "")

              KeyCap {
                required property string modelData
                anchors.verticalCenter: parent.verticalCenter
                text: modelData
              }
            }

            Item { width: 6; height: 1; visible: !!root.entry?.settings }

            KitButton {
              visible: !!root.entry?.settings
              icon: "rotate-ccw"
              text: "Reset"
              disabled: !ModuleSettings.changed(root.selected)
              onClicked: ModuleSettings.reset(root.selected)
            }
          }
        }

        KitLine {}

        // its components are off on this machine: nothing to set until installed
        KitRow {
          visible: root.entry !== null && !ShellAppsService.installed(root.entry)
          label: "Not installed"
          hint: "components add " + (BarLayout.notInstalled[root.entry?.module] ?? []).join(" or ")
          labelColor: Theme.foreground2
        }

        // ---- the app: how its window opens first, then its own options ----
        Column {
          width: parent.width
          visible: ShellAppsService.installed(root.entry)
          spacing: Theme.gapGroup

          // one line: how it opens now; the options in a dialog (WindowDialog)
          KitRow {
            visible: root.window !== null
            label: "Window"
            hint: !root.window ? "" : root.window.settings.mode === "tiled" ? "Tiled, in the layout"
                : "Floating · " + ShellAppsService.sizeOf(root.window, root.window.settings).join(" × ")
                  + " · " + ShellAppsService.placeName(root.window.settings)

            KitButton {
              width: Theme.buttonWidth
              icon: "app-window"
              text: "Set up"
              onClicked: root.windowSetup(root.window.id)
            }
          }

          KitLine { visible: root.window !== null && !!root.entry?.settings }

          Loader {
            width: parent.width
            visible: active
            active: !!root.entry?.settings
            source: active ? Quickshell.shellPath(root.entry.settings) : ""
          }
        }

        // its bar module's options are in Bar modules (05)
        KitLinkRow {
          visible: root.hasModule && ShellAppsService.installed(root.entry)
          label: "Bar module"
          hint: "In Bar modules › " + (root.entry?.label ?? "")
          target: "modules:" + (root.entry?.module ?? "")
        }

        // an app with nothing to set gets a row in their place, like one
        KitRow {
          visible: root.window === null && !root.entry?.settings && !root.entry?.module
          label: "No options"
          hint: "Opens with its key or the launcher"
          labelColor: Theme.foreground2
        }
      }
    }
  }

  onSelectedChanged: pane.contentY = 0
}
