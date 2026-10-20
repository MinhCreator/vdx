import QtQuick
import qs.config
import qs.kit

// Music options in the Shell Manager (Apps › Music): how the window opens and plays.
// The Yandex Music popup's timeline follows "Time left" too.
KitColumn {
  spacing: Theme.gapGroup

  KitLabel { text: "OPENING" }

  KitOptionRow {
    module: "music"; key: "opensOn"; fallback: "playing"
    label: "Opens on"; hint: "Likes needs Yandex Music"
    model: [
      { label: "Now playing", value: "playing" },
      { label: "Likes", value: "likes" },
      { label: "Last page", value: "last" }
    ]
  }

  KitToggleRow {
    module: "music"; key: "closeOnPlay"; fallback: false
    label: "Close when a track plays"; hint: "After a click in a list"
  }

  KitLine {}

  KitLabel { text: "PLAYER" }

  KitToggleRow {
    module: "music"; key: "showRemaining"; fallback: false
    label: "Time left"; hint: "The timeline counts down"
  }

  KitGrouper {}
}
