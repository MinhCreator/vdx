pragma Singleton
import QtQuick
import Quickshell

// Theme — single place every module reads from.
//
// Colors are aliased from the Colors singleton (base = gruvbox fallback; the
// active theme overlays Colors.qml via install.py). Metrics, font, shared
// Nerd Font glyphs and script paths — the parts that don't change per theme —
// live here.
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
  readonly property color muted:  Colors.muted   // kitty color8 — disconnected / secondary
  readonly property color frame:  Colors.frame   // hyprland active_border (#282828)
  readonly property color dim:    Colors.dim     // rofi `fg` / kitty color0

  // theme-dependent module values (mirrors themes/<t>/waybar/modules/*.jsonc)
  readonly property string workspaceFormat: Colors.workspaceFormat
  readonly property string workspaceIconDefault: Colors.workspaceIconDefault
  readonly property string workspaceIconActive: Colors.workspaceIconActive

  // ---- bar metrics (waybar: styles/base.css + modules/00-global.jsonc) ----
  readonly property string fontFamily: "JetBrainsMono Nerd Font"
  readonly property int fontSize: 13
  readonly property int fontWeight: Font.ExtraBold   // CSS font-weight: 800
  readonly property int barHeight: 34
  readonly property int moduleSpacing: 2
  readonly property int edgeMargin: 20               // #workspaces margin-left / #language margin-right
  readonly property int separatorMargin: 8           // #custom-separator margin-left/right
  readonly property int workspaceMinWidth: 16        // GTK theme `button { min-width:16px }`
  // Pango (waybar) advances text ~0.8px wider per module than Qt (Quickshell),
  // which accumulates across the right-hand group. Add it back as spacing so
  // the eleven right-side items line up with waybar (the left group has only
  // one text module, so it needs no correction).
  readonly property real rightGroupSpacingExtra: 0.8

  // ---- polling / restart intervals, same as waybar configs -----------------
  readonly property int clockIntervalMs: 1000
  readonly property int brightnessIntervalMs: 2000
  readonly property int networkIntervalMs: 5000
  readonly property int batteryIntervalMs: 3000
  readonly property int vpnIntervalMs: 2000
  readonly property int audioPortIntervalMs: 2000    // pactl active-port poll
  readonly property int mediaRestartMs: 5000         // waybar media restart-interval
  readonly property int mediaMaxLength: 60           // waybar media max-length

  // ---- interaction limits (waybar pulseaudio/brightness) -------------------
  readonly property int audioMaxPercent: 150         // max-volume
  readonly property int audioScrollStep: 5           // scroll-step
  readonly property int brightnessScrollStep: 5

  // ---- language formats (waybar format-en / format-ru) ---------------------
  readonly property string languageFormatEn: "US"
  readonly property string languageFormatRu: "RU"

  // ---- Nerd Font glyphs — same codepoints as the waybar module configs -----
  // (the wifi, battery and brightness glyphs are emitted by their scripts, so
  //  they are not duplicated here.)
  readonly property string iconVolumeOff: "\uF026"     // volume off
  readonly property string iconVolumeLow: "\uF027"     // volume low
  readonly property string iconVolumeHigh: "\uF028"    // volume high
  readonly property string iconHeadphone: "\uF025"     // headphone
  readonly property string iconMuted: "\uEEE8"         // muted (audio.jsonc)
  readonly property string iconMihomo: "\uF132"        // shield — mihomo module
  readonly property string iconPower: "\uF011"         // power — service toggle
  readonly property string iconRefresh: "\uF021"       // refresh
  readonly property string iconSettings: "\uF013"      // gear — open mihomo config
  readonly property string iconDots: "\uF141"          // … — open provider config
  readonly property string iconSpinner: "\uF110"       // busy spinner (rotated)
  readonly property string iconOk: "\uF00C"            // check — success
  readonly property string iconError: "\uF00D"         // times — failure
  readonly property string ellipsis: "\u2026"          // …

  // ---- mihomo popup (rofi-style square frame) ------------------------------
  readonly property int popupWidth: 370
  readonly property int popupFrameWidth: 4              // hyprland border_size
  readonly property int popupPadding: 10
  readonly property int popupGap: 6                     // gap between bar and popup
  readonly property int mihomoRowHeight: 26
  readonly property int mihomoVisibleRows: 8
  readonly property int switchWidth: 34                 // square toggle (popup header)
  readonly property int switchKnob: 14

  // ---- scripts --------------------------------------------------------------
  readonly property string mediaToggleScript: scriptsDir + "/media.sh"
  readonly property string brightnessScript: scriptsDir + "/brightness.sh"
  readonly property string networkScript: scriptsDir + "/network.sh"
  readonly property string vpnScript: scriptsDir + "/vpn.sh"
  readonly property string batteryScript: scriptsDir + "/battery.sh"
  readonly property string sinkPortScript: scriptsDir + "/sink_port.sh"
  readonly property string mihomoScript: scriptsDir + "/mihomo.sh"

  // policy group the mihomo rules use (custom/… in config.yaml)
  readonly property string mihomoGroup: "Proxies"
  readonly property int mihomoStatusIntervalMs: 2000
  readonly property int mihomoTrafficRestartMs: 2000

  // shellDir = directory containing shell.qml (~/.config/quickshell when linked)
  readonly property string scriptsDir: Quickshell.shellDir + "/scripts"
}