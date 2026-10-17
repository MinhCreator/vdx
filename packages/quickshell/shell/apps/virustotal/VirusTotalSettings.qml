import QtQuick
import qs.kit
import qs.config

// VirusTotal options in the Shell Manager (ModuleSettings "virustotal"): what
// the window remembers, how long a lookup waits, and what Report does. The
// bar module's own row is VirusTotalBarSettings (Shell apps › BAR).
KitColumn {
  spacing: Theme.gapGroup

  KitLabel { text: "HISTORY" }

  KitOptionRow {
    module: "virustotal"; key: "historyKeep"; fallback: 20
    label: "Lookups kept"; hint: "Under the field, newest first"
    model: [{ label: "None", value: 0 }, { label: "20", value: 20 }, { label: "50", value: 50 }]
  }

  KitToggleRow {
    module: "virustotal"; key: "keepHistory"; fallback: false
    visible: ModuleSettings.get("virustotal", "historyKeep", 20) !== 0
    label: "Keep between runs"; hint: "Saved in the state folder"
  }

  KitLine {}

  KitLabel { text: "LOOKUPS" }

  KitOptionRow {
    module: "virustotal"; key: "waitSeconds"; fallback: 90
    label: "Wait for analysis"; hint: "Max wait for new files"
    model: [{ label: "30 s", value: 30 }, { label: "90 s", value: 90 }, { label: "3 min", value: 180 }]
  }

  KitOptionRow {
    module: "virustotal"; key: "reportAction"; fallback: "browser"
    label: "Report button"; hint: "Opens the page or copies link"
    model: [{ label: "Browser", value: "browser" }, { label: "Copy link", value: "copy" }]
  }
}
