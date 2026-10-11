pragma Singleton
import QtQuick
import Quickshell

// Theme — the single place every module reads from.
//
// Colors are aliased from the Colors singleton (base = gruvbox fallback; the
// active theme overlays Colors.qml via install.py). Metrics, the shared font,
// Nerd Font glyphs, script paths and formatting helpers — the parts that don't
// change per theme — live here.
//
// Quickshell auto-registers this file as a singleton (`singleton Theme 1.0`).

QtObject {
  id: root

  // ---- palette (from the active theme's Colors.qml) -----------------------
  readonly property color background0: Colors.background0
  readonly property color background1: Colors.background1
  readonly property color background2: Colors.background2
  readonly property color background3: Colors.background3

  readonly property color foreground0: Colors.foreground0
  readonly property color foreground1: Colors.foreground1
  readonly property color foreground2: Colors.foreground2

  readonly property color red:    Colors.red
  readonly property color orange: Colors.orange
  readonly property color yellow: Colors.yellow
  readonly property color green:  Colors.green
  readonly property color aqua:   Colors.aqua
  readonly property color blue:   Colors.blue
  readonly property color purple: Colors.purple
  readonly property color gray:   Colors.gray
  readonly property color muted:  Colors.muted
  readonly property color frame:  Colors.frame
  readonly property color dim:    Colors.dim

  // theme-dependent module values (mirrors themes/<t>/waybar/modules/*.jsonc)
  readonly property string workspaceFormat: Colors.workspaceFormat
  readonly property string workspaceIconDefault: Colors.workspaceIconDefault
  readonly property string workspaceIconActive: Colors.workspaceIconActive

  // ---- bar metrics ---------------------------------------------------------
  readonly property string fontFamily: "JetBrainsMono Nerd Font"
  readonly property int fontSize: 13
  readonly property int fontWeight: Font.ExtraBold
  readonly property int barHeight: 34
  readonly property int moduleSpacing: 2
  readonly property int edgeMargin: 20
  readonly property int separatorMargin: 8
  readonly property int workspaceMinWidth: 16

  // ---- polling / restart intervals -----------------------------------------
  readonly property int clockIntervalMs: 1000
  readonly property int brightnessIntervalMs: 2000
  readonly property int batteryIntervalMs: 3000
  readonly property int audioPortIntervalMs: 2000
  readonly property int mediaRestartMs: 5000
  readonly property int mediaMaxLength: 60

  // ---- interaction limits --------------------------------------------------
  readonly property int audioMaxPercent: 150
  readonly property int audioScrollStep: 5
  readonly property int brightnessScrollStep: 5

  // ---- language formats ----------------------------------------------------
  readonly property string languageFormatEn: "US"
  readonly property string languageFormatRu: "RU"

  // ---- Nerd Font glyphs ----------------------------------------------------
  // All from the same Nerd Fonts v2/v3 FA range (\uF000–\uF2FF) except where a
  // wider codepoint is required (Material Design icons live above the BMP and
  // use surrogate pairs, written as "\uDB81\uDCxx" below).
  readonly property string iconVolumeOff: "\uF026"
  readonly property string iconVolumeLow: "\uF027"
  readonly property string iconVolumeHigh: "\uF028"
  readonly property string iconHeadphone: "\uF025"
  readonly property string iconMuted: "\uEEE8"
  readonly property string iconMihomo: "\uF132"
  readonly property string iconSettings: "\uF013"
  readonly property string iconRefresh: "\uF021"        // nf-fa-refresh — UPDATE
  readonly property string iconPing: "\uF0E7"           // nf-fa-bolt — health-check / PING
  readonly property string iconDots: "\uF141"
  readonly property string iconSpinner: "\uF110"
  readonly property string iconOk: "\uF00C"
  readonly property string iconError: "\uF00D"
  readonly property string ellipsis: "\u2026"
  readonly property string iconWifi: "\uF1EB"
  readonly property string iconLock: "\uF023"
  readonly property string iconQr: "\uDB81\uDC32"       // nf-md-qrcode
  readonly property string iconSpeedtest: "\uDB81\uDCC5" // nf-md-speedometer
  readonly property string iconHome: "\uF015"            // nf-fa-home

  // ---- popup chrome --------------------------------------------------------
  readonly property int popupWidth: 370
  readonly property int popupFrameWidth: 4
  readonly property int popupPadding: 10
  readonly property int popupGap: 6
  readonly property int rowHeight: 26
  readonly property int visibleRows: 8
  readonly property int switchWidth: 34
  readonly property int switchKnob: 14
  readonly property int popupInputHeight: 24

  // ---- wifi popup ----------------------------------------------------------
  readonly property int wifiStatusIntervalMs: 5000
  readonly property int wifiTrafficRestartMs: 2000
  readonly property int wifiPingIntervalMs: 3000

  // ---- mihomo --------------------------------------------------------------
  readonly property string mihomoGroup: "Proxies"
  readonly property int mihomoStatusIntervalMs: 2000
  readonly property int mihomoTrafficRestartMs: 2000

  // ---- scripts -------------------------------------------------------------
  readonly property string scriptsDir: Quickshell.shellDir + "/scripts"
  readonly property string mediaScript: scriptsDir + "/media.sh"
  readonly property string brightnessScript: scriptsDir + "/brightness.sh"
  readonly property string batteryScript: scriptsDir + "/battery.sh"
  readonly property string sinkPortScript: scriptsDir + "/sink_port.sh"
  readonly property string mihomoScript: scriptsDir + "/mihomo.sh"
  readonly property string wifiScript: scriptsDir + "/wifi.sh"

  // ---- shared formatting ---------------------------------------------------
  // Bytes per second, human-readable (used by the wifi + mihomo popups).
  function humanRate(bytes) {
    if (bytes < 1024) return Math.round(bytes) + " B/s";
    if (bytes < 1048576) return (bytes / 1024).toFixed(1) + " KB/s";
    if (bytes < 1073741824) return (bytes / 1048576).toFixed(1) + " MB/s";
    return (bytes / 1073741824).toFixed(2) + " GB/s";
  }

  // Cumulative byte counters, human-readable.
  function humanSize(bytes) {
    if (bytes < 1024) return Math.round(bytes) + " B";
    if (bytes < 1048576) return (bytes / 1024).toFixed(1) + " KB";
    if (bytes < 1073741824) return (bytes / 1048576).toFixed(1) + " MB";
    if (bytes < 1099511627776) return (bytes / 1073741824).toFixed(2) + " GB";
    return (bytes / 1099511627776).toFixed(2) + " TB";
  }
}
