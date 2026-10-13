import QtQuick
import qs.config

// Horizontal separator for popup chrome — one file, one look for every popup.
//
// The rect is baked into its own offscreen layer before being composited.
// On a fractional device pixel ratio (1.25×, 1.5×, 1.75×) a line of logical
// height 2 can land half-way between two physical pixel rows for one
// separator and on a whole row for another — same code, visibly different
// thickness. `layer.enabled` makes Qt round the rect to whole device pixels
// before compositing, so every separator ends up the same physical size no
// matter where it sits on the fractional grid. `layer.smooth: false` stops
// the compositor from softening the edge again on the way out.
Rectangle {
  implicitHeight: 1.5
  height: 1.5
  color: Theme.dim

  layer.enabled: true
  layer.smooth: false
}
