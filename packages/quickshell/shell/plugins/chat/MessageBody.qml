import QtQuick
import Quickshell
import qs.config
import qs.kit

// One message's text: prose as Markdown, each ``` fenced block as code — a
// framed box with its language and Copy. User messages and errors stay plain.
Column {
  id: root

  property string text: ""
  property bool markdown: true
  property color color: Theme.foreground0

  // [{code: bool, lang, text}] in order
  readonly property var parts: {
    if (!markdown) return [{ code: false, lang: "", text: text }];
    const out = [];
    const re = /```([\w+-]*)[^\n]*\n([\s\S]*?)(?:```|$)/g;
    let last = 0, m;
    while ((m = re.exec(text)) !== null) {
      if (m.index > last) out.push({ code: false, lang: "", text: text.slice(last, m.index).trim() });
      out.push({ code: true, lang: m[1], text: m[2].replace(/\n$/, "") });
      last = re.lastIndex;
    }
    if (last < text.length) out.push({ code: false, lang: "", text: text.slice(last).trim() });
    return out.filter(p => p.code || p.text !== "");
  }

  spacing: 8

  Repeater {
    model: root.parts

    Loader {
      id: part
      required property var modelData
      width: root.width
      sourceComponent: part.modelData.code ? codeBlock : prose

      Component {
        id: prose

        TextEdit {
          readOnly: true
          selectByMouse: true
          wrapMode: TextEdit.Wrap
          textFormat: root.markdown ? TextEdit.MarkdownText : TextEdit.PlainText
          text: part.modelData.text
          color: root.color
          selectionColor: Theme.background3
          selectedTextColor: Theme.foreground1
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontSize
          font.weight: Font.DemiBold
        }
      }

      Component {
        id: codeBlock

        Rectangle {
          implicitHeight: codeColumn.implicitHeight + 16
          color: Theme.background1
          border.width: Theme.frameWidth
          border.color: Theme.gray

          Column {
            id: codeColumn
            x: 10
            y: 8
            width: parent.width - 20
            spacing: 6

            Item {
              width: parent.width
              height: copy.height

              KitText {
                anchors.verticalCenter: parent.verticalCenter
                text: (part.modelData.lang || "code").toUpperCase()
                color: Theme.muted
                font.pixelSize: Theme.fontSize - 2
                font.letterSpacing: 1
              }

              KitButton {
                id: copy
                anchors.right: parent.right
                icon: "clipboard"
                text: "Copy"
                onClicked: Quickshell.execDetached(["wl-copy", "--", part.modelData.text])
              }
            }

            TextEdit {
              width: parent.width
              readOnly: true
              selectByMouse: true
              wrapMode: TextEdit.WrapAnywhere
              textFormat: TextEdit.PlainText
              text: part.modelData.text
              color: Theme.foreground1
              selectionColor: Theme.background3
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSize - 1
            }
          }
        }
      }
    }
  }
}
