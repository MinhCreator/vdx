import QtQuick
import qs.config
import qs.kit

// The capture toolbar, one row: what to capture (region / window / screen), a
// shot or a recording, Options and close. Options shows a summary and opens a
// menu below: the pointer, and for a recording its sound, frame rate, quality
// and encoder (auto: integrated GPU on battery).
Rectangle {
  id: root

  property bool menuOpen: false

  readonly property var labels: ({
    off: "No sound", system: "System sound", mic: "Microphone",
    low: "Low", medium: "Medium", high: "High",
    auto: "Auto", igpu: "iGPU", gpu: "GPU", cpu: "CPU"
  })

  // the menu, one section per setting; record-only ones hide for a shot
  readonly property var sections: [
    { key: "cursor", title: "POINTER", record: false, items: [
      { label: "Hide cursor", value: false }, { label: "Show cursor", value: true }] },
    { key: "audio", title: "SOUND", record: true, items: [
      { label: "Off", value: "off" }, { label: "System", value: "system" }, { label: "Microphone", value: "mic" }] },
    { key: "fps", title: "FRAME RATE", record: true, items: [
      { label: "30 fps", value: 30 }, { label: "60 fps", value: 60 }] },
    { key: "quality", title: "QUALITY", record: true, items: [
      { label: "Low", value: "low" }, { label: "Medium", value: "medium" }, { label: "High", value: "high" }] },
    { key: "encoder", title: "ENCODER", record: true, items: [
      { label: "Auto", value: "auto", hint: CaptureService.encoderInUse === "igpu" ? "iGPU now" : "GPU now" },
      { label: "iGPU", value: "igpu" }, { label: "GPU", value: "gpu" }, { label: "CPU", value: "cpu" }] }
  ]

  readonly property string summary: CaptureService.kind === "record"
    ? [labels[CaptureService.audio], CaptureService.fps + " fps", labels[CaptureService.quality]].join(" · ")
    : CaptureService.cursor ? "Cursor shown" : "Cursor hidden"

  function current(key) {
    return { cursor: CaptureService.cursor, audio: CaptureService.audio, fps: CaptureService.fps,
             quality: CaptureService.quality, encoder: CaptureService.encoder }[key];
  }

  function pick(key, value) {
    if (key === "cursor") CaptureService.setCursor(value);
    else if (key === "audio") CaptureService.setAudio(value);
    else if (key === "fps") CaptureService.setFps(value);
    else if (key === "quality") CaptureService.setQuality(value);
    else if (key === "encoder") CaptureService.setEncoder(value);
  }

  implicitWidth: content.implicitWidth + 24
  implicitHeight: content.implicitHeight + 24
  color: Theme.background0
  border.width: Theme.frameWidth
  border.color: Theme.frame

  // keeps clicks on the toolbar from reaching the selection below
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.AllButtons
  }

  Column {
    id: content
    x: 12
    y: 12
    spacing: 8

    Row {
      id: toolRow
      spacing: 10

      KitChoices {
        model: [
          { label: "Region", value: "region", icon: "crop" },
          { label: "Window", value: "window", icon: "app-window" },
          { label: "Screen", value: "screen", icon: "monitor" }
        ]
        current: CaptureService.mode
        onPicked: value => CaptureService.setMode(value)
      }

      Rectangle { width: 1; height: 30; color: Theme.background3; anchors.verticalCenter: parent.verticalCenter }

      KitChoices {
        model: [
          { label: "Shot",   value: "shot",   icon: "camera" },
          { label: "Record", value: "record", icon: "video" }
        ]
        current: CaptureService.kind
        onPicked: value => CaptureService.setKind(value)
      }

      Rectangle { width: 1; height: 30; color: Theme.background3; anchors.verticalCenter: parent.verticalCenter }

      KitButton {
        id: optionsButton
        icon: "sliders"
        text: root.summary
        selected: root.menuOpen
        onClicked: root.menuOpen = !root.menuOpen
      }

      KitButton {
        icon: "x"
        onClicked: CaptureService.close()
      }
    }

    KitText {
      text: (CaptureService.mode === "region" ? "Drag to select"
           : CaptureService.mode === "window" ? "Click a window"
           : "Click a screen")
        + (CaptureService.kind === "record" ? " to record" : " to capture")
        + " · Esc or right click to cancel"
      color: Theme.muted
      font.pixelSize: Theme.fontSize - 2
    }
  }

  // ---- options menu ------------------------------------------------------------
  // one column right under Options, as wide as it, like a native menu: a caps title per group,
  // the chosen row filled, bold and checked, lines between groups
  Rectangle {
    id: menu
    visible: root.menuOpen
    x: content.x + toolRow.x + optionsButton.x
    y: root.height + 6
    width: optionsButton.width      // as wide as the button it hangs from
    height: groups.implicitHeight + 16
    color: Theme.background0
    border.width: Theme.frameWidth
    border.color: Theme.frame

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.AllButtons
    }

    Column {
      id: groups
      x: Theme.frameWidth
      y: 8
      width: parent.width - 2 * Theme.frameWidth

      Repeater {
        model: root.sections.filter(s => !s.record || CaptureService.kind === "record")

        Column {
          id: group

          required property var modelData
          required property int index

          width: groups.width

          Rectangle {
            visible: group.index > 0
            x: 12
            width: parent.width - 24
            height: 1
            color: Theme.background3
          }

          Item { width: 1; height: group.index > 0 ? 8 : 0 }

          KitText {
            x: 12
            height: implicitHeight + 4
            text: group.modelData.title
            color: Theme.muted
            font.pixelSize: Theme.fontSize - 3
            font.letterSpacing: 1
          }

          Repeater {
            model: group.modelData.items

            Rectangle {
              id: option

              required property var modelData

              readonly property bool active: root.current(group.modelData.key) === modelData.value

              width: group.width
              height: 26
              color: active ? Theme.background3 : optionArea.containsMouse ? Theme.background1 : "transparent"

              KitText {
                anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                text: option.modelData.label
                color: option.active || optionArea.containsMouse ? Theme.foreground0 : Theme.foreground2
                font.weight: option.active ? Font.ExtraBold : Font.DemiBold
              }

              KitText {
                anchors { right: check.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                visible: (option.modelData.hint ?? "") !== ""
                text: option.modelData.hint ?? ""
                color: Theme.muted
                font.pixelSize: Theme.fontSize - 3
              }

              KitIcon {
                id: check
                anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                opacity: option.active ? 1 : 0
                name: "check"
                size: 13
              }

              MouseArea {
                id: optionArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.pick(group.modelData.key, option.modelData.value)
              }
            }
          }

          Item { width: 1; height: 6 }
        }
      }
    }
  }
}
