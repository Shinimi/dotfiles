// Launcher (SUPER + Space): a big search field, category chips, the results on the left and a preview of the
// selected one on the right; with an empty search your most-used apps sit on top as tiles.
//   = also converts: = 5 usd to try · = 72 f to c · = 10 km to mi · = 15% of 240 · = time tokyo Type to search apps and quick actions (fix audio, lock, focus mode…).
//   ? query → web     : name → emoji (Enter copies)     / name → files     = 12*7 → math     > cmd → run
// ↑↓ move · Tab / Shift+Tab category · Enter open · Esc or click outside closes. Made by Claude.
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "."   // our own Label wins over the Qt Controls one

Scope {
    id: root
    required property var screen
    property bool visible: false
    property string query: ""
    property int sel: 0
    property string cat: "all"
    property var usage: ({})                    // item key -> launch count (most used first)
    readonly property string usageFile: Quickshell.env("HOME") + "/.local/state/launcher-usage.json"
    readonly property string scripts: Quickshell.env("HOME") + "/.config/hypr/scripts"
    readonly property string qsDir: Quickshell.env("HOME") + "/.config/quickshell/bar"
    readonly property string q: query.trim()
    readonly property string mode: q.startsWith("=") ? "calc" : q.startsWith(">") ? "cmd" : q.startsWith("?") ? "web"
                                  : q.startsWith(":") ? "emoji" : q.startsWith("/") ? "files" : "apps"
    readonly property string arg: mode === "apps" ? q : q.slice(1).trim()

    // ---------- categories ----------
    readonly property var cats: [["all", "All"], ["actions", "Actions"], ["develop", "Code"], ["internet", "Internet"], ["media", "Media"],
                                 ["games", "Games"], ["graphics", "Graphics"], ["office", "Office"], ["system", "System"], ["other", "Other"]]
    function catOf(e) {
        const c = (e.categories || []).join(";")
        if (/Game/.test(c)) return "games"
        if (/Development|IDE|TextEditor/.test(c)) return "develop"
        if (/AudioVideo|Audio|Video|Player|Music|TV/.test(c)) return "media"
        if (/Network|WebBrowser|Chat|Email|InstantMessaging|FileTransfer/.test(c)) return "internet"
        if (/Graphics|Photography/.test(c)) return "graphics"
        if (/Office/.test(c)) return "office"
        if (/System|Settings|Utility|Monitor|TerminalEmulator|FileManager|Accessories/.test(c)) return "system"
        return "other"
    }

    // ---------- sources ----------
    readonly property var apps: DesktopEntries.applications.values.filter(a => !a.noDisplay && a.name)
    function ipc(target, fn) { return ["qs", "ipc", "-p", qsDir, "call", target, fn || "toggle"] }
    readonly property var actions: [   // [name, keywords, glyph, command]
        ["Fix audio", "sound broken restart pipewire spotify discord no sound", "\u{f057e}", [scripts + "/fix-audio.sh"]],
        ["Lock screen", "lock away", "\u{f033e}", ["qs", "ipc", "-p", Quickshell.env("HOME") + "/.config/quickshell/bar", "call", "curtain", "lock"]],
        ["Focus mode", "zen no gaps distraction", "\u{f02f1}", [scripts + "/focus-mode.sh"]],
        ["Drop-down terminal", "terminal kitty console", "\u{f018d}", [scripts + "/dropterm.sh"]],
        ["Draw on screen", "ink annotate pen marker", "\u{f03eb}", ipc("ink")],
        ["Home screen", "dashboard clock calendar", "\u{f02dc}", ipc("home")],
        ["Quick notes", "notes todo list remember write", "\u{f082e}", ipc("notes")],
        ["Control center", "control hub quick settings volume", "\u{f0493}", ipc("panel")],
        ["Screenshot region", "snip capture print", "\u{f0100}", ["sh", "-c", "sleep 0.3; " + scripts + "/screenshot.sh region"]],
        ["Color picker", "colour pick hex eyedropper", "\u{f0d52}", ["sh", "-c", "sleep 0.3; hyprpicker -a"]],
        ["Clipboard history", "paste copy", "\u{f014c}", ipc("clipboard")],
        ["Wallpaper", "background picture carousel", "\u{f02e9}", ipc("wallpaper")],
        ["Workspace overview", "windows expose", "\u{f0d61}", ipc("overview")],
        ["Settings", "preferences config", "\u{f0493}", ipc("settings")],
        ["Night light", "blue light warm", "\u{f0594}", [scripts + "/nightlight.sh"]],
        ["Fix desktop", "reload restart bar broken", "\u{f0450}", [Quickshell.env("HOME") + "/.local/bin/hypr-doctor.sh", "--fix"]],
        ["Update system", "upgrade pacman packages", "\u{f06b0}", ["kitty", "--class", "updater", "-e", "bash", "-c", Quickshell.env("HOME") + "/.local/bin/safe-update.sh"]],
        ["Power menu", "shutdown reboot restart logout suspend sleep", "\u{f0425}", ["qs", "ipc", "-p", qsDir, "call", "bar", "power"]]
    ]
    property var emojis: []
    Process { id: loadEmoji; command: ["cat", root.qsDir + "/emoji.json"]
              stdout: StdioCollector { onStreamFinished: { try { root.emojis = JSON.parse(this.text) } catch (e) {} } } }
    property var files: []
    Process {
        id: findFiles
        command: ["fd", "-i", "-H", "--max-results", "30", "--max-depth", "7",
                  "-E", ".cache", "-E", ".local/share/Steam", "-E", "Games", "-E", ".var", "-E", ".wine", "-E", "node_modules",
                  "-E", ".git", "-E", ".mozilla", "-E", ".config/*/Cache*", "--", root.arg, Quickshell.env("HOME")]
        stdout: StdioCollector { onStreamFinished: root.files = this.text.split("\n").filter(x => x) }
    }
    Timer { id: fileDelay; interval: 180; onTriggered: if (root.mode === "files" && root.arg.length >= 2) findFiles.running = true }

    function score(name, extra, q) {
        const n = name.toLowerCase(), k = (extra || "").toLowerCase()
        if (n === q) return 1000
        if (n.startsWith(q)) return 800
        if (n.split(/[\s\-_.]/).some(w => w.startsWith(q))) return 600
        if (n.indexOf(q) >= 0) return 400
        if (k.split(" ").some(w => w.startsWith(q))) return 300
        if (k.indexOf(q) >= 0) return 200
        let i = 0; for (const c of n) if (c === q[i]) i++          // fuzzy: letters in order
        return i === q.length ? 100 : -1
    }
    // anything plain JavaScript can't do (units, currencies, percentages) goes to qalc
    readonly property string qalcExpr: {
        if (mode !== "calc" || calc !== null || !arg) return ""
        return arg.replace(/(\d)\s*°?f\s+(to|in)\s+°?c\b/i, "$1 °F to °C").replace(/(\d)\s*°?c\s+(to|in)\s+°?f\b/i, "$1 °C to °F")
                  .replace(/(\d+(\.\d+)?)\s*%\s+of\s+/i, "$1% * ").replace(/\s+in\s+([a-z€$£₺]+)\s*$/i, " to $1")
    }
    property string qalcOut: ""
    onQalcExprChanged: { qalcOut = ""; if (qalcExpr && !timeZone) qalcDelay.restart() }
    Timer { id: qalcDelay; interval: 160; onTriggered: if (root.qalcExpr) qalcProc.running = true }
    Process {
        id: qalcProc
        command: ["qalc", "-t", root.qalcExpr]
        stdout: StdioCollector { onStreamFinished: {
            const t = this.text.trim().split("\n").pop()
            root.qalcOut = t && !/error|warning|rem\(/i.test(t) && t !== root.qalcExpr ? t : ""
        } }
    }
    // = time tokyo  /  = time in new york  → that city's clock
    property var zones: []
    Process { id: zoneList; command: ["timedatectl", "list-timezones"]
              stdout: StdioCollector { onStreamFinished: root.zones = this.text.split("\n").filter(z => z.indexOf("/") > 0) } }
    readonly property string timeZone: {
        const m = mode === "calc" ? arg.match(/^time\s+(in\s+)?(.+)$/i) : null
        if (!m) return ""
        const want = m[2].trim().toLowerCase().replace(/\s+/g, "_")
        return zones.find(z => z.split("/").pop().toLowerCase() === want) || zones.find(z => z.toLowerCase().indexOf(want) >= 0) || ""
    }
    property string zoneOut: ""
    onTimeZoneChanged: { zoneOut = ""; if (timeZone) zoneProc.running = true }
    Process { id: zoneProc; command: ["sh", "-c", "TZ=\"$1\" date '+%H:%M · %a %d %b'", "sh", root.timeZone]
              stdout: StdioCollector { onStreamFinished: root.zoneOut = this.text.trim() } }

    readonly property var calc: {
        if (mode !== "calc") return null
        const e = arg.replace(/\^/g, "**").replace(/x/g, "*")
        if (!/^[\d\s+\-*/().%*]+$/.test(e) || !e.trim()) return null
        try { const v = Function('"use strict";return (' + e + ')')(); return isFinite(v) ? String(Math.round(v * 1e10) / 1e10) : null } catch (x) { return null }
    }

    // every app / action with its category, built once per app list change
    readonly property var items: apps.map(x => ({ kind: "app", key: x.id, name: x.name, sub: x.genericName || "", icon: x.icon, cat: catOf(x),
                                                  extra: (x.genericName || "") + " " + (x.keywords || []).join(" "), entry: x }))
        .concat(actions.map(x => ({ kind: "glyph", key: "action:" + x[0], name: x[0], sub: "Action", glyph: x[2], cat: "actions", extra: x[1], cmd: x[3] })))
    readonly property var frequent: {
        const a = items.filter(x => x.kind === "app")
        const used = a.filter(x => usage[x.key]).sort((m, n) => usage[n.key] - usage[m.key])
        return used.concat(a.filter(x => !usage[x.key])).slice(0, 8)
    }
    readonly property bool showTiles: mode === "apps" && q === "" && cat === "all"
    readonly property var cur: shown[sel] || null
    function countIn(c) { return c === "all" ? items.length : items.filter(x => x.cat === c).length }

    // ---------- one list for everything: {kind, key, name, sub, cat, icon, glyph, emoji, run} ----------
    readonly property var shown: {
        const a = arg.toLowerCase()
        if (mode === "calc") {
            if (timeZone) return zoneOut ? [{ kind: "glyph", glyph: "\u{f0954}", name: zoneOut, sub: timeZone.replace(/_/g, " "), cat: "time",
                                              run: () => Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | wl-copy", "sh", zoneOut]) }] : []
            const res = calc !== null ? calc : qalcOut
            return res ? [{ kind: "glyph", glyph: "\u{f00ec}", name: "= " + res, sub: "Enter copies the result", cat: "math",
                            run: () => Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | wl-copy", "sh", res]) }] : []
        }
        if (mode === "cmd") return arg ? [{ kind: "glyph", glyph: "\u{f018d}", name: arg, sub: "Run as a command", cat: "shell", run: () => Quickshell.execDetached(["sh", "-c", arg]) }] : []
        if (mode === "web") return arg ? [{ kind: "glyph", glyph: "\u{f059f}", name: arg, sub: "Search the web", cat: "web",
                                            run: () => Quickshell.execDetached(["xdg-open", "https://duckduckgo.com/?q=" + encodeURIComponent(arg)]) }] : []
        if (mode === "emoji") {
            if (!a) return []
            return emojis.filter(e => e.n.indexOf(a) >= 0).slice(0, 40).map(e => ({ kind: "emoji", emoji: e.e, name: e.n, sub: "Enter copies", cat: "emoji",
                run: () => Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | wl-copy", "sh", e.e]) }))
        }
        if (mode === "files") return files.map(f => ({ kind: "file", name: f.replace(/\/$/, "").split("/").pop(), cat: f.endsWith("/") ? "folder" : "file",
            sub: f.replace(Quickshell.env("HOME"), "~").replace(/\/[^/]*\/?$/, ""), icon: f.endsWith("/") ? "folder" : "text-x-generic",
            run: () => Quickshell.execDetached(["xdg-open", f]) }))
        const pool = cat === "all" ? (a ? items : items.filter(x => x.kind === "app")) : items.filter(x => x.cat === cat)
        const list = a ? pool.map(x => ({ x: x, s: score(x.name, x.extra, a) })).filter(o => o.s >= 0) : pool.map(x => ({ x: x, s: 0 }))
        list.sort((m, n) => (n.s + (usage[n.x.key] || 0) * 3) - (m.s + (usage[m.x.key] || 0) * 3) || m.x.name.localeCompare(n.x.name))
        return list.slice(0, 80).map(o => o.x)
    }
    onShownChanged: sel = 0
    onArgChanged: if (mode === "files") { files = []; fileDelay.restart() }
    onModeChanged: { if (mode === "emoji" && emojis.length === 0) loadEmoji.running = true; if (mode === "calc" && zones.length === 0) zoneList.running = true }

    function toggle() { visible = !visible }
    onVisibleChanged: if (visible) { query = ""; sel = 0; cat = "all"; PopupState.current = root; loadUsage.running = true }
    Connections { target: PopupState; function onCurrentChanged() { if (PopupState.current !== root) root.visible = false } }
    IpcHandler { target: "launcher"; function toggle(): void { root.toggle() } }

    Process {
        id: loadUsage
        command: ["cat", root.usageFile]
        stdout: StdioCollector { onStreamFinished: { try { root.usage = JSON.parse(this.text) } catch (e) {} } }
    }
    function remember(key) {
        if (!key) return
        const u = Object.assign({}, usage); u[key] = (u[key] || 0) + 1; usage = u
        Quickshell.execDetached(["sh", "-c", "mkdir -p ~/.local/state && printf '%s' \"$1\" > \"$2\"", "sh", JSON.stringify(u), usageFile])
    }
    function launch(it) {
        if (!it) return
        visible = false
        remember(it.key)
        if (it.kind === "app") it.entry.execute()
        else if (it.cmd) Quickshell.execDetached(it.cmd)
        else if (it.run) it.run()
    }
    function accept() { launch(shown[sel]) }
    function stepCat(d) { const i = cats.findIndex(c => c[0] === cat); cat = cats[(i + d + cats.length) % cats.length][0] }

    PanelWindow {   // dim + click anywhere outside closes
        visible: root.visible; screen: root.screen
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "qsbar-dismiss"
        color: "#80000000"
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onClicked: root.visible = false }
    }

    PanelWindow {
        visible: root.visible; screen: root.screen
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qsbar-launcher"
        WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "transparent"
        implicitWidth: 960; implicitHeight: 620

        Rectangle {
            id: frame
            anchors.fill: parent; radius: 28
            color: "#f50b0b0b"
            border.width: 1; border.color: "#14ffffff"

            // ---------- search ----------
            TextField {
                id: search
                x: 16; y: 16; width: parent.width - 32; height: 58
                focus: root.visible
                Connections { target: root; function onVisibleChanged() { if (root.visible) { search.text = ""; search.forceActiveFocus() } } }
                onTextChanged: root.query = text
                placeholderText: "Search apps, files, emoji or do math"; placeholderTextColor: "#555555"
                color: "#ffffff"; selectionColor: "#ffffff33"; selectedTextColor: "#ffffff"
                font.family: Theme.font; font.pixelSize: 17; leftPadding: 54; rightPadding: 110; verticalAlignment: TextInput.AlignVCenter
                background: Rectangle { radius: 20; color: "#161616" }
                Text { x: 20; anchors.verticalCenter: parent.verticalCenter; text: "\u{f0349}"; color: "#8a8a8a"; font.family: Theme.font; font.pixelSize: 19 }
                Rectangle {   // which mode you're in
                    visible: root.mode !== "apps"
                    anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                    width: modeLbl.implicitWidth + 24; height: 32; radius: 16; color: "#ececec"
                    Text { id: modeLbl; anchors.centerIn: parent; color: "#0b0b0b"; font.family: Theme.font; font.pixelSize: 11; font.bold: true
                           text: ({ calc: "Math", cmd: "Command", web: "Web", emoji: "Emoji", files: "Files", apps: "" })[root.mode] }
                }
                Keys.onEscapePressed: root.visible = false
                Keys.onReturnPressed: root.accept()
                Keys.onEnterPressed: root.accept()
                Keys.onDownPressed: root.sel = Math.min(root.sel + 1, root.shown.length - 1)
                Keys.onUpPressed: root.sel = Math.max(root.sel - 1, 0)
                Keys.onTabPressed: root.stepCat(1)
                Keys.onBacktabPressed: root.stepCat(-1)
            }

            // ---------- categories ----------
            Flickable {
                id: chips
                visible: root.mode === "apps"
                x: 16; y: search.y + search.height + 12; width: parent.width - 32; height: 32
                contentWidth: chipRow.implicitWidth; clip: true; boundsBehavior: Flickable.StopAtBounds
                Row {
                    id: chipRow; spacing: 5
                    Repeater {
                        model: root.cats
                        Rectangle {
                            required property var modelData
                            readonly property bool on: root.cat === modelData[0]
                            width: chl.implicitWidth + 20; height: 32; radius: 16
                            color: on ? "#ececec" : (chm.containsMouse ? "#222222" : "#161616")
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Text { id: chl; anchors.centerIn: parent; text: modelData[1]; color: on ? "#0b0b0b" : "#a8a8a8"; font.family: Theme.font; font.pixelSize: 11; font.bold: on }
                            MouseArea { id: chm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { root.cat = modelData[0]; search.forceActiveFocus() } }
                        }
                    }
                }
            }

            // ---------- results ----------
            ListView {
                id: lv
                x: 10; y: (chips.visible ? chips.y + chips.height : search.y + search.height) + 12
                width: 580; height: foot.y - y - 4
                header: Item {   // most used, as tiles (only with an empty search)
                    width: lv.width; height: root.showTiles ? tilesCol.implicitHeight + 12 : 0; visible: root.showTiles
                    Column {
                        id: tilesCol
                        x: 6; width: parent.width - 12; spacing: 8
                        Text { text: "MOST USED"; color: "#6a6a6a"; font.family: Theme.font; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1.6; leftPadding: 4 }
                        Grid {
                            width: parent.width; columns: 4; columnSpacing: 8; rowSpacing: 8
                            Repeater {
                                model: root.frequent
                                Rectangle {
                                    id: ft
                                    required property var modelData
                                    width: (parent.width - 24) / 4; height: 88; radius: 16
                                    color: ftm.containsMouse ? "#ececec" : "#141414"; border.width: 1; border.color: ftm.containsMouse ? "#ececec" : "#1f1f1f"
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                    IconImage { id: fti; anchors.horizontalCenter: parent.horizontalCenter; y: 14; width: 34; height: 34; visible: false
                                                source: Quickshell.iconPath(ft.modelData.icon, true) || Quickshell.iconPath("application-x-executable") }
                                    MultiEffect { anchors.fill: fti; source: fti; saturation: ftm.containsMouse ? 0 : -1.0 }
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 10; width: parent.width - 12
                                           horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: ft.modelData.name
                                           color: ftm.containsMouse ? "#0b0b0b" : "#d8d8d8"; font.family: Theme.font; font.pixelSize: 10 }
                                    MouseArea { id: ftm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.launch(ft.modelData) }
                                }
                            }
                        }
                        Text { text: "ALL APPS"; color: "#6a6a6a"; font.family: Theme.font; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1.6; leftPadding: 4; topPadding: 6 }
                    }
                }
                clip: true; spacing: 2
                model: root.shown
                currentIndex: root.sel
                highlightMoveDuration: 90
                boundsBehavior: Flickable.StopAtBounds
                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool cur: index === root.sel
                    width: lv.width; height: 54; radius: 16
                    color: cur ? "#1c1c1c" : "transparent"
                    Rectangle {
                        id: ic; x: 10; anchors.verticalCenter: parent.verticalCenter; width: 38; height: 38; radius: 12
                        color: row.cur ? "#2a2a2a" : "#151515"
                        IconImage {
                            id: img; anchors.centerIn: parent; width: 26; height: 26; visible: false
                            source: row.modelData.kind === "app" || row.modelData.kind === "file"
                                    ? (Quickshell.iconPath(row.modelData.icon, true) || Quickshell.iconPath("application-x-executable")) : ""
                        }
                        MultiEffect { anchors.fill: img; source: img; saturation: -1.0; brightness: row.cur ? 0.05 : -0.1
                                      visible: row.modelData.kind === "app" || row.modelData.kind === "file" }
                        Text { visible: row.modelData.kind === "glyph"; anchors.centerIn: parent; text: row.modelData.glyph || ""
                               font.family: Theme.font; font.pixelSize: 17; color: row.cur ? "#ffffff" : "#c8c8c8" }
                        Text { font.family: Theme.font; visible: row.modelData.kind === "emoji"; anchors.centerIn: parent; text: row.modelData.emoji || ""; font.pixelSize: 20 }
                    }
                    Column {
                        anchors.left: ic.right; anchors.leftMargin: 14; anchors.right: hint.left; anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter; spacing: 2
                        Text { width: parent.width; elide: Text.ElideRight; text: row.modelData.name; color: row.cur ? "#ffffff" : "#dcdcdc"
                               font.family: Theme.font; font.pixelSize: 13; font.bold: row.cur }
                        Text { visible: !!row.modelData.sub; width: parent.width; elide: Text.ElideMiddle; text: row.modelData.sub || ""
                               color: "#666666"; font.family: Theme.font; font.pixelSize: 10 }
                    }
                    Rectangle {
                        id: hint
                        anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                        width: row.cur ? hl.implicitWidth + 20 : hl.implicitWidth; height: 26; radius: 13
                        color: row.cur ? "#ececec" : "transparent"
                        Text { id: hl; anchors.centerIn: parent; text: row.cur ? "\u{f0311} " + (["math", "time", "emoji"].indexOf(row.modelData.cat) >= 0 ? "Copy" : "Open") : ""
                               color: row.cur ? "#0b0b0b" : "#454545"; font.family: Theme.font; font.pixelSize: 10; font.bold: row.cur }
                    }
                    MouseArea { id: rm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onEntered: root.sel = row.index; onClicked: root.launch(row.modelData) }
                }
            }
            Text {
                visible: root.shown.length === 0
                anchors.centerIn: lv
                text: root.mode === "files" ? (root.arg.length < 2 ? "Type a file name" : (findFiles.running || fileDelay.running ? "Searching…" : "No files found"))
                    : root.mode === "emoji" ? "Type an emoji name"
                    : root.mode === "web" ? "Type what to search for" : root.mode === "cmd" ? "Type a command" : "Nothing found"
                color: "#5a5a5a"; font.family: Theme.font; font.pixelSize: 12
            }

            // ---------- preview of the selected result ----------
            Rectangle {
                id: pv
                x: lv.x + lv.width + 14; y: lv.y; width: parent.width - x - 16; height: lv.height
                radius: 22; color: "#111111"; border.width: 1; border.color: "#1c1c1c"
                visible: !!root.cur
                readonly property var it: root.cur
                readonly property bool isApp: !!it && it.kind === "app"
                Column {
                    x: 24; y: 28; width: parent.width - 48; spacing: 10
                    Rectangle {
                        width: 84; height: 84; radius: 24; color: "#1a1a1a"
                        IconImage { id: pvi; anchors.centerIn: parent; width: 54; height: 54; visible: false
                                    source: pv.it && (pv.it.kind === "app" || pv.it.kind === "file") ? (Quickshell.iconPath(pv.it.icon, true) || Quickshell.iconPath("application-x-executable")) : "" }
                        MultiEffect { anchors.fill: pvi; source: pvi; saturation: -0.6; visible: !!pv.it && (pv.it.kind === "app" || pv.it.kind === "file") }
                        Text { anchors.centerIn: parent; visible: !!pv.it && pv.it.kind === "glyph"; text: pv.it ? pv.it.glyph || "" : ""; color: "#ececec"; font.family: Theme.font; font.pixelSize: 36 }
                        Text { anchors.centerIn: parent; visible: !!pv.it && pv.it.kind === "emoji"; text: pv.it ? pv.it.emoji || "" : ""; font.pixelSize: 44 }
                    }
                    Item { width: 1; height: 4 }
                    Text { width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 3; elide: Text.ElideRight; text: pv.it ? pv.it.name : ""
                           color: "#ffffff"; font.family: Theme.font; font.pixelSize: root.mode === "calc" ? 26 : 18; font.bold: true }
                    Text { width: parent.width; wrapMode: Text.WordWrap; text: pv.it ? (pv.isApp ? (pv.it.entry.genericName || pv.it.sub || "") : pv.it.sub || "") : ""
                           color: "#9a9a9a"; font.family: Theme.font; font.pixelSize: 11; visible: text !== "" }
                    Text { width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 5; elide: Text.ElideRight
                           text: pv.isApp ? (pv.it.entry.comment || "") : ""; visible: text !== ""; color: "#6e6e6e"; font.family: Theme.font; font.pixelSize: 11; lineHeight: 1.2 }
                    Flow {
                        width: parent.width; spacing: 6; visible: pv.isApp || (pv.it && pv.it.kind === "glyph" && pv.it.cat === "actions")
                        Repeater {
                            model: pv.it ? [(root.cats.find(c => c[0] === pv.it.cat) || [0, pv.it.cat])[1], root.usage[pv.it.key] ? "Opened " + root.usage[pv.it.key] + (root.usage[pv.it.key] === 1 ? " time" : " times") : "Never opened yet"] : []
                            Rectangle { required property string modelData; width: pt.implicitWidth + 16; height: 22; radius: 11; color: "#1c1c1c"
                                        Text { id: pt; anchors.centerIn: parent; text: parent.modelData; color: "#a8a8a8"; font.family: Theme.font; font.pixelSize: 10 } }
                        }
                    }
                }
                Rectangle {   // the big Open / Copy button
                    anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 20
                    height: 46; radius: 23; color: pvm.containsMouse ? "#ffffff" : "#ececec"
                    Text { anchors.centerIn: parent; color: "#0b0b0b"; font.family: Theme.font; font.pixelSize: 12; font.bold: true
                           text: pv.it && ["math", "time", "emoji"].indexOf(pv.it.cat) >= 0 ? "\u{f018f}  Copy" : "\u{f0311}  Open" }
                    MouseArea { id: pvm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.accept() }
                }
            }

            // ---------- footer ----------
            Item {
                id: foot
                y: parent.height - height; width: parent.width; height: 58
                Rectangle { x: 20; width: parent.width - 40; height: 1; color: "#14ffffff" }
                Row {
                    x: 22; anchors.verticalCenter: parent.verticalCenter; spacing: 14
                    Repeater {
                        model: [["?", "Web"], [":", "Emoji"], ["/", "Files"], ["=", "Math and convert"], [">", "Run"]]
                        Row {
                            required property var modelData
                            spacing: 6
                            Rectangle { width: 20; height: 20; radius: 6; color: "#1a1a1a"
                                        Text { anchors.centerIn: parent; text: modelData[0]; color: "#bdbdbd"; font.family: Theme.font; font.pixelSize: 11; font.bold: true } }
                            Text { anchors.verticalCenter: parent.verticalCenter; text: modelData[1]; color: "#5e5e5e"; font.family: Theme.font; font.pixelSize: 10 }
                        }
                    }
                }
                Row {
                    anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter; spacing: 6
                    Repeater {
                        model: [["\u{f018d}", ["kitty"]], ["\u{f024b}", ["dolphin"]], ["\u{f033e}", ["qs", "ipc", "-p", root.qsDir, "call", "curtain", "lock"]],
                                ["\u{f0425}", ["qs", "ipc", "-p", root.qsDir, "call", "bar", "power"]]]
                        Rectangle {
                            required property var modelData
                            width: 34; height: 34; radius: 17
                            color: fm.containsMouse ? "#ececec" : "#161616"
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Text { anchors.centerIn: parent; text: modelData[0]; color: fm.containsMouse ? "#0b0b0b" : "#cfcfcf"; font.family: Theme.font; font.pixelSize: 14 }
                            MouseArea { id: fm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { root.visible = false; Quickshell.execDetached(modelData[1]) } }
                        }
                    }
                }
            }
        }
    }
}
