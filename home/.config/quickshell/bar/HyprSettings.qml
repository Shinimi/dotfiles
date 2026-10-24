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
        ["effects", "\u{f1545}", "Effects", "Look & feel", "glow shadow dim animation speed"],
        ["theme", "\u{f08b5}", "Theme", "Look & feel", "icons folder cursor font"],
        ["glass", "\u{f00b5}", "Glass & blur", "Look & feel", "transparency opacity blur"],
        ["wallpaper", "\u{f02e9}", "Wallpaper", "Look & feel", "background picture"],
        ["bar", "\u{f009a}", "Notifications", "Desktop", "notifications pop-ups sounds do not disturb desktop clock"],
        ["comfort", "\u{f04b9}", "Comfort", "Desktop", "instant apply volume step screenshot confirm power snapshot backup restore"],
        ["extras", "\u{f0674}", "Extras", "Desktop", "hot corner focus mode drop-down terminal screensaver ink draw magnifier zoom picture in picture wallpaper shuffle pause music lock"],
        ["shortcuts", "\u{f030c}", "Shortcuts", "Desktop", "keybinds keys hotkeys"],
        ["defaults", "\u{f003b}", "Default apps", "Desktop", "browser file manager open with"],
        ["autostart", "\u{f14df}", "Autostart", "Desktop", "login startup apps"],
        ["games", "\u{f0eb5}", "Games", "Desktop", "fps cap overlay mangohud profile power"],
        ["display", "\u{f0379}", "Display", "Devices", "monitor resolution refresh hz colour night light vibrance"],
        ["sound", "\u{f057e}", "Sound", "Devices", "audio volume mic eq headset"],
        ["input", "\u{f037d}", "Mouse & keyboard", "Devices", "pointer scroll layout typing repeat"],
        ["network", "\u{f0200}", "Network", "Devices", "internet ethernet wifi ip"],
        ["bluetooth", "\u{f00af}", "Bluetooth", "Devices", "headphones devices pair"],
        ["storage", "\u{f02ca}", "Storage", "Devices", "disk ssd space health"],
        ["power", "\u{f0425}", "Power & lock", "System", "sleep lock screen off game mode performance"],
        ["datetime", "\u{f0954}", "Date & time", "System", "clock timezone ntp"],
        ["about", "\u{f02fd}", "About & updates", "System", "system info updates maintenance cpu gpu"]
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
                        SetHeading { text: "Tiling layout · how new windows are placed"; icon: "\u{f0570}" }
                        Row {   // each layout drawn as a tiny screen
                            width: parent.width; spacing: 10
                            Repeater {
                                model: [["dwindle", "Spiral", "each new window splits the last one"], ["master", "Main + stack", "one big window, the rest stack beside it"], ["scrolling", "Scrolling", "windows sit in a row you scroll through"]]
                                Rectangle {
                                    id: lt
                                    required property var modelData
                                    readonly property bool on: Settings.get("layout") === modelData[0]
                                    width: (parent.width - 20) / 3; height: 150; radius: 16
                                    color: on ? "#ececec" : ltm.containsMouse ? "#1c1c1c" : "#131313"; border.width: 1; border.color: on ? "#ececec" : ltm.containsMouse ? "#33ffffff" : "#1d1d1d"
                                    Behavior on color { ColorAnimation { duration: 130 } }
                                    readonly property color ink: on ? "#0b0b0b" : "#cfcfcf"
                                    readonly property color soft: on ? "#300b0b0b" : "#2a2a2a"
                                    Item {
                                        id: scr; x: 14; y: 14; width: parent.width - 28; height: 80
                                        Rectangle { anchors.fill: parent; radius: 8; color: "transparent"; border.width: 1; border.color: lt.soft }
                                        // dwindle: half | quarter | eighths
                                        Repeater {
                                            model: lt.modelData[0] === "dwindle" ? [[0, 0, 0.5, 1], [0.5, 0, 0.5, 0.5], [0.5, 0.5, 0.25, 0.5], [0.75, 0.5, 0.25, 0.5]]
                                                 : lt.modelData[0] === "master" ? [[0, 0, 0.6, 1], [0.6, 0, 0.4, 0.333], [0.6, 0.333, 0.4, 0.333], [0.6, 0.666, 0.4, 0.334]]
                                                 : [[-0.25, 0, 0.45, 1], [0.25, 0, 0.5, 1], [0.8, 0, 0.45, 1]]
                                            Rectangle {
                                                required property var modelData
                                                required property int index
                                                x: Math.max(4, scr.width * modelData[0] + 4); y: scr.height * modelData[1] + 4
                                                width: Math.min(scr.width - 4, scr.width * (modelData[0] + modelData[2]) - 4) - x; height: scr.height * modelData[3] - 8
                                                radius: 5; color: index === (lt.modelData[0] === "scrolling" ? 1 : 0) ? lt.ink : "transparent"
                                                border.width: 1.5; border.color: lt.ink; opacity: lt.modelData[0] === "scrolling" && index !== 1 ? 0.45 : 1
                                            }
                                        }
                                    }
                                    Column {
                                        x: 14; y: 104; width: parent.width - 28; spacing: 2
                                        Text { text: lt.modelData[1]; color: lt.on ? "#0b0b0b" : "#ececec"; font.family: Theme.font; font.pixelSize: 12; font.bold: true }
                                        Text { width: parent.width; elide: Text.ElideRight; text: lt.modelData[2].charAt(0).toUpperCase() + lt.modelData[2].slice(1); color: lt.on ? "#70000000" : "#6e6e6e"; font.family: Theme.font; font.pixelSize: 9 }
                                    }
                                    MouseArea { id: ltm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Settings.set("layout", lt.modelData[0]) }
                                }
                            }
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
                                Label { width: parent.width; wrapMode: Text.WordWrap; text: "Tiling layout is chosen above. These change how windows behave."; color: "#6e6e6e"; font.pixelSize: 10; font.weight: Font.Normal }
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
                                SetTiles {
                                    visible: Settings.get("animations"); label: "Speed"; columns: 3
                                    current: Settings.get("anim_speed"); onPicked: v => Settings.set("anim_speed", v)
                                    options: [["slow", "Relaxed", "calm", "\u{f0d3b}"], ["normal", "Normal", "balanced", "\u{f046e}"], ["fast", "Snappy", "quick", "\u{f0907}"]]
                                }
                                SetTiles {
                                    visible: Settings.get("animations"); label: "Workspace switch"; columns: 2
                                    current: Settings.get("ws_anim"); onPicked: v => Settings.set("ws_anim", v)
                                    options: [["slidefade", "Slide + fade", "", "\u{f084e}"], ["slide", "Slide", "", "\u{f04e1}"], ["slidevert", "Vertical", "", "\u{f04e2}"], ["fade", "Fade", "", "\u{f1853}"]]
                                }
                            }
                        }
                    }

                    // ---------- Theme ----------
                    Column {
                        visible: root.page === "theme"; width: parent.width; spacing: 14
                        SetSection {
                            width: parent.width; title: "Icons"; icon: "\u{f02e9}"
                            SetTiles {
                                label: "Icon style"; columns: 3; current: Settings.get("icon_base")
                                options: [["Tela-mono", "Tela mono", "flat, single colour", "\u{f024b}"], ["Papirus-Dark", "Papirus", "rounded, pick a folder colour", "\u{f024b}"], ["breeze-dark", "Breeze", "KDE's own", "\u{f024b}"]]
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
                                SetTiles {
                                    label: "Style"; columns: 2; current: Settings.get("cursor_theme")
                                    options: [["Vimix-white-cursors", "Vimix white", "light pointer"], ["Vimix-cursors", "Vimix dark", "dark pointer"], ["capitaine-cursors", "Capitaine dark", "macOS-like"], ["capitaine-cursors-light", "Capitaine light", "macOS-like"], ["breeze_cursors", "Breeze", "KDE's own"]]
                                    onPicked: v => Settings.set("cursor_theme", v)
                                }
                                SetTiles {
                                    label: "Size"; columns: 3; current: Settings.get("cursor_size")
                                    options: [[24, "Normal", "24 px", "\u{f01bf}"], [32, "Large", "32 px", "\u{f01bf}"], [40, "Huge", "40 px", "\u{f01bf}"]]
                                    onPicked: v => Settings.set("cursor_size", v)
                                }
                            }
                            SetSection {
                                width: (parent.width - 14) / 2; title: "Font"; icon: "\u{f0881}"
                                Column {
                                    width: parent.width; spacing: 8
                                    Label { text: "App font"; color: "#e6e6e6"; font.pixelSize: 12 }
                                    Grid {   // each font shown in itself
                                        width: parent.width; columns: 2; columnSpacing: 8; rowSpacing: 8
                                        Repeater {
                                            model: ["Inter", "Noto Sans", "Fira Sans", "Cantarell"]
                                            Rectangle {
                                                id: fo
                                                required property string modelData
                                                readonly property bool cur: Settings.get("ui_font") === modelData
                                                width: (parent.width - 8) / 2; height: 74; radius: 14
                                                color: cur ? "#ececec" : fom.containsMouse ? "#1c1c1c" : "#0f0f0f"; border.width: 1; border.color: cur ? "#ececec" : "#222222"
                                                Behavior on color { ColorAnimation { duration: 130 } }
                                                Text { x: 12; y: 6; text: "Aa"; font.family: fo.modelData; font.pixelSize: 30; color: fo.cur ? "#0b0b0b" : "#f0f0f0" }
                                                Text { x: 12; anchors.bottom: parent.bottom; anchors.bottomMargin: 8; text: fo.modelData; font.family: fo.modelData; font.pixelSize: 11; color: fo.cur ? "#70000000" : "#8a8a8a" }
                                                MouseArea { id: fom; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Settings.set("ui_font", fo.modelData) }
                                            }
                                        }
                                    }
                                }
                                SetSlider { label: "Font size"; key: "ui_font_size"; from: 9; to: 13; suffix: " pt" }
                            }
                        }
                        Label { width: parent.width; wrapMode: Text.WordWrap; text: "Icons and fonts update in GTK apps right away; Qt apps like Dolphin pick them up next time they open."; color: Theme.muted; font.pixelSize: 10 }
                        SetSection {
                            width: parent.width; title: "Terminal art (fastfetch)"; icon: "\u{f018d}"
                            SetTiles {
                                label: "Shown next to your system info"; columns: 5; current: Settings.get("fetch_logo"); onPicked: v => Settings.set("fetch_logo", v)
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
                    Column {
                        visible: root.page === "glass"; width: parent.width; spacing: 18
                        LivePreview { visible: root.page === "glass" }
                        Row {
                        width: parent.width; spacing: 14
                        SetSection {
                            width: (parent.width - 14) / 2; title: "Transparency"; icon: "\u{f05cc}"
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
                    }

                    // ---------- Notifications ----------
                    Column {
                        visible: root.page === "bar"; width: parent.width; spacing: 18
                        Rectangle {   // a mini screen showing where pop-ups and the desktop clock go
                            id: nscr
                            width: parent.width; height: 210; radius: 18; color: "#0e0e0e"; border.width: 1; border.color: "#1d1d1d"
                            Rectangle { x: 14; y: 12; width: parent.width - 28; height: 14; radius: 7; color: "#1a1a1a" }
                            Rectangle {   // the pop-up
                                width: 220; height: 58; radius: 12; color: Notifs.dnd ? "#141414" : "#1f1f1f"; border.width: 1; border.color: Notifs.dnd ? "#222" : "#3a3a3a"
                                x: Settings.get("notif_center") ? (parent.width - width) / 2 : parent.width - width - 20; y: 36
                                opacity: Notifs.dnd ? 0.35 : 1
                                Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                Rectangle { x: 10; y: 10; width: 38; height: 38; radius: 10; color: "#2c2c2c"; Text { anchors.centerIn: parent; text: "\u{f009a}"; color: "#d0d0d0"; font.family: Theme.font; font.pixelSize: 16 } }
                                Column { x: 58; y: 12; spacing: 4
                                    Text { text: Notifs.dnd ? "Silenced" : "New message"; color: "#ececec"; font.family: Theme.font; font.pixelSize: 11; font.bold: true }
                                    Text { text: Notifs.dnd ? "Do not disturb is on" : "Stays " + Settings.get("notif_timeout") + " s"; color: "#7a7a7a"; font.family: Theme.font; font.pixelSize: 10 } }
                                Rectangle {   // the time it stays, as a bar
                                    anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.margins: 8; height: 2; radius: 1; color: "#8a8a8a"
                                    width: (parent.width - 16) * Settings.get("notif_timeout") / 15
                                    Behavior on width { NumberAnimation { duration: 150 } }
                                }
                            }
                            Column {   // the desktop clock
                                visible: Settings.get("desktop_clock")
                                x: Settings.get("desktop_clock_pos") === "center" ? (parent.width - width) / 2 : 28
                                y: Settings.get("desktop_clock_pos") === "center" ? 104 : parent.height - height - 22
                                Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                Text { text: Qt.formatTime(new Date(), "HH:mm"); color: "#d8d8d8"; font.family: Theme.font; font.pixelSize: 34; font.bold: true }
                                Text { text: Qt.formatDate(new Date(), "dddd d MMMM"); color: "#7a7a7a"; font.family: Theme.font; font.pixelSize: 10 }
                            }
                            Text { anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 12; text: "Preview"; color: "#4a4a4a"; font.family: Theme.font; font.pixelSize: 9 }
                        }
                        Row {
                            width: parent.width; spacing: 14
                            SetSection {
                                width: (parent.width - 14) / 2; title: "Pop-ups"; icon: "\u{f009a}"
                                SetTiles {
                                    label: "Position"; columns: 2; current: Settings.get("notif_center") ? "c" : "r"
                                    options: [["r", "Top right", "out of the way", "\u{f0e57}"], ["c", "Top centre", "easy to spot", "\u{f009f}"]]
                                    onPicked: v => Settings.set("notif_center", v === "c")
                                }
                                SetSlider { label: "Pop-ups stay for"; key: "notif_timeout"; from: 2; to: 15; suffix: " s" }
                                SetToggle { label: "Sounds"; desc: "soft sounds for notifications, login and screenshots"; key: "sounds" }
                                SetSwitch { label: "Do not disturb"; desc: "hide pop-ups, works right away"; on: Notifs.dnd; onToggled: Notifs.dnd = !Notifs.dnd }
                            }
                            SetSection {
                                width: (parent.width - 14) / 2; title: "Desktop clock"; icon: "\u{f0954}"
                                SetToggle { label: "Desktop clock"; desc: "big clock, date and today's line on the wallpaper"; key: "desktop_clock" }
                                SetTiles {
                                    visible: Settings.get("desktop_clock"); label: "Position"; columns: 2
                                    current: Settings.get("desktop_clock_pos"); onPicked: v => Settings.set("desktop_clock_pos", v)
                                    options: [["left", "Bottom left", "", "\u{f005b}"], ["center", "Top centre", "", "\u{f0954}"]]
                                }
                            }
                        }
                    }

                    // ---------- Comfort ----------
                    Column {
                        visible: root.page === "comfort"; width: parent.width; spacing: 18
                        SetHeading { text: "Everyday"; icon: "\u{f04b9}" }
                        Grid {
                            width: parent.width; columns: 3; columnSpacing: 10; rowSpacing: 10
                            readonly property real cw: (width - 20) / 3
                            FeatureCard { width: parent.cw; icon: "\u{f0241}"; label: "Apply instantly"; desc: "no Apply button: every change here takes effect right away"; key: "instant_apply" }
                            FeatureCard { width: parent.cw; icon: "\u{f0565}"; label: "Ask before power"; desc: "log out, restart and shut down need a second click"; key: "confirm_power" }
                            FeatureCard { width: parent.cw; icon: "\u{f0100}"; label: "Keep screenshots"; desc: "saved to ~/Pictures/Screenshots; off: clipboard only"; key: "shot_save" }
                            FeatureCard { width: parent.cw; icon: "\u{f038a}"; label: "Pause for calls"; desc: "Spotify pauses when the mic opens or a video plays, then continues"; key: "auto_pause" }
                            FeatureCard { width: parent.cw; icon: "\u{f024d}"; label: "Sort downloads"; desc: "into Images, Videos, Music, Documents, Archives, Installers"; key: "sort_downloads" }
                            FeatureCard { width: parent.cw; icon: "\u{f051f}"; label: "Screen time"; desc: "time per app on the home screen and control center"; key: "screen_time" }
                            FeatureCard { width: parent.cw; icon: "\u{f0128}"; label: "Music stats"; desc: "your top Spotify songs and artists on the home screen"; key: "music_stats" }
                        }
                        Row {
                            width: parent.width; spacing: 14
                            SetSection {
                                width: (parent.width - 14) / 2; title: "Volume keys"; icon: "\u{f057e}"
                                SetTiles {
                                    label: "One press changes the volume by"; columns: 5
                                    current: Settings.get("volume_step"); onPicked: v => Settings.set("volume_step", v)
                                    options: [[1, "1%", "fine"], [2, "2%", ""], [3, "3%", ""], [5, "5%", ""], [10, "10%", "big"]]
                                }
                                Label { width: parent.width; wrapMode: Text.WordWrap; color: "#6e6e6e"; font.pixelSize: 10; font.weight: Font.Normal
                                        text: "Screenshots: Print = area, Ctrl + Print = screen, Alt + Print = window." }
                            }
                            SetSection {
                                width: (parent.width - 14) / 2; title: "Backup and tidy"; icon: "\u{f0bc7}"
                                Label { width: parent.width; wrapMode: Text.WordWrap; color: "#8a8a8a"; font.pixelSize: 10; font.weight: Font.Normal
                                        text: "Save a copy of everything you set here before experimenting. The last 20 copies are kept." }
                                Row {
                                    spacing: 8
                                    SetButton { icon: "\u{f0193}"; text: "Save snapshot"; onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/settings-snapshot.sh", "save"]) }
                                    SetButton { icon: "\u{f0450}"; text: "Restore last"
                                        onClicked: root.confirm("\u{f0450}", "Restore your last snapshot?", "Your current settings are replaced by the last copy you saved. Save a snapshot first if you want to keep these.", "Restore", () => Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/settings-snapshot.sh", "restore"])) }
                                }
                                Label { width: parent.width; wrapMode: Text.WordWrap; color: "#8a8a8a"; font.pixelSize: 10; font.weight: Font.Normal
                                        text: "Once a month the system tidies itself: old thumbnails, AUR build leftovers, 30-day-old trash and unused caches (game shader caches are kept)." }
                                SetButton { icon: "\u{f00e2}"; text: "Tidy now"; onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/tidy.sh"]) }
                            }
                        }
                    }

                    // ---------- Extras ----------
                    Column {
                        visible: root.page === "extras"; width: parent.width; spacing: 18
                        SetHeading { text: "Modes and tools"; icon: "\u{f0674}" }
                        Grid {
                            width: parent.width; columns: 3; columnSpacing: 10; rowSpacing: 10
                            readonly property real cw: (width - 20) / 3
                            FeatureCard { width: parent.cw; icon: "\u{f02f1}"; label: "Focus mode"; hint: "Super + Z"; desc: "no gaps, no bar, no pop-ups, just the window"
                                          on: root.focusOn; onToggled: { Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/focus-mode.sh"]); root.focusOn = !root.focusOn } }
                            FeatureCard { width: parent.cw; icon: "\u{f018d}"; label: "Drop-down terminal"; hint: "Super + \""; desc: "a terminal slides from the top; the same key hides it"; action: true
                                          onToggled: { root.visible = false; Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/dropterm.sh"]) } }
                            FeatureCard { width: parent.cw; icon: "\u{f0f49}"; label: "Ink"; hint: "Super + D"; desc: "draw on the screen; Ctrl + S saves a screenshot with it"; action: true
                                          onToggled: { root.visible = false; Quickshell.execDetached(["qs", "ipc", "-p", root.qsDir, "call", "ink", "toggle"]) } }
                        }
                        Label { width: parent.width; wrapMode: Text.WordWrap; color: "#6e6e6e"; font.pixelSize: 10; font.weight: Font.Normal
                                text: "Also: hold Super + Alt and scroll to magnify (Super + Alt + Z resets). Picture-in-picture videos pop into the bottom-right corner and stay on every workspace." }
                        SetHeading { text: "Little helpers"; icon: "\u{f0674}" }
                        Grid {
                            width: parent.width; columns: 3; columnSpacing: 10; rowSpacing: 10
                            readonly property real cw: (width - 20) / 3
                            FeatureCard { width: parent.cw; icon: "\u{f005b}"; label: "Hot corner"; desc: "push the mouse into the top-left corner for the overview"; key: "hot_corner" }
                            FeatureCard { width: parent.cw; icon: "\u{f06d0}"; label: "Workspace previews"; desc: "hover a workspace in the bar to see its windows"; key: "ws_preview" }
                            FeatureCard { width: parent.cw; icon: "\u{f0b78}"; label: "Song card"; desc: "a small card drops under the bar when the song changes"; key: "island_peeks" }
                            FeatureCard { width: parent.cw; icon: "\u{f033e}"; label: "Pause when locking"; desc: "music stops when the screen locks"; key: "pause_on_lock" }
                            FeatureCard { width: parent.cw; icon: "\u{f0297}"; label: "Game workspace"; desc: "games open on workspace 5; you're brought back after"; key: "game_workspace" }
                            FeatureCard { width: parent.cw; icon: "\u{f1104}"; label: "Screensaver"; desc: "your wallpaper in glowing characters, halfway to the auto-lock"; key: "screensaver" }
                            FeatureCard { width: parent.cw; icon: "\u{f0169}"; label: "ASCII wallpaper"; desc: "your wallpaper drawn in glowing characters, slowly moving"; key: "ascii_wall" }
                            FeatureCard { width: parent.cw; icon: "\u{f0342}"; label: "Login hand-off"; desc: "after logging in, the ASCII dunes dissolve into your desktop"; key: "login_handoff" }
                            FeatureCard { width: parent.cw; icon: "\u{f0266}"; label: "Wallpaper tint"; desc: "the glass picks up a little of your wallpaper's colour"; key: "wall_tint" }
                        }
                        SetSection {
                            width: parent.width; title: "Wallpaper shuffle"; icon: "\u{f02e9}"
                            SetTiles {
                                desc: "a different monochrome wallpaper now and then"; columns: 4
                                current: Settings.get("wall_shuffle"); onPicked: v => Settings.set("wall_shuffle", v)
                                options: [[0, "Off", "keep mine", "\u{f051e}"], [15, "15 min", "", "\u{f051f}"], [60, "Hourly", "", "\u{f0150}"], [1440, "Daily", "", "\u{f00f6}"]]
                            }
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
                                SetTiles {
                                    label: "Middle-click scrolling"; columns: 2
                                    current: Settings.get("scroll_mode"); onPicked: v => Settings.set("scroll_mode", v)
                                    options: [["autoscroll", "Click and move", "like Windows", "\u{f0041}"], ["hold", "Hold and drag", "", "\u{f0d77}"]]
                                }
                                SetToggle { label: "Middle-click paste"; key: "middle_paste" }
                            }
                            SetSection {
                                width: (parent.width - 14) / 2; title: "Keyboard"; icon: "\u{f030c}"
                                SetTiles {
                                    label: "Layout"; columns: 3; current: Settings.get("kb_layout"); onPicked: v => Settings.set("kb_layout", v)
                                    options: [["tr", "Turkish Q", "", "TR"], ["us", "US", "", "US"], ["tr,us", "Both", "switch with Alt+Shift", "TR US"]]
                                }
                                SetSlider { label: "Key repeat speed"; key: "repeat_rate"; from: 10; to: 60; suffix: " /s" }
                                SetSlider { label: "Delay before repeat"; key: "repeat_delay"; from: 150; to: 800; step: 10; suffix: " ms" }
                                SetToggle { label: "Num Lock on at start"; key: "numlock" }
                                Column {   // try the repeat speed and delay right here
                                    width: parent.width; spacing: 6
                                    Label { text: "Try it"; color: "#e6e6e6"; font.pixelSize: 12 }
                                    TextField {
                                        id: kbTry
                                        width: parent.width; height: 36
                                        placeholderText: "Hold a key here to feel the repeat"; placeholderTextColor: Theme.muted
                                        color: Theme.fg; font.family: Theme.font; font.pixelSize: 12; leftPadding: 12
                                        background: Rectangle { radius: 10; color: "#0e0e0e"; border.width: 1; border.color: kbTry.activeFocus ? "#55ffffff" : "#262626" }
                                    }
                                }
                                SetButton { icon: "\u{f030c}"; text: "Show all shortcuts"; onClicked: root.exec(["qs", "ipc", "-p", root.qsDir, "call", "keys", "toggle"]) }
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

                    // ---------- Display (its own file) ----------
                    PgDisplay { visible: root.page === "display"; width: parent.width; host: root }

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
                        SetHeading { text: "Effects"; icon: "\u{f0ea2}" }
                        Row {
                            width: parent.width; spacing: 10
                            FeatureCard { width: (parent.width - 10) / 2; icon: "\u{f036c}"; label: "Clean mic"; desc: "AI noise removal on your headset mic: keyboard, fans and the room disappear"
                                          on: !!SysState.fx.mic; onToggled: SysState.fxToggle("mic") }
                            FeatureCard { width: (parent.width - 10) / 2; icon: "\u{f02cb}"; label: "Headset EQ"; desc: "tuned sound for the Fuxi-H3; pick a style below"
                                          on: !!SysState.fx.eq; onToggled: SysState.fxToggle("eq") }
                        }
                        Grid {   // EQ styles, each with its curve drawn
                            visible: !!SysState.fx.eq
                            width: parent.width; columns: 5; columnSpacing: 8
                            Repeater {
                                model: [["flat", "Flat", "as recorded", [0, 0, 0, 0, 0, 0]], ["music", "Music", "warm and full", [3, -1, 0, 1, -1.5, 1.5]],
                                        ["vocal", "Vocal", "clear voices", [-1.5, -2, 1, 2, -1, 0.5]], ["games", "Games", "footsteps forward", [-2, -1.5, 0, 2.5, 1, 1]],
                                        ["bass", "Bass", "deep low end", [5.5, -1, 0, 0.5, 0, 1]]]
                                Rectangle {
                                    id: eq
                                    required property var modelData
                                    readonly property bool on: SysState.fx.preset === modelData[0]
                                    width: (parent.width - 32) / 5; height: 110; radius: 14
                                    color: on ? "#ececec" : eqm.containsMouse ? "#1c1c1c" : "#131313"; border.width: 1; border.color: on ? "#ececec" : "#1d1d1d"
                                    Behavior on color { ColorAnimation { duration: 130 } }
                                    Canvas {
                                        id: curve
                                        x: 12; y: 12; width: parent.width - 24; height: 44
                                        property bool on: eq.on
                                        onOnChanged: requestPaint()
                                        onWidthChanged: requestPaint()
                                        Component.onCompleted: requestPaint()
                                        onPaint: {
                                            const c = getContext("2d"); c.reset()
                                            const g = eq.modelData[3], n = g.length, mid = height / 2
                                            c.strokeStyle = eq.on ? "rgba(0,0,0,0.15)" : "rgba(255,255,255,0.08)"; c.lineWidth = 1
                                            c.beginPath(); c.moveTo(0, mid); c.lineTo(width, mid); c.stroke()
                                            c.strokeStyle = eq.on ? "#0b0b0b" : "#d0d0d0"; c.lineWidth = 2; c.lineJoin = "round"
                                            c.beginPath()
                                            for (let i = 0; i < n; i++) {
                                                const x = i / (n - 1) * width, y = mid - g[i] / 6 * (height / 2 - 3)
                                                if (i === 0) c.moveTo(x, y); else { const px = (i - 1) / (n - 1) * width, py = mid - g[i - 1] / 6 * (height / 2 - 3); c.bezierCurveTo((px + x) / 2, py, (px + x) / 2, y, x, y) }
                                            }
                                            c.stroke()
                                        }
                                    }
                                    Column {
                                        x: 12; anchors.bottom: parent.bottom; anchors.bottomMargin: 10; spacing: 1
                                        Text { text: eq.modelData[1]; color: eq.on ? "#0b0b0b" : "#ececec"; font.family: Theme.font; font.pixelSize: 12; font.bold: true }
                                        Text { text: eq.modelData[2]; color: eq.on ? "#70000000" : "#6e6e6e"; font.family: Theme.font; font.pixelSize: 9 }
                                    }
                                    MouseArea { id: eqm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: SysState.fxPreset(eq.modelData[0]) }
                                }
                            }
                        }
                    }

                    // ---------- 5 Power & lock ----------
                    Column {
                        visible: root.page === "power"; width: parent.width; spacing: 18
                        SetHeading { text: "Power profile"; icon: "\u{f0241}" }
                        SetTiles {
                            columns: 3; current: SysState.profile; onPicked: v => SysState.setProfile(v)
                            options: [["power-saver", "Quiet", "cooler, slower, silent fans", "\u{f032a}"], ["balanced", "Balanced", "everyday", "\u{f05d1}"], ["performance", "Performance", "highest clocks, warmer and louder", "\u{f14de}"]]
                        }
                        SetSection {
                            width: parent.width
                            SetToggle { label: "Automatic game mode"; desc: "Performance and Do not disturb while a game is open"; key: "game_mode" }
                        }
                        SetHeading { text: "When you step away"; icon: "\u{f033e}" }
                        Rectangle {   // a timeline: screensaver, lock, screens off
                            id: tl
                            width: parent.width; height: 118; radius: 16; color: "#131313"; border.width: 1; border.color: "#1d1d1d"
                            readonly property int lockM: Settings.get("lock_minutes")
                            readonly property int offM: lockM + Settings.get("screen_off_after")
                            readonly property real span: offM * 1.12
                            readonly property real x0: 56
                            readonly property real w: width - 112
                            Rectangle { x: tl.x0; y: 54; width: tl.w; height: 2; color: "#2a2a2a" }
                            Rectangle { x: tl.x0; y: 54; width: tl.w * tl.offM / tl.span; height: 2; color: SysState.awake ? "#3a3a3a" : "#8a8a8a"; Behavior on width { NumberAnimation { duration: 150 } } }
                            Repeater {
                                model: [[0, "\u{f0583}", "You step away", ""], [Settings.get("screensaver") ? Math.max(1, Math.floor(tl.lockM / 2)) : -1, "\u{f1104}", "Screensaver", ""],
                                        [tl.lockM, "\u{f033e}", "Locks", ""], [tl.offM, "\u{f0379}", "Screens off", ""]].filter(x => x[0] >= 0)
                                Item {
                                    required property var modelData
                                    x: tl.x0 + tl.w * modelData[0] / tl.span - 17; y: 38; width: 34; height: 70
                                    Behavior on x { NumberAnimation { duration: 150 } }
                                    Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 34; height: 34; radius: 17; color: SysState.awake && modelData[0] > 0 ? "#1f1f1f" : "#ececec"
                                                Text { anchors.centerIn: parent; text: modelData[1]; color: SysState.awake && modelData[0] > 0 ? "#5a5a5a" : "#0b0b0b"; font.family: Theme.font; font.pixelSize: 15 } }
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; y: -22; text: modelData[0] === 0 ? "0 min" : modelData[0] + " min"; color: "#8a8a8a"; font.family: Theme.font; font.pixelSize: 9 }
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; y: 40; text: modelData[2]; color: "#cfcfcf"; font.family: Theme.font; font.pixelSize: 10 }
                                }
                            }
                            Text { visible: SysState.awake; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 12; text: "Keep awake is on: none of this happens"; color: "#9a9a9a"; font.family: Theme.font; font.pixelSize: 10 }
                        }
                        SetSection {
                            width: parent.width
                            SetSlider { label: "Lock after"; key: "lock_minutes"; from: 2; to: 60; suffix: " min" }
                            SetSlider { label: "Screens off after locking"; key: "screen_off_after"; from: 1; to: 30; suffix: " min" }
                            SetToggle { label: "Moving the mouse wakes the screens"; desc: "otherwise only a key press does"; key: "mouse_wakes" }
                            SetSwitch { label: "Keep awake"; desc: "pause auto-lock and screen-off until you turn this off. Fullscreen games and videos never lock anyway"; on: SysState.awake; onToggled: SysState.toggleAwake() }
                        }
                        Row {
                            spacing: 8
                            SetButton { icon: "\u{f033e}"; text: "Lock now"; onClicked: root.exec(["loginctl", "lock-session"]) }
                            SetButton { icon: "\u{f0425}"; text: "Power menu"; onClicked: root.exec(["qs", "ipc", "-p", root.qsDir, "call", "bar", "power"]) }
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
