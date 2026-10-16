import QtQuick
import Quickshell
import Quickshell.Io
import qs.apps.auth
import qs.apps.capture
import qs.apps.clipboard
import qs.apps.cleaner
import qs.apps.packages
import qs.apps.virustotal
import qs.apps.keybinds
import qs.apps.taskbar
import qs.apps.launcher
import qs.apps.lock
import qs.apps.overview
import qs.apps.shellmanager
import qs.apps.switcher
import qs.apps.taskmanager
import qs.bar
import qs.components

// Entry point: a bar on every screen that has one on (BarLayout), recoloured when the dotfiles theme changes.
Scope {
  Variants {
    model: Quickshell.screens.filter(s => BarLayout.barOn(s.name))

    Bar {}
  }

  ShellManagerWindow {}
  TaskManagerWindow {}
  CleanerWindow {}
  VirusTotalWindow {}
  PackagesWindow {}
  ClipboardWindow {}
  Keybinds {}
  Taskbar {}
  Launcher {}
  Lock {}
  Overview {}
  // Super+Tab: the floating mode's window switcher (Switcher.step)
  Switcher {}

  // the polkit agent: password requests slide down from under the bar
  AuthPrompt {}

  Wallpaper {}

  PopupCatcher {}

  // Super+Shift+S: screenshot or recording of a region, window or screen
  CaptureOverlay {}

  CaptureRecording {}

  CaptureSave {}

  // `install.py theme set` (here or from a terminal) writes .theme; reread the
  // theme colours and the shell recolours live — Colors.qml only seeds the start.
  FileView {
    path: ThemeService.dotfiles + "/.theme"
    watchChanges: true
    printErrors: false
    onFileChanged: refreshTimer.restart()
  }

  Timer {
    id: refreshTimer
    interval: 400   // longer than install.py's relink (~220 ms)
    onTriggered: ThemeService.refresh()
  }
}