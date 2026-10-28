import QtQuick
import qs.config
import qs.kit

// Bar › Live: the island's live activities — what grows out of the pill, in
// priority order — and the rules that apply to all of them. An activity's own options
// open under its row (LiveOptions).
Column {
  id: root

  Column {
    width: parent.width

    KitLabel { text: "LIVE ACTIVITIES" }
    KitRow {
      label: "Live activities"
      hint: "Off: nothing grows out of the pill, it stays at rest"
      KitSwitch { checked: ShellSettings.liveEnabled; onToggled: ShellSettings.setLook("liveEnabled", !checked, "island") }
    }
    KitGrouper {}
  }

  KitLine { visible: ShellSettings.liveEnabled }

  BarLiveSection {
    width: parent.width
    visible: ShellSettings.liveEnabled
    section: "asks"
    title: "ASKS"
    info: ({
      notice: { label: "Messages", hint: "A new notification as a line in the slot; off: a card" },
      battery: { label: "Low battery", hint: "The charge left, when it runs low" },
      bluetooth: { label: "Device connected", hint: "Headphones and other Bluetooth devices" }
    })
  }

  KitLine { visible: ShellSettings.liveEnabled }

  BarLiveSection {
    width: parent.width
    visible: ShellSettings.liveEnabled
    section: "held"
    title: "HELD"
    about: "They stay while the job runs; drag a row to set who takes the pill first"
    info: ({
      recording: { label: "Recording", hint: "A timer while the screen records" },
      update: { label: "Updates", hint: "Progress of an update run" },
      backup: { label: "Backup", hint: "Progress of a backup" },
      vpn: { label: "VPN", hint: "Which server and the ping" },
      music: { label: "Music", hint: "The playing track and its sound" }
    })
  }

  KitLine { visible: ShellSettings.liveEnabled }

  BarLiveSection {
    width: parent.width
    visible: ShellSettings.liveEnabled
    section: "flash"
    title: "FLASH"
    info: ({
      volume: { label: "Volume and brightness", hint: "A level while you change it" },
      mic: { label: "Microphone", hint: "When the mic is muted or unmuted" },
      layout: { label: "Keyboard layout", hint: "EN → RU when it changes" },
      plugged: { label: "Plugged in", hint: "Charge when the cable connects" }
    })
  }

  KitLine { visible: ShellSettings.liveEnabled }

  Column {
    width: parent.width
    visible: ShellSettings.liveEnabled

    KitLabel { text: "BEHAVIOUR" }

    KitSliderRow {
      label: "Flash lasts"
      snaps: [0, 1/6, 2/6, 3/6, 4/6, 5/6, 1]
      value: (ShellSettings.liveFlashMs - 1000) / 3000
      text: ((pressed ? 1000 + Math.round(dragValue * 6) * 500 : ShellSettings.liveFlashMs) / 1000).toFixed(1) + " s"
      onMoved: value => ShellSettings.setLook("liveFlashMs", 1000 + Math.round(value * 6) * 500, "island")
    }
    KitRow {
      label: "Wheel pages through them"
      hint: "Scrolling over the pill moves between running activities"
      KitSwitch { checked: ShellSettings.liveWheel; onToggled: ShellSettings.setLook("liveWheel", !checked, "island") }
    }
    KitGrouper {}
  }

  KitGrouper {}
}
