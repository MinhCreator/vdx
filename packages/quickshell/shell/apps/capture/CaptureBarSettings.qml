import QtQuick
import qs.bar
import qs.config
import qs.kit

// Capture's bar module options (Apps › Bar module): the face, and what the
// popup shows. The popup's choices themselves (region, shot, the codec...) are
// the app's and always there; these toggles only hide what you do not use.
Column {
  spacing: Theme.gapGroup

  KitLabel { text: "BAR" }
  BarTextRow { module: "capture" }

  KitLine {}

  KitLabel { text: "POPUP SHOWS" }

  KitToggleRow { module: "capture"; key: "popupSound"; fallback: true; label: "Sound"; hint: "Off, system or mic" }
  KitToggleRow { module: "capture"; key: "popupFps"; fallback: true; label: "Frame rate"; hint: "30 or 60 fps" }
  KitToggleRow { module: "capture"; key: "popupQuality"; fallback: true; label: "Quality"; hint: "Low, medium or high" }
  KitToggleRow { module: "capture"; key: "popupAdvanced"; fallback: true; label: "Advanced"; hint: "Codec and encoder, folded" }
  KitToggleRow { module: "capture"; key: "popupAdvancedOpen"; fallback: false; label: "Advanced open"; hint: "Unfolded when it opens" }
  KitToggleRow { module: "capture"; key: "popupNotes"; fallback: true; label: "Problem notes"; hint: "Yellow when a setting hurts" }
  KitToggleRow { module: "capture"; key: "popupCursor"; fallback: true; label: "Cursor toggle"; hint: "Keep the pointer out of it" }
}
