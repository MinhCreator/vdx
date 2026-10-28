import QtQuick
import qs.config
import qs.kit

// Notifications › App colours: rules that give an app's avatar a colour. A rule is
// a piece of the app's name and a colour from the list; the first one that fits
// wins, an app with none gets its own stable colour. Stored in the module's
// settings as `appColours` [{app, colour}].
Column {
  id: root

  readonly property var rules: ModuleSettings.get("notifications", "appColours", []) ?? []
  // apps in the history with no rule yet: a click makes the rule
  readonly property var seen: {
    const out = [];
    for (const n of NotificationsService.items)
      if (n.app !== "" && !out.includes(n.app)) out.push(n.app);
    return out.filter(a => !rules.some(r => (r.app ?? "") !== "" && a.toLowerCase().includes(r.app.toLowerCase()))).slice(0, 6);
  }

  function save(list) { ModuleSettings.set("notifications", "appColours", list); }
  function add(app) {
    const next = Theme.autoColourName(app);
    save(rules.concat([{ app: app, colour: app === "" ? Theme.appPalette[rules.length % Theme.appPalette.length] : next }]));
  }
  function edit(i, change) { save(rules.map((r, j) => j === i ? Object.assign({}, r, change) : r)); }
  function remove(i) { save(rules.filter((r, j) => j !== i)); }

  KitLabel { text: "APP COLOURS"; about: "Each app's avatar has its own colour; a rule picks yours" }

  KitRow {
    label: "Add a rule"
    hint: "A piece of the name; the first match wins"
    KitButton { icon: "plus"; text: "Add rule"; onClicked: root.add("") }
  }

  // the apps seen lately, one click each
  Item {
    visible: root.seen.length > 0
    width: parent.width
    height: visible ? Math.max(Theme.rowHeight, chips.implicitHeight + 12) : 0

    KitText {
      id: fromHistory
      anchors { left: parent.left; verticalCenter: parent.verticalCenter }
      text: "From history"
      color: Theme.foreground2
      font.pixelSize: Theme.fontSize - 1
    }
    Flow {
      id: chips
      anchors { left: fromHistory.right; leftMargin: Theme.gapWide; right: parent.right; verticalCenter: parent.verticalCenter }
      spacing: Theme.gapSmall
      Repeater {
        model: root.seen
        KitButton { required property string modelData; text: modelData; onClicked: root.add(modelData) }
      }
    }
  }

  // a rule: the app's name (a piece of it), its colour, away
  Repeater {
    model: root.rules.length

    Item {
      id: rule
      required property int index
      readonly property var rl: root.rules[index] ?? ({ app: "", colour: "blue" })

      width: root.width
      height: Theme.rowHeight + 8

      // the avatar as the rule will draw it
      Rectangle {
        id: sample
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        width: 28
        height: 28
        radius: Theme.radiusFor(height)
        color: Theme.mix(Theme.background0, Theme.paletteColour(rule.rl.colour), 0.22)
        KitText {
          anchors.centerIn: parent
          text: (rule.rl.app || "?").slice(0, 1).toUpperCase()
          color: Theme.paletteColour(rule.rl.colour)
          font.weight: Font.Medium
        }
      }

      KitInput {
        id: field
        anchors { left: sample.right; leftMargin: Theme.gapWide; verticalCenter: parent.verticalCenter }
        width: Math.max(120, parent.width * 0.34)
        placeholder: "App name"
        text: rule.rl.app
        onTextEdited: root.edit(rule.index, { app: text })
      }

      KitButton {
        id: away
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        icon: "x"
        Accessible.name: "Remove the rule"
        onClicked: root.remove(rule.index)
      }

      KitSwatches {
        anchors { right: away.left; rightMargin: Theme.gapWide; verticalCenter: parent.verticalCenter }
        model: Theme.appPalette
        picked: rule.rl.colour
        colours: name => [Theme.paletteColour(name), Theme.paletteColour(name)]
        onChosen: name => root.edit(rule.index, { colour: name })
      }
    }
  }

  KitGrouper {}
}
