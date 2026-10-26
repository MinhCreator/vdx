import QtQuick
import Quickshell.Io

// The options of settings.json with their defaults: ShellSettings' file reads
// into one; a second, never written, gives the defaults (ShellSettings.reset).
JsonAdapter {
  property int version: 0         // schema (scripts/settings_migrate.py stamps it)
  property bool solidIcons: false
  property string managerStart: "main"
  property string managerTab: "appearance"
  property string font: "JetBrainsMono Nerd Font"
  property int textSize: 13
  property string underlineAnimation: "none"
  property string wallpaperMode: "theme"
  property string wallpaperColor: "#32302f"
  property var wallpaperImages: ({})
  property var wallpaperOutputs: ({})
  property bool pauseMusic: false
  property bool resumeMusic: true
  property bool barRightSettings: true
  property bool barFolderDot: true
  property string barDotColor: "red"
  property string barStyle: "solid"
  property var looks: ({})
  property string corners: "sharp"
  property bool material: false
  property string visualStyle: "material"
  property bool accent: false
  property var accentStops: ["blue", "purple"]
  property bool accentGradient: false
  property var accentCustom: ["", ""]
  property var accentWhere: ({})
  property bool passwordDots: false
  property int cornerRadius: 12
  property bool cornerSplit: false
  property var cornerRadii: ({})
  property bool motion: true
  property string motionSpeed: "normal"
  property string motionPopups: "slide"
  property bool motionPanels: true
  property bool motionControls: true
  property bool motionBar: true
  property bool motionPages: true
  property bool motionLock: true
  property bool motionIsland: true
}
