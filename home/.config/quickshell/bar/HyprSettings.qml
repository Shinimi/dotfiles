// System settings (SUPER + comma): sidebar + pages. Changes wait for Apply (Ctrl+S); Discard throws them away. Made by Claude.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire

Scope {
    id: root
    required property var screen
    property bool visible: false
    property int page: 0
    readonly property string qsDir: Quickshell.env("HOME") + "/.config/quickshell/bar"
    readonly property var pages: [
        ["\u{f03d8}", "Appearance"], ["\u{f0d4a}", "Effects"], ["\u{f0e09}", "Theme"], ["\u{f0c8a}", "Glass & blur"],
        ["\u{f0e9e}", "Bar & notifications"], ["\u{f037d}", "Mouse & keyboard"], ["\u{f0379}", "Display"],
        ["\u{f057e}", "Sound"], ["\u{f0425}", "Power & lock"], ["\u{f0493}", "System"]
    ]
    readonly property var keyPage: ({
        accent: 0, border_spin: 0, border_angle: 0, gaps_in: 0, gaps_out: 0, border_size: 0, rounding: 0, layout: 0, smart_split: 0, snap: 0, resize_on_border: 0,
        glow: 1, glow_range: 1, glow_strength: 1, shadows: 1, shadow_range: 1, shadow_tint: 1, dim_inactive: 1, dim_strength: 1, animations: 1, anim_speed: 1, ws_anim: 1,
        folder_color: 2, icon_base: 2, cursor_theme: 2, cursor_size: 2, ui_font: 2, ui_font_size: 2,
        opacity_active: 3, opacity_inactive: 3, glass: 3, blur: 3, blur_size: 3, blur_passes: 3, vibrancy: 3, blur_brightness: 3, blur_noise: 3, blur_xray: 3, blur_popups: 3,
        clock_seconds: 4, clock_12h: 4, clock_date: 4, bar_weather: 4, bar_media: 4, notif_timeout: 4, notif_center: 4,
        sensitivity: 5, accel_flat: 5, natural_scroll: 5, scroll_factor: 5, follow_mouse: 5, middle_scroll: 5, middle_paste: 5, focus_on_activate: 5,
        repeat_rate: 5, repeat_delay: 5, kb_layout: 5, numlock: 5, hide_cursor_typing: 5, cursor_hide_after: 5, ws_back_forth: 5, swallow: 5,
        night_temp: 6, night_auto: 6, night_from: 6, night_to: 6, vibrance: 6, monitors: 6, lock_minutes: 8, screen_off_after: 8, mouse_wakes: 8, game_mode: 8
    })
    function pageDirty(i) { return Settings.changedKeys.some(k => keyPage[k] === i) }
    function toggle() { visible = !visible }
    function open(p) { page = p; visible = true }
    function exec(cmd) { visible = false; Quickshell.execDetached(cmd) }
    onVisibleChanged: if (visible) { PopupState.current = root; SysState.refresh(); about.running = true; mons.running = true }
    Connections { target: PopupState; function onCurrentChanged() { if (PopupState.current !== root) root.visible = false } }
    IpcHandler {
        target: "settings"
        function toggle(): void { root.toggle() }
        function open(page: int): void { root.open(page) }
        function set(key: string, value: string): void {
            Settings.setNow(key, value === "true" ? true : value === "false" ? false : isNaN(Number(value)) ? value : Number(value))
        }
        function apply(): void { Settings.apply() }
        function discard(): void { Settings.discard() }
    }

    // ---- data for the Display / System pages ----
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
                root.countdown = 15; revertTimer.restart(); root.page = 6
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
        implicitWidth: 1000; implicitHeight: 660

        Rectangle {
            anchors.fill: parent; radius: 22; color: Theme.panel; border.width: 1; border.color: Theme.glassLine
            focus: true
            Keys.onEscapePressed: root.visible = false
            Keys.onPressed: e => { if ((e.modifiers & Qt.ControlModifier) && e.key === Qt.Key_S) { Settings.apply(); e.accepted = true } }
            Keys.onUpPressed: root.page = Math.max(0, root.page - 1)
            Keys.onDownPressed: root.page = Math.min(root.pages.length - 1, root.page + 1)

            // ================= sidebar =================
            Rectangle {
                id: side
                x: 0; y: 0; width: 240; height: parent.height
                radius: 22; color: "#33000000"
                Rectangle { anchors.right: parent.right; width: 22; height: parent.height; color: "#33000000" } // square right edge
                Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: "#14c0caf5" }

                Column {
                    x: 16; y: 22; width: parent.width - 32; spacing: 4
                    Row {
                        spacing: 12; bottomPadding: 18; leftPadding: 4
                        Rectangle {
                            width: 42; height: 42; radius: 13
                            gradient: Gradient { orientation: Gradient.Horizontal
                                GradientStop { position: 0; color: Theme.blue } GradientStop { position: 1; color: Theme.purple } }
                            Label { anchors.centerIn: parent; text: "\u{f0493}"; color: Theme.bg; font.pixelSize: 20 }
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            Label { text: "Settings"; font.pixelSize: 16; font.weight: Font.Bold }
                            Label { text: "Hyprland · Tokyo Night"; color: Theme.muted; font.pixelSize: 10; font.weight: Font.Normal }
                        }
                    }
                    Repeater {
                        model: root.pages
                        Rectangle {
                            required property var modelData
                            required property int index
                            readonly property bool cur: root.page === index
                            width: parent.width; height: 40; radius: 12
                            color: cur ? Qt.rgba(0.48, 0.64, 0.97, 0.18) : (nm.containsMouse ? "#1ec0caf5" : "transparent")
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Rectangle { visible: cur; x: 0; anchors.verticalCenter: parent.verticalCenter; width: 3; height: 18; radius: 2; color: Theme.blue }
                            Row {
                                x: 14; anchors.verticalCenter: parent.verticalCenter; spacing: 12
                                Label { width: 18; text: modelData[0]; color: cur ? Theme.blue : Theme.muted; font.pixelSize: 15; anchors.verticalCenter: parent.verticalCenter }
                                Label { text: modelData[1]; color: cur ? Theme.fg : Theme.fgDim; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                            }
                            Rectangle { visible: root.pageDirty(index); anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                                        width: 7; height: 7; radius: 4; color: Theme.yellow }
                            MouseArea { id: nm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.page = index }
                        }
                    }
                }
                Column {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 16 }
                    spacing: 8
                    SetButton { width: parent.width; icon: "\u{f0450}"; text: "Reset to defaults"; accent: Theme.muted; onClicked: Settings.reset() }
                    Label { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: Settings.dirty ? "Ctrl+S applies" : "everything is applied"; color: Theme.muted; font.pixelSize: 10; font.weight: Font.Normal }
                }
            }

            // ================= apply bar =================
            Rectangle {
                id: applyBar
                anchors { left: side.right; right: parent.right; bottom: parent.bottom; margins: 14 }
                height: Settings.dirty ? 56 : 0; radius: 14; clip: true
                color: Qt.rgba(0.48, 0.64, 0.97, 0.12); border.width: Settings.dirty ? 1 : 0; border.color: Qt.rgba(0.48, 0.64, 0.97, 0.5)
                Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 10; spacing: 10
                    Rectangle { width: 9; height: 9; radius: 5; color: Theme.yellow }
                    Column {
                        Layout.fillWidth: true
                        Label { text: Settings.changedKeys.length + (Settings.changedKeys.length === 1 ? " change" : " changes") + " not applied yet"; font.pixelSize: 13 }
                        Label { text: "Apply to see them · Ctrl+S"; color: Theme.muted; font.pixelSize: 10; font.weight: Font.Normal }
                    }
                    SetButton { icon: "\u{f0156}"; text: "Discard"; accent: Theme.red; onClicked: { Settings.discard(); root.lastGoodMonitors = null } }
                    SetButton { icon: "\u{f012c}"; text: "Apply"; primary: true; onClicked: Settings.apply() }
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
                        Label { text: root.pages[root.page][1]; font.pixelSize: 22; font.weight: Font.Bold }
                        Label {
                            color: Theme.muted; font.pixelSize: 11; font.weight: Font.Normal
                            text: ["Colours, borders, gaps and window layout", "Glow, shadows, dimming and animations", "Icons, folders, cursor and fonts",
                                   "How see-through windows and panels are", "Clock, bar items and pop-ups",
                                   "Pointer, scrolling, typing and focus", "Resolution, refresh rate and colour",
                                   "Devices, clean mic and headset EQ (changes here are instant)", "Performance, auto-lock and screens off",
                                   "About this PC and maintenance"][root.page]
                        }
                    }

                    // ---------- 0 Appearance ----------
                    Column {
                        visible: root.page === 0; width: parent.width; spacing: 14
                        SetSection {
                            width: parent.width; title: "Accent"; icon: "\u{f0e09}"
                            Row {
                                spacing: 10
                                Repeater {
                                    model: [["tokyo", "Tokyo", ["#7aa2f7", "#bb9af7", "#7dcfff"]], ["storm", "Storm", ["#7aa2f7", "#7dcfff"]],
                                            ["sakura", "Sakura", ["#f7768e", "#bb9af7"]], ["matcha", "Matcha", ["#9ece6a", "#73daca"]],
                                            ["sunset", "Sunset", ["#ff9e64", "#e0af68", "#f7768e"]], ["mono", "Mono", ["#c0caf5", "#565f89"]]]
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
                        visible: root.page === 1; width: parent.width; spacing: 14
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
                        visible: root.page === 2; width: parent.width; spacing: 14
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
                                            color: cur ? Qt.rgba(0.48, 0.64, 0.97, 0.16) : (fcm.containsMouse ? "#1ec0caf5" : "transparent")
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
                                    options: [["capitaine-cursors", "Capitaine dark"], ["capitaine-cursors-light", "Capitaine light"], ["breeze_cursors", "Breeze"]]
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
                                            color: cur ? Qt.rgba(0.48, 0.64, 0.97, 0.16) : (fom.containsMouse ? "#1ec0caf5" : "#331a1b26")
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
                    }

                    // ---------- 1 Glass ----------
                    Row {
                        visible: root.page === 3; width: parent.width; spacing: 14
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
                        visible: root.page === 4; width: parent.width; spacing: 14
                        SetSection {
                            width: (parent.width - 14) / 2; title: "Bar"; icon: "\u{f0e9e}"
                            SetToggle { label: "Show seconds"; key: "clock_seconds" }
                            SetToggle { label: "12-hour clock"; desc: "3:45 PM instead of 15:45"; key: "clock_12h" }
                            SetToggle { label: "Show the date"; key: "clock_date" }
                            SetToggle { label: "Show the weather"; key: "bar_weather" }
                            SetToggle { label: "Show what's playing"; key: "bar_media" }
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
                        visible: root.page === 5; width: parent.width; spacing: 14
                        Row {
                            width: parent.width; spacing: 14
                            SetSection {
                                width: (parent.width - 14) / 2; title: "Mouse"; icon: "\u{f037d}"
                                SetSlider { label: "Mouse speed"; key: "sensitivity"; from: -1; to: 1; step: 0.05; decimals: 2 }
                                SetToggle { label: "Raw input (no acceleration)"; desc: "best for games and aiming"; key: "accel_flat" }
                                SetSlider { label: "Scroll speed"; key: "scroll_factor"; from: 0.2; to: 3; step: 0.1; decimals: 1; suffix: "×" }
                                SetToggle { label: "Natural scrolling"; desc: "content follows your finger, like a phone"; key: "natural_scroll" }
                                SetToggle { label: "Middle-click scrolling"; desc: "hold middle button + move"; key: "middle_scroll" }
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
                        visible: root.page === 6; width: parent.width; spacing: 14

                        Rectangle {   // "keep these settings?" after a screen change
                            visible: root.undoMonitors !== null
                            width: parent.width; height: 58; radius: 14
                            color: Qt.rgba(0.88, 0.69, 0.41, 0.14); border.width: 1; border.color: Theme.yellow
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
                                    color: sel ? Qt.rgba(0.48, 0.64, 0.97, 0.12) : (mcm.containsMouse ? "#1ec0caf5" : Theme.card)
                                    border.width: 1; border.color: sel ? Theme.blue : "#14c0caf5"
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
                        visible: root.page === 7; width: parent.width; spacing: 14
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
                        visible: root.page === 8; width: parent.width; spacing: 14
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
                        visible: root.page === 9; width: parent.width; spacing: 14
                        Rectangle {
                            width: parent.width; height: 120; radius: 16; color: Theme.card; border.width: 1; border.color: "#14c0caf5"
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
