import QtQuick
import qs.config
import qs.kit

// Clipboard history, newest first: text previews and image thumbnails. Click
// to copy it back (COPIED, then the popup closes), × to delete it; drag text
// or an image out into any app. A search
// field narrows the list; Clear empties it (the limit: Shell Manager › Plugins).
KitFrame {
  id: root

  property string query: ""
  property bool confirmClear: false
  property string copiedId: ""      // the entry just copied: COPIED, then close

  readonly property var shown: ClipboardService.entries.filter(e =>
    query.trim() === "" || (e.kind === "text" && e.preview.toLowerCase().includes(query.trim().toLowerCase())))

  signal picked()

  Timer {
    id: copiedTimer
    interval: 800
    onTriggered: {
      root.copiedId = "";
      root.picked();
    }
  }

  function when(time) {
    const d = new Date(time * 1000);
    const today = d.toDateString() === new Date().toDateString();
    return Qt.formatDateTime(d, today ? "HH:mm" : "dd.MM HH:mm");
  }

  // ---- header ----------------------------------------------------------------
  KitHeader {
    icon: "clipboard"
    title: "Clipboard"
    subtitle: ClipboardService.entries.length + " OF " + ClipboardService.limit + " KEPT"

    KitButton {
      icon: "trash"
      text: root.confirmClear ? "Sure?" : "Clear"
      disabled: ClipboardService.entries.length === 0
      onClicked: {
        if (!root.confirmClear) { root.confirmClear = true; return; }
        root.confirmClear = false;
        ClipboardService.clear();
      }
    }
  }

  KitInput {
    width: parent.width
    visible: ClipboardService.entries.length > 0
    placeholder: "search text"
    text: root.query
    onTextEdited: root.query = text
  }

  KitLine {}

  KitText {
    visible: root.shown.length === 0
    text: ClipboardService.entries.length === 0 ? "Nothing copied yet." : "No text matches \"" + root.query + "\"."
    color: Theme.muted
    font.pixelSize: Theme.fontSize - 1
  }

  // ---- history -------------------------------------------------------------------
  Flickable {
    width: parent.width
    visible: root.shown.length > 0
    height: Math.min(contentHeight, 440)
    contentHeight: rows.implicitHeight
    interactive: contentHeight > height
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
      id: rows
      width: parent.width
      spacing: 10

      Repeater {
        model: root.shown

        // like a notification: a caps line (kind left, time right), then
        // the content; lines between entries
        Column {
          id: item

          required property var modelData
          required property int index

          readonly property bool image: modelData.kind === "image"
          readonly property bool hot: area.containsMouse || remove.containsMouse

          width: rows.width
          spacing: 3

          KitLine { visible: item.index > 0 }
          Item { width: 1; height: item.index > 0 ? 6 : 0 }

          Item {
            width: parent.width
            height: entry.implicitHeight

            // hover: the entry is clickable
            Rectangle {
              anchors { fill: parent; margins: -4 }
              color: item.hot ? Theme.background1 : "transparent"
            }

            Column {
              id: entry
              width: parent.width
              spacing: 3

              Item {
                width: parent.width
                height: kind.implicitHeight

                KitText {
                  id: kind
                  anchors { left: parent.left; right: time.left; rightMargin: 8 }
                  text: root.copiedId === item.modelData.id ? "COPIED"
                      : item.image ? "IMAGE · " + thumb.sourceSize.width + "×" + thumb.sourceSize.height : "TEXT"
                  elide: Text.ElideRight
                  color: root.copiedId === item.modelData.id ? Theme.green : Theme.muted
                  font.pixelSize: Theme.fontSize - 2
                  font.letterSpacing: 1
                }

                KitText {
                  id: time
                  anchors.right: parent.right
                  visible: !item.hot
                  text: root.when(item.modelData.time)
                  color: Theme.muted
                  font.pixelSize: Theme.fontSize - 2
                }

                // delete: takes the time's place on hover
                KitIcon {
                  anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                  visible: item.hot
                  name: "x"
                  size: 14
                  tint: remove.containsMouse ? Theme.red : Theme.foreground2
                }
              }

              KitText {
                width: parent.width
                visible: !item.image
                text: item.modelData.preview.trim().replace(/\s+/g, " ")
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
              }

              Image {
                id: thumb
                visible: item.image
                source: item.image ? "file://" + item.modelData.path : ""
                width: Math.min(parent.width, sourceSize.width)
                height: visible ? Math.min(90, implicitHeight * width / Math.max(1, implicitWidth)) : 0
                fillMode: Image.PreserveAspectFit
                horizontalAlignment: Image.AlignLeft
                asynchronous: true
                cache: false

                Rectangle {
                  anchors.fill: parent
                  color: "transparent"
                  border.width: 1
                  border.color: Theme.gray
                }
              }
            }

            // click copies; an image can be dragged out as its file
            MouseArea {
              id: area
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              drag.target: dragProxy
              onClicked: {
                ClipboardService.copy(item.modelData.id);
                root.copiedId = item.modelData.id;
                copiedTimer.restart();
              }
            }

            MouseArea {
              id: remove
              anchors { right: parent.right; top: parent.top }
              width: 20
              height: kind.implicitHeight
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: ClipboardService.remove(item.modelData.id)
            }

            Item {
              id: dragProxy
              Drag.active: area.drag.active
              Drag.dragType: Drag.Automatic
              Drag.supportedActions: Qt.CopyAction
              Drag.mimeData: item.image ? { "text/uri-list": "file://" + item.modelData.path }
                                        : { "text/plain": item.modelData.preview }
              Drag.imageSource: item.image ? "file://" + item.modelData.path : ""
            }
          }
        }
      }
    }
  }

  KitText {
    width: parent.width
    visible: ClipboardService.error !== ""
    text: ClipboardService.error
    color: Theme.red
    wrapMode: Text.WordWrap
    font.pixelSize: Theme.fontSize - 1
  }
}
