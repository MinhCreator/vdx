pragma Singleton
import QtQuick

// The hub's blocks under the clock and day (which is always there): which there are, in what
// order, and which are shown. Bar › Hub sets them, the island's hub reads them. Stored in
// ModuleSettings "hub": `blocks` (the order) and `blocksOff` (the hidden ones).
QtObject {
  id: root

  // id -> what it is, in the default order
  readonly property var all: ["tiles", "week", "sliders", "player", "modules"]
  readonly property var names: ({ tiles: "Toggles", week: "Calendar", player: "Player", sliders: "Sliders", modules: "Module chips" })
  readonly property var notes: ({
    tiles: "The tiles of the Hub row: Wi-Fi, Bluetooth, VPN, Focus",
    week: "The week, or the whole month",
    player: "Opens the Music popup",
    sliders: "Sound, brightness and the rest you pick",
    modules: "The Hub row's other modules, as chips"
  })

  readonly property var saved: ModuleSettings.get("hub", "blocks", []) ?? []
  readonly property var off: ModuleSettings.get("hub", "blocksOff", []) ?? []

  // the saved order first, then what it did not name (a block added later lands at the end)
  readonly property var order: saved.filter(id => all.includes(id)).concat(all.filter(id => !saved.includes(id)))

  // (the player once had a switch of its own, ShellSettings look hubPlayer: off there is off here)
  function shown(id) { return !off.includes(id) && !(id === "player" && ShellSettings.look("hubPlayer", "island") === false); }
  function setOrder(list) { ModuleSettings.set("hub", "blocks", list); }
  function setShown(id, on) {
    if (id === "player" && on) ShellSettings.setLook("hubPlayer", true, "island");
    const rest = off.filter(x => x !== id);
    ModuleSettings.set("hub", "blocksOff", on ? rest : rest.concat([id]));
  }
}
