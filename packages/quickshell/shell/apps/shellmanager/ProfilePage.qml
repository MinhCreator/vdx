import QtQuick
import Quickshell
import qs.apps.files
import qs.config
import qs.kit

// Profile: who the shell says you are — the picture and the name the hub's header and the
// lock screen show. Its keys are ModuleSettings "profile".
Column {
  id: root
  readonly property Item previewItem: null

  readonly property string icon: "user"
  readonly property string title: "Profile"
  readonly property string description: "Your picture and name, shown on the hub and the lock screen."
  readonly property var jumps: []

  readonly property bool changed: ModuleSettings.changed("profile")
  function reset() { ModuleSettings.reset("profile"); }

  readonly property string picture: ModuleSettings.get("profile", "avatar", "")

  spacing: Theme.sectionGap

  Column {
    width: parent.width

    KitLabel { text: "PICTURE" }
    KitRow {
      label: "Picture"
      hint: root.picture.split("/").pop() || "None: your initial"
      KitButton { text: "Choose…"; onClicked: FilesService.pick("Choose a profile picture", FilesService.home, false, ["image/*"], path => { if (path) ModuleSettings.set("profile", "avatar", path); }) }
      KitButton { visible: root.picture !== ""; icon: "x"; Accessible.name: "Clear the picture"; onClicked: ModuleSettings.set("profile", "avatar", "") }
    }
    KitGrouper {}
  }

  KitLine {}

  Column {
    width: parent.width

    KitLabel { text: "NAME" }
    KitRow {
      wide: true
      label: "Name"
      hint: "Empty: your login name"
      KitInput {
        text: ModuleSettings.get("profile", "name", "")
        placeholder: Quickshell.env("USER") || "name"
        onAccepted: ModuleSettings.set("profile", "name", text.trim())
      }
    }
    KitGrouper {}
  }

  KitGrouper {}
}
