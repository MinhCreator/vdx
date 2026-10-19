import QtQuick
import qs.config
import qs.kit

// Appearance › FONT: a sample in the selected font beside the list; Apply
// installs it if needed and makes it the system one. Then the shell's text size.
Column {
  id: root

  // the font in the preview; Apply installs it if needed and makes it the system one
  property string fontSelected: FontService.current
  readonly property var fontRow: FontService.fonts.find(f => f.family === fontSelected) ?? null
  readonly property var fontRows: FontService.fonts.map(f => ({ key: f.family, label: f.family.replace(" Nerd Font", ""),
                                                               installed: f.installed, family: f.family }))

  spacing: Theme.gapGroup

  KitLabel {
    id: fontGroup
    text: "FONT"
    value: FontService.current.replace(" Nerd Font", "").toUpperCase() + " · " + ShellSettings.textSize + " PX"
  }

  // a sample in the selected font beside the list
  Row {
    width: parent.width
    spacing: Theme.gapGroup

    Rectangle {
      radius: Theme.radiusControl
      width: parent.width - fontList.width - 14
      height: fontList.height
      color: Theme.controlFill
      border.width: Theme.frameWidth
      border.color: Theme.gray

      // a font installed after the shell started can't be drawn until it restarts
      readonly property bool drawable: root.fontRow !== null && root.fontRow.installed
                                       && Qt.fontFamilies().includes(root.fontRow.family)

      Column {
        x: 14
        y: 14
        width: parent.width - 28
        spacing: Theme.gapLoose
        visible: parent.drawable

        KitText {
          text: "Appearance"
          font.family: root.fontSelected
          font.weight: Font.ExtraBold
          font.pixelSize: Theme.fontSize + 3
        }

        KitText {
          text: "CONNECTED · RULE · 82%"
          color: Theme.muted
          font.family: root.fontSelected
          font.pixelSize: Theme.fontSize - 2
        }

        KitText {
          width: parent.width
          text: "The quick brown fox jumps over the lazy dog."
          wrapMode: Text.WordWrap
          font.family: root.fontSelected
        }

        KitText {
          text: "0123456789 {}[]() => != -> <="
          color: Theme.foreground2
          font.family: root.fontSelected
        }

        KitText {
          text: "iIlL1| oO0 ❯ ~/.dotfiles"
          color: Theme.foreground2
          font.family: root.fontSelected
        }
      }

      KitText {
        anchors.centerIn: parent
        width: parent.width - 40
        visible: !parent.drawable
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        color: Theme.muted
        text: root.fontRow && !root.fontRow.installed
          ? "Not installed yet.\nApply downloads it and restarts the shell."
          : "Installed after the shell started.\nApply restarts the shell to draw it."
      }
    }

    Column {
      id: fontList
      width: Theme.sideWidth
      height: 240
      spacing: Theme.gapMedium

      PickList {
        width: parent.width
        height: parent.height - fontButtons.height - parent.spacing
        model: root.fontRows
        selected: root.fontSelected
        current: FontService.current
        working: FontService.working
        onPicked: row => root.fontSelected = row.key
      }

      Row {
        id: fontButtons
        width: parent.width
        spacing: Theme.gapSmall

        KitButton {
          width: (parent.width - parent.spacing) / 2
          icon: "x"
          text: "Cancel"
          disabled: root.fontSelected === FontService.current || FontService.busy
          onClicked: root.fontSelected = FontService.current
        }

        KitButton {
          width: (parent.width - parent.spacing) / 2
          icon: root.fontRow && !root.fontRow.installed ? "download" : "check"
          text: "Apply"
          busy: FontService.busy
          disabled: root.fontSelected === FontService.current || root.fontRow === null
          onClicked: FontService.apply(root.fontRow)
        }
      }
    }
  }

  // the shell's own text (Theme.fontSize); larger stops at 15: the bar's and rows' heights are fixed
  KitRow {
    wide: true
    label: "Text size"
    hint: "The bar keeps its height"

    KitChoices {
      stretch: true
      model: [12, 13, 14, 15].map(n => ({ label: n + " px", value: n }))
      current: ShellSettings.textSize
      onPicked: value => ShellSettings.set("textSize", value)
    }
  }

  KitText {
    width: parent.width
    visible: FontService.error !== ""
    text: FontService.error
    color: Theme.red
    wrapMode: Text.WordWrap
    font.pixelSize: Theme.fontSize - 1
  }
}
