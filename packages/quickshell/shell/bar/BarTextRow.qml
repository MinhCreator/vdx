import QtQuick
import qs.config
import qs.kit

// The first row of a module's BAR group: Content (its own text, the options under
// it), Name (the module's name) or Icon (no text). Set `module`; the content
// options show only under Content. A module without content (`hasContent: false`)
// has Name and Icon only.
KitOptionRow {
  property bool hasContent: true
  readonly property bool content: ModuleSettings.get(module, "text", fallback) === "content"   // the content rows' `visible`

  key: "text"
  fallback: hasContent ? "content" : "name"
  label: "Bar text"
  model: hasContent
    ? [{ label: "Content", value: "content" }, { label: "Name", value: "name" }, { label: "Icon", value: "icon" }]
    : [{ label: "Name", value: "name" }, { label: "Icon", value: "icon" }]
}
