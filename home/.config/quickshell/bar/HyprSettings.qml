// System settings (SUPER + comma): sidebar + pages. Changes wait for Apply (Ctrl+S); Discard throws them away. Made by Claude.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire

Scope {
    id: root
    required property var screen
    property bool visible: false
    property string page: "appearance"
    property string kbMode: "kocho"
    readonly property string qsDir: Quickshell.env("HOME") + "/.config/quickshell/bar"
    // sidebar: [id, icon, title, group, search words]
    readonly property var pages: [
        ["account", "\u{f0004}", "Account", "Personal", "user name picture avatar photo profile"],
        ["appearance", "\u{f03d8}", "Appearance", "Look & feel", "accent colour border gaps rounding layout tiling"],
        ["effects", "\u{f0d4a}", "Effects", "Look & feel", "glow shadow dim animation speed"],
        ["theme", "\u{f0e09}", "Theme", "Look & feel", "icons folder cursor font"],
        ["glass", "\u{f0c8a}", "Glass & blur", "Look & feel", "transparency opacity blur"],
        ["wallpaper", "\u{f02e9}", "Wallpaper", "Look & feel", "background picture"],
        ["bar", "\u{f0e9e}", "Bar & notifications", "Desktop", "clock seconds weather popup do not disturb"],
        ["shortcuts", "\u{f030c}", "Shortcuts", "Desktop", "keybinds keys hotkeys"],
        ["defaults", "\u{f03d6}", "Default apps", "Desktop", "browser file manager open with"],
        ["autostart", "\u{f0412}", "Autostart", "Desktop", "login startup apps"],
        ["display", "\u{f0379}", "Display", "Devices", "monitor resolution refresh hz colour night light vibrance"],
        ["sound", "\u{f057e}", "Sound", "Devices", "audio volume mic eq headset"],
        ["input", "\u{f037d}", "Mouse & keyboard", "Devices", "pointer scroll layout typing repeat"],
        ["network", "\u{f0200}", "Network", "Devices", "internet ethernet wifi ip"],
        ["bluetooth", "\u{f00af}", "Bluetooth", "Devices", "headphones devices pair"],
        ["storage", "\u{f02ca}", "Storage", "Devices", "disk ssd space health"],
        ["power", "\u{f0425}", "Power & lock", "System", "sleep lock screen off game mode performance"],
        ["datetime", "\u{f0954}", "Date & time", "System", "clock timezone ntp weather location"],
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
        glow: "effects", glow_range: "effects", glow_strength: "effects", shadows: "effects", shadow_range: "effects", shadow_tint: "effects", dim_inactive: "effects", dim_strength: "effects", animations: "effects", anim_speed: "effects", ws_anim: "effects",
        folder_color: "theme", icon_base: "theme", cursor_theme: "theme", cursor_size: "theme", ui_font: "theme", ui_font_size: "theme", fetch_logo: "theme", fetch_source: "theme",
        opacity_active: "glass", opacity_inactive: "glass", glass: "glass", blur: "glass", blur_size: "glass", blur_passes: "glass", vibrancy: "glass", blur_brightness: "glass", blur_noise: "glass", blur_xray: "glass", blur_popups: "glass",
        clock_seconds: "bar", clock_12h: "bar", clock_date: "bar", bar_weather: "bar", bar_media: "bar", notif_timeout: "bar", notif_center: "bar", desktop_clock: "bar", desktop_clock_pos: "bar",
        sensitivity: "input", accel_flat: "input", natural_scroll: "input", scroll_factor: "input", follow_mouse: "input", middle_scroll: "input", scroll_mode: "input", middle_paste: "input", focus_on_activate: "input",
        repeat_rate: "input", repeat_delay: "input", kb_layout: "input", numlock: "input", hide_cursor_typing: "input", cursor_hide_after: "input", ws_back_forth: "input", swallow: "input",
        night_temp: "display", night_auto: "display", night_from: "display", night_to: "display", vibrance: "display", monitors: "display", lock_minutes: "power", screen_off_after: "power", mouse_wakes: "power", game_mode: "power"
,
        user_name: "account", avatar: "account", cc_logo: "account", wall_main: "wallpaper", wall_side: "wallpaper",
        default_apps: "defaults", autostart: "autostart", weather_place: "datetime", weather_label: "datetime"
    })
    function pageDirty(id) { return Settings.changedKeys.some(k => keyPage[k] === id) }
    function toggle() { visible = !visible }
    function open(p) { page = p; visible = true }
    function exec(cmd) { visible = false; Quickshell.execDetached(cmd) }
    onVisibleChanged: if (visible) { PopupState.current = root; SysState.refresh(); about.running = true; mons.running = true }
    Connections { target: PopupState; function onCurrentChanged() { if (PopupState.current !== root) root.visible = false } }
    IpcHandler {
        target: "settings"
        function toggle(): void { root.toggle() }
        function open(page: string): void { root.open(page) }
        function set(key: string, value: string): void {
            Settings.setNow(key, value === "true" ? true : value === "false" ? false : isNaN(Number(value)) ? value : Number(value))
        }
        function apply(): void { Settings.apply() }
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
                  "echo \"disk=$(df -h --output=used,size / | tail -1 | awk '{print $1\" / \"$2}')\""]
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
            anchors.fill: parent; radius: 22; color: Theme.panel; border.width: 1; border.color: Theme.glassLine
            focus: true
            Keys.onEscapePressed: root.visible = false
            Keys.onPressed: e => { if ((e.modifiers & Qt.ControlModifier) && e.key === Qt.Key_S) { Settings.apply(); e.accepted = true } }
            Keys.onUpPressed: { const i = root.shownPages.findIndex(p => p[0] === root.page); if (i > 0) root.page = root.shownPages[i - 1][0] }
            Keys.onDownPressed: { const i = root.shownPages.findIndex(p => p[0] === root.page); if (i < root.shownPages.length - 1) root.page = root.shownPages[i + 1][0] }

            // ================= sidebar =================
            Rectangle {
                id: side
                x: 0; y: 0; width: 260; height: parent.height
                radius: 22; color: "#33000000"
                Rectangle { anchors.right: parent.right; width: 22; height: parent.height; color: "#33000000" } // square right edge
                Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: "#14efeaf8" }

                Column {
                    id: sideTop
                    x: 16; y: 20; width: parent.width - 32; spacing: 14
                    Rectangle {   // you
                        width: parent.width; height: 62; radius: 16
                        color: root.page === "account" ? Qt.rgba(0.64, 0.54, 0.91, 0.18) : (um.containsMouse ? "#1eefeaf8" : "#22000000")
                        Row {
                            x: 10; anchors.verticalCenter: parent.verticalCenter; spacing: 12
                            Avatar { size: 42; radius: 21; pick: Settings.get("avatar") }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                Label { text: Settings.get("user_name") || Quickshell.env("USER"); font.pixelSize: 15; font.weight: Font.Bold }
                                Label { text: "Account · picture & name"; color: Theme.muted; font.pixelSize: 10; font.weight: Font.Normal }
                            }
                        }
                        MouseArea { id: um; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.page = "account" }
                    }
                    TextField {
                        id: find
                        width: parent.width; height: 36
                        placeholderText: "Search settings…"; placeholderTextColor: Theme.muted
                        onTextEdited: { root.search = text; if (root.shownPages.length) root.page = root.shownPages[0][0] }
                        Keys.onEscapePressed: { text = ""; root.search = "" }
                        color: Theme.fg; font.family: Theme.font; font.pixelSize: 12; leftPadding: 34
                        background: Rectangle { radius: 11; color: "#3313121c"; border.width: find.activeFocus ? 2 : 1; border.color: find.activeFocus ? Theme.blue : "#1eefeaf8" }
                        Label { x: 12; anchors.verticalCenter: parent.verticalCenter; text: "\u{f0349}"; color: Theme.muted; font.pixelSize: 14 }
                    }
                }
                ListView {
                    id: nav
                    anchors { top: sideTop.bottom; topMargin: 8; left: parent.left; right: parent.right; bottom: sideBottom.top; leftMargin: 16; rightMargin: 16; bottomMargin: 8 }
                    clip: true; spacing: 2; boundsBehavior: Flickable.StopAtBounds
                    model: root.shownPages.filter(p => p[0] !== "account")
                    section.property: "modelData.3"
                    section.criteria: ViewSection.FullString
                    section.delegate: Item {
                        required property string section
                        width: nav.width; height: 30
                        Label { x: 6; anchors.bottom: parent.bottom; anchors.bottomMargin: 6; text: parent.section.toUpperCase(); color: Theme.muted; font.pixelSize: 9; font.letterSpacing: 1.2 }
                    }
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool cur: root.page === modelData[0]
                        width: nav.width; height: 36; radius: 11
                        color: cur ? Qt.rgba(0.64, 0.54, 0.91, 0.18) : (nm.containsMouse ? "#1eefeaf8" : "transparent")
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Rectangle { visible: cur; x: 0; anchors.verticalCenter: parent.verticalCenter; width: 3; height: 16; radius: 2; color: Theme.blue }
                        Row {
                            x: 14; anchors.verticalCenter: parent.verticalCenter; spacing: 12
                            Label { width: 18; text: modelData[1]; color: cur ? Theme.blue : Theme.muted; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                            Label { text: modelData[2]; color: cur ? Theme.fg : Theme.fgDim; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                        }
                        Rectangle { visible: root.pageDirty(modelData[0]); anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                                    width: 7; height: 7; radius: 4; color: Theme.yellow }
                        MouseArea { id: nm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.page = modelData[0] }
                    }
                    Label { anchors.centerIn: parent; visible: nav.count === 0; text: "Nothing found"; color: Theme.muted; font.pixelSize: 11 }
                }
                Column {
                    id: sideBottom
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 16 }
                    SetButton { width: parent.width; icon: "\u{f0450}"; text: "Reset to defaults"; accent: Theme.muted; onClicked: Settings.reset() }
                }
            }

            // ================= apply bar (always there) =================
            Rectangle {
                id: applyBar
                anchors { left: side.right; right: parent.right; bottom: parent.bottom; margins: 14 }
                height: 58; radius: 15
                color: Settings.dirty ? Qt.rgba(0.64, 0.54, 0.91, 0.12) : "#22000000"
                border.width: 1; border.color: Settings.dirty ? Qt.rgba(0.64, 0.54, 0.91, 0.5) : "#14efeaf8"
                Behavior on color { ColorAnimation { duration: 160 } }
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 10; spacing: 10
                    Rectangle { width: 9; height: 9; radius: 5; color: Settings.dirty ? Theme.yellow : Theme.green }
                    Column {
                        Layout.fillWidth: true
                        Label { text: Settings.dirty ? Settings.changedKeys.length + (Settings.changedKeys.length === 1 ? " change" : " changes") + " waiting" : "Everything is applied"; font.pixelSize: 13 }
                        Label { text: Settings.dirty ? "Press Apply (or Ctrl+S) to use them · Discard to undo" : "Change anything, then press Apply"; color: Theme.muted; font.pixelSize: 10; font.weight: Font.Normal }
                    }
                    SetButton { visible: Settings.dirty; icon: "\u{f0156}"; text: "Discard"; accent: Theme.red; onClicked: { Settings.discard(); root.lastGoodMonitors = null } }
                    SetButton {
                        icon: "\u{f012c}"; text: "Apply"; primary: Settings.dirty; opacity: Settings.dirty ? 1 : 0.45
                        onClicked: Settings.apply()
                    }
                }
            }

            // ================= page =================
            Flickable {
                id: flick
                anchors { left: side.right; right: parent.right; top: parent.top; bottom: applyBar.top; margins: 24; bottomMargin: 10 }
                contentHeight: pageCol.implicitHeight; clip: true
                boundsBehavior: Flickable.StopAtBounds
                Connections { target: root; function onPageChanged() { flick.contentY = 0; fadeIn.restart() } }
                NumberAnimation { id: fadeIn; target: pageCol; property: "opacity"; from: 0.2; to: 1; duration: 180 }

                Column {
                    id: pageCol
                    width: flick.width; spacing: 14

                    Column {
                        spacing: 2; bottomPadding: 4
                        Label { text: root.pageInfo[2]; font.pixelSize: 22; font.weight: Font.Bold }
                        Label {
                            color: Theme.muted; font.pixelSize: 11; font.weight: Font.Normal
                            text: ({ account: "Your picture and name", appearance: "Colours, borders, gaps and window layout",
                                     effects: "Glow, shadows, dimming and animations", theme: "Icons, folders, cursor and fonts",
                                     glass: "How see-through windows and panels are", wallpaper: "Pick a picture for each screen",
                                     bar: "Clock, bar items and pop-ups", shortcuts: "Every keyboard shortcut",
                                     defaults: "Which app opens links, folders, pictures and more", autostart: "Apps that open when you log in",
                                     display: "Resolution, refresh rate and colour", sound: "Devices, clean mic and headset EQ (changes here are instant)",
                                     input: "Pointer, scrolling, typing and focus", network: "Your connection", bluetooth: "Wireless devices",
                                     storage: "Drives, health and free space", power: "Performance, auto-lock and screens off",
                                     datetime: "Clock, time sync and weather location", about: "This PC, updates and maintenance" })[root.page] || ""
                        }
                    }

                    PgAccount { visible: root.page === "account"; width: parent.width }
                    PgWallpaper { visible: root.page === "wallpaper"; width: parent.width }
                    PgShortcuts { visible: root.page === "shortcuts"; width: parent.width }
                    PgDefaults { visible: root.page === "defaults"; width: parent.width }
                    PgAutostart { visible: root.page === "autostart"; width: parent.width }
                    PgNetwork { visible: root.page === "network"; width: parent.width }
                    PgBluetooth { visible: root.page === "bluetooth"; width: parent.width }
                    PgStorage { visible: root.page === "storage"; width: parent.width }
                    PgDateTime { visible: root.page === "datetime"; width: parent.width }

                    // ---------- 0 Appearance ----------
                    Column {
                        visible: root.page === "appearance"; width: parent.width; spacing: 14
                        SetSection {
                            width: parent.width; title: "Accent"; icon: "\u{f0e09}"
                            Row {
                                spacing: 10
                                Repeater {
                                    model: [["tokyo", "Kochō", ["#a28ae8", "#e39ec0", "#7fc4e3"]], ["storm", "Wisteria", ["#a28ae8", "#7fc4e3"]],
                                            ["sakura", "Sakura", ["#ec6f8f", "#e39ec0"]], ["matcha", "Matcha", ["#8fd6b8", "#6fb8d6"]],
                                            ["sunset", "Sunset", ["#f2ad94", "#eec48e", "#ec6f8f"]], ["mono", "Mono", ["#efeaf8", "#807a9c"]]]
                                    Column {
                                        id: sw
                                        required property var modelData
                                        readonly property bool cur: Settings.get("accent") === modelData[0]
                                        spacing: 6
                                        Rectangle {
                                            width: 76; height: 50; radius: 13
                                            border.width: sw.cur ? 2 : 0; border.color: Theme.fg
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
                                SetButton { icon: "\u{f02e9}"; text: "Wallpaper"; onClicked: root.exec(["qs", "ipc", "-p", root.qsDir, "call", "wallpaper", "toggle"]) }
                            }
                        }
                    }

                    // ---------- Effects ----------
                    Column {
                        visible: root.page === "effects"; width: parent.width; spacing: 14
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
                                options: [["Papirus-Dark", "Papirus"], ["breeze-dark", "Breeze"]]
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
                                            color: cur ? Qt.rgba(0.64, 0.54, 0.91, 0.16) : (fcm.containsMouse ? "#1eefeaf8" : "transparent")
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
                                    options: [["Kocho-cursors", "Kochō"], ["capitaine-cursors", "Capitaine dark"], ["capitaine-cursors-light", "Capitaine light"], ["breeze_cursors", "Breeze"]]
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
                                            width: parent.width; height: 34; radius: 10
                                            color: cur ? Qt.rgba(0.64, 0.54, 0.91, 0.16) : (fom.containsMouse ? "#1eefeaf8" : "#3313121c")
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
                            width: parent.width; title: "Keyboard lighting"; icon: "\u{f030c}"
                            SetChoice {
                                label: "AULA F87 Pro colours (instant)"; current: root.kbMode
                                options: [["kocho", "Kochō gradient"], ["violet", "Wisteria"], ["pink", "Haori pink"], ["off", "Off"]]
                                onPicked: v => { root.kbMode = v; Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/kb-colors.sh", v]) }
                            }
                        }
                        SetSection {
                            width: parent.width; title: "Terminal art (fastfetch)"; icon: "\u{f018d}"
                            SetChoice {
                                label: "Shown next to your system info"; current: Settings.get("fetch_logo"); onPicked: v => Settings.set("fetch_logo", v)
                                options: [["kamon", "Kochō crest"], ["butterfly", "Butterfly"], ["portrait", "Shinobu portrait"], ["picture", "My picture"], ["ascii", "Text art"], ["distro", "CachyOS logo"]]
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
                        visible: root.page === "glass"; width: parent.width; spacing: 14
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
                            SetToggle { label: "See wallpaper through windows (x-ray)"; key: "blur_xray" }
                            SetToggle { label: "Blur menus and pop-ups"; key: "blur_popups" }
                        }
                    }

                    // ---------- Bar & notifications ----------
                    Row {
                        visible: root.page === "bar"; width: parent.width; spacing: 14
                        SetSection {
                            width: (parent.width - 14) / 2; title: "Bar"; icon: "\u{f0e9e}"
                            SetToggle { label: "Show seconds"; key: "clock_seconds" }
                            SetToggle { label: "12-hour clock"; desc: "3:45 PM instead of 15:45"; key: "clock_12h" }
                            SetToggle { label: "Show the date"; key: "clock_date" }
                            SetToggle { label: "Show the weather"; key: "bar_weather" }
                            SetToggle { label: "Show what's playing"; key: "bar_media" }
                            SetToggle { label: "Desktop clock"; desc: "big clock, weather and music on the wallpaper"; key: "desktop_clock" }
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
                            SetSwitch { label: "Do not disturb"; desc: "hide pop-ups (instant)"; on: Notifs.dnd; accent: Theme.purple; onToggled: Notifs.dnd = !Notifs.dnd }
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

                        Rectangle {   // "keep these settings?" after a screen change
                            visible: root.undoMonitors !== null
                            width: parent.width; height: 58; radius: 14
                            color: Qt.rgba(0.93, 0.77, 0.56, 0.14); border.width: 1; border.color: Theme.yellow
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 12; spacing: 10
                                Label { text: "\u{f0026}"; color: Theme.yellow; font.pixelSize: 18 }
                                Column {
                                    Layout.fillWidth: true
                                    Label { text: "Keep these display settings?"; font.pixelSize: 13 }
                                    Label { text: "Going back in " + root.countdown + " s if you don't answer"; color: Theme.muted; font.pixelSize: 11; font.weight: Font.Normal }
                                }
                                SetButton { text: "Revert"; icon: "\u{f0450}"; onClicked: root.revertMonitors() }
                                SetButton { text: "Keep"; icon: "\u{f012c}"; primary: true; accent: Theme.green; onClicked: root.keepMonitors() }
                            }
                        }

                        Row {   // pick a screen
                            width: parent.width; spacing: 14
                            Repeater {
                                model: root.monitors
                                Rectangle {
                                    id: monCard
                                    required property var modelData
                                    readonly property bool sel: root.selMon === modelData.name
                                    width: (parent.width - 14) / 2; height: 112; radius: 14
                                    color: sel ? Qt.rgba(0.64, 0.54, 0.91, 0.12) : (mcm.containsMouse ? "#1eefeaf8" : Theme.card)
                                    border.width: 1; border.color: sel ? Theme.blue : "#14efeaf8"
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
                                label: "Adaptive sync (VRR)"; desc: "smoother games below max Hz — it made these screens flicker before"; accent: Theme.yellow
                                on: !!root.selCfg.vrr; onToggled: root.monChange("vrr", root.selCfg.vrr ? 0 : 1)
                            }
                        }

                        Row {
                            width: parent.width; spacing: 14
                            SetSection {
                                width: (parent.width - 14) / 2; title: "Vibrance"; icon: "\u{f0e09}"
                                SetSlider { label: "Colour vibrance (all screens)"; key: "vibrance"; from: 70; to: 150; step: 5; suffix: "%" }
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
                                options: [["flat", "Flat"], ["music", "Music"], ["games", "Games · footsteps"], ["bass", "Bass boost"]]
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
                            width: parent.width; height: 120; radius: 16; color: Theme.card; border.width: 1; border.color: "#14efeaf8"
                            Row {
                                x: 22; anchors.verticalCenter: parent.verticalCenter; spacing: 20
                                Label { text: "\u{f08c7}"; font.pixelSize: 64; color: Theme.blue; anchors.verticalCenter: parent.verticalCenter }
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter; spacing: 4
                                    Label { text: "CachyOS"; font.pixelSize: 20; font.weight: Font.Bold }
                                    Label { text: (root.info.host || "") + " · Hyprland " + (root.info.hypr || ""); color: Theme.blue; font.pixelSize: 12 }
                                    Label { text: "Linux " + (root.info.kernel || "") + " · up " + Stats.d.uptime; color: Theme.muted; font.pixelSize: 11 }
                                }
                            }
                        }
                        GridLayout {
                            width: parent.width; columns: 2; columnSpacing: 10; rowSpacing: 10
                            Repeater {
                                model: [["\u{f0ee0}", "Processor", root.info.cpu, Theme.cyan], ["\u{f08ae}", "Graphics", root.info.gpu, Theme.purple],
                                        ["\u{f035b}", "Memory", root.info.ram, Theme.yellow], ["\u{f02ca}", "Disk", root.info.disk, Theme.green],
                                        ["\u{f03d6}", "Packages", root.info.pkgs, Theme.blue], ["\u{f0aaa}", "Updates", Updates.total > 0 ? Updates.total + " waiting" : "up to date", Updates.total > 0 ? Theme.yellow : Theme.green]]
                                Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true; Layout.preferredWidth: 1; height: 58; radius: 12; color: Theme.card
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
                            width: parent.width; title: "Maintenance"; icon: "\u{f0ad}"
                            Flow {
                                width: parent.width; spacing: 8
                                SetButton { icon: "\u{f06b0}"; text: "Update system"; primary: true
                                    onClicked: root.exec(["kitty", "--class", "updater", "-e", "bash", "-c", "yay -Syu; echo; read -n1 -rsp 'Done – press any key to close'"]) }
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
