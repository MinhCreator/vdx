import QtQuick
import qs.config
import qs.kit

// Yandex Music options in the Shell Manager (Apps › Yandex Music): how the
// window opens and behaves. The bar module and the window share these keys
// (ModuleSettings "yandex"), so the popup's timeline follows "Time left" too.
KitColumn {
  spacing: Theme.gapGroup

  KitLabel { text: "START" }

  KitOptionRow {
    module: "yandex"; key: "defaultTab"; fallback: "likes"
    label: "Opens on"; hint: "Each time the window opens"
    model: [
      { label: "Queue", value: "queue" },
      { label: "Likes", value: "likes" }, { label: "Search", value: "search" },
      { label: "Playlists", value: "playlists" }
    ]
  }

  KitLine {}

  KitLabel { text: "PLAYER" }

  KitToggleRow {
    module: "yandex"; key: "showRemaining"; fallback: false
    label: "Time left"; hint: "The timeline counts down"
  }

  KitToggleRow {
    module: "yandex"; key: "closeOnPlay"; fallback: false
    label: "Close when a track plays"; hint: "The window hides after a click"
  }

  KitGrouper {}
}
