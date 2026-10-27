import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.bar
import qs.config
import qs.kit
import qs.modules.sysmon

// A non-interactive layout preview: no volume, brightness or session actions.
Item {
  id: root
  property string screenName: ""
  readonly property bool hasPlayer: ShellSettings.look("hubPlayer", "island")
  readonly property bool hasModules: BarLayout.islandIn("hub", screenName).length > 0
  readonly property string layout: "chips"
  readonly property bool grid: layout === "grid"
  readonly property bool grouped: layout === "grouped"
  readonly property bool kitUnboxed: true
  readonly property var sliderRows: [
    { key: "volume", icon: "volume", value: 0.65 },
    { key: "microphone", icon: "mic", value: 0.4 },
    { key: "brightness", icon: "sun", value: 0.75 },
    { key: "dimming", icon: "moon", value: 1 }
  ].filter(s => ModuleSettings.get("hub", s.key, s.key === "volume" || s.key === "brightness"))
  implicitHeight: sample.implicitHeight + 2 * Theme.gapWide
  Rectangle {
    id: sample
    anchors.horizontalCenter: parent.horizontalCenter
    width: Math.min(root.width, ModuleSettings.get("hub", "width", 400))
    implicitHeight: body.implicitHeight + 2 * Theme.gapWide
    height: implicitHeight
    radius: Theme.radiusSurface
    color: Theme.background0
    border.width: Theme.hairline
    border.color: Theme.controlLineHover
    Column {
      id: body
      x: Theme.gapWide; y: Theme.gapWide
      width: parent.width - 2 * Theme.gapWide
      spacing: Theme.sectionGap
      Item {
        width: parent.width; height: 38
        ClippingRectangle {
          id: avatar
          anchors { left: parent.left; verticalCenter: parent.verticalCenter }
          width: 34; height: 34; radius: Theme.radiusFor(height); color: Theme.pickFill
          Image {
            id: avatarImage
            anchors.fill: parent
            readonly property string path: ModuleSettings.get("hub", "avatar", "")
            source: path ? "file://" + path : ""
            fillMode: Image.PreserveAspectCrop
            visible: status === Image.Ready
          }
          KitText { anchors.centerIn: parent; visible: !avatarImage.visible; text: (Quickshell.env("USER") || "U").slice(0, 1).toUpperCase() }
        }
        Column {
          anchors { left: avatar.right; leftMargin: Theme.gapMedium; right: actions.left; rightMargin: Theme.gapSmall; verticalCenter: parent.verticalCenter }
          spacing: Theme.gapTight
          KitText { width: parent.width; text: Quickshell.env("USER") || "User"; elide: Text.ElideRight; font.weight: Font.Medium }
          KitText { width: parent.width; text: "Up " + Math.floor(SysmonService.uptime / 3600) + "h " + Math.floor(SysmonService.uptime % 3600 / 60) + "m"; color: Theme.muted; elide: Text.ElideRight; font.pixelSize: Theme.fontSize - 1 }
        }
        Row {
          id: actions
          anchors { right: parent.right; verticalCenter: parent.verticalCenter }
          spacing: Theme.gapSmall
          KitIcon { name: "settings"; size: 16 }
          KitIcon { name: "power"; size: 16 }
        }
      }
      KitLine { visible: root.hasPlayer || root.sliderRows.length > 0 || root.hasModules }
      Rectangle {
        visible: root.hasPlayer
        width: parent.width; height: 36; radius: Theme.radiusControl; color: Theme.controlFill
        border.width: Theme.frameWidth
        border.color: Theme.controlLine
        Row {
          anchors { left: parent.left; leftMargin: Theme.gapMedium; verticalCenter: parent.verticalCenter }
          spacing: Theme.gapMedium
          KitIcon { name: "music"; anchors.verticalCenter: parent.verticalCenter; size: 16 }
          KitText { text: "Media player"; color: Theme.muted; font.pixelSize: Theme.fontSize - 1 }
        }
        KitIcon { anchors { right: parent.right; rightMargin: Theme.gapWide; verticalCenter: parent.verticalCenter } name: "play"; size: 16 }
      }
      KitLine { visible: root.hasPlayer && root.sliderRows.length > 0 }
      Repeater {
        model: root.sliderRows
        Item {
          id: sliderRow
          required property var modelData
          width: body.width; height: 28
          KitIcon { id: icon; anchors.verticalCenter: parent.verticalCenter; name: sliderRow.modelData.icon; size: 14 }
          Rectangle {
            anchors { left: icon.right; leftMargin: Theme.gapWide; right: parent.right; rightMargin: 38; verticalCenter: parent.verticalCenter }
            height: Theme.material ? 10 : 3; radius: Theme.pill(height); color: Theme.background3
            Rectangle {
              width: parent.width * sliderRow.modelData.value; height: parent.height; radius: parent.radius
              gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.accentFor("sliders", Theme.foreground0) } GradientStop { position: 1; color: Theme.accentOn("sliders") ? Theme.accentEnd : Theme.foreground0 } }
            }
          }
          KitText { anchors { right: parent.right; verticalCenter: parent.verticalCenter } text: Math.round(sliderRow.modelData.value * 100) + "%"; color: Theme.muted; font.pixelSize: Theme.fontSize - 1 }
        }
      }
      KitLine { visible: root.hasModules && (root.hasPlayer || root.sliderRows.length > 0) }
      Column {
        width: parent.width
        spacing: Theme.gapMedium
        Repeater {
          model: BarLayout.hubGroups(BarLayout.islandIn("hub", root.screenName), root.layout)
          Column {
            id: moduleGroup
            required property var modelData
            width: parent.width
            spacing: Theme.gapTight
            KitLabel { visible: root.grouped; text: moduleGroup.modelData.label.toUpperCase() }
            Flow {
              id: chips
              width: parent.width
              spacing: Theme.gapSmall
              Repeater {
                model: moduleGroup.modelData.ids
                Rectangle {
                  id: chip
                  required property string modelData
                  width: root.grid ? (chips.width - chips.spacing) / 2 : Math.min(content.implicitWidth + 16, body.width)
                  height: root.grouped ? 32 : root.grid ? 44 : Theme.material ? 30 : 28
                  radius: root.grid ? Theme.radiusControl : Theme.radiusFor(height)
                  color: Theme.controlFill
                  border.width: Theme.frameWidth
                  border.color: Theme.controlLine
                  clip: true
                  Row {
                    id: content
                    anchors.verticalCenter: parent.verticalCenter
                    x: root.grid ? Theme.gapLoose : (parent.width - width) / 2
                    spacing: Theme.gapSmall
                    KitIcon { name: BarLayout.icon(chip.modelData); size: Theme.iconSmall; anchors.verticalCenter: parent.verticalCenter }
                    KitText { visible: ModuleSettings.get(chip.modelData, "text", "content") !== "icon"; text: BarLayout.label(chip.modelData); font.pixelSize: Theme.fontSize - 1; anchors.verticalCenter: parent.verticalCenter }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
