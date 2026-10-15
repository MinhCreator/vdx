import QtQuick
import qs.kit

// The VirusTotal bar module's options (Shell apps › BAR, under the module's
// place): how the icon shows a verdict, and what the popup takes from the
// clipboard when it opens.
Column {
  spacing: 14

  KitLabel { text: "ICON" }

  KitToggleRow { module: "virustotal"; key: "tint"; fallback: true; label: "Colour by verdict"; hint: "Red malicious, yellow suspicious" }

  KitLine {}

  KitLabel { text: "POPUP" }

  KitToggleRow { module: "virustotal"; key: "clipboard"; fallback: false; label: "Read the clipboard"; hint: "Fills the field with a hash or URL" }
}
