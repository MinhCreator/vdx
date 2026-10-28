import QtQuick
import qs.config
import qs.kit

// Bar › Live: the island's live activities — what grows out of the pill, in
// priority order — and the rules that apply to all of them.
Column {
  id: root

  spacing: Theme.sectionGap

  KitText {
    width: parent.width
    text: "Things that grow out of the pill. The row order is the priority: the top one takes the pill, the others wait in the wheel."
    color: Theme.muted
    wrapMode: Text.WordWrap
    font.pixelSize: Theme.fontSize - 1
  }

  BarLiveSection {
    width: parent.width
    section: "asks"
    title: "Asks"
    caption: "waits for an answer"
    text: "Needs your attention, so it takes the front of the queue. Keep it for things you must not miss."
    info: ({
      notice: { label: "Messages", hint: "A new notification, as a toast on the pill" },
      battery: { label: "Low battery", hint: "The charge left, when it runs low" },
      bluetooth: { label: "Device connected", hint: "Headphones and other Bluetooth devices" }
    })
  }

  BarLiveSection {
    width: parent.width
    title: "Low battery"
    caption: "selected above"
    text: "Choose when it interrupts. \"Until fixed\" keeps it up until the charger is back or the charge recovers; \"5 s\" lets it fold away by itself."
    Column {
      width: parent.width
      KitRow {
        label: "Interrupts below"
        wide: true
        KitSegments {
          model: [{label: "10%", value: 10}, {label: "15%", value: 15}, {label: "20%", value: 20}, {label: "30%", value: 30}]
          current: ShellSettings.liveBatteryBelow
          onPicked: value => ShellSettings.setLook("liveBatteryBelow", value, "island")
        }
      }
      KitRow {
        label: "Stays for"
        wide: true
        KitSegments {
          model: [{label: "5 s", value: "5s"}, {label: "Until fixed", value: "fixed"}]
          current: ShellSettings.liveBatteryStay
          onPicked: value => ShellSettings.setLook("liveBatteryStay", value, "island")
        }
      }
    }
  }

  BarLiveSection {
    width: parent.width
    section: "held"
    title: "Held"
    caption: "stays while it runs"
    text: "Stays as long as the job runs, then folds away on its own. When several run at once, scroll over the pill to page through them. Drag a row up to let it take the pill first."
    info: ({
      recording: { label: "Recording", hint: "A timer while the screen records" },
      update: { label: "Updates", hint: "Progress of an update run" },
      backup: { label: "Backup", hint: "Progress of a backup" },
      vpn: { label: "VPN", hint: "Which server and the ping" },
      music: { label: "Music", hint: "The playing track and its sound" }
    })
  }

  BarLiveSection {
    width: parent.width
    section: "flash"
    title: "Flash"
    caption: "passes by"
    text: "A short note about a quick change. It shows for a moment, then folds back to rest. Nothing to click, so turn off the ones you find noisy."
    info: ({
      volume: { label: "Volume and brightness", hint: "A level while you change it" },
      mic: { label: "Microphone", hint: "When the mic is muted or unmuted" },
      layout: { label: "Keyboard layout", hint: "EN → RU when it changes" },
      track: { label: "New track", hint: "Cover and title when the song changes" },
      plugged: { label: "Plugged in", hint: "Charge when the cable connects" }
    })
  }

  Rectangle {
    width: parent.width
    implicitHeight: rules.implicitHeight + 16
    radius: Theme.radiusCard
    color: Theme.background1

    Column {
      id: rules
      anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 22; rightMargin: 22; topMargin: 8 }

      Item {
        width: parent.width
        height: 44
        KitText { anchors { left: parent.left; verticalCenter: parent.verticalCenter } text: "Behaviour"; font.weight: Font.Medium }
        KitText { anchors { right: parent.right; verticalCenter: parent.verticalCenter } text: "every activity"; color: Theme.muted; font.pixelSize: Theme.fontSize - 2 }
      }
      KitText {
        width: Math.min(parent.width, 600)
        text: "Rules that apply to all of them. The row order above is the priority: when two things happen at once, the higher row wins the pill and the other waits in the wheel."
        color: Theme.muted
        font.pixelSize: Theme.fontSize - 1
        wrapMode: Text.WordWrap
        bottomPadding: 12
      }

      KitSliderRow {
        label: "Flash lasts"
        snaps: [0, 1/6, 2/6, 3/6, 4/6, 5/6, 1]
        value: (ShellSettings.liveFlashMs - 1000) / 3000
        text: ((pressed ? 1000 + Math.round(dragValue * 6) * 500 : ShellSettings.liveFlashMs) / 1000).toFixed(1) + " s"
        onMoved: value => ShellSettings.setLook("liveFlashMs", 1000 + Math.round(value * 6) * 500, "island")
      }
      KitSliderRow {
        label: "Return to rest after"
        snaps: [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1]
        value: (ShellSettings.liveFullMs - 1000) / 5000
        text: ((pressed ? 1000 + Math.round(dragValue * 10) * 500 : ShellSettings.liveFullMs) / 1000).toFixed(1) + " s"
        onMoved: value => ShellSettings.setLook("liveFullMs", 1000 + Math.round(value * 10) * 500, "island")
      }
      KitRow {
        label: "Expand on arrival"
        hint: "A new activity opens whole, not as a chip"
        KitSwitch { checked: ShellSettings.liveExpand; onToggled: ShellSettings.setLook("liveExpand", !checked, "island") }
      }
      KitRow {
        label: "Wheel pages through them"
        hint: "Scrolling over the pill moves between running activities"
        KitSwitch { checked: ShellSettings.liveWheel; onToggled: ShellSettings.setLook("liveWheel", !checked, "island") }
      }
      KitRow {
        label: "Open on hover"
        hint: "The folded activity opens where it is"
        KitSwitch { checked: ShellSettings.liveHover; onToggled: ShellSettings.setLook("liveHover", !checked, "island") }
      }
    }
  }
}
