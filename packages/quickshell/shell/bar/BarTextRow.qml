import QtQuick
import qs.kit

// The first row of a module's BAR group, in every module that has a text on its
// face: Content (its own text, the options under it) or Name (the module's name,
// BarLayout.faceText). Set `module`; its content options hide under Name.
KitOptionRow {
  key: "text"
  fallback: "content"
  label: "Bar text"
  model: [{ label: "Content", value: "content" }, { label: "Name", value: "name" }]
}
