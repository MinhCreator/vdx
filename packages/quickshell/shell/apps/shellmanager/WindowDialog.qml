import QtQuick
import QtQuick.Controls as Controls
import qs.config
import qs.kit

Item {
  id: root
  property string appId: ""
  readonly property var app: ShellAppsService.windows.find(a => a.id === appId) ?? null
  function close() { appId = ""; }
  visible: app !== null

  Rectangle {
    anchors.fill: parent
    color: Theme.scrim
    MouseArea { anchors.fill: parent; onClicked: root.close() }
  }

  Rectangle {
    id: dialog
    anchors.centerIn: parent
    width: Math.min(parent.width - 48, 900)
    height: Math.min(parent.height - 48, 640)
    radius: Theme.radiusSurface
    color: Theme.background0
    border.width: Theme.windowFrameWidth
    border.color: Theme.popupFrame
    clip: true
    readonly property bool stacked: width < 700
    MouseArea { anchors.fill: parent }

    KitHeader {
      id: heading
      x: Theme.windowPadding; y: Theme.windowPadding
      width: parent.width - 2 * Theme.windowPadding
      title: root.app?.title ?? ""
      subtitle: "WINDOW · APPLIED THE NEXT TIME IT OPENS"
      KitButton { text: "Done"; onClicked: root.close() }
    }

    Flickable {
      id: viewport
      anchors { left: parent.left; right: parent.right; top: heading.bottom; bottom: parent.bottom; margins: Theme.windowPadding }
      contentHeight: content.implicitHeight
      contentWidth: width
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      Controls.ScrollBar.vertical: KitScrollBar {}
      Column {
        id: content
        width: viewport.width
        spacing: Theme.gapWide
        Loader {
          width: parent.width
          active: root.app !== null
          sourceComponent: WindowOptions {
            app: root.app
            ipc: root.app.ipc
            labelled: false
            showPreview: dialog.stacked
          }
        }
      }
      anchors.rightMargin: dialog.stacked ? Theme.windowPadding : preview.width + 2 * Theme.windowPadding
    }
    Column {
      id: preview
      visible: !dialog.stacked && root.app !== null
      width: 260
      anchors { right: parent.right; rightMargin: Theme.windowPadding; top: heading.bottom; topMargin: Theme.windowPadding }
      spacing: Theme.gapWide
      KitLabel { text: "PREVIEW" }
      Loader {
        width: parent.width
        active: preview.visible
        sourceComponent: WindowPreview { app: root.app; settings: root.app.settings }
      }
      KitText {
        width: parent.width
        text: "Size and position are applied the next time this app opens."
        color: Theme.muted
        wrapMode: Text.WordWrap
      }
    }
  }
  Shortcut { sequences: [StandardKey.Cancel]; enabled: root.visible; onActivated: root.close() }
}
