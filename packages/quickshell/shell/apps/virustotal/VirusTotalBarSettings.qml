import QtQuick
import qs.kit
import qs.config

// The VirusTotal bar module's options (Shell apps › BAR, under the module's
// place): how the icon shows a verdict, and what the popup takes from the
// clipboard when it opens.
Column {
  spacing: Theme.gapGroup

  KitLabel { text: "BAR" }
  BarTextRow { module: "virustotal"; hasContent: false }

  KitToggleRow { module: "virustotal"; key: "tint"; fallback: true; label: "Colour by verdict"; hint: "Red malicious, yellow suspicious" }

  KitLine {}

  KitLabel { text: "POPUP" }

  KitToggleRow { module: "virustotal"; key: "clipboard"; fallback: false; label: "Read the clipboard"; hint: "Fills the field with a hash or URL" }

  KitToggleRow { module: "virustotal"; key: "closeOnOpen"; label: "Close when its window opens"; hint: "Off: popup stays open" }

  KitGrouper {}
}
