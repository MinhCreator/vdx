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
// WindowDialog, for the apps with a window of their own) and its module in the bar (shown, where,
// its own options). Each pane scrolls on its own.
Column {
  id: root

  // the window's fixed header shows these; the page under it scrolls
  readonly property string icon: "grid"
  readonly property string title: "Shell apps"
  readonly property string subtitle: ShellAppsService.entries.length + " APPS · "
                                     + ShellAppsService.windows.length + " WITH A WINDOW"

  // its own list does the job of the sidebar's group links
  readonly property var jumps: []

  property string selected: ShellAppsService.entries[0].id
  readonly property var entry: ShellAppsService.entries.find(e => e.id === selected) ?? null
  // its window's settings (shellapps.py), when it has one
  readonly property var window: entry?.window ? (ShellAppsService.windows.find(a => a.id === entry.window.id) ?? null) : null

  // the tab: the app or its bar module (an app with a module only)
  property string scope: "app"
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
  // bar module's id
  function jump(id) {
    const e = ShellAppsService.entries.find(e => e.id === id || e.module === id);
    if (e) selected = e.id;
  }

  spacing: 14

  onVisibleChanged: if (visible) { ShellAppsService.refresh(); KeybindsService.refresh(); }

  Row {
    width: parent.width
    height: root.height
    spacing: 18

    EntryList {
      id: list
      width: 190
      height: parent.height
      title: "APPS"
      model: ShellAppsService.entries
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
        spacing: 14

        // heading: icon, name and about; the key that opens it; Reset
        Item {
          width: parent.width
          height: Math.max(heading.implicitHeight, trailing.height)

          Row {
            id: heading
            anchors { left: parent.left; right: trailing.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
            spacing: 10

            KitIcon {
              id: headingIcon
              anchors.verticalCenter: parent.verticalCenter
              name: root.entry?.icon ?? ""
              size: 18
            }

            Column {
              anchors.verticalCenter: parent.verticalCenter
              width: heading.width - headingIcon.width - heading.spacing
              spacing: 2

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
            spacing: 6

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

        // the app and its bar module, each on its own tab, so every option
        // says what it belongs to (only for apps with a module)
        KitChoices {
          width: parent.width
          visible: root.hasModule
          stretch: true
          model: [{ label: "App", value: "app", icon: "app-window" },
                  { label: "Bar module", value: "bar", icon: "layout" }]
          current: root.scope
          onPicked: value => root.scope = value
        }

        // hidden when off: a zero-height item still takes a Column gap
        // ---- the app: how its window opens first, then its own options ----
        Column {
          width: parent.width
          visible: root.scope === "app"
          spacing: 14

          // one line: how it opens now; the options in a dialog (WindowDialog)
          KitRow {
            visible: root.window !== null
            label: "Window"
            hint: !root.window ? "" : root.window.settings.mode === "tiled" ? "Tiled, in the layout"
                : "Floating · " + ShellAppsService.sizeOf(root.window, root.window.settings).join(" × ")
                  + " · " + ShellAppsService.placeName(root.window.settings)

            KitButton {
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

        // ---- its bar module: a short version of the app in the bar ----
        Column {
          width: parent.width
          visible: root.scope === "bar"
          spacing: 14

          KitText {
            width: parent.width
            wrapMode: Text.WordWrap
            color: Theme.muted
            font.pixelSize: Theme.fontSize - 2
            text: "The app's short version in the bar: a summary and quick actions; a click opens its popup."
          }

          KitLabel { text: "PLACE"; value: root.place.toUpperCase() }

          KitRow {
            visible: root.place !== "hidden"
            label: "Zone and order"
            hint: "Dragged on the Bar page"

            KitButton {
              icon: "layout"
              text: "Arrange"
              onClicked: root.navigate("bar", "layout")
            }
          }

          KitLine { visible: barOptions.active }

          Loader {
            id: barOptions
            width: parent.width
            visible: active
            active: !!root.entry?.moduleSettings
            source: active ? Quickshell.shellPath(root.entry.moduleSettings) : ""
          }
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

  onSelectedChanged: { pane.contentY = 0; scope = "app"; }
}
