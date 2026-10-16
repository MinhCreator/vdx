import QtQuick
import Quickshell.Widgets
import qs.components
import qs.config
import qs.kit

// The launcher (Super+R), like rofi: the screen dims, in the middle a
// search over one of four lists — Apps, Files (in ~), Shell (the shell's own
// actions) and Power. Typing filters, ↑ ↓ pick, Enter runs, Tab / Shift+Tab
// switch the list, Escape or a click on the dimmed screen closes.
ScrimWindow {
  id: root

  readonly property var ls: LauncherService
  // Shell Manager › Launcher (ModuleSettings "launcher")
  readonly property int rows: ModuleSettings.get("launcher", "rows", 8)
  readonly property int panelWidth: ({ small: 520, medium: 640, large: 800 })[ModuleSettings.get("launcher", "size", "medium")] ?? 640
  readonly property string position: ModuleSettings.get("launcher", "position", "top")
  readonly property string opens: ModuleSettings.get("launcher", "opens", "apps")
  readonly property bool clearOnClose: ModuleSettings.get("launcher", "clear", true)
  readonly property bool english: ModuleSettings.get("launcher", "english", true)
  property string tab: "apps"
  property int current: 0
  readonly property string query: field.text.trim().toLowerCase()
  readonly property var tabs: ls.tabs
  readonly property var items: tab === "apps" ? ls.apps(query)
                             : tab === "files" ? ls.fileItems()
                             : tab === "shell" ? ls.filter(ls.shellItems, query)
                             : ls.filter(ls.powerItems, query)

  function close() { ls.open = false; }
  function runAt(i) {
    const item = items[i];
    if (!item) return;
    close();
    item.run();
  }
  function step(d) {
    const i = tabs.findIndex(t => t.value === tab);
    tab = tabs[(i + d + tabs.length) % tabs.length].value;
  }

  onTabChanged: { current = 0; if (tab === "files") filesTimer.restart(); }
  onQueryChanged: { current = 0; if (tab === "files") filesTimer.restart(); }
  onCurrentChanged: list.positionViewAtIndex(current, ListView.Contain)

  open: ls.open
  namespace: "launcher"
  onDismissed: close()

  Connections {
    target: root.ls
    function onOpenChanged() {
      if (!root.ls.open) return;
      if (root.clearOnClose) field.text = "";
      if (root.english) root.ls.englishLayout();
      root.tab = root.tabs.some(t => t.value === root.opens) ? root.opens : root.tabs[0].value;
      root.current = 0;
      field.input.forceActiveFocus();
    }
  }

  Timer {
    id: filesTimer
    interval: 200
    onTriggered: root.ls.searchFiles(root.query)
  }

  Item {
    anchors.fill: parent

    // clicks on the panel don't reach the dimmed screen
    MouseArea { anchors.fill: panel }

    KitFrame {
      id: panel
      anchors.horizontalCenter: parent.horizontalCenter
      y: root.position === "center" ? (parent.height - height) / 2
       : root.position === "bottom" ? parent.height * 0.82 - height
       : parent.height * 0.18
      width: root.panelWidth

      KitInput {
        id: field
        width: parent.width
        placeholder: root.tab === "files" ? "File name in ~" : "Search " + root.tabs.find(t => t.value === root.tab).label.toLowerCase()

        input.Keys.onPressed: event => {
          const k = event.key;
          if (k === Qt.Key_Escape) root.close();
          else if (k === Qt.Key_Down) root.current = Math.min(root.current + 1, root.items.length - 1);
          else if (k === Qt.Key_Up) root.current = Math.max(root.current - 1, 0);
          else if (k === Qt.Key_Return || k === Qt.Key_Enter) root.runAt(root.current);
          else if (k === Qt.Key_Backtab || (k === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) root.step(-1);
          else if (k === Qt.Key_Tab) root.step(1);
          else return;
          event.accepted = true;
        }
      }

      KitChoices {
        width: parent.width
        stretch: true
        model: root.tabs
        current: root.tab
        onPicked: value => { root.tab = value; field.input.forceActiveFocus(); }
      }

      KitLine {}

      Item {
        width: parent.width
        height: root.rows * 44

        KitText {
          anchors.centerIn: parent
          visible: root.items.length === 0
          color: Theme.muted
          text: root.tab === "files" ? (root.ls.searching ? "Searching…" : root.query.length < 2 ? "Type two letters or more." : "Nothing found.")
                                     : "Nothing found."
        }

        ListView {
          id: list
          anchors.fill: parent
          clip: true
          model: root.items
          boundsBehavior: Flickable.StopAtBounds

          delegate: Rectangle {
            id: row
            required property var modelData
            required property int index
            readonly property bool selected: index === root.current

            width: list.width
            height: 44
            color: selected ? Theme.background3 : "transparent"

            IconImage {
              id: image
              x: 10
              anchors.verticalCenter: parent.verticalCenter
              implicitSize: 24
              source: row.modelData.image ?? ""
              visible: source != ""
            }

            KitIcon {
              x: 12
              anchors.verticalCenter: parent.verticalCenter
              visible: !image.visible
              name: row.modelData.icon ?? "app-window"
              size: 20
              tint: row.selected ? Theme.foreground0 : Theme.foreground2
            }

            Column {
              x: 46
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width - x - keys.width - 20

              KitText {
                width: parent.width
                elide: Text.ElideRight
                text: row.modelData.title
                font.weight: row.selected ? Font.ExtraBold : Theme.fontWeight
              }

              KitText {
                width: parent.width
                visible: text !== ""
                elide: Text.ElideRight
                text: row.modelData.hint ?? ""
                color: Theme.muted
                font.pixelSize: Theme.fontSize - 2
              }
            }

            KitText {
              id: keys
              anchors.right: parent.right
              anchors.rightMargin: 12
              anchors.verticalCenter: parent.verticalCenter
              text: row.modelData.keys ?? ""
              color: Theme.muted
              font.pixelSize: Theme.fontSize - 2
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onEntered: root.current = row.index
              onClicked: root.runAt(row.index)
            }
          }
        }
      }

      KitLine {}

      KitText {
        width: parent.width
        horizontalAlignment: Text.AlignRight
        color: Theme.muted
        font.pixelSize: Theme.fontSize - 2
        text: "↑ ↓ pick · enter run · tab list · esc close"
      }
    }
  }
}
