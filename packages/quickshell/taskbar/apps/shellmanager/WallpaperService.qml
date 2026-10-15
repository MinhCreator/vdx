pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Wallpaper pictures in ~/.dotfiles/wallpapers (<theme>/ and common/) for the
// Shell Manager: the folders, the picture each theme uses (ShellSettings
// .wallpaperImages, a path under that folder) and adding a file — copied
// into the active theme's folder, so it lives in the repo.
Singleton {
  id: root

  readonly property string dir: Quickshell.env("HOME") + "/.dotfiles/wallpapers"
  readonly property var extensions: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif"]

  // ---- state ----
  property bool busy: false
  property string error: ""

  signal added()

  function imageFor(theme) { return ShellSettings.wallpaperImages[theme] ?? ""; }

  // the picture `rel` for `theme`, and pictures on
  function choose(theme, rel) {
    const map = Object.assign({}, ShellSettings.wallpaperImages);
    map[theme] = rel;
    ShellSettings.set("wallpaperImages", map);
    ShellSettings.set("wallpaperMode", "image");
  }

  // copies `path` (~ allowed) into wallpapers/<theme>/ and picks it
  property string adding: ""
  property string addingTheme: ""
  function add(path, theme) {
    const src = path.trim().replace(/^~(?=\/)/, Quickshell.env("HOME"));
    if (busy || src === "") return;
    const name = src.split("/").pop();
    if (!/\.(jpe?g|png|webp|gif)$/i.test(name)) { error = "not a picture: " + name; return; }
    busy = true;
    error = "";
    adding = theme + "/" + name;
    addingTheme = theme;
    copyProc.command = ["bash", "-c", 'mkdir -p "$2" && cp -- "$1" "$2/"', "_", src, dir + "/" + theme];
    copyProc.running = true;
  }

  Process {
    id: copyProc
    stderr: StdioCollector { id: copyErr }
    onExited: code => {
      root.busy = false;
      if (code === 0) {
        root.choose(root.addingTheme, root.adding);
        root.added();
      }
      else root.error = copyErr.text.trim() || "copy failed";
    }
  }
}
