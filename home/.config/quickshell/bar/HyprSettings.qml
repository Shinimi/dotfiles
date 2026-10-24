// System settings (SUPER + comma): grouped sidebar + pages, opening on Home (profile, search, a tile per page).
// Look pages show a live mini desktop. Changes wait for Apply (the pill at the bottom, or Ctrl+S). Changes wait for Apply (Ctrl+S); Discard throws them away. Made by Claude.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "."   // our own Label wins over the Qt Controls one

Scope {
    id: root
    required property var screen
    property bool visible: false
    property string page: "home"
    property string kbMode: "kocho"
    property bool focusOn: false
    property bool _statsOn: visible
    on_StatsOnChanged: Stats.watchers = Math.max(0, Stats.watchers + (_statsOn ? 1 : -1))
    readonly property string qsDir: Quickshell.env("HOME") + "/.config/quickshell/bar"
    // sidebar: [id, icon, title, group, search words]
    readonly property var pages: [
        ["account", "\u{f0004}", "Account", "Personal", "user name picture avatar photo profile"],
        ["appearance", "\u{f03d8}", "Appearance", "Look & feel", "accent colour border gaps rounding layout tiling"],
        ["effects", "\u{f0d4a}", "Effects", "Look & feel", "glow shadow dim animation speed"],
        ["theme", "\u{f0e09}", "Theme", "Look & feel", "icons folder cursor font"],
        ["glass", "\u{f0c8a}", "Glass & blur", "Look & feel", "transparency opacity blur"],
        ["wallpaper", "\u{f02e9}", "Wallpaper", "Look & feel", "background picture"],
        ["bar", "\u{f009a}", "Notifications", "Desktop", "notifications pop-ups sounds do not disturb desktop clock"],
        ["comfort", "\u{f02dc}", "Comfort", "Desktop", "instant apply volume step screenshot confirm power snapshot backup restore"],
        ["extras", "\u{f0674}", "Extras", "Desktop", "hot corner focus mode drop-down terminal screensaver ink draw magnifier zoom picture in picture wallpaper shuffle pause music lock"],
        ["shortcuts", "\u{f030c}", "Shortcuts", "Desktop", "keybinds keys hotkeys"],
        ["defaults", "\u{f03d6}", "Default apps", "Desktop", "browser file manager open with"],
        ["autostart", "\u{f0412}", "Autostart", "Desktop", "login startup apps"],
        ["games", "\u{f0eb5}", "Games", "Desktop", "fps cap overlay mangohud profile power"],
        ["display", "\u{f0379}", "Display", "Devices", "monitor resolution refresh hz colour night light vibrance"],
        ["sound", "\u{f057e}", "Sound", "Devices", "audio volume mic eq headset"],
        ["input", "\u{f037d}", "Mouse & keyboard", "Devices", "pointer scroll layout typing repeat"],
        ["network", "\u{f0200}", "Network", "Devices", "internet ethernet wifi ip"],
        ["bluetooth", "\u{f00af}", "Bluetooth", "Devices", "headphones devices pair"],
        ["storage", "\u{f02ca}", "Storage", "Devices", "disk ssd space health"],
        ["power", "\u{f0425}", "Power & lock", "System", "sleep lock screen off game mode performance"],
        ["datetime", "\u{f0954}", "Date & time", "System", "clock timezone ntp"],
        ["about", "\u{f0493}", "About & updates", "System", "system info updates maintenance cpu gpu"]
    ]
    readonly property var pageInfo: pages.find(p => p[0] === page) || pages[0]
    property string search: ""
    readonly property var shownPages: {
        const q = search.trim().toLowerCase()
        return q ? pages.filter(p => (p[2] + " " + p[4]).toLowerCase().indexOf(q) >= 0) : pages
    }
    readonly property var keyPage: ({
        accent: "appearance", border_spin: "appearance", border_angle: "appearance", gaps_in: "appearance", gaps_out: "appearance", border_size: "appearance", rounding: "appearance", layout: "appearance", smart_split: "appearance", snap: "appearance", resize_on_border: "appearance",
        glow: "effects", glow_range: "effects", glow_strength: "effects", shadows: "effects", shadow_range: "effects", shadow_tint: "effects", dim_inactive: "effects", dim_strength: "effects", animations: "effects", anim_speed: "effects", butterflies: "effects", butterfly_count: "effects", ws_anim: "effects",
        folder_color: "theme", icon_base: "theme", cursor_theme: "theme", cursor_size: "theme", ui_font: "theme", ui_font_size: "theme", fetch_logo: "theme", fetch_source: "theme",
        opacity_active: "glass", opacity_inactive: "glass", glass: "glass", blur: "glass", blur_size: "glass", blur_passes: "glass", vibrancy: "glass", blur_brightness: "glass", blur_noise: "glass", blur_xray: "glass", blur_popups: "glass",
        clock_seconds: "bar", clock_12h: "bar", clock_date: "bar", bar_media: "bar", notif_timeout: "bar", notif_center: "bar", sounds: "bar", desktop_clock: "bar", desktop_clock_pos: "bar",
        sensitivity: "input", accel_flat: "input", natural_scroll: "input", scroll_factor: "input", follow_mouse: "input", middle_scroll: "input", scroll_mode: "input", middle_paste: "input", focus_on_activate: "input",
        repeat_rate: "input", repeat_delay: "input", kb_layout: "input", numlock: "input", hide_cursor_typing: "input", cursor_hide_after: "input", ws_back_forth: "input", swallow: "input",
        night_temp: "display", night_auto: "display", night_from: "display", night_to: "display", vibrance: "display", mono_mode: "display", monitors: "display", auto_pause: "comfort", sort_downloads: "comfort", screen_time: "comfort", music_stats: "comfort", lock_minutes: "power", screen_off_after: "power", mouse_wakes: "power", game_mode: "power"
,
        user_name: "account", avatar: "account", cc_logo: "account", wall_main: "wallpaper", wall_side: "wallpaper",
        default_apps: "defaults", autostart: "autostart", game_profiles: "games"
    })
    // Home tiles: one live line per page
    function summary(id) {
        const g = k => Settings.get(k)
        const n = (a, one, many) => a + " " + (a === 1 ? one : many)
        switch (id) {
        case "appearance": return ({ tokyo: "Silver", storm: "Pearl", sakura: "Ember", matcha: "Ash", sunset: "Dusk", mono: "Mono" })[g("accent")] + " · gaps " + g("gaps_in") + "/" + g("gaps_out")
        case "effects": return (g("animations") ? "Animations on" : "Animations off") + (g("shadows") ? " · shadows" : "")
        case "theme": return g("icon_base") + " · " + g("ui_font")
        case "glass": return "Windows " + g("opacity_active") + "%" + (g("blur") ? " · blur" : "")
        case "wallpaper": return "Main and side screen"
        case "bar": return (g("sounds") ? "Sounds on" : "Silent pop-ups") + (g("desktop_clock") ? " · desktop clock" : "")
        case "comfort": return g("screen_time") ? "Screen time on" : "Everyday helpers"
        case "extras": return g("hot_corner") ? "Hot corner on" : "Little helpers"
        case "shortcuts": return "Every keybind"
        case "defaults": return "Browser, files, media"
        case "autostart": return n((g("autostart") || []).length, "app", "apps") + " at login"
        case "games": return n(Object.keys(g("game_profiles") || {}).length, "profile", "profiles")
        case "display": return n(root.monitors.length, "screen", "screens") + (g("mono_mode") ? " · monochrome" : "")
        case "sound": { const s = Pipewire.defaultAudioSink; return s ? (s.nickname || s.description || s.name || "").replace(/ Analog Stereo| Stereo/g, "") : "Audio" }
        case "input": return "Sensitivity " + g("sensitivity") + " · " + String(g("kb_layout")).toUpperCase()
        case "network": return "Your connection"
        case "bluetooth": return "Wireless devices"
        case "storage": return root.info.disk ? root.info.disk + " used" : "Drives"
        case "power": return "Lock after " + g("lock_minutes") + " min"
        case "datetime": return Qt.formatTime(new Date(), "HH:mm")
        case "about": return Updates.total > 0 ? n(Updates.total, "update", "updates") + " waiting" : "Up to date"
        }
        return ""
    }
    function pageDirty(id) { return Settings.changedKeys.some(k => keyPage[k] === id) }
    function toggle() { if (!visible) { page = "home"; search = "" } visible = !visible }
    function open(p) { page = p; visible = true }
    function exec(cmd) { visible = false; Quickshell.execDetached(cmd) }
    onVisibleChanged: if (visible) { PopupState.current = root; SysState.refresh(); about.running = true; mons.running = true; focusChk.running = true }
    Process { id: focusChk; command: ["sh", "-c", "test -e \"$XDG_RUNTIME_DIR/focus-mode\" && echo 1"]
              stdout: StdioCollector { onStreamFinished: root.focusOn = this.text.trim() === "1" } }
    Connections { target: PopupState; function onCurrentChanged() { if (PopupState.current !== root) root.visible = false } }
    IpcHandler {
        target: "settings"
        function toggle(): void { root.toggle() }
        function open(page: string): void { root.open(page) }
        function set(key: string, value: string): void {
            Settings.setNow(key, value === "true" ? true : value === "false" ? false : isNaN(Number(value)) ? value : Number(value))
        }
        function flip(key: string): void { Settings.setNow(key, !Settings.cur(key)) }
        function apply(): void { Settings.apply() }
        function reload(): void { Settings.reload() }
        function discard(): void { Settings.discard() }
    }

    // ---- data for the Display / System pages ----
    Process {
        id: fetchPick
        command: ["kdialog", "--title", "Picture for terminal art", "--getopenfilename", Quickshell.env("HOME") + "/Pictures", "Images (*.png *.jpg *.jpeg *.webp)"]
        stdout: StdioCollector { onStreamFinished: { const p = this.text.trim(); if (p) Settings.set("fetch_source", p) } }
    }
    property var monitors: []
    Process {
        id: mons
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector { onStreamFinished: { try { root.monitors = JSON.parse(this.text) } catch (e) {} } }
    }
    property var info: ({})
    Process {
        id: about
        command: ["sh", "-c", "echo \"kernel=$(uname -r)\"; echo \"host=$(cat /etc/hostname)\"; " +
                  "echo \"cpu=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //')\"; " +
                  "echo \"gpu=$(lspci | grep -m1 -E 'VGA|Display' | sed 's/.*: //; s/Advanced Micro Devices, Inc. //; s/\\[AMD\\/ATI\\] //')\"; " +
                  "echo \"ram=$(free -g | awk '/Mem/{print $2}') GB\"; echo \"pkgs=$(pacman -Qq | wc -l)\"; " +
                  "echo \"hypr=$(hyprctl version -j | python3 -I -c 'import json,sys;print(json.load(sys.stdin)[\"tag\"])' 2>/dev/null)\"; " +
                  "echo \"disk=$(df -B1 --output=used,size / | tail -1 | awk '{printf \"%d GB of %d GB\", $1/1e9, $2/1e9}')\"; " +
                  "echo \"gpu2=$(glxinfo -B 2>/dev/null | sed -n 's/.*renderer string: \\(.*\\) (.*/\\1/p')\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const o = {}
                for (const l of this.text.split("\n")) { const i = l.indexOf("="); if (i > 0) o[l.slice(0, i)] = l.slice(i + 1) }
                root.info = o
            }
        }
    }
    // ---- Display page: modes, colour, and a 15 s "keep or revert" safety net ----
    property string selMon: "DP-1"
    readonly property var selInfo: monitors.find(m => m.name === selMon) || null
    function liveCfg(m) {
        if (!m) return {}
        const modes = (m.availableModes || []).map(x => x.replace("Hz", ""))
        const same = modes.filter(x => x.split("@")[0] === m.width + "x" + m.height)
        let best = same[0] || (m.width + "x" + m.height + "@" + m.refreshRate.toFixed(2))
        for (const x of same) if (Math.abs(parseFloat(x.split("@")[1]) - m.refreshRate) < Math.abs(parseFloat(best.split("@")[1]) - m.refreshRate)) best = x
        return { mode: best, cm: m.colorManagementPreset || "srgb", bitdepth: (m.currentFormat || "").indexOf("2101010") >= 0 ? 10 : 8, vrr: m.vrr ? 1 : 0 }
    }
    readonly property var selCfg: Object.assign({}, liveCfg(selInfo), (Settings.get("monitors") || {})[selMon] || {})
    readonly property var resolutions: {
        const out = []
        for (const x of (selInfo ? selInfo.availableModes : [])) { const r = x.split("@")[0]; if (out.indexOf(r) < 0 && parseInt(r) >= 1280) out.push(r) }
        out.sort((a, b) => { const pa = a.split("x"), pb = b.split("x"); return pb[0] * pb[1] - pa[0] * pa[1] })
        return out.slice(0, 6)
    }
    function ratesFor(res) {
        const out = []
        for (const x of (selInfo ? selInfo.availableModes : [])) {
            const p = x.replace("Hz", "").split("@")
            if (p[0] === res && !out.some(o => Math.round(parseFloat(o)) === Math.round(parseFloat(p[1])))) out.push(p[1])
        }
        return out.sort((a, b) => parseFloat(b) - parseFloat(a))
    }
    property var undoMonitors: null
    property int countdown: 15
    property var lastGoodMonitors: null
    function monChange(field, val) {
        if (lastGoodMonitors === null) {
            const snap = {}
            for (const m of monitors) snap[m.name] = Object.assign({}, liveCfg(m), (Settings.cur("monitors") || {})[m.name] || {})
            lastGoodMonitors = snap
        }
        Settings.setMon(selMon, field, val, liveCfg(selInfo))
    }
    Connections {
        target: Settings
        function onApplied(keys) {
            if (keys.indexOf("monitors") >= 0 && root.lastGoodMonitors !== null) {
                root.undoMonitors = root.lastGoodMonitors; root.lastGoodMonitors = null
                root.countdown = 15; revertTimer.restart(); root.page = "display"
            }
            monsLater.restart()
        }
    }
    // one popup style for the whole window: "are you sure?" questions, and the display keep/revert countdown
    property var ask: null           // { icon, title, body, yes, fn }
    function confirm(icon, title, body, yes, fn) { ask = { icon: icon, title: title, body: body, yes: yes, fn: fn } }
    function keepMonitors() { undoMonitors = null; revertTimer.stop() }
    function revertMonitors() { if (undoMonitors) Settings.setNow("monitors", undoMonitors); undoMonitors = null; revertTimer.stop(); monsLater.restart() }
    Timer { id: revertTimer; interval: 1000; repeat: true; onTriggered: { root.countdown--; if (root.countdown <= 0) root.revertMonitors() } }
    Timer { id: monsLater; interval: 2500; onTriggered: mons.running = true }

    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio && !(n.name || "").startsWith("effect_") && n.name !== "headset_eq")
    readonly property var sources: Pipewire.nodes.values.filter(n => !n.isSink && !n.isStream && n.audio && !(n.name || "").startsWith("effect_") && n.name !== "clean_mic" && (n.name || "").indexOf(".monitor") < 0)
    PwObjectTracker { objects: root.sinks.concat(root.sources) }

    PanelWindow {
        visible: root.visible; screen: root.screen
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "qsbar-dismiss"
        color: "#44000000"
        MouseArea { anchors.fill: parent; onClicked: root.visible = false }
    }

    PanelWindow {
        visible: root.visible; screen: root.screen
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qsbar-settings"
        WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"
        implicitWidth: 1080; implicitHeight: 760

        Rectangle {
            id: frame
            anchors.fill: parent; radius: 30; color: "#f70b0b0b"
            border.width: 1; border.color: "#14ffffff"
            focus: true
            Keys.onEscapePressed: { if (root.ask) root.ask = null; else if (root.undoMonitors) root.revertMonitors(); else root.visible = false }
            Keys.onPressed: e => { if ((e.modifiers & Qt.ControlModifier) && e.key === Qt.Key_S) { Settings.apply(); e.accepted = true } }
            Keys.onUpPressed: { const i = root.shownPages.findIndex(p => p[0] === root.page); if (i > 0) root.page = root.shownPages[i - 1][0] }
            Keys.onDownPressed: { const i = root.shownPages.findIndex(p => p[0] === root.page); if (i < root.shownPages.length - 1) root.page = root.shownPages[i + 1][0] }

            // ================= sidebar =================
            Rectangle {
                id: side
                x: 0; y: 0; width: 268; height: parent.height
                color: "transparent"

                Column {
                    id: sideTop
                    x: 16; y: 20; width: parent.width - 32; spacing: 14
                    Rectangle {   // you
                        width: parent.width; height: 66; radius: 20
                        color: root.page === "account" ? "#222222" : (um.containsMouse ? "#1c1c1c" : "#151515")
                        Row {
                            x: 10; anchors.verticalCenter: parent.verticalCenter; spacing: 12
                            Avatar { size: 42; radius: 21; pick: Settings.get("avatar") }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                Label { text: (n => n.charAt(0).toUpperCase() + n.slice(1).toLowerCase())(Settings.get("user_name") || Quickshell.env("USER")); font.pixelSize: 15; font.weight: Font.Bold }
                                Label { text: "Picture and name"; color: "#6e6e6e"; font.pixelSize: 10; font.weight: Font.Normal }
                            }
                        }
                        MouseArea { id: um; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.page = "account" }
                    }
                    Rectangle {   // Home: the overview with a tile per page
                        width: parent.width; height: 38; radius: 12
                        readonly property bool cur: root.page === "home"
                        color: cur ? "#ececec" : (hmM.containsMouse ? "#181818" : "transparent")
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Row {
                            x: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 12
                            Label { width: 18; text: "\u{f02dc}"; color: parent.parent.cur ? "#0b0b0b" : "#7a7a7a"; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                            Label { text: "Home"; color: parent.parent.cur ? "#0b0b0b" : "#c4c4c4"; font.pixelSize: 12; font.bold: parent.parent.cur; anchors.verticalCenter: parent.verticalCenter }
                        }
                        MouseArea { id: hmM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.page = "home"; root.search = ""; find.text = "" } }
                    }
                    TextField {
                        id: find
                        width: parent.width; height: 40
                        placeholderText: "Search settings"; placeholderTextColor: Theme.muted
                        onTextEdited: { root.search = text; if (root.page !== "home" && root.shownPages.length) root.page = root.shownPages[0][0] }
                        Keys.onEscapePressed: { text = ""; root.search = "" }
                        color: Theme.fg; font.family: Theme.font; font.pixelSize: 12; leftPadding: 34
                        background: Rectangle { radius: 14; color: "#151515"; border.width: 1; border.color: find.activeFocus ? "#40ffffff" : "transparent" }
                        Label { x: 12; anchors.verticalCenter: parent.verticalCenter; text: "\u{f0349}"; color: Theme.muted; font.pixelSize: 14 }
                    }
                }
                Flickable {   // the pages, grouped: LOOK & FEEL, DESKTOP, DEVICES, SYSTEM
                    id: nav
                    anchors { top: sideTop.bottom; topMargin: 4; left: parent.left; right: parent.right; bottom: sideBottom.top; leftMargin: 16; rightMargin: 16; bottomMargin: 8 }
                    clip: true; boundsBehavior: Flickable.StopAtBounds
                    contentHeight: navCol.implicitHeight
                    Column {
                        id: navCol
                        width: nav.width; spacing: 2
                        Repeater {
                            model: ["Look & feel", "Desktop", "Devices", "System"]
                            Column {
                                id: ng
                                required property string modelData
                                readonly property var items: root.shownPages.filter(p => p[3] === ng.modelData)
                                visible: items.length > 0
                                width: navCol.width; spacing: 2
                                Item {
                                    width: parent.width; height: 28
                                    Label { x: 12; anchors.bottom: parent.bottom; anchors.bottomMargin: 6; text: ng.modelData.toUpperCase(); color: "#5a5a5a"; font.pixelSize: 9; font.letterSpacing: 1.6; font.bold: true }
                                }
                                Repeater {
                                    model: ng.items
                                    Rectangle {
                                        required property var modelData
                                        readonly property bool cur: root.page === modelData[0]
                                        width: navCol.width; height: 36; radius: 12
                                        color: cur ? "#ececec" : (nm.containsMouse ? "#181818" : "transparent")
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                        Row {
                                            x: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 12
                                            Label { width: 18; text: modelData[1]; color: cur ? "#0b0b0b" : "#7a7a7a"; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                                            Label { text: modelData[2]; color: cur ? "#0b0b0b" : "#c4c4c4"; font.pixelSize: 12; font.bold: cur; anchors.verticalCenter: parent.verticalCenter }
                                        }
                                        Rectangle { visible: root.pageDirty(modelData[0]); anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                                                    width: 7; height: 7; radius: 4; color: cur ? "#0b0b0b" : "#ffffff" }
                                        MouseArea { id: nm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.page = modelData[0] }
                                    }
                                }
                            }
                        }
                    }
                    Label { anchors.centerIn: parent; visible: root.shownPages.filter(p => p[0] !== "account").length === 0; text: "Nothing found"; color: Theme.muted; font.pixelSize: 11 }
                }
                Column {
                    id: sideBottom
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 16 }
                    SetButton { width: parent.width; icon: "\u{f0450}"; text: "Reset to defaults"; accent: Theme.muted
                        onClicked: root.confirm("\u{f0450}", "Reset every setting?", Settings.cur("instant_apply") ? "Everything goes back to how it came, right away." : "Everything goes back to how it came. Nothing changes until you press Apply, so you can still Discard.", "Reset", () => Settings.reset()) }
                }
            }

            // ================= apply pill: only while something is waiting =================
            Rectangle {
                id: applyBar
                readonly property bool show: !Settings.cur("instant_apply") && Settings.dirty
                z: 5; visible: opacity > 0; opacity: show ? 1 : 0
                anchors.horizontalCenter: flick.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: show ? 22 : 8
                Behavior on opacity { NumberAnimation { duration: 160 } }
                Behavior on anchors.bottomMargin { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                width: pillRow.implicitWidth + 24; height: 52; radius: 26
                color: "#1e1e1e"; border.width: 1; border.color: "#33ffffff"
                RowLayout {
                    id: pillRow
                    anchors.centerIn: parent; spacing: 10
                    Rectangle { width: 8; height: 8; radius: 4; color: "#ffffff"; Layout.leftMargin: 8 }
                    Label { text: Settings.changedKeys.length + (Settings.changedKeys.length === 1 ? " change waiting" : " changes waiting"); font.pixelSize: 12; Layout.rightMargin: 6 }
                    SetButton { icon: "\u{f0156}"; text: "Discard"; onClicked: { Settings.discard(); root.lastGoodMonitors = null } }
                    SetButton { icon: "\u{f012c}"; text: "Apply"; primary: true; onClicked: Settings.apply() }
                }
            }

            // ================= popup: dims the window, one card in the middle =================
            Item {
                id: modal
                readonly property bool isDisplay: root.undoMonitors !== null
                readonly property bool show: isDisplay || root.ask !== null
                anchors.fill: parent; z: 20
                visible: opacity > 0; opacity: show ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 160 } }
                Rectangle { anchors.fill: parent; radius: 30; color: "#b3000000" }
                MouseArea { anchors.fill: parent; hoverEnabled: true; onClicked: if (!modal.isDisplay) root.ask = null }   // clicking outside = cancel
                Rectangle {
                    anchors.centerIn: parent
                    width: 440; height: mcol.implicitHeight + 56; radius: 24
                    color: "#151515"; border.width: 1; border.color: "#2c2c2c"
                    scale: modal.show ? 1 : 0.94
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    MouseArea { anchors.fill: parent }
                    Column {
                        id: mcol
                        x: 28; y: 28; width: parent.width - 56; spacing: 14
                        Item {   // a ring that empties as the countdown runs, or the question's icon
                            width: 64; height: 64
                            Canvas {
                                id: ring
                                visible: modal.isDisplay; anchors.fill: parent
                                property real v: root.countdown / 15
                                onVChanged: requestPaint()
                                onPaint: {
                                    const c = getContext("2d"); c.reset()
                                    c.lineWidth = 4; c.lineCap = "round"
                                    c.strokeStyle = "rgba(255,255,255,0.08)"; c.beginPath(); c.arc(32, 32, 28, 0, 2 * Math.PI); c.stroke()
                                    c.strokeStyle = "#ececec"; c.beginPath(); c.arc(32, 32, 28, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * v); c.stroke()
                                }
                            }
                            Text { visible: modal.isDisplay; anchors.centerIn: parent; text: root.countdown; color: "#ffffff"; font.family: Theme.font; font.pixelSize: 22; font.bold: true }
                            Rectangle {
                                visible: !modal.isDisplay; width: 52; height: 52; radius: 16; color: "#222222"; anchors.verticalCenter: parent.verticalCenter
                                Label { anchors.centerIn: parent; text: root.ask ? root.ask.icon : ""; color: "#e6e6e6"; font.pixelSize: 22 }
                            }
                        }
                        Text { width: parent.width; wrapMode: Text.WordWrap; color: "#ffffff"; font.family: Theme.font; font.pixelSize: 17; font.bold: true
                               text: modal.isDisplay ? "Keep these display settings?" : root.ask ? root.ask.title : "" }
                        Label { width: parent.width; wrapMode: Text.WordWrap; color: "#8a8a8a"; font.pixelSize: 11; font.weight: Font.Normal; lineHeight: 1.15
                                text: modal.isDisplay ? "Your screens go back to how they were in " + root.countdown + " s unless you keep them. If the picture went black or looks wrong, just wait or press Esc."
                                                      : root.ask ? root.ask.body : "" }
                        Item { width: 1; height: 4 }
                        Row {
                            anchors.right: parent.right; spacing: 8
                            SetButton { text: modal.isDisplay ? "Revert" : "Cancel"; onClicked: modal.isDisplay ? root.revertMonitors() : (root.ask = null) }
                            SetButton { text: modal.isDisplay ? "Keep" : root.ask ? root.ask.yes : ""; primary: true
                                        onClicked: { if (modal.isDisplay) root.keepMonitors(); else { const f = root.ask.fn; root.ask = null; f() } } }
                        }
                    }
                }
            }

            // ================= page =================
            Flickable {
                id: flick
                anchors { left: side.right; right: parent.right; top: parent.top; bottom: parent.bottom; margins: 26; leftMargin: 8; bottomMargin: 6 }
                contentHeight: pageCol.implicitHeight; clip: true
                boundsBehavior: Flickable.StopAtBounds
                Connections { target: root; function onPageChanged() { flick.contentY = 0; fadeIn.restart() } }
                NumberAnimation { id: fadeIn; target: pageCol; property: "opacity"; from: 0.2; to: 1; duration: 180 }

                Column {
                    id: pageCol
                    readonly property bool isPage: true
                    width: flick.width; spacing: 18; bottomPadding: 80   // room under the last group for the apply pill

                    Column {
                        visible: root.page !== "home"
                        spacing: 4; bottomPadding: 6
                        Text { id: ttl; text: root.pageInfo[2]; color: "#ffffff"; font.family: Theme.font; font.pixelSize: 24; font.bold: true }
                        Label {
                            color: "#6e6e6e"; font.pixelSize: 12; font.weight: Font.Normal
                            text: ({ comfort: "Little things that make the desktop nicer to live with", account: "Your picture and name", appearance: "Colours, borders, gaps and window layout",
                                     effects: "Glow, shadows, dimming and animations", theme: "Icons, folders, cursor and fonts",
                                     glass: "How see-through windows and panels are", wallpaper: "Pick a picture for each screen",
                                     bar: "Pop-ups, sounds and the clock on the wallpaper", shortcuts: "Every keyboard shortcut",
                                     defaults: "Which app opens links, folders, pictures and more", autostart: "Apps that open when you log in", games: "A profile for each game, applied while it runs",
                                     display: "Resolution, refresh rate and colour", sound: "Devices, clean mic and headset EQ (changes here are instant)",
                                     input: "Pointer, scrolling, typing and focus", network: "Your connection", bluetooth: "Wireless devices",
                                     storage: "Drives, health and free space", power: "Performance, auto-lock and screens off",
                                     datetime: "Clock and time sync", about: "This PC, updates and maintenance" })[root.page] || ""
                        }
                    }


                    // ---------- Home: you, a big search, and a tile per page ----------
                    Column {
                        visible: root.page === "home"; width: parent.width; spacing: 18
                        RowLayout {
                            width: parent.width; spacing: 16
                            Avatar { size: 64; radius: 32; pick: Settings.get("avatar") }
                            Column {
                                Layout.fillWidth: true; spacing: 4
                                Text { text: (n => n.charAt(0).toUpperCase() + n.slice(1).toLowerCase())(Settings.get("user_name") || Quickshell.env("USER"))
                                       color: "#ffffff"; font.family: Theme.font; font.pixelSize: 24; font.bold: true }
                                Label { text: "CachyOS  ·  Hyprland " + (root.info.hypr || "") + "  ·  up " + Stats.d.uptime; color: "#7a7a7a"; font.pixelSize: 11; font.weight: Font.Normal }
                            }
                            SetButton { visible: Updates.total > 0; icon: "\u{f06b0}"; text: Updates.total + " updates"; onClicked: root.page = "about" }
                        }
                        TextField {
                            id: bigFind
                            width: parent.width; height: 48
                            text: root.search
                            placeholderText: "Search all settings"; placeholderTextColor: Theme.muted
                            onTextEdited: root.search = text
                            onAccepted: { const p = root.shownPages.filter(x => x[0] !== "account"); if (p.length) root.page = p[0][0] }
                            Keys.onEscapePressed: { text = ""; root.search = "" }
                            color: Theme.fg; font.family: Theme.font; font.pixelSize: 13; leftPadding: 44
                            background: Rectangle { radius: 16; color: "#131313"; border.width: 1; border.color: bigFind.activeFocus ? "#40ffffff" : "#1d1d1d" }
                            Label { x: 16; anchors.verticalCenter: parent.verticalCenter; text: "\u{f0349}"; color: Theme.muted; font.pixelSize: 16 }
                        }
                        Repeater {
                            model: ["Look & feel", "Desktop", "Devices", "System"]
                            Column {
                                id: grp
                                required property string modelData
                                readonly property var items: root.shownPages.filter(p => p[3] === grp.modelData)
                                visible: items.length > 0
                                width: parent.width; spacing: 8
                                Label { x: 6; text: grp.modelData.toUpperCase(); color: "#5a5a5a"; font.pixelSize: 9; font.letterSpacing: 1.6; font.bold: true }
                                Grid {
                                    width: parent.width; columns: 4; columnSpacing: 10; rowSpacing: 10
                                    Repeater {
                                        model: grp.items
                                        Rectangle {
                                            id: tl
                                            required property var modelData
                                            width: (parent.width - 30) / 4; height: 92; radius: 16
                                            color: tlM.containsMouse ? "#1a1a1a" : "#131313"; border.width: 1; border.color: tlM.containsMouse ? "#33ffffff" : "#1d1d1d"
                                            Behavior on color { ColorAnimation { duration: 120 } }
                                            scale: tlM.pressed ? 0.97 : 1
                                            Behavior on scale { NumberAnimation { duration: 90 } }
                                            Rectangle {
                                                x: 14; y: 14; width: 32; height: 32; radius: 10; color: tlM.containsMouse ? "#ececec" : "#1f1f1f"
                                                Behavior on color { ColorAnimation { duration: 120 } }
                                                Label { anchors.centerIn: parent; text: tl.modelData[1]; color: tlM.containsMouse ? "#0b0b0b" : "#d0d0d0"; font.pixelSize: 15 }
                                            }
                                            Rectangle { visible: root.pageDirty(tl.modelData[0]); x: parent.width - 18; y: 14; width: 7; height: 7; radius: 4; color: "#ffffff" }
                                            Column {
                                                x: 14; y: 54; width: parent.width - 28; spacing: 2
                                                Label { width: parent.width; elide: Text.ElideRight; text: tl.modelData[2]; color: "#ececec"; font.pixelSize: 12 }
                                                Label { width: parent.width; elide: Text.ElideRight; text: root.summary(tl.modelData[0]); color: "#6e6e6e"; font.pixelSize: 10; font.weight: Font.Normal }
                                            }
                                            MouseArea { id: tlM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.page = tl.modelData[0] }
                                        }
                                    }
                                }
                            }
                        }
                        Label { visible: root.shownPages.filter(p => p[0] !== "account").length === 0; text: "Nothing matches \u201c" + root.search + "\u201d"; color: Theme.muted; font.pixelSize: 12 }
                    }
                    PgAccount { visible: root.page === "account"; width: parent.width }
                    PgWallpaper { visible: root.page === "wallpaper"; width: parent.width }
                    PgShortcuts { visible: root.page === "shortcuts"; width: parent.width }
                    PgDefaults { visible: root.page === "defaults"; width: parent.width }
                    PgAutostart { visible: root.page === "autostart"; width: parent.width }
                    PgGames { visible: root.page === "games"; width: parent.width }
                    PgNetwork { visible: root.page === "network"; width: parent.width }
                    PgBluetooth { visible: root.page === "bluetooth"; width: parent.width }
                    PgStorage { visible: root.page === "storage"; width: parent.width }
                    PgDateTime { visible: root.page === "datetime"; width: parent.width }

                    // ---------- 0 Appearance ----------
                    Column {
                        visible: root.page === "appearance"; width: parent.width; spacing: 18
                        LivePreview { visible: root.page === "appearance" }
                        SetSection {
                            width: parent.width; title: "Accent"; icon: "\u{f0e09}"
                            Row {
                                spacing: 10
                                Repeater {
                                    model: [["tokyo", "Silver", ["#e0e0e0", "#b0b0b0", "#c4c4c4"]], ["storm", "Pearl", ["#e0e0e0", "#c4c4c4"]],
                                            ["sakura", "Ember", ["#cf6b6b", "#b0b0b0"]], ["matcha", "Ash", ["#c8c8c8", "#bdbdbd"]],
                                            ["sunset", "Dusk", ["#c0c0c0", "#d6d6d6", "#cf6b6b"]], ["mono", "Mono", ["#eaeaea", "#7a7a7a"]]]
                                    Column {
                                        id: sw
                                        required property var modelData
                                        readonly property bool cur: Settings.get("accent") === modelData[0]
                                        spacing: 6
                                        Rectangle {
                                            width: 76; height: 50; radius: 16
                                            border.width: sw.cur ? 2 : 0; border.color: "#ffffff"
                                            gradient: Gradient { orientation: Gradient.Horizontal
                                                GradientStop { position: 0; color: sw.modelData[2][0] }
                                                GradientStop { position: 0.5; color: sw.modelData[2][1] }
                                                GradientStop { position: 1; color: sw.modelData[2][sw.modelData[2].length - 1] } }
                                            Label { visible: sw.cur; anchors.centerIn: parent; text: "\u{f012c}"; color: Theme.bg; font.pixelSize: 18 }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Settings.set("accent", sw.modelData[0]) }
                                        }
                                        Label { anchors.horizontalCenter: parent.horizontalCenter; text: sw.modelData[1]; color: sw.cur ? Theme.fg : Theme.muted; font.pixelSize: 11 }
                                    }
                                }
                            }
                            SetToggle { label: "Rotating border"; desc: "the focused window's gradient slowly turns"; key: "border_spin" }
                            SetSlider { visible: !Settings.get("border_spin"); label: "Gradient angle"; key: "border_angle"; from: 0; to: 360; step: 15; suffix: "°" }
                        }
                        Row {
                            width: parent.width; spacing: 14
                            SetSection {
                                width: (parent.width - 14) / 2; title: "Layout"; icon: "\u{f0570}"
                                SetSlider { label: "Gaps between windows"; key: "gaps_in"; from: 0; to: 20; suffix: " px" }
                                SetSlider { label: "Gaps at screen edges"; key: "gaps_out"; from: 0; to: 40; suffix: " px" }
                                SetSlider { label: "Border size"; key: "border_size"; from: 0; to: 6; suffix: " px" }
                                SetSlider { label: "Corner rounding"; key: "rounding"; from: 0; to: 20; suffix: " px" }
                            }
                            SetSection {
                                width: (parent.width - 14) / 2; title: "Windows"; icon: "\u{f05b4}"
                                SetChoice {
                                    label: "Tiling layout"; desc: "how new windows are placed on the main screen"
                                    current: Settings.get("layout"); onPicked: v => Settings.set("layout", v)
                                    options: [["dwindle", "Spiral"], ["master", "Main + stack"], ["scrolling", "Scrolling"]]
                                }
                                SetToggle { label: "Smart split"; desc: "split towards where the mouse is"; key: "smart_split" }
                                SetToggle { label: "Snap floating windows"; desc: "to edges and other windows"; key: "snap" }
                                SetToggle { label: "Resize by dragging borders"; key: "resize_on_border" }
                            }
                        }
                    }

                    // ---------- Effects ----------
                    Column {
                        visible: root.page === "effects"; width: parent.width; spacing: 18
                        LivePreview { visible: root.page === "effects" }
                        Row {
                            width: parent.width; spacing: 14
                            SetSection {
                                width: (parent.width - 14) / 2; title: "Glow"; icon: "\u{f0335}"
                                SetToggle { label: "Window glow"; desc: "soft accent-coloured light around the focused window"; key: "glow" }
                                SetSlider { visible: Settings.get("glow"); label: "Glow size"; key: "glow_range"; from: 4; to: 40; suffix: " px" }
                                SetSlider { visible: Settings.get("glow"); label: "Glow strength"; key: "glow_strength"; from: 10; to: 100; step: 5; suffix: "%" }
                            }
                            SetSection {
                                width: (parent.width - 14) / 2; title: "Shadows"; icon: "\u{f0ee8}"
                                SetToggle { label: "Shadows"; desc: "soft drop shadow under windows"; key: "shadows" }
                                SetSlider { visible: Settings.get("shadows"); label: "Shadow size"; key: "shadow_range"; from: 2; to: 30; suffix: " px" }
                                SetToggle { visible: Settings.get("shadows"); label: "Accent-tinted shadow"; desc: "uses your accent colour instead of black"; key: "shadow_tint" }
                            }
                        }
                        Row {
                            width: parent.width; spacing: 14
                            SetSection {
                                width: (parent.width - 14) / 2; title: "Focus"; icon: "\u{f0f08}"
                                SetToggle { label: "Dim unfocused windows"; desc: "makes the active window stand out"; key: "dim_inactive" }
                                SetSlider { visible: Settings.get("dim_inactive"); label: "Dim amount"; key: "dim_strength"; from: 5; to: 50; suffix: "%" }
                            }
                            SetSection {
                                width: (parent.width - 14) / 2; title: "Animations"; icon: "\u{f0d4a}"
                                SetToggle { label: "Animations"; desc: "open, close and workspace motion"; key: "animations" }
                                SetChoice {
                                    visible: Settings.get("animations"); label: "Speed"; accent: Theme.cyan
                                    current: Settings.get("anim_speed"); onPicked: v => Settings.set("anim_speed", v)
                                    options: [["slow", "Relaxed"], ["normal", "Normal"], ["fast", "Snappy"]]
                                }
                                SetChoice {
                                    visible: Settings.get("animations"); label: "Workspace switch"; accent: Theme.purple
                                    current: Settings.get("ws_anim"); onPicked: v => Settings.set("ws_anim", v)
                                    options: [["slidefade", "Slide + fade"], ["slide", "Slide"], ["slidevert", "Vertical"], ["fade", "Fade"]]
                                }
                            }
                        }
                    }

                    // ---------- Theme ----------
                    Column {
                        visible: root.page === "theme"; width: parent.width; spacing: 14
                        SetSection {
                            width: parent.width; title: "Icons"; icon: "\u{f02e9}"
                            SetChoice {
                                label: "Icon style"; current: Settings.get("icon_base")
                                options: [["Tela-mono", "Tela mono"], ["Papirus-Dark", "Papirus"], ["breeze-dark", "Breeze"]]
                                onPicked: v => Settings.set("icon_base", v)
                            }
                            Column {
                                visible: Settings.get("icon_base") === "Papirus-Dark"
                                width: parent.width; spacing: 8
                                Label { text: "Folder colour"; color: Theme.fgDim; font.pixelSize: 12 }
                                Flow {
                                    width: parent.width; spacing: 8
                                    Repeater {
                                        model: ["blue", "indigo", "violet", "magenta", "pink", "cyan", "teal", "green", "nordic", "grey"]
                                        Rectangle {
                                            id: fc
                                            required property string modelData
                                            readonly property bool cur: Settings.get("folder_color") === modelData
                                            width: 57; height: 70; radius: 12
                                            color: cur ? Qt.rgba(0.88, 0.88, 0.88, 0.16) : (fcm.containsMouse ? "#1eeaeaea" : "transparent")
                                            border.width: cur ? 1 : 0; border.color: Theme.blue
                                            Image { x: 10; y: 6; width: 36; height: 36; sourceSize.width: 72; source: "file:///usr/share/icons/Papirus/48x48/places/folder-" + fc.modelData + ".svg" }
                                            Label { anchors.horizontalCenter: parent.horizontalCenter; y: 48; text: fc.modelData; color: fc.cur ? Theme.fg : Theme.muted; font.pixelSize: 10 }
                                            MouseArea { id: fcm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Settings.set("folder_color", fc.modelData) }
                                        }
                                    }
                                }
                            }
                        }
                        Row {
                            width: parent.width; spacing: 14
                            SetSection {
                                width: (parent.width - 14) / 2; title: "Cursor"; icon: "\u{f01bf}"
                                SetChoice {
                                    label: "Style"; current: Settings.get("cursor_theme")
                                    options: [["Vimix-white-cursors", "Vimix white"], ["Vimix-cursors", "Vimix dark"], ["capitaine-cursors", "Capitaine dark"], ["capitaine-cursors-light", "Capitaine light"], ["breeze_cursors", "Breeze"]]
                                    onPicked: v => Settings.set("cursor_theme", v)
                                }
                                SetChoice {
                                    label: "Size"; accent: Theme.cyan; current: Settings.get("cursor_size")
                                    options: [[24, "Normal"], [32, "Large"], [40, "Huge"]]
                                    onPicked: v => Settings.set("cursor_size", v)
                                }
                            }
                            SetSection {
                                width: (parent.width - 14) / 2; title: "Font"; icon: "\u{f0881}"
                                Column {
                                    width: parent.width; spacing: 6
                                    Label { text: "App font"; color: Theme.fgDim; font.pixelSize: 12 }
                                    Repeater {
                                        model: ["Inter", "Noto Sans", "Fira Sans", "Cantarell"]
                                        Rectangle {
                                            id: fo
                                            required property string modelData
                                            readonly property bool cur: Settings.get("ui_font") === modelData
                                            width: parent.width; height: 34; radius: 12
                                            color: cur ? Qt.rgba(0.88, 0.88, 0.88, 0.16) : (fom.containsMouse ? "#1eeaeaea" : "#33111111")
                                            border.width: cur ? 1 : 0; border.color: Theme.blue
                                            Text { x: 12; anchors.verticalCenter: parent.verticalCenter; text: fo.modelData + " — The quick brown fox"; font.family: fo.modelData; font.pixelSize: 13; color: fo.cur ? Theme.fg : Theme.fgDim }
                                            MouseArea { id: fom; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Settings.set("ui_font", fo.modelData) }
                                        }
                                    }
                                }
                                SetSlider { label: "Font size"; key: "ui_font_size"; from: 9; to: 13; suffix: " pt" }
                            }
                        }
                        Label { width: parent.width; wrapMode: Text.WordWrap; text: "Icons and fonts update in GTK apps right away; Qt apps like Dolphin pick them up next time they open."; color: Theme.muted; font.pixelSize: 10 }
                        SetSection {
                            width: parent.width; title: "Terminal art (fastfetch)"; icon: "\u{f018d}"
                            SetChoice {
                                label: "Shown next to your system info"; current: Settings.get("fetch_logo"); onPicked: v => Settings.set("fetch_logo", v)
                                options: [["katana", "Katana"], ["guts", "Guts portrait"], ["mono", "Mono ring"], ["crest", "Butterfly crest"], ["kamon", "Crest (dots)"], ["butterfly", "Butterfly"], ["portrait", "Shinobu portrait"], ["picture", "My picture"], ["ascii", "Text art"], ["distro", "CachyOS logo"]]
                            }
                            Row {
                                visible: Settings.get("fetch_logo") === "ascii"; spacing: 8
                                SetButton { icon: "\u{f0256}"; text: "Make text art from a picture…"; onClicked: fetchPick.running = true }
                                Label { anchors.verticalCenter: parent.verticalCenter; text: Settings.get("fetch_source") ? Settings.get("fetch_source").split("/").pop() : "Shinobu (default)"; color: Theme.muted; font.pixelSize: 11 }
                            }
                            Label { width: parent.width; wrapMode: Text.WordWrap; text: "Tip: close-up, high-contrast pictures (manga panels, simple portraits) turn into the clearest art."; color: Theme.muted; font.pixelSize: 10 }
                        }
                    }

                    // ---------- 1 Glass ----------
                    Row {
                        visible: root.page === "glass"; width: parent.width; spacing: 18
                        LivePreview { visible: root.page === "glass" }
                        SetSection {
                            width: (parent.width - 14) / 2; title: "Transparency"; icon: "\u{f0c8a}"
                            SetSlider { label: "Focused window"; key: "opacity_active"; from: 50; to: 100; suffix: "%" }
                            SetSlider { label: "Unfocused windows"; key: "opacity_inactive"; from: 40; to: 100; suffix: "%" }
                            SetSlider { label: "Bar & panels glass"; key: "glass"; from: 0; to: 100; suffix: "%" }
                        }
                        SetSection {
                            width: (parent.width - 14) / 2; title: "Blur"; icon: "\u{f00b6}"
                            SetToggle { label: "Blur"; desc: "frosted background behind glass"; key: "blur" }
                            SetSlider { label: "Blur strength"; key: "blur_size"; from: 1; to: 14 }
                            SetSlider { label: "Blur quality"; key: "blur_passes"; from: 1; to: 4 }
                            SetSlider { label: "Colour vibrancy"; key: "vibrancy"; from: 0; to: 60; suffix: "%" }
                            SetSlider { label: "Background brightness"; key: "blur_brightness"; from: 50; to: 110; suffix: "%" }
                            SetSlider { label: "Grain"; key: "blur_noise"; from: 0; to: 10; suffix: "%" }
                            SetToggle { label: "Blur shows only the wallpaper (x-ray)"; key: "blur_xray" }
                            SetToggle { label: "Blur menus and pop-ups"; key: "blur_popups" }
                        }
                    }

                    // ---------- Bar & notifications ----------
                    Row {
                        visible: root.page === "bar"; width: parent.width; spacing: 14
                        SetSection {
                            width: (parent.width - 14) / 2; title: "Desktop clock"; icon: "\u{f0954}"
                            SetToggle { label: "Desktop clock"; desc: "big clock, date and today's line on the wallpaper"; key: "desktop_clock" }
                            SetChoice {
                                visible: Settings.get("desktop_clock"); label: "Desktop clock position"
                                current: Settings.get("desktop_clock_pos"); onPicked: v => Settings.set("desktop_clock_pos", v)
                                options: [["left", "Bottom left"], ["center", "Top centre"]]
                            }
                        }
                        SetSection {
                            width: (parent.width - 14) / 2; title: "Notifications"; icon: "\u{f009a}"
                            SetSlider { label: "Pop-ups stay for"; key: "notif_timeout"; from: 2; to: 15; suffix: " s" }
                            SetChoice {
                                label: "Pop-up position"; current: Settings.get("notif_center") ? "c" : "r"
                                options: [["r", "Top right"], ["c", "Top centre"]]
                                onPicked: v => Settings.set("notif_center", v === "c")
                            }
                            SetToggle { label: "Sounds"; desc: "soft sounds for notifications, login and screenshots"; key: "sounds" }
                            SetSwitch { label: "Do not disturb"; desc: "hide pop-ups, works right away"; on: Notifs.dnd; accent: Theme.purple; onToggled: Notifs.dnd = !Notifs.dnd }
                        }
                    }

                    // ---------- Comfort ----------
                    Row {
                        visible: root.page === "comfort"; width: parent.width; spacing: 14
                        SetSection {
                            width: (parent.width - 14) / 2; title: "Everyday"; icon: "\u{f02dc}"
                            SetToggle { label: "Apply changes instantly"; desc: "no Apply button: every change here takes effect right away"; key: "instant_apply" }
                            SetToggle { label: "Ask before power actions"; desc: "log out, restart and shut down need a second click"; key: "confirm_power" }
                            SetChoice {
                                label: "Volume key step"; desc: "how much one press of the volume keys changes"
                                current: Settings.get("volume_step"); onPicked: v => Settings.set("volume_step", v)
                                options: [[1, "1%"], [2, "2%"], [3, "3%"], [5, "5%"], [10, "10%"]]
                            }
                            SetToggle { label: "Keep screenshot files"; desc: "off: screenshots only go to the clipboard"; key: "shot_save" }
                            SetToggle { label: "Pause music for calls and videos"; desc: "Spotify pauses when the mic opens or a video plays, then continues"; key: "auto_pause" }
                            SetToggle { label: "Sort downloads into folders"; desc: "Images, Videos, Music, Documents, Archives, Installers"; key: "sort_downloads" }
                            SetToggle { label: "Track screen time"; desc: "time per app, shown on the home screen and in the control center (stays on this PC)"; key: "screen_time" }
                            SetToggle { label: "Music stats"; desc: "your top Spotify songs and artists, shown on the home screen (stays on this PC)"; key: "music_stats" }
                        }
                        SetSection {
                            width: (parent.width - 14) / 2; title: "Settings backup"; icon: "\u{f0bc7}"
                            Label { width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: 10; font.weight: Font.Normal
                                    text: "Save a copy of everything you set here before experimenting. The last 20 copies are kept." }
                            Row {
                                spacing: 8
                                SetButton { icon: "\u{f0193}"; text: "Save snapshot"; onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/settings-snapshot.sh", "save"]) }
                                SetButton { icon: "\u{f0450}"; text: "Restore last"
                                    onClicked: root.confirm("\u{f0450}", "Restore your last snapshot?", "Your current settings are replaced by the last copy you saved. Save a snapshot first if you want to keep these.", "Restore", () => Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/settings-snapshot.sh", "restore"])) }
                            }
                            Label { width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: 10; font.weight: Font.Normal
                                    text: "Once a month the system tidies itself: old thumbnails, AUR build leftovers, 30-day-old trash and unused cache files (game shader caches are kept)." }
                            SetButton { icon: "\u{f00e2}"; text: "Tidy now"; onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/tidy.sh"]) }
                            Label { width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: 10; font.weight: Font.Normal
                                    text: "Screenshots: Print = area, Ctrl+Print = screen, Alt+Print = window. They land in ~/Pictures/Screenshots." }
                        }
                    }

                    // ---------- Extras ----------
                    Row {
                        visible: root.page === "extras"; width: parent.width; spacing: 14
                        SetSection {
                            width: (parent.width - 14) / 2; title: "Little helpers"; icon: "\u{f0674}"
                            SetToggle { label: "Hot corner"; desc: "push the mouse into the top-left corner for the overview"; key: "hot_corner" }
                            SetToggle { label: "Pause music when locking"; desc: "Spotify & co. stop when the screen locks"; key: "pause_on_lock" }
                            SetToggle { label: "Song card"; desc: "a small card drops under the bar when the song changes"; key: "island_peeks" }
                            SetToggle { label: "Games get their own workspace"; desc: "a game opens on workspace 5; when it closes you're back where you were"; key: "game_workspace" }
                            SetToggle { label: "ASCII living wallpaper"; desc: "your wallpaper drawn in glowing characters, slowly moving"; key: "ascii_wall" }
                            SetToggle { label: "Wallpaper tint"; desc: "the glass picks up a little of your wallpaper's colour"; key: "wall_tint" }
                            SetToggle { label: "Login hand-off"; desc: "after logging in, the ASCII dunes dissolve into your desktop"; key: "login_handoff" }
                            SetToggle { label: "Workspace previews"; desc: "hover a workspace in the bar to see its windows"; key: "ws_preview" }
                            SetToggle { label: "Screensaver"; desc: "your wallpaper in glowing characters, halfway to the auto-lock"; key: "screensaver" }
                            SetChoice {
                                label: "Wallpaper shuffle"; desc: "a different monochrome wallpaper now and then"
                                current: Settings.get("wall_shuffle"); onPicked: v => Settings.set("wall_shuffle", v)
                                options: [[0, "Off"], [15, "15 min"], [60, "Hourly"], [1440, "Daily"]]
                            }
                        }
                        SetSection {
                            width: (parent.width - 14) / 2; title: "Modes & tricks"; icon: "\u{f0d4a}"
                            SetSwitch {
                                label: "Focus mode  ·  Super + Z"; desc: "no gaps, no bar, no pop-ups, just the window"
                                on: root.focusOn; accent: Theme.on
                                onToggled: { Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/focus-mode.sh"]); root.focusOn = !root.focusOn }
                            }
                            SetSwitch {
                                label: "Drop-down terminal  ·  Super + \""; desc: "a terminal slides from the top; same key hides it"
                                on: false; accent: Theme.on
                                onToggled: { root.visible = false; Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/dropterm.sh"]) }
                            }
                            SetSwitch {
                                label: "Ink  ·  Super + D"; desc: "draw on the screen; Ctrl + S saves a screenshot with it"
                                on: false; accent: Theme.on
                                onToggled: { root.visible = false; Quickshell.execDetached(["qs", "ipc", "-p", root.qsDir, "call", "ink", "toggle"]) }
                            }
                            Label { width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: 10; font.weight: Font.Normal
                                    text: "Magnifier: hold Super + Alt and scroll (Super + Alt + Z resets). "
                                        + "Picture-in-picture videos from any browser pop into the bottom-right corner, stay on every workspace and never go see-through." }
                        }
                    }

                    // ---------- Mouse & keyboard ----------
                    Column {
                        visible: root.page === "input"; width: parent.width; spacing: 14
                        Row {
                            width: parent.width; spacing: 14
                            SetSection {
                                width: (parent.width - 14) / 2; title: "Mouse"; icon: "\u{f037d}"
                                SetSlider { label: "Mouse speed"; key: "sensitivity"; from: -1; to: 1; step: 0.05; decimals: 2 }
                                SetToggle { label: "Raw input (no acceleration)"; desc: "best for games and aiming"; key: "accel_flat" }
                                SetSlider { label: "Scroll speed"; key: "scroll_factor"; from: 0.2; to: 3; step: 0.1; decimals: 1; suffix: "×" }
                                SetToggle { label: "Natural scrolling"; desc: "content follows your finger, like a phone"; key: "natural_scroll" }
                                SetChoice {
                                    label: "Middle-click scrolling"; desc: "Windows style: click the wheel, move to scroll, click to stop"
                                    current: Settings.get("scroll_mode"); onPicked: v => Settings.set("scroll_mode", v)
                                    options: [["autoscroll", "Windows (click & move)"], ["hold", "Hold & drag"]]
                                }
                                SetToggle { label: "Middle-click paste"; key: "middle_paste" }
                            }
                            SetSection {
                                width: (parent.width - 14) / 2; title: "Keyboard"; icon: "\u{f030c}"
                                SetChoice {
                                    label: "Layout"; current: Settings.get("kb_layout"); onPicked: v => Settings.set("kb_layout", v)
                                    options: [["tr", "Turkish Q"], ["us", "US"], ["tr,us", "Turkish + US"]]
                                }
                                SetSlider { label: "Key repeat speed"; key: "repeat_rate"; from: 10; to: 60; suffix: " /s" }
                                SetSlider { label: "Delay before repeat"; key: "repeat_delay"; from: 150; to: 800; step: 10; suffix: " ms" }
                                SetToggle { label: "Num Lock on at start"; key: "numlock" }
                                SetButton { icon: "\u{f030c}"; text: "Show all shortcuts"; onClicked: root.exec([Quickshell.env("HOME") + "/.config/hypr/scripts/keybinds.sh"]) }
                            }
                        }
                        Row {
                            width: parent.width; spacing: 14
                            SetSection {
                                width: (parent.width - 14) / 2; title: "Focus"; icon: "\u{f0f08}"
                                SetToggle { label: "Focus follows mouse"; key: "follow_mouse" }
                                SetToggle { label: "Focus on activate"; desc: "apps can pull you to them"; key: "focus_on_activate" }
                                SetToggle { label: "Workspace back-and-forth"; desc: "pressing the current workspace's key goes back"; key: "ws_back_forth" }
                                SetToggle { label: "Terminal swallowing"; desc: "kitty hides while an app it opened is running"; key: "swallow" }
                            }
                            SetSection {
                                width: (parent.width - 14) / 2; title: "Pointer"; icon: "\u{f01bf}"
                                SetToggle { label: "Hide pointer while typing"; key: "hide_cursor_typing" }
                                SetSlider { label: "Hide pointer when idle"; key: "cursor_hide_after"; from: 0; to: 30; suffix: " s" }
                                Label { text: "0 s = never"; color: Theme.muted; font.pixelSize: 10 }
                            }
                        }
                    }

                    // ---------- Display ----------
                    Column {
                        visible: root.page === "display"; width: parent.width; spacing: 14

                        Row {   // pick a screen
                            width: parent.width; spacing: 14
                            Repeater {
                                model: root.monitors
                                Rectangle {
                                    id: monCard
                                    required property var modelData
                                    readonly property bool sel: root.selMon === modelData.name
                                    width: (parent.width - 14) / 2; height: 112; radius: 12
                                    color: sel ? Qt.rgba(0.88, 0.88, 0.88, 0.12) : (mcm.containsMouse ? "#1eeaeaea" : Theme.card)
                                    border.width: 1; border.color: sel ? Theme.blue : "#14eaeaea"
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                    MouseArea { id: mcm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.selMon = monCard.modelData.name }
                                    Rectangle {
                                        x: 16; anchors.verticalCenter: parent.verticalCenter
                                        width: monCard.modelData.width > 2000 ? 120 : 100; height: width * 9 / 16; radius: 7
                                        color: Theme.bgAlt; border.width: 2; border.color: monCard.sel ? Theme.blue : Theme.line
                                        Label { anchors.centerIn: parent; text: monCard.modelData.name === "DP-1" ? "Main" : "Side"; color: monCard.sel ? Theme.blue : Theme.muted; font.pixelSize: 11 }
                                    }
                                    Column {
                                        x: monCard.modelData.width > 2000 ? 150 : 130; width: parent.width - x - 12
                                        anchors.verticalCenter: parent.verticalCenter; spacing: 3
                                        Label { width: parent.width; elide: Text.ElideRight; text: monCard.modelData.model || monCard.modelData.name; font.pixelSize: 13; font.weight: Font.Bold }
                                        Label { text: monCard.modelData.width + " × " + monCard.modelData.height + " · " + Math.round(monCard.modelData.refreshRate) + " Hz"; color: Theme.blue; font.pixelSize: 12 }
                                        Label { text: monCard.modelData.name + " · " + (monCard.modelData.name === "DP-1" ? "workspaces 1–20" : "Discord + Spotify"); color: Theme.muted; font.pixelSize: 10 }
                                    }
                                }
                            }
                        }

                        SetSection {
                            width: parent.width; title: "Resolution & refresh rate · " + root.selMon; icon: "\u{f0379}"
                            SetChoice {
                                label: "Resolution"
                                current: root.selCfg.mode ? root.selCfg.mode.split("@")[0] : ""
                                options: root.resolutions.map(r => [r, r.replace("x", " × ")])
                                onPicked: v => root.monChange("mode", v + "@" + root.ratesFor(v)[0])
                            }
                            SetChoice {
                                label: "Refresh rate"; accent: Theme.cyan
                                current: root.selCfg.mode ? root.selCfg.mode.split("@")[1] : ""
                                options: root.ratesFor(root.selCfg.mode ? root.selCfg.mode.split("@")[0] : "").map(r => [r, Math.round(parseFloat(r)) + " Hz"])
                                onPicked: v => root.monChange("mode", root.selCfg.mode.split("@")[0] + "@" + v)
                            }
                        }

                        SetSection {
                            width: parent.width; title: "Colour · " + root.selMon; icon: "\u{f03d8}"
                            SetChoice {
                                label: "Colour mode"; desc: "How colours are mapped to this screen"; accent: Theme.purple
                                current: root.selCfg.cm || "srgb"
                                options: [["srgb", "Accurate (sRGB)"], ["wide", "Vivid (wide gamut)"], ["edid", "Monitor's own (EDID)"]]
                                onPicked: v => root.monChange("cm", v)
                            }
                            SetSwitch {
                                label: "10-bit colour"; desc: "smoother gradients, less banding (if the screen supports it)"; accent: Theme.purple
                                on: root.selCfg.bitdepth === 10; onToggled: root.monChange("bitdepth", root.selCfg.bitdepth === 10 ? 8 : 10)
                            }
                            SetSwitch {
                                label: "Adaptive sync (VRR)"; desc: "smoother games below max Hz; only in fullscreen, so the desktop never flickers"; accent: Theme.yellow
                                on: !!root.selCfg.vrr; onToggled: root.monChange("vrr", root.selCfg.vrr ? 0 : 1)
                            }
                        }

                        Row {
                            width: parent.width; spacing: 14
                            SetSection {
                                width: (parent.width - 14) / 2; title: "Vibrance"; icon: "\u{f0e09}"
                                SetSlider { label: "Colour vibrance (all screens)"; key: "vibrance"; from: 70; to: 150; step: 5; suffix: "%" }
                                SetToggle { label: "Monochrome mode"; desc: "the whole screen in black and white, colours come back while you play (Super + Alt + M)"; key: "mono_mode" }
                                Label { width: parent.width; wrapMode: Text.WordWrap; text: "100% = untouched. Higher makes colours pop; uses a tiny bit of GPU."; color: Theme.muted; font.pixelSize: 10 }
                            }
                            SetSection {
                                width: (parent.width - 14) / 2; title: "Night light"; icon: "\u{f0594}"
                                SetSwitch { label: "Night light"; desc: "warmer colours at night"; on: SysState.night; accent: Theme.yellow; onToggled: SysState.toggleNight() }
                                SetSlider { label: "Warmth"; key: "night_temp"; from: 2500; to: 6500; step: 100; suffix: " K" }
                                SetToggle { label: "On a schedule"; desc: "on in the evening, off in the morning"; key: "night_auto" }
                                SetSlider { visible: Settings.get("night_auto"); label: "Turn on at"; key: "night_from"; from: 17; to: 23; suffix: ":00" }
                                SetSlider { visible: Settings.get("night_auto"); label: "Turn off at"; key: "night_to"; from: 4; to: 10; suffix: ":00" }
                            }
                        }
                    }

                    // ---------- 4 Sound ----------
                    Column {
                        visible: root.page === "sound"; width: parent.width; spacing: 14
                        Row {
                            width: parent.width; spacing: 14
                            SetSection {
                                width: (parent.width - 14) / 2; title: "Output"; icon: "\u{f057e}"
                                Repeater {
                                    model: root.sinks
                                    DeviceRow { required property var modelData; node: modelData; current: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.id === modelData.id || (SysState.fx.eq && (modelData.name || "").indexOf("Fuxi") >= 0)
                                        onPicked: { if (SysState.fx.eq) SysState.fxToggle("eq"); Pipewire.preferredDefaultAudioSink = modelData } }
                                }
                            }
                            SetSection {
                                width: (parent.width - 14) / 2; title: "Input"; icon: "\u{f036c}"
                                Repeater {
                                    model: root.sources
                                    DeviceRow { required property var modelData; node: modelData; accent: Theme.purple; current: Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.id === modelData.id || (SysState.fx.mic && (modelData.name || "").indexOf("Fuxi") >= 0)
                                        onPicked: { if (SysState.fx.mic) SysState.fxToggle("mic"); Pipewire.preferredDefaultAudioSource = modelData } }
                                }
                            }
                        }
                        SetSection {
                            width: parent.width; title: "Effects"; icon: "\u{f1de}"
                            SetSwitch { label: "Clean mic"; desc: "AI noise removal on your headset mic (keyboard, fans, room)"; on: !!SysState.fx.mic; accent: Theme.purple; onToggled: SysState.fxToggle("mic") }
                            SetSwitch { label: "Headset EQ"; desc: "tuned sound for the Fuxi-H3"; on: !!SysState.fx.eq; accent: Theme.cyan; onToggled: SysState.fxToggle("eq") }
                            SetChoice {
                                visible: !!SysState.fx.eq
                                label: "EQ preset"; accent: Theme.cyan; current: SysState.fx.preset
                                options: [["flat", "Flat"], ["music", "Music"], ["vocal", "Vocal"], ["games", "Games · footsteps"], ["bass", "Bass boost"]]
                                onPicked: v => SysState.fxPreset(v)
                            }
                        }
                    }

                    // ---------- 5 Power & lock ----------
                    Column {
                        visible: root.page === "power"; width: parent.width; spacing: 14
                        SetSection {
                            width: parent.width; title: "Power profile"; icon: "\u{f0e7}"
                            SetChoice {
                                label: "Profile"; desc: "Performance lets the CPU and GPU clock higher (warmer, louder)"
                                current: SysState.profile; accent: Theme.red
                                options: [["power-saver", "\u{f032a}  Quiet"], ["balanced", "\u{f05d1}  Balanced"], ["performance", "\u{f04c5}  Performance"]]
                                onPicked: v => SysState.setProfile(v)
                            }
                            SetToggle { label: "Automatic game mode"; desc: "Performance + Do not disturb while a game is open"; key: "game_mode" }
                        }
                        SetSection {
                            width: parent.width; title: "Lock & screen off"; icon: "\u{f033e}"
                            SetSlider { label: "Lock after"; key: "lock_minutes"; from: 2; to: 60; suffix: " min" }
                            SetSlider { label: "Screens off after locking"; key: "screen_off_after"; from: 1; to: 30; suffix: " min" }
                            SetToggle { label: "Moving the mouse wakes the screens"; desc: "otherwise only a key press does"; key: "mouse_wakes" }
                            Label { text: "Full-screen games and videos never lock."; color: Theme.muted; font.pixelSize: 11; width: parent.width; wrapMode: Text.WordWrap }
                            SetSwitch { label: "Keep awake"; desc: "pause auto-lock and screen-off until you turn this off"; on: SysState.awake; accent: Theme.cyan; onToggled: SysState.toggleAwake() }
                            Row {
                                spacing: 8; topPadding: 4
                                SetButton { icon: "\u{f033e}"; text: "Lock now"; onClicked: root.exec(["loginctl", "lock-session"]) }
                                SetButton { icon: "\u{f0425}"; text: "Power menu"; accent: Theme.red; onClicked: root.exec([Quickshell.env("HOME") + "/.config/hypr/scripts/powermenu.sh"]) }
                            }
                        }
                    }

                    // ---------- 6 System ----------
                    Column {
                        visible: root.page === "about"; width: parent.width; spacing: 14
                        Rectangle {
                            width: parent.width; height: 120; radius: 22; color: "#131313"
                            Row {
                                x: 22; anchors.verticalCenter: parent.verticalCenter; spacing: 20
                                Label { text: "\u{f08c7}"; font.pixelSize: 64; color: Theme.blue; anchors.verticalCenter: parent.verticalCenter }
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter; spacing: 4
                                    Label { text: "CachyOS"; font.pixelSize: 20; font.weight: Font.Bold }
                                    Label { text: "Hyprland " + (root.info.hypr || "") + " · " + (root.info.host || ""); color: "#b0b0b0"; font.pixelSize: 12 }
                                    Label { text: "Linux " + (root.info.kernel || "") + " · up " + Stats.d.uptime; color: Theme.muted; font.pixelSize: 11 }
                                }
                            }
                        }
                        GridLayout {
                            width: parent.width; columns: 2; columnSpacing: 10; rowSpacing: 10
                            Repeater {
                                model: [["\u{f0ee0}", "Processor", root.info.cpu, Theme.cyan], ["\u{f08ae}", "Graphics", root.info.gpu2 || root.info.gpu, Theme.purple],
                                        ["\u{f035b}", "Memory", root.info.ram, Theme.yellow], ["\u{f02ca}", "Disk", root.info.disk, Theme.green],
                                        ["\u{f03d6}", "Packages", root.info.pkgs, Theme.blue], ["\u{f0aaa}", "Updates", Updates.total > 0 ? Updates.total + " waiting" : "up to date", Updates.total > 0 ? Theme.yellow : Theme.green]]
                                Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true; Layout.preferredWidth: 1; height: 58; radius: 18; color: "#131313"
                                    Row {
                                        x: 14; anchors.verticalCenter: parent.verticalCenter; spacing: 12
                                        Label { text: modelData[0]; color: modelData[3]; font.pixelSize: 18; anchors.verticalCenter: parent.verticalCenter }
                                        Column {
                                            anchors.verticalCenter: parent.verticalCenter
                                            Label { text: modelData[1]; color: Theme.muted; font.pixelSize: 10 }
                                            Label { text: modelData[2] || "…"; font.pixelSize: 12; width: 280; elide: Text.ElideRight }
                                        }
                                    }
                                }
                            }
                        }
                        PgUpdates { width: parent.width }
                        SetSection {
                            width: parent.width; title: "Safety"; icon: "\u{f0499}"
                            Label { width: parent.width; wrapMode: Text.WordWrap; color: Theme.fgDim; font.pixelSize: 11
                                text: "A snapshot of the system is saved automatically before and after every update. Updates from here also check that Hyprland and the bar still load afterwards." }
                            Label { width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: 11
                                text: "If an update ever breaks something: reboot, open Snapshots in the boot menu and pick the one from before the update." }
                            Flow {
                                width: parent.width; spacing: 8
                                SetButton { icon: "\u{f0e9c}"; text: "Save a snapshot now"; onClicked: root.exec(["kitty", "--class", "updater", "-e", "bash", "-c", "sudo snapper -c root create -d 'manual (Settings)' && echo '✓ snapshot saved'; sudo snapper -c root list | tail -5; read -n1 -rsp 'press any key'"]) }
                                SetButton { icon: "\u{f0279}"; text: "Show snapshots"; onClicked: root.exec(["kitty", "--class", "updater", "-e", "bash", "-c", "sudo snapper -c root list; read -n1 -rsp 'press any key'"]) }
                            }
                        }
                        SetSection {
                            width: parent.width; title: "Maintenance"; icon: "\u{f0ad}"
                            Flow {
                                width: parent.width; spacing: 8
                                SetButton { icon: "\u{f06b0}"; text: "Update system"; primary: true
                                    onClicked: root.exec(["kitty", "--class", "updater", "-e", "bash", "-c", Quickshell.env("HOME") + "/.local/bin/safe-update.sh"]) }
                                SetButton { icon: "\u{f04d9}"; text: "Run check-up"; onClicked: root.exec([Quickshell.env("HOME") + "/.local/bin/weekly-checkup.sh"]) }
                                SetButton { icon: "\u{f02a2}"; text: "Back up config to GitHub"
                                    onClicked: root.exec(["sh", "-c", "out=$(~/dotfiles/sync.sh 2>&1 | tail -2); notify-send -a Dotfiles 'Config backup' \"$out\""]) }
                                SetButton { icon: "\u{f018d}"; text: "Task manager"; onClicked: root.exec(["kitty", "--class", "btop", "-e", "btop"]) }
                            }
                        }
                    }
                }
            }
        }
    }
}
