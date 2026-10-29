import QtQuick
import qs.config
import qs.kit
import qs.modules.battery

// Power: the platform profile and the charge limit (it was the Battery module's popup
// only). The writes are the service's, the same as the popup's.
Column {
  id: root
  readonly property Item previewItem: null

  readonly property string icon: "zap"
  readonly property string title: "Power"
  readonly property string description: "Power profile and battery charge limit."
  readonly property var jumps: []

  readonly property bool changed: false
  function reset() {}

  spacing: Theme.sectionGap

  // hardware that cannot change: said once, the rows stay away
  KitNotice {
    visible: !BatteryService.present && BatteryService.profiles.length === 0
    icon: "info"
    title: "This computer has nothing to set here"
    text: "No battery and no power profiles were found: the charge limit and the profile are hidden."
  }

  Column {
    width: parent.width
    spacing: Theme.sectionGap
    visible: BatteryService.profiles.length > 0

    KitLabel { text: "PROFILE" }
    KitRow {
      label: "Power profile"
      hint: BatteryService.saver ? "Saver: quiet and slow" : "The one in use now"
      wide: true
      KitSegments {
        model: BatteryService.profiles.map(p => ({ label: p.charAt(0).toUpperCase() + p.slice(1), value: p }))
        current: BatteryService.profile
        onPicked: value => BatteryService.setProfile(value)
      }
    }
    KitGrouper {}
  }

  KitLine { visible: BatteryService.present && BatteryService.limitSupported && BatteryService.profiles.length > 0 }

  Column {
    width: parent.width
    spacing: Theme.sectionGap
    visible: BatteryService.present && BatteryService.limitSupported

    KitLabel { text: "CHARGE" }
    KitRow {
      label: "Charge limit"
      hint: "The battery stops charging here"
      wide: true
      KitSegments {
        model: BatteryService.limits.map(v => ({ label: v + "%", value: v }))
        current: BatteryService.threshold
        onPicked: value => BatteryService.setThreshold(value)
      }
    }
    KitGrouper {}
  }

  KitGrouper {}
}
