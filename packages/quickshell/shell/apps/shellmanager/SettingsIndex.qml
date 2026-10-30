pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The search over the shell's settings: every page's rows from
// config/settings-index.json (scripts/settings_index.py, rebuilt with the
// pages). The Shell Manager's sidebar search and the launcher's Shell tab share
// it. The file is read the first time a search needs it (`load()`), not at start.
Singleton {
  id: root

  property var entries: []
  property bool wanted: false

  function load() { wanted = true; }

  FileView {
    path: root.wanted ? Quickshell.shellDir + "/config/settings-index.json" : ""
    printErrors: false
    onLoaded: { try { root.entries = JSON.parse(text()); } catch (e) { root.entries = []; } }
  }

  // letters and digits only, lower case: "wifi" finds "Wi-Fi", "dark mode" finds "Dark  mode"
  function norm(s) { return (s ?? "").toLowerCase().replace(/[^a-z0-9а-яё]+/g, ""); }
  // the words of a text, lower case: a hint matches by whole-word starts ("scan" finds "Scan files",
  // not "…ing a scan…" inside a word), so a hint or a place does not match every row near it
  function words(s) { return (s ?? "").toLowerCase().split(/[^a-z0-9а-яё]+/).filter(w => w !== ""); }
  function wordsMatch(text, q) {
    const w = words(text);
    const tokens = words(q);
    return tokens.length > 0 && tokens.every(t => w.some(x => x.startsWith(t)));
  }

  // the rows for a typed text: a label match before an alias, a hint or a place one
  function search(raw) {
    const q = norm(raw);
    if (q === "") return [];
    const index = entries;
    const aliased = e => (e.aliases ?? []).some(a => norm(a).includes(q));
    const first = index.filter(e => norm(e.label).includes(q));
    const second = index.filter(e => !first.includes(e) && aliased(e));
    const then = index.filter(e => !first.includes(e) && !second.includes(e) && wordsMatch(e.hint, raw));
    // the page or group named (a place) only when nothing else answers
    const place = first.length + second.length + then.length > 0 ? []
      : index.filter(e => wordsMatch(e.where, raw));
    return first.concat(second, then, place).slice(0, 30);
  }
}
