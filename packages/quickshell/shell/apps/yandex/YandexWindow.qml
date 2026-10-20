import QtQuick
import Quickshell
import Quickshell.Io
import qs.components
import qs.config
import qs.modules.yandex

// Yandex Music as a window of its own (how it opens: Shell Manager › Shell apps).
// `qs -c shell ipc call yandex-music <toggle|open|close>` or the launcher; Escape
// closes. Opening reads the likes, the search and the playlists again.
FloatingWindow {
  id: root

  title: "Yandex Music"
  visible: false
  implicitWidth: 640
  implicitHeight: 620
  color: Theme.background0

  // Hyprland closing the window hides it but leaves FloatingWindow's own visible
  // set, so the next `visible = true` would do nothing: reset it.
  onVisibleChanged: if (visible) {
    app.show();
    YandexService.setWindowOpen(true);
    Qt.callLater(() => PopupManager.closeModule("yandex"));
  } else {
    visible = false;
    menu.close();
    YandexService.setWindowOpen(false);
  }

  YandexApp {
    id: app
    anchors.fill: parent
    framed: false
    padding: Theme.windowPadding
    headerInset: Theme.headerInset
    onCloseRequested: root.visible = false
    // a track's ⋮ button: the menu opens there; in a playlist it can take the track out
    onMenuRequested: (track, index, anchor) => menu.show(track, index,
      app.tab === "playlists" && YandexLibrary.playlist ? YandexLibrary.playlist : null, anchor)
  }

  // above the window's content: a click outside it closes it
  YandexTrackMenu {
    id: menu
    host: app
    onPlayed: if (ModuleSettings.get("yandex", "closeOnPlay", false)) root.visible = false
  }

  Shortcut {
    sequences: [StandardKey.Cancel]
    onActivated: root.visible = false
  }

  IpcHandler {
    target: "yandex-music"
    function toggle(): void { Hypr.toggleWindow(root); }
    function open(): void { root.visible = true; }
    function close(): void { root.visible = false; }
  }
}
