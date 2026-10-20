import QtQuick
import qs.bar
import qs.config
import qs.kit

// Bar module: the active keyboard layout as a short code (LanguageService);
// no popup. Bar text › Icon shows a keyboard instead.
Item {
  id: root

  readonly property bool iconOnly: ModuleSettings.get("language", "text", "content") === "icon"

  implicitWidth: face.implicitWidth
  implicitHeight: face.implicitHeight

  KitBarItem {
    id: face
    icon: root.iconOnly ? "keyboard" : ""
    text: BarLayout.faceText("language", Format.layout(LanguageService.layout) || LanguageService.layout)
    tint: Theme.foreground1
  }
}
