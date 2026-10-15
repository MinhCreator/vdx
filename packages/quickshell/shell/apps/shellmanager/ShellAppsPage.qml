import QtQuick
import Quickshell
import qs.config
import qs.kit

// Shell apps: how each of the shell's own windows opens. Per app one row —
// its icon, name, how it opens now and the key that opens it; a click unfolds a small monitor showing the
// window as it will open (and a button to open it), then Window (floating /
// tiled) and, floating, Size (its own, a preset share of the screen, custom
// pixels) and Position (one of nine spots, at the cursor, custom x, y).
// Choices apply at once, numbers on Enter; it shows the next time the window
// opens.
Column {
  id: root

  // the window's fixed header shows these; the page under it scrolls
  readonly property string icon: "app-window"
  readonly property string title: "Shell apps"
  readonly property string subtitle: ShellAppsService.apps.length + " APPS · APPLIED THE NEXT TIME ONE OPENS"

  // groups for the Shell Manager's sidebar: a click scrolls to `y`
  readonly property var jumps: {
    appList.implicitHeight;
    return ShellAppsService.apps.map((a, i) => ({ key: a.id, label: a.title, y: appList.y + (appRepeater.itemAt(i)?.y ?? 0) }));
  }

  // the one app unfolded ("" none): opening one folds the other
  property string openApp: ""
  // the sidebar's link unfolds it
  function jump(id) { openApp = id; }
  function toggle(id) { openApp = openApp === id ? "" : id; }

  spacing: 14

  onVisibleChanged: if (visible) { ShellAppsService.refresh(); BindsService.refresh(); }

  Column {
    id: appList
    width: parent.width
    spacing: 14

    Repeater {
      id: appRepeater
      model: ShellAppsService.apps

      Column {
        id: group

        required property var modelData
        required property int index

        readonly property var app: modelData
        readonly property var s: modelData.settings
        readonly property bool floating: s.mode !== "tiled"
        readonly property var px: ShellAppsService.sizeOf(app, s)
        readonly property bool unfolded: root.openApp === app.id
        readonly property string summary: floating ? "Floating · " + px[0] + " × " + px[1] + " · " + ShellAppsService.placeName(s)
                                                   : "Tiled, in the layout"

        // the numbers being typed, until Enter
        property string wDraft: String(s.width)
        property string hDraft: String(s.height)
        property string xDraft: String(s.x)
        property string yDraft: String(s.y)

        function set(change) { ShellAppsService.set(app, change); }

        width: appList.width
        spacing: 14

        // the app: its icon, name, how it opens and its key; a click folds the rest in / out
        Item {
          width: parent.width
          height: header.implicitHeight

          KitIcon {
            id: appIcon
            anchors.verticalCenter: parent.verticalCenter
            name: group.app.icon
            size: 20
            tint: group.unfolded ? Theme.foreground0 : Theme.foreground2
          }

          KitRow {
            id: header
            x: appIcon.width + 14
            width: parent.width - x
            label: group.app.title
            hint: group.summary

            Repeater {
              model: BindsService.keysFor(group.app.bind)

              KeyCap {
                required property string modelData
                anchors.verticalCenter: parent.verticalCenter
                text: modelData
              }
            }

            Item { width: 6; height: 1 }

            KitIcon {
              anchors.verticalCenter: parent.verticalCenter
              name: "chevron-down"
              size: 16
              tint: Theme.foreground2
              rotation: group.unfolded ? 180 : 0
              Behavior on rotation { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggle(group.app.id)
          }
        }

        // what unfolds
        Item {
          width: parent.width
          height: group.unfolded ? body.implicitHeight : 0
          opacity: group.unfolded ? 1 : 0
          clip: true
          visible: height > 0

          Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
          Behavior on opacity { NumberAnimation { duration: 220 } }

          Column {
            id: body
            width: parent.width
            spacing: 14

            // the window as it will open
            Row {
              width: parent.width
              spacing: 18

              WindowPreview {
                width: 220
                app: group.app
                settings: group.s
              }

              Column {
                width: parent.width - 220 - parent.spacing
                spacing: 8

                KitText {
                  width: parent.width
                  visible: group.app.id !== "shell-manager"
                  text: "Shows the next time the window opens."
                  color: Theme.muted
                  wrapMode: Text.WordWrap
                  font.pixelSize: Theme.fontSize - 2
                }

                KitButton {
                  visible: group.app.id !== "shell-manager"
                  icon: "external"
                  text: "Open it"
                  onClicked: Quickshell.execDetached(["qs", "-c", "shell", "ipc", "call", group.app.ipc, "open"])
                }

                KitText {
                  width: parent.width
                  visible: group.app.id === "shell-manager"
                  text: "Close and reopen this window to see it."
                  color: Theme.muted
                  wrapMode: Text.WordWrap
                  font.pixelSize: Theme.fontSize - 2
                }
              }
            }

            KitRow {
              wide: true
              label: "Window"
              hint: group.floating ? "Over the others, where you put it" : "Takes its place in the layout"

              KitChoices {
                stretch: true
                model: [{ label: "Floating", value: "floating" }, { label: "Tiled", value: "tiled" }]
                current: group.s.mode
                onPicked: value => group.set({ mode: value })
              }
            }

            KitRow {
              visible: group.floating
              wide: true
              label: "Size"
              hint: group.s.size === "preset" ? "A share of the screen"
                  : group.s.size === "custom" ? "Your own, in pixels" : group.app.width + " × " + group.app.height + ", the app's own"

              KitChoices {
                stretch: true
                model: [{ label: "Default", value: "default" }, { label: "Preset", value: "preset" }, { label: "Custom", value: "custom" }]
                current: group.s.size
                onPicked: value => group.set({ size: value })
              }
            }

            KitRow {
              visible: group.floating && group.s.size === "preset"
              wide: true
              label: "Preset"
              hint: {
                const p = ShellAppsService.presets[group.s.preset] ?? [0, 0];
                return Math.round(p[0] * 100) + " × " + Math.round(p[1] * 100) + "% of the screen";
              }

              KitChoices {
                stretch: true
                model: [{ label: "Small", value: "small" }, { label: "Medium", value: "medium" }, { label: "Large", value: "large" }]
                current: group.s.preset
                onPicked: value => group.set({ preset: value })
              }
            }

            PairRow {
              visible: group.floating && group.s.size === "custom"
              label: "Width × height"
              hint: valid ? "Press Enter to apply" : "At least " + ShellAppsService.minWidth + " × " + ShellAppsService.minHeight
              first: group.wDraft
              second: group.hDraft
              onEdited: (a, b) => { group.wDraft = a; group.hDraft = b; }
              onAccepted: (a, b) => group.set({ size: "custom", width: a, height: b })
            }

            KitRow {
              visible: group.floating
              wide: true
              label: "Position"
              hint: group.s.position === "cursor" ? "Centred on the pointer, on screen"
                  : group.s.position === "custom" ? "From the screen's top-left" : group.s.position.charAt(0).toUpperCase() + group.s.position.slice(1).replace("-", " ") + " of the screen"

              // a spot of the screen, or the pointer, or your own
              Row {
                spacing: 10

                PositionGrid {
                  id: grid
                  anchors.verticalCenter: parent.verticalCenter
                  current: group.s.position
                  onPicked: spot => group.set({ position: spot })
                }

                KitChoices {
                  width: parent.width - grid.width - parent.spacing
                  stretch: true
                  model: [{ label: "Cursor", value: "cursor" }, { label: "Custom", value: "custom" }]
                  current: group.s.position
                  onPicked: value => group.set({ position: value })
                }
              }
            }

            PairRow {
              visible: group.floating && group.s.position === "custom"
              label: "X, Y"
              hint: valid ? "Press Enter to apply; kept on screen" : "Whole pixels"
              separator: ","
              first: group.xDraft
              second: group.yDraft
              onEdited: (a, b) => { group.xDraft = a; group.yDraft = b; }
              onAccepted: (a, b) => group.set({ position: "custom", x: a, y: b })
            }
          }
        }

        KitText {
          width: parent.width
          visible: ShellAppsService.error !== "" && ShellAppsService.errorApp === group.app.id
          text: ShellAppsService.error
          color: Theme.red
          wrapMode: Text.WordWrap
          font.pixelSize: Theme.fontSize - 1
        }

        KitLine { visible: group.index < ShellAppsService.apps.length - 1 }
      }
    }
  }
}
