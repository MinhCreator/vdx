import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.bar
import qs.config
import qs.kit

// The previewed theme on a desktop: its wallpaper, the bar with the modules as the
// shell draws them, and two windows over it. The focused one (on top) takes the
// accent frame; both hold the shell's own rows at their real size. `page` is the
// Appearance page (its p(role) gives the previewed theme's colours).
ClippingRectangle {
  id: root

  required property var page

  radius: Theme.radiusCard
  color: page.wallpaper
  border.width: Theme.windowFrameWidth
  border.color: page.p(Theme.material ? "background2" : "gray")

  Behavior on color { enabled: Motion.pages; ColorAnimation { duration: Motion.normal } }

  // the previewed theme's picture, when it has one
  Image {
    anchors.fill: parent
    visible: root.page.previewImage !== ""
    source: visible ? "file://" + WallpaperService.dir + "/" + root.page.previewImage : ""
    sourceSize: Qt.size(width, height)
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
  }

  // the bar's modules as the shell draws them (size, rules), in the previewed colours
  component BarIcons: Row {
    id: icons
    property var ids: []
    property var page: null
    // a rule (custom or automatic) between two modules when the bar draws them
    readonly property var shown: {
      if (!ShellSettings.barSeparators) return ids;
      const out = [];
      ids.forEach((id, i) => {
        if (i > 0 && !BarLayout.isSeparator(id) && !BarLayout.isSeparator(ids[i - 1])) out.push("sep-");
        out.push(id);
      });
      return out;
    }

    spacing: Theme.gapLoose

    Repeater {
      model: icons.shown

      Item {
        id: slot
        required property string modelData
        readonly property bool rule: BarLayout.isSeparator(modelData)

        anchors.verticalCenter: parent.verticalCenter
        width: rule ? 2 + 2 * Theme.separatorMargin : Theme.iconSmall + ShellSettings.barIconGrow
        height: Theme.iconSmall + ShellSettings.barIconGrow

        Rectangle {
          visible: slot.rule
          anchors.centerIn: parent
          width: 2
          height: parent.height
          radius: Theme.pill(width)
          color: icons.page.p("foreground2")
        }

        KitIcon {
          visible: !slot.rule
          anchors.centerIn: parent
          name: BarLayout.icon(slot.modelData)
          tint: icons.page.p("foreground2")
          size: Theme.iconSmall + ShellSettings.barIconGrow
        }
      }
    }
  }

  // the bar: the island as a pill at the top centre, or the strip across the top
  Rectangle {
    id: bar
    readonly property bool island: Theme.island
    x: island ? (root.width - width) / 2 : 0
    y: island ? Theme.islandTop : 0
    width: island ? barRow.implicitWidth + 2 * Theme.gapWide : root.width
    height: island ? Theme.islandHeight : Theme.barHeight
    radius: island ? Math.min(height / 2, Theme.islandRadius) : 0
    color: root.page.p(Theme.material ? "background0" : "background1")

    Row {
      id: barRow
      anchors.centerIn: parent
      spacing: Theme.gapSmall
      visible: bar.island

      BarIcons { page: root.page; ids: BarLayout.islandIn("start", BarLayout.mainScreen()) }
      Text {
        text: "14:32"
        color: root.page.p("foreground0")
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.weight: Font.ExtraBold
      }
      BarIcons { page: root.page; ids: BarLayout.islandIn("end", BarLayout.mainScreen()) }
    }

    BarIcons {
      visible: !bar.island
      anchors { left: parent.left; leftMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }
      page: root.page
      ids: BarLayout.visibleIn("left", BarLayout.mainScreen())
    }
    Text {
      visible: !bar.island
      anchors.centerIn: parent
      text: "14:32"
      color: root.page.p("foreground0")
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontSize
      font.weight: Font.ExtraBold
    }
    BarIcons {
      visible: !bar.island
      anchors { right: parent.right; rightMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }
      page: root.page
      ids: BarLayout.visibleIn("right", BarLayout.mainScreen())
    }
  }

  // a terminal, low and left: a window behind the other
  Rectangle {
    id: terminal
    x: 14
    y: bar.y + bar.height + 56
    width: Math.round(root.width * 0.62)
    height: root.height - y - 14
    radius: Theme.radiusSurface
    color: root.page.p("gray")

    Rectangle {
      anchors.fill: parent
      anchors.margins: Theme.windowFrameWidth
      radius: Math.max(0, terminal.radius - Theme.windowFrameWidth)
      color: root.page.p("background0")
      clip: true

      Column {
        x: 14
        y: 12
        spacing: 6

        Text { text: "❯ ls ~/dotfiles"; color: root.page.p("green"); font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize }
        Text { text: "packages/   themes/   hypr/"; color: root.page.p("blue"); font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize }
        Text { text: "install.py   README.md"; color: root.page.p("foreground2"); font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize }
        Text { text: "❯ █"; color: root.page.p("aqua"); font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize }
      }
    }
  }

  // the focused window, on top and right: the accent frame, the shell's rows
  Rectangle {
    id: settings
    x: Math.round(root.width * 0.44)
    y: bar.y + bar.height + 14
    width: root.width - x - 14
    height: Math.round(terminal.y + terminal.height * 0.62 - y)
    radius: Theme.radiusSurface
    gradient: Gradient {
      orientation: Gradient.Horizontal
      GradientStop { position: 0; color: Theme.accentFor("window", root.page.p("frame")) }
      GradientStop { position: 1; color: Theme.accentEndFor("window", root.page.p("frame")) }
    }

    Rectangle {
      anchors.fill: parent
      anchors.margins: Theme.windowFrameWidth
      radius: Math.max(0, settings.radius - Theme.windowFrameWidth)
      color: root.page.p("background0")
      clip: true

      Column {
        x: 14
        y: 14
        width: parent.width - 28
        spacing: Theme.gapMedium

        KitRow {
          label: "Wi-Fi"
          KitSwitch { checked: true }
        }

        KitSliderRow {
          label: "Volume"
          text: "60%"
          value: 0.6
        }

        KitRow {
          label: "Layout"
          KitChoices {
            width: 130
            model: [
              { label: "Master", value: "master" },
              { label: "Stack", value: "stack" }
            ]
            current: "master"
          }
        }
      }
    }
  }
}
