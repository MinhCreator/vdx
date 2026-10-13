import QtQuick
import qs.components
import qs.config

Column {
  id: root

  spacing: 4

  ThemeText {
    text: !WifiService.radioOn ? "WI-FI IS OFF"
        : WifiService.networks.length > 0 ? "NETWORKS"
        : "NO NETWORKS FOUND"
    color: WifiService.radioOn && WifiService.networks.length > 0 ? Theme.foreground0 : Theme.muted
    font.letterSpacing: 1
  }

  Flickable {
    width: parent.width
    height: Math.min(contentHeight, Theme.rowHeight * Theme.visibleRows)
    contentHeight: rows.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
      id: rows
      width: parent.width

      Repeater {
        model: WifiService.networks

        NetworkRow { width: rows.width }
      }
    }
  }
}
