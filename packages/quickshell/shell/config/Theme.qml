pragma Singleton
import QtQuick
import Quickshell

// Everything modules read: the theme's colours (from its Colors.qml), type,
// metrics, intervals, script paths and formatting helpers. Icons are SVGs in
// kit/icons, not font glyphs.
QtObject {
  id: root

  // ---- colours (from the active theme's Colors.qml) ----
  // `live` is the active theme's colours read at runtime (ThemeService), so a
  // theme switch recolours everything without reloading the shell.
  property var live: ({})

  readonly property color background0: live.background0 ?? Colors.background0
  readonly property color background1: live.background1 ?? Colors.background1
  readonly property color background2: live.background2 ?? Colors.background2
  readonly property color background3: live.background3 ?? Colors.background3

  readonly property color foreground0: live.foreground0 ?? Colors.foreground0
  readonly property color foreground1: live.foreground1 ?? Colors.foreground1
  readonly property color foreground2: live.foreground2 ?? Colors.foreground2

  readonly property color red:    live.red ?? Colors.red
  readonly property color orange: live.orange ?? Colors.orange
  readonly property color yellow: live.yellow ?? Colors.yellow
  readonly property color green:  live.green ?? Colors.green
  readonly property color aqua:   live.aqua ?? Colors.aqua
  readonly property color blue:   live.blue ?? Colors.blue
  readonly property color purple: live.purple ?? Colors.purple
  readonly property color gray:   live.gray ?? Colors.gray
  readonly property color muted:  live.muted ?? Colors.muted
  readonly property color frame:  live.frame ?? Colors.frame
  readonly property color dim:    live.dim ?? Colors.dim

  // ---- type and bar metrics ----
  readonly property string fontFamily: ShellSettings.font     // the system monospace, Shell Manager › Appearance
  readonly property int fontSize: 13
  readonly property int fontWeight: Font.DemiBold
  readonly property int barHeight: 34
  readonly property int moduleSpacing: 2
  readonly property int edgeMargin: 20
  readonly property int separatorMargin: 8
  readonly property int workspaceMinWidth: 16

  // ---- polling / restart intervals ----
  readonly property int clockIntervalMs: 1000
  readonly property int brightnessIntervalMs: 2000
  readonly property int batteryIntervalMs: 3000
  readonly property int audioPortIntervalMs: 2000
  readonly property int musicRestartMs: 5000
  readonly property int musicCoverSize: 64
  readonly property int musicUpNext: 9             // queue rows visible before scrolling

  // ---- interaction limits ----
  readonly property int audioMaxPercent: 150
  readonly property int audioScrollStep: 5
  readonly property int brightnessScrollStep: 5
  readonly property int nightTemperatureMin: 2000   // K
  readonly property int nightTemperatureMax: 6500   // K
  readonly property int dimGammaMin: 30             // %, lowest gamma of the dim slider

  // ---- battery ----
  readonly property int batteryWarning: 30          // %, yellow
  readonly property int batteryCritical: 15         // %, red
  readonly property var batteryNotifyLevels: [15, 5] // %, low-battery notifications
  readonly property var batteryLimits: [60, 80, 100] // %, charge limit choices
  readonly property string powerSaverProfile: "quiet"  // platform profile of the power saver

  // ---- notifications ----
  readonly property int notificationsMax: 100       // kept in history

  // ---- claude code ----
  readonly property int claudeUsageIntervalMs: 300000   // plan limits poll (API)
  readonly property int claudeLocalIntervalMs: 30000    // today's tokens + sessions, popup open
  readonly property int claudeWarning: 75               // %, bar icon yellow
  readonly property int claudeCritical: 90              // %, bar icon red
  readonly property int ollamaIntervalMs: 5000           // status poll while the tab is open
  readonly property string ollamaCoachModel: "qwen2.5:1.5b"   // the nvim habit coach's model

  // ---- language formats ----
  readonly property string languageFormatEn: "US"
  readonly property string languageFormatRu: "RU"

  // ---- popups (kit) ----
  // the dimmed screen under the launcher, the keybinds and the overview
  readonly property color scrim: Qt.rgba(background0.r, background0.g, background0.b, 0.7)

  // the spacing scale: between the items of a column, in px
  readonly property int gapTight: 2
  readonly property int gapSmall: 6
  readonly property int gapMedium: 8
  readonly property int gapGroup: 14
  readonly property int popupPadding: 16       // a popup's frame, every side (KitFrame)
  readonly property int popupWidth: 370
  // a window's frame: the gap to its edges on every side, and the space the
  // title's line keeps above its capitals (the header draws that far into its box)
  readonly property int windowPadding: 24
  readonly property int headerInset: 3
  readonly property int textDescent: 2          // the line box under a text's baseline, past its ink
  readonly property int controlWidth: 300        // a setting's choices / field (KitRow wide)
  readonly property int rowStackBelow: 480       // a wide KitRow narrower than this puts its control under the label
  readonly property int popupGap: 6
  readonly property int frameWidth: 1          // controls: buttons, selects, fields
  readonly property int windowFrameWidth: 2    // popup frames, like hypr windows, mako
  readonly property int visibleRows: 8
  readonly property int popupStatusMs: 2500       // how long ok / error marks stay
  readonly property string ellipsis: "\u2026"

  // ---- wifi ----
  readonly property int wifiStatusIntervalMs: 5000
  readonly property int wifiPingIntervalMs: 3000
  readonly property int wifiTrafficRestartMs: 2000
  readonly property int wifiSpeedtestTimeoutMs: 60000
  readonly property int wifiBarMaxLength: 14

  // ---- mihomo ----
  readonly property string mihomoGroup: "Proxies"
  readonly property int mihomoStatusIntervalMs: 2000
  readonly property int mihomoTrafficRestartMs: 2000

  // ---- scripts ----
  readonly property string scriptsDir: Quickshell.shellDir + "/scripts"
  readonly property string musicScript: scriptsDir + "/music.sh"
  readonly property string likesScript: scriptsDir + "/yandex_likes.py"
  readonly property string brightnessScript: scriptsDir + "/brightness.sh"
  readonly property string batteryScript: scriptsDir + "/battery.sh"
  readonly property string audioScript: scriptsDir + "/audio.sh"
  readonly property string mihomoScript: scriptsDir + "/mihomo.sh"
  readonly property string wifiScript: scriptsDir + "/wifi.sh"
  readonly property string notificationsScript: scriptsDir + "/notifications.sh"
  readonly property string claudeScript: scriptsDir + "/claude.sh"
  readonly property string ollamaScript: scriptsDir + "/ollama.sh"

  // ---- shared formatting ----
  // Bytes per second, human-readable.
  function humanRate(bytes) {
    if (bytes < 1024) return Math.round(bytes) + " B/s";
    if (bytes < 1048576) return (bytes / 1024).toFixed(1) + " KB/s";
    if (bytes < 1073741824) return (bytes / 1048576).toFixed(1) + " MB/s";
    return (bytes / 1073741824).toFixed(2) + " GB/s";
  }

  // Green / yellow / orange for a measured value. Thresholds may ascend
  // (lower is better: ping, loss) or descend (higher is better: signal).
  function qualityColor(value, good, fair) {
    const lowerIsBetter = good <= fair;
    if (lowerIsBetter ? value <= good : value >= good) return green;
    if (lowerIsBetter ? value <= fair : value >= fair) return yellow;
    return orange;
  }

  // Latency color shared by every module; no measurement reads as muted.
  readonly property int pingGoodMs: 100
  readonly property int pingFairMs: 300

  function pingColor(ms) {
    return ms > 0 ? qualityColor(ms, pingGoodMs, pingFairMs) : muted;
  }

  // Large counts: 812, 47.1k, 176.9M.
  function humanCount(n) {
    if (n < 1000) return String(Math.round(n));
    if (n < 1e6) return (n / 1e3).toFixed(1) + "k";
    if (n < 1e9) return (n / 1e6).toFixed(1) + "M";
    return (n / 1e9).toFixed(2) + "B";
  }

  // Load of a resource in %: yellow from 70, red from 90.
  function loadColor(percent) {
    return percent >= 90 ? red : percent >= 70 ? yellow : foreground0;
  }

  // Sizes in lists, compact: 312 KB, 48 MB, 1.4 GB.
  function shortSize(bytes) {
    if (bytes < 1048576) return Math.round(bytes / 1024) + " KB";
    if (bytes < 1073741824) return Math.round(bytes / 1048576) + " MB";
    return (bytes / 1073741824).toFixed(1) + " GB";
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
