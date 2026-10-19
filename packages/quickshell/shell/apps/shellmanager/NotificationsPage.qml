import QtQuick
import qs.config
import qs.kit
import qs.modules.notifications

// Notifications: toasts, the history popup and the bar's marks
// (modules/notifications/NotificationsSettings.qml: ModuleSettings
// "notifications" and ShellSettings' unseen dot). Reset in the window's header
// brings the module's defaults and the dot's back. Bar modules lists it as a link here.
Column {
  id: root

  // the window's fixed header shows these; the page under it scrolls
  readonly property string icon: "bell"
  readonly property string title: "Notifications"
  readonly property string subtitle: "TOASTS " + (toast === 0 ? "STAY" : toast + " S")
  readonly property int toast: ModuleSettings.get("notifications", "toastSeconds", 5)
  readonly property var jumps: []

  // the header's Reset
  readonly property bool changed: ModuleSettings.changed("notifications") || ShellSettings.changed(["barFolderDot", "barDotColor"])
  function reset() {
    ModuleSettings.reset("notifications");
    ShellSettings.reset(["barFolderDot", "barDotColor"]);
  }

  NotificationsSettings { width: parent.width }
}
