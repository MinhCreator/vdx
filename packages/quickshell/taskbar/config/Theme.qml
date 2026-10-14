pragma Singleton
import QtQuick
import Quickshell

// Everything modules read: the palette (from the theme's Colors.qml), font,
// metrics, glyphs, intervals, script paths and formatting helpers.

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

  // per-theme workspace label style
  readonly property string workspaceFormat: Colors.workspaceFormat
  readonly property string workspaceIconDefault: Colors.workspaceIconDefault
  readonly property string workspaceIconActive: Colors.workspaceIconActive

  // ---- bar metrics ---------------------------------------------------------
  readonly property string fontFamily: "JetBrainsMono Nerd Font"
  readonly property int fontSize: 13
  readonly property int fontWeight: Font.DemiBold
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
  readonly property int musicRestartMs: 5000
  readonly property int musicMaxLength: 60          // bar label, chars
  readonly property int musicCoverSize: 64
  readonly property int musicUpNext: 9             // queue rows visible before scrolling

  // ---- interaction limits --------------------------------------------------
  readonly property int audioMaxPercent: 150
  readonly property int audioScrollStep: 5
  readonly property int brightnessScrollStep: 5
  readonly property int nightTemperatureMin: 2000   // K
  readonly property int nightTemperatureMax: 6500   // K
  readonly property int dimGammaMin: 30             // %, lowest gamma of the dim slider

  // ---- battery ---------------------------------------------------------------
  readonly property int batteryWarning: 30          // %, yellow
  readonly property int batteryCritical: 15         // %, red
  readonly property var batteryNotifyLevels: [15, 5] // %, low-battery notifications
  readonly property var batteryLimits: [60, 80, 100] // %, charge limit choices
  readonly property string powerSaverProfile: "quiet"  // platform profile of the power saver

  // ---- notifications -------------------------------------------------------
  readonly property int notificationsMax: 100       // kept in history
  readonly property int notificationsVisible: 6     // rows before scrolling

  // ---- claude code -----------------------------------------------------------
  readonly property int claudeUsageIntervalMs: 300000   // plan limits poll (API)
  readonly property int claudeLocalIntervalMs: 30000    // today's tokens + sessions, popup open
  readonly property int claudeWarning: 75               // %, bar icon yellow
  readonly property int claudeCritical: 90              // %, bar icon red
  readonly property int ollamaIntervalMs: 5000           // status poll while the tab is open
  readonly property string ollamaCoachModel: "qwen2.5:1.5b"   // the nvim habit coach's model

  // ---- language formats ----------------------------------------------------
  readonly property string languageFormatEn: "US"
  readonly property string languageFormatRu: "RU"

  // ---- Nerd Font glyphs (Material Design) ---------------------------------
  readonly property string iconVolume: "\udb81\udd7e"      // nf-md-volume_high
  readonly property string iconHeadphone: "\udb80\udecb"       // nf-md-headphones
  readonly property string iconMuted: "\udb81\udd81"           // nf-md-volume_off
  readonly property string iconMicrophone: "\udb80\udf6c"     // nf-md-microphone
  readonly property string iconMicrophoneOff: "\udb80\udf6d"  // nf-md-microphone_off
  readonly property string iconBrightness: "\udb80\udce0"    // nf-md-brightness_7
  readonly property string iconBatteryCharging: "\udb80\udc84" // nf-md-battery_charging
  readonly property string iconPlug: "\udb81\udea5"            // nf-md-power_plug
  readonly property string iconLeaf: "\udb80\udf2a"           // nf-md-leaf
  readonly property string iconMusic: "\udb81\udf5a"           // nf-md-music
  readonly property string iconPlay: "\udb81\udc0a"            // nf-md-play
  readonly property string iconPause: "\udb80\udfe4"           // nf-md-pause
  readonly property string iconNext: "\udb81\udcad"            // nf-md-skip_next
  readonly property string iconPrev: "\udb81\udcae"            // nf-md-skip_previous
  readonly property string iconRandom: "\udb81\udc9d"          // nf-md-shuffle
  readonly property string iconRandomOff: "\udb81\udc9e"       // nf-md-shuffle_disabled
  readonly property string iconRepeat: "\udb81\udc56"          // nf-md-repeat
  readonly property string iconRepeatOff: "\udb81\udc57"       // nf-md-repeat_off
  readonly property string iconRepeatOnce: "\udb81\udc58"      // nf-md-repeat_once
  readonly property string iconHeart: "\udb80\uded1"           // nf-md-heart
  readonly property string iconHeartOutline: "\udb80\uded5"    // nf-md-heart_outline
  readonly property string iconRadio: "\udb81\udc39"           // nf-md-radio
  readonly property string iconSearch: "\udb80\udf49"          // nf-md-magnify
  readonly property string iconBell: "\udb80\udc9a"            // nf-md-bell
  readonly property string iconClearAll: "\udb83\udc79"        // nf-md-notification_clear_all
  readonly property string iconRobot: "\udb81\udea9"           // nf-md-robot
  readonly property string iconDrag: "\udb80\udddd"            // nf-md-drag
  readonly property string iconPuzzle: "\udb81\udc31"          // nf-md-puzzle
  readonly property string iconEye: "\udb80\ude08"             // nf-md-eye
  readonly property string iconEyeOff: "\udb80\ude09"          // nf-md-eye_off
  readonly property string iconGrid: "\udb81\udd70"            // nf-md-view_grid
  readonly property string iconClock: "\udb82\udd54"           // nf-md-clock_outline
  readonly property string iconKeyboard: "\udb80\udf0c"        // nf-md-keyboard
  readonly property string iconRestore: "\udb82\udd9b"         // nf-md-backup_restore
  readonly property var iconBatteryLevels: ["\udb80\udc7a", "\udb80\udc7c", "\udb80\udc7e", "\udb80\udc82", "\udb80\udc79"]   // nf-md-battery_10/30/50/80/full
  readonly property string iconMihomo: "\udb81\udc98"          // nf-md-shield
  readonly property string iconSettings: "\udb81\udc93"        // nf-md-cog
  readonly property string iconRefresh: "\udb81\udc50"         // nf-md-refresh
  readonly property string iconPing: "\udb85\udc0b"            // nf-md-lightning_bolt
  readonly property string iconDots: "\udb80\uddd8"            // nf-md-dots_horizontal
  readonly property string iconSpinner: "\udb81\udf72"         // nf-md-loading
  readonly property string iconOk: "\udb80\udd2c"              // nf-md-check
  readonly property string iconError: "\udb80\udd56"           // nf-md-close
  readonly property string iconWifi: "\udb82\udd28"            // nf-md-wifi
  readonly property string iconSpeedtest: "\udb81\udcc5"       // nf-md-speedometer
  readonly property string iconArrowLeft: "\udb80\udc4d"       // nf-md-arrow_left
  readonly property string iconArrowDown: "\udb80\udc45"       // nf-md-arrow_down
  readonly property string iconArrowUp: "\udb80\udc5d"         // nf-md-arrow_up
  readonly property string iconChevron: "\udb80\udd42"         // nf-md-chevron_right
  readonly property string iconLock: "\udb80\udf3e"            // nf-md-lock
  readonly property string ellipsis: "\u2026"

  // ---- popup chrome --------------------------------------------------------
  readonly property int popupWidth: 370          // popups with two-column info (wifi, mihomo)
  readonly property int popupWidthCompact: 300   // single-column popups (audio, brightness)
  readonly property int popupWidthWide: 520      // three-column popups (plugin manager)
  readonly property int popupFrameWidth: 4
  readonly property int popupPadding: 10
  readonly property int popupGap: 6
  readonly property int rowHeight: 24
  readonly property int visibleRows: 8
  readonly property int switchWidth: 34
  readonly property int switchKnob: 14
  readonly property int popupInputHeight: 24
  readonly property int headerButtonSize: fontSize + 3   // glyph buttons next to a header switch
  readonly property int popupStatusMs: 2500       // how long ok / error marks stay

  // ---- wifi ----------------------------------------------------------------
  readonly property int wifiStatusIntervalMs: 5000
  readonly property int wifiPingIntervalMs: 3000
  readonly property int wifiTrafficRestartMs: 2000
  readonly property int wifiSpeedtestTimeoutMs: 60000
  readonly property int wifiBarMaxLength: 14

  // ---- mihomo --------------------------------------------------------------
  readonly property string mihomoGroup: "Proxies"
  readonly property int mihomoStatusIntervalMs: 2000
  readonly property int mihomoTrafficRestartMs: 2000

  // ---- scripts -------------------------------------------------------------
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

  // ---- shared formatting ---------------------------------------------------
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

  // Latency color shared by every plugin; no measurement reads as muted.
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

  // Cumulative byte counters, human-readable.
  function humanSize(bytes) {
    if (bytes < 1024) return Math.round(bytes) + " B";
    if (bytes < 1048576) return (bytes / 1024).toFixed(1) + " KB";
    if (bytes < 1073741824) return (bytes / 1048576).toFixed(1) + " MB";
    if (bytes < 1099511627776) return (bytes / 1073741824).toFixed(2) + " GB";
    return (bytes / 1099511627776).toFixed(2) + " TB";
  }
}
