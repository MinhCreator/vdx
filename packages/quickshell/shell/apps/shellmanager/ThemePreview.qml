import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.bar
import qs.config
import qs.kit

// The previewed theme, two parts in one card:
// - the desktop: its wallpaper, the bar with the modules as the shell draws them,
//   a terminal at rest (the theme's palette in use) and the focused Wi-Fi popup
//   over it (accent frame; the surface, a hovered and a selected row, the text
//   levels, a switch, a state colour);
// - the palette: every role by group (surfaces, text, states, terminal); a hover
//   names the role and its contrast, at rest the body text's contrast and grade.
// `page` is the Appearance page (its p(role) gives the previewed theme's colours).
ClippingRectangle {
  id: root

  required property var page

  readonly property var groups: [
    ["background0", "background1", "background2", "background3"],
    ["foreground0", "foreground1", "foreground2", "muted", "dim"],
    ["green", "yellow", "orange", "red"],
    ["aqua", "blue", "purple"]
  ]
  readonly property var surfaces: groups[0]

  property string hovered: ""                 // the role under the pointer in the palette

  readonly property bool current: page.selected === ThemeService.current
  readonly property bool applying: ThemeService.applying === page.selected

  // WCAG 2.x: relative luminance and contrast ratio of two colours
  function lum(c) {
    const f = v => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
    const k = Qt.color(c);
    return 0.2126 * f(k.r) + 0.7152 * f(k.g) + 0.0722 * f(k.b);
  }

  function contrast(a, b) {
    const x = lum(a), y = lum(b);
    return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05);
  }

  // a role against the surface it is read on: a surface against the text
  function ratioOf(role) {
    return surfaces.includes(role) ? contrast(p(role), p("foreground0")) : contrast(p(role), p("background0"));
  }

  function grade(r) { return r >= 7 ? "AAA" : r >= 4.5 ? "AA" : r >= 3 ? "AA LARGE" : "FAIL"; }
  function gradeColour(r) { return r >= 4.5 ? Theme.green : r >= 3 ? Theme.yellow : Theme.red; }

  function p(role) { return page.p(role); }

  readonly property real textRatio: contrast(p("foreground0"), p("background0"))
  readonly property real shownRatio: hovered !== "" ? ratioOf(hovered) : textRatio

  radius: Theme.radiusCard
  color: page.wallpaper
  border.width: Theme.windowFrameWidth
  border.color: p(Theme.material ? "background2" : "gray")

  Behavior on color { enabled: Motion.pages; ColorAnimation { duration: Motion.normal; easing.type: Motion.easing } }

  // a fill in a previewed role: it glides to the next theme's colour
  component Fill: Rectangle {
    Behavior on color { enabled: Motion.pages; ColorAnimation { duration: Motion.normal; easing.type: Motion.easing } }
  }

  // a line of text in a previewed role
  component Line: Text {
    property string role: "foreground0"
    color: root.p(role)
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize - 1
    Behavior on color { enabled: Motion.pages; ColorAnimation { duration: Motion.normal; easing.type: Motion.easing } }
  }

  // ---- desktop ----

  Item {
    id: desktop
    width: root.width
    height: root.height - paletteBar.height

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

          Fill {
            visible: slot.rule
            anchors.centerIn: parent
            width: 2
            height: parent.height
            radius: Theme.pill(width)
            color: root.p("foreground2")
          }

          KitIcon {
            visible: !slot.rule
            anchors.centerIn: parent
            name: BarLayout.icon(slot.modelData)
            tint: root.p("foreground2")
            size: Theme.iconSmall + ShellSettings.barIconGrow
          }
        }
      }
    }

    component Clock: Line {
      text: "14:32"
      font.pixelSize: Theme.fontSize
      font.weight: Font.ExtraBold
    }

    // the bar: the island as a pill at the top centre, or the strip across the top
    Fill {
      id: bar
      readonly property bool island: Theme.island
      x: island ? (desktop.width - width) / 2 : 0
      y: island ? Theme.islandTop : 0
      width: island ? islandRow.implicitWidth + 2 * Theme.gapWide : desktop.width
      height: island ? Theme.islandHeight : Theme.barHeight
      radius: island ? Math.min(height / 2, Theme.islandRadius) : 0
      color: root.p(Theme.material ? "background0" : "background1")

      Row {
        id: islandRow
        anchors.centerIn: parent
        spacing: Theme.gapSmall
        visible: bar.island

        BarIcons { ids: BarLayout.islandIn("start", BarLayout.mainScreen()) }
        Clock {}
        BarIcons { ids: BarLayout.islandIn("end", BarLayout.mainScreen()) }
      }

      BarIcons {
        visible: !bar.island
        anchors { left: parent.left; leftMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }
        ids: BarLayout.visibleIn("left", BarLayout.mainScreen())
      }
      Clock {
        visible: !bar.island
        anchors.centerIn: parent
      }
      BarIcons {
        visible: !bar.island
        anchors { right: parent.right; rightMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }
        ids: BarLayout.visibleIn("right", BarLayout.mainScreen())
      }
    }

    // a window: a frame of `edge` (or the accent gradient when focused), the surface inside
    component DeskWindow: Rectangle {
      id: win
      property bool focused: false
      property color edge: root.p("gray")
      default property alias content: surface.data

      radius: Theme.radiusSurface
      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0; color: win.focused ? Theme.accentFor("window", root.p("frame")) : win.edge }
        GradientStop { position: 1; color: win.focused ? Theme.accentEndFor("window", root.p("frame")) : win.edge }
      }

      Fill {
        id: surface
        anchors { fill: parent; margins: Theme.windowFrameWidth }
        radius: Math.max(0, win.radius - Theme.windowFrameWidth)
        color: root.p("background0")
        clip: true
      }
    }

    readonly property int windowsTop: bar.y + bar.height + Theme.gapWide

    // the terminal, at rest behind the popup: the palette as programs use it
    DeskWindow {
      id: terminal
      x: Theme.gapWide
      y: desktop.windowsTop + 22
      width: Math.round(desktop.width * 0.56)
      height: desktop.height - y - Theme.gapWide

      Column {
        x: Theme.gapWide
        y: Theme.gapLoose
        spacing: Theme.gapHair

        Row { Line { role: "green"; text: "❯ " } Line { text: "git status -s" } }
        Row { Line { role: "yellow"; text: " M " } Line { role: "foreground2"; text: "ThemePreview.qml" } }
        Row { Line { role: "green"; text: " A " } Line { role: "foreground2"; text: "markup.js" } }
        Row { Line { role: "green"; text: "❯ " } Line { text: "ls" } }
        Row {
          spacing: Theme.gapMedium
          Line { role: "blue"; text: "themes/" }
          Line { role: "purple"; text: "install.py" }
          Line { role: "aqua"; text: "README" }
        }
        Row {
          Line { role: "green"; text: "❯ " }
          Fill { width: 7; height: Theme.fontSize; color: root.p("foreground0") }
        }
      }
    }

    // the focused popup, on top: the shell's own Wi-Fi popup in the previewed roles
    DeskWindow {
      id: popup
      focused: true
      x: Math.max(terminal.x + terminal.width - 60, desktop.width - width - Theme.gapWide)
      y: Math.max(bar.y + bar.height + Theme.gapHair, Math.min(desktop.windowsTop, desktop.height - height - Theme.gapWide))
      width: Math.min(250, desktop.width * 0.52)
      height: popupBody.implicitHeight + 2 * Theme.gapWide + 2 * Theme.windowFrameWidth

      Column {
        id: popupBody
        x: Theme.gapWide
        y: Theme.gapWide
        width: parent.width - 2 * Theme.gapWide
        spacing: Theme.gapMedium

        // header: icon, title, caps subtitle; the switch on the right
        Item {
          width: parent.width
          height: 26

          KitIcon {
            id: wifiIcon
            anchors.verticalCenter: parent.verticalCenter
            name: "wifi"
            tint: root.p("foreground0")
            size: 18
          }

          Column {
            anchors { left: wifiIcon.right; leftMargin: Theme.gapMedium; verticalCenter: parent.verticalCenter }

            Line { text: "Wi-Fi"; font.pixelSize: Theme.fontSize; font.weight: Font.ExtraBold }
            Line { role: "muted"; text: "HOME · 5 GHZ"; font.pixelSize: Theme.fontSize - 3; font.letterSpacing: 1 }
          }

          // an on switch: the track, the knob on the right (the accent when Switches takes it)
          Rectangle {
            id: track
            readonly property bool accented: Theme.accentOn("switches")
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            width: 30
            height: 16
            radius: Theme.pill(height)
            gradient: Gradient {
              orientation: Gradient.Horizontal
              GradientStop { position: 0; color: track.accented ? Theme.accent : root.p("background3") }
              GradientStop { position: 1; color: track.accented ? Theme.accentEnd : root.p("background3") }
            }

            Fill {
              anchors { right: parent.right; rightMargin: 2; verticalCenter: parent.verticalCenter }
              width: 12
              height: 12
              radius: Theme.pill(height)
              color: root.p(track.accented ? "background0" : "foreground0")
            }
          }
        }

        Fill { width: parent.width; height: 1; color: root.p("background3") }

        // NETWORKS: the selected row, a hovered one, one at rest
        Column {
          width: parent.width
          spacing: Theme.gapTight

          Item {
            width: parent.width
            height: networksLabel.implicitHeight + Theme.gapHair

            Line { id: networksLabel; role: "muted"; text: "NETWORKS"; font.pixelSize: Theme.fontSize - 3; font.letterSpacing: 1 }
            Line { anchors.right: parent.right; role: "muted"; text: "3"; font.pixelSize: Theme.fontSize - 3; font.letterSpacing: 1 }
          }

          Repeater {
            model: [
              { name: "home", fill: "background3", text: "foreground0", bold: true, note: "connected", noteRole: "green" },
              { name: "café", fill: Theme.material ? "background2" : "background1", text: "foreground0", bold: false, note: "open", noteRole: "muted" },
              { name: "office", fill: "", text: "foreground2", bold: false, note: "", noteRole: "muted" }
            ]

            Fill {
              id: net
              required property var modelData
              width: parent.width
              height: 22
              radius: Theme.radiusControl
              color: modelData.fill !== "" ? root.p(modelData.fill) : Theme.clear

              Line {
                anchors { left: parent.left; leftMargin: Theme.gapMedium; verticalCenter: parent.verticalCenter }
                role: net.modelData.text
                text: net.modelData.name
                font.weight: net.modelData.bold ? Font.ExtraBold : Font.Normal
              }

              Row {
                anchors { right: parent.right; rightMargin: Theme.gapMedium; verticalCenter: parent.verticalCenter }
                spacing: Theme.gapHair

                Fill {
                  visible: net.modelData.noteRole === "green"
                  anchors.verticalCenter: parent.verticalCenter
                  width: 6
                  height: 6
                  radius: Theme.pill(height)
                  color: root.p("green")
                }
                Line {
                  visible: net.modelData.note !== ""
                  role: net.modelData.noteRole
                  text: net.modelData.note
                  font.pixelSize: Theme.fontSize - 2
                }
                KitIcon {
                  visible: net.modelData.note === ""
                  name: "lock"
                  tint: root.p("muted")
                  size: Theme.iconSmall - 2
                }
              }
            }
          }
        }
      }
    }
  }

  // ---- palette ----

  Fill {
    id: paletteBar
    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
    height: 34
    color: root.p("background0")

    Fill { width: parent.width; height: 1; color: root.p("background3") }

    // the roles by group: each group one strip, segments joined
    Row {
      id: strips
      anchors { left: parent.left; leftMargin: Theme.gapWide; verticalCenter: parent.verticalCenter }
      spacing: Theme.gapMedium

      Repeater {
        model: root.groups

        Rectangle {
          id: strip
          required property var modelData
          width: segments.width + 2
          height: 16
          radius: Theme.radiusControl
          color: root.p("background3")             // a hairline round the strip: bg0 shows on bg0

          ClippingRectangle {
            anchors { fill: parent; margins: 1 }
            radius: Math.max(0, strip.radius - 1)
            color: "transparent"

            Row {
              id: segments

              Repeater {
                model: strip.modelData

                Fill {
                  id: seg
                  required property string modelData
                  width: 14
                  height: 14
                  color: root.p(modelData)

                  // the hovered role: a bar under it in the text colour
                  Fill {
                    visible: root.hovered === seg.modelData
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: 3
                    color: root.p(root.surfaces.includes(seg.modelData) ? "foreground0" : "background0")
                  }

                  MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: root.hovered = seg.modelData
                    onExited: if (root.hovered === seg.modelData) root.hovered = ""
                  }
                }
              }
            }
          }
        }
      }
    }

    // at rest: the theme's state and its body text's contrast; on a hover: the role's
    Row {
      anchors { right: parent.right; rightMargin: Theme.gapWide; verticalCenter: parent.verticalCenter }
      spacing: Theme.gapSmall

      KitSpinner {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.applying && root.hovered === ""
      }
      Line {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.width - strips.width > 260
        role: "muted"
        text: root.hovered !== "" ? root.hovered.toUpperCase()
            : (root.current ? "CURRENT" : "PREVIEW") + " · TEXT"
        font.pixelSize: Theme.fontSize - 2
        font.letterSpacing: 1
      }
      Line {
        anchors.verticalCenter: parent.verticalCenter
        text: root.shownRatio.toFixed(1) + ":1 " + root.grade(root.shownRatio)
        color: root.gradeColour(root.shownRatio)
        font.pixelSize: Theme.fontSize - 2
        font.weight: Font.ExtraBold
        font.letterSpacing: 1
      }
    }
  }
}
