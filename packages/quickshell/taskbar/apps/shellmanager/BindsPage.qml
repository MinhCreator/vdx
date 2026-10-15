import QtQuick
import qs.config
import qs.kit

// Binds: Hyprland's keybinds as they are in effect (BindsService), by group —
// a caps label per group, a row per bind: what it does on the left, its keys
// as keycaps on the right. The search matches the name, the group and the keys.
// Changing a bind: hypr/components/keybinds.lua.
Column {
  id: root

  property string query: ""
  readonly property string q: query.trim().toLowerCase()
  readonly property var shown: BindsService.groups
    .map(g => ({ name: g.name, binds: g.binds.filter(b => q === "" || (g.name + " " + b.what + " " + b.keys.join(" ")).toLowerCase().includes(q)) }))
    .filter(g => g.binds.length > 0)

  // the window's fixed header shows these; the page under it scrolls
  readonly property string icon: "keyboard"
  readonly property string title: "Binds"
  readonly property string subtitle: BindsService.count + " BINDS · " + BindsService.groups.length + " GROUPS · HYPRLAND"

  // groups for the Shell Manager's sidebar: a click scrolls to `y`
  readonly property var jumps: {
    groupList.implicitHeight;                 // re-read once the groups are laid out
    return shown.map((g, i) => ({ key: g.name, label: g.name, y: groupList.y + (groupRepeater.itemAt(i)?.y ?? 0) }));
  }

  spacing: 14

  onVisibleChanged: if (visible) BindsService.refresh()

  KitRow {
    label: "Search"
    hint: "By action, group or key"
    wide: true

    KitInput {
      placeholder: "volume, super, workspace"
      text: root.query
      onTextEdited: root.query = text
    }
  }

  KitLine {}

  Column {
    id: groupList
    width: parent.width
    spacing: 14

    Repeater {
      id: groupRepeater
      model: root.shown

      Column {
        id: group

        required property var modelData
        required property int index

        width: groupList.width
        spacing: 14

        KitLabel {
          text: group.modelData.name.toUpperCase()
          value: String(group.modelData.binds.length)
        }

        Repeater {
          model: group.modelData.binds

          KitRow {
            required property var modelData

            label: modelData.what

            Repeater {
              model: modelData.keys

              KeyCap {
                required property string modelData
                anchors.verticalCenter: parent.verticalCenter
                text: modelData
              }
            }
          }
        }

        KitLine { visible: group.index < root.shown.length - 1 }
      }
    }
  }

  KitText {
    visible: root.shown.length === 0
    text: BindsService.error !== "" ? BindsService.error : "No bind matches."
    color: BindsService.error !== "" ? Theme.red : Theme.muted
  }
}
