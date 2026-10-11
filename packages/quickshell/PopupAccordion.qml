import QtQuick

// Collapsible section for the popup chrome — a full-width header that toggles
// a clipped content area underneath. Shared by every plugin that needs
// progressive disclosure: a long list, an inline form, anything that would
// otherwise crowd the popup.
//
// Interaction model:
//   * the whole header row is the hit target, not just the chevron
//   * the chevron rotates 90° when open (▶ → ▼)
//   * the content height animates, the popup grows / shrinks smoothly
//   * the default content slot is a Column, so children stack vertically with
//     `spacing: 8` — the same rhythm used everywhere else in the popup
//
// Visual state:
//   * collapsed: transparent header, dim chevron — just a row of "places you
//     could go"
//   * expanded:  2px accent bar on the left + background2 header + foreground0
//     chevron — same visual language as a selected list row, so "this one is
//     open" reads the same way everywhere in the popup
//
// Group coordination: give several accordions the same `group` QtObject and at
// most one of them will be expanded at a time. The internal logic lives in a
// Connections block rather than an onExpandedChanged handler, because an
// instance-level onExpandedChanged in the owner would otherwise override it.

Item {
  id: root

  property string title: ""
  property string glyph: ""
  property string badge: ""
  property bool expanded: false
  property bool disabled: false
  property var group: null

  default property alias content: body.data
  property alias trailing: trailingSlot.data

  signal toggled()

  readonly property bool interactive: !root.disabled
  // Background shows on hover AND while the section is open — the same
  // subtle fill used by hover in the lists.
  readonly property bool highlighted: root.interactive && (headerArea.containsMouse || root.expanded)

  implicitHeight: header.height + contentArea.height

  // ---- group coordination ------------------------------------------------
  Connections {
    target: root
    function onExpandedChanged() {
      if (!root.group) return;
      if (root.expanded) {
        var prev = root.group.openSection;
        if (prev && prev !== root) prev.expanded = false;
        root.group.openSection = root;
      } else if (root.group.openSection === root) {
        root.group.openSection = null;
      }
    }
  }

  Connections {
    target: root.group
    function onOpenSectionChanged() {
      if (root.group.openSection !== root && root.expanded) root.expanded = false;
    }
  }

  // ---- header ------------------------------------------------------------
  Rectangle {
    id: header
    width: parent.width
    height: 28
    color: root.highlighted ? Theme.background2 : "transparent"

    // 2px accent bar on the left while the section is open — the same marker
    // used by the selected row in the lists, so "this one is active" reads
    // identically across the popup.
    Rectangle {
      visible: root.expanded
      anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
      width: 2
      color: Theme.foreground0
    }

    // Hit target first — the visual children below paint on top of it, and the
    // trailing buttons on top of everything else, so each layer swallows only
    // its own clicks and passes the rest down.
    MouseArea {
      id: headerArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: {
        if (!root.interactive) return;
        root.expanded = !root.expanded;
        root.toggled();
      }
    }

    Text {
      id: chevron
      anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
      text: "\u25B6"
      color: root.disabled ? Theme.muted
           : root.expanded ? Theme.foreground0
           : Theme.dim
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontSize - 3
      font.weight: Theme.fontWeight
      rotation: root.expanded ? 90 : 0

      Behavior on rotation {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
      }

      Behavior on color {
        ColorAnimation { duration: 120 }
      }
    }

    Text {
      id: glyphText
      anchors {
        left: chevron.right; leftMargin: 6
        verticalCenter: parent.verticalCenter
      }
      visible: root.glyph !== ""
      text: root.glyph
      color: root.disabled ? Theme.muted : Theme.foreground0
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontSize
      font.weight: Theme.fontWeight
    }

    Text {
      id: titleText
      anchors {
        left: glyphText.visible ? glyphText.right : chevron.right
        leftMargin: 6
        verticalCenter: parent.verticalCenter
      }
      text: root.title
      color: root.disabled ? Theme.muted : Theme.foreground0
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontSize
      font.weight: Theme.fontWeight
      font.letterSpacing: 1
    }

    // trailing slot on the right — declared after the hit-target MouseArea and
    // after the visual texts, so its own MouseAreas win the click race.
    Item {
      id: trailingSlot
      anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
      width: childrenRect.width
      height: childrenRect.height
      visible: children.length > 0
    }

    Text {
      id: badgeText
      anchors {
        right: trailingSlot.visible ? trailingSlot.left : parent.right
        rightMargin: 8
        verticalCenter: parent.verticalCenter
      }
      visible: root.badge !== ""
      text: root.badge
      color: Theme.dim
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontSize - 3
      font.weight: Theme.fontWeight
    }
  }

  // ---- content -----------------------------------------------------------
  Item {
    id: contentArea
    y: header.height
    width: parent.width
    height: root.expanded ? body.implicitHeight + 6 : 0
    clip: true

    Behavior on height {
      NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

    Column {
      id: body
      anchors { top: parent.top; topMargin: 6; left: parent.left; right: parent.right }
      spacing: 8
    }
  }
}
