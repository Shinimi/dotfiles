// Launcher (SUPER + Space), Tsugumori-style: categories on the left, numbered results on the right,
// session buttons along the bottom. Type to search apps and quick actions (fix audio, lock, focus mode…).
//   ? query → web     : name → emoji (Enter copies)     / name → files     = 12*7 → math     > cmd → run
// ↑↓ move · Tab / Shift+Tab category · Enter open · Esc or click outside closes. Made by Claude.
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

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
    readonly property var cats: [["all", "all", "全"], ["actions", "actions", "操作"], ["develop", "develop", "開発"], ["internet", "internet", "通信"],
                                 ["media", "media", "再生"], ["games", "games", "遊戯"], ["graphics", "graphics", "画像"], ["office", "office", "事務"],
                                 ["system", "system", "系統"], ["other", "other", "他"]]
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
        ["Focus mode", "zen no gaps distraction", "\u{f0d4a}", [scripts + "/focus-mode.sh"]],
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
    readonly property var calc: {
        if (mode !== "calc") return null
        const e = arg.replace(/\^/g, "**").replace(/x/g, "*")
        if (!/^[\d\s+\-*/().%*]+$/.test(e) || !e.trim()) return null
        try { const v = Function('"use strict";return (' + e + ')')(); return isFinite(v) ? String(Math.round(v * 1e10) / 1e10) : null } catch (x) { return null }
    }

    // every app / action with its category, built once per app list change
    readonly property var items: apps.map(x => ({ kind: "app", key: x.id, name: x.name, sub: x.genericName || "", icon: x.icon, cat: catOf(x),
                                                  extra: (x.genericName || "") + " " + (x.keywords || []).join(" "), entry: x }))
        .concat(actions.map(x => ({ kind: "glyph", key: "action:" + x[0], name: x[0], sub: "action", glyph: x[2], cat: "actions", extra: x[1], cmd: x[3] })))
    function countIn(c) { return c === "all" ? items.length : items.filter(x => x.cat === c).length }

    // ---------- one list for everything: {kind, key, name, sub, cat, icon, glyph, emoji, run} ----------
    readonly property var shown: {
        const a = arg.toLowerCase()
        if (mode === "calc") return calc === null ? [] : [{ kind: "glyph", glyph: "\u{f00ec}", name: "= " + calc, sub: "Enter copies the result", cat: "math",
                                                             run: () => Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | wl-copy", "sh", calc]) }]
        if (mode === "cmd") return arg ? [{ kind: "glyph", glyph: "\u{f018d}", name: arg, sub: "run command", cat: "shell", run: () => Quickshell.execDetached(["sh", "-c", arg]) }] : []
        if (mode === "web") return arg ? [{ kind: "glyph", glyph: "\u{f059f}", name: arg, sub: "search the web", cat: "web",
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
    onModeChanged: if (mode === "emoji" && emojis.length === 0) loadEmoji.running = true

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
        implicitWidth: 900; implicitHeight: 600

        Rectangle {
            id: frame
            anchors.fill: parent; radius: 3
            color: Theme.mix(Qt.rgba(0.035, 0.035, 0.035, 0.94), Theme.tint, 0.07 * Theme.tintOn)
            border.width: 1; border.color: "#3dffffff"
            // corner brackets
            Repeater {
                model: [[0, 0], [1, 0], [0, 1], [1, 1]]
                Item {
                    required property var modelData
                    x: modelData[0] ? frame.width - 12 + 4 : -4; y: modelData[1] ? frame.height - 12 + 4 : -4
                    width: 12; height: 12
                    Rectangle { x: modelData[0] ? 11 : 0; width: 1; height: 12; color: "#ffffff" }
                    Rectangle { y: modelData[1] ? 11 : 0; width: 12; height: 1; color: "#ffffff" }
                }
            }

            // ---------- header ----------
            Item {
                id: head
                x: 0; y: 0; width: parent.width; height: 44
                Row {
                    x: 20; anchors.verticalCenter: parent.verticalCenter; spacing: 12
                    Text { text: "LAUNCH"; color: "#f0f0f0"; font.family: Theme.font; font.pixelSize: 12; font.letterSpacing: 4; font.bold: true }
                    Text { text: "//"; color: "#555555"; font.family: Theme.font; font.pixelSize: 12 }
                    Text { text: "起動"; color: "#8a8a8a"; font.family: "Noto Sans CJK JP"; font.pixelSize: 12 }
                }
                Row {
                    anchors.right: parent.right; anchors.rightMargin: 20; anchors.verticalCenter: parent.verticalCenter; spacing: 22
                    Text { text: root.items.filter(x => x.kind === "app").length + " APPS"; color: "#8a8a8a"; font.family: Theme.font; font.pixelSize: 10; font.letterSpacing: 2 }
                    Text { id: clk; text: Qt.formatTime(new Date(), "HH:mm:ss"); color: "#e8e8e8"; font.family: Theme.font; font.pixelSize: 11; font.letterSpacing: 1
                           Timer { interval: 1000; running: root.visible; repeat: true; triggeredOnStart: true; onTriggered: clk.text = Qt.formatTime(new Date(), "HH:mm:ss") } }
                }
                Rectangle { anchors.bottom: parent.bottom; x: 1; width: parent.width - 2; height: 1; color: "#26ffffff" }
            }

            // ---------- categories ----------
            Column {
                id: side
                x: 12; y: head.height + 12; width: 168; spacing: 2
                Repeater {
                    model: root.cats
                    Rectangle {
                        required property var modelData
                        readonly property bool on: root.cat === modelData[0] && root.mode === "apps"
                        width: side.width; height: 32; radius: 2
                        color: on ? Theme.on : (catMouse.containsMouse ? "#12ffffff" : "transparent")
                        Behavior on color { ColorAnimation { duration: 110 } }
                        Text { x: 12; anchors.verticalCenter: parent.verticalCenter; text: (on ? "▸ " : "· ") + modelData[1].toUpperCase()
                               color: on ? Theme.onText : "#a0a0a0"; font.family: Theme.font; font.pixelSize: 11; font.letterSpacing: 1.5; font.bold: on }
                        Text { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                               text: modelData[2]; color: on ? "#66000000" : "#4a4a4a"; font.family: "Noto Sans CJK JP"; font.pixelSize: 10 }
                        MouseArea { id: catMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { root.cat = modelData[0]; search.forceActiveFocus() } }
                    }
                }
                Item { width: 1; height: 14 }
                Text { x: 12; text: root.shown.length + " / " + root.countIn(root.cat) + " NODES"; color: "#5a5a5a"; font.family: Theme.font; font.pixelSize: 9; font.letterSpacing: 1.5 }
            }
            Rectangle { x: side.x + side.width + 12; y: head.height; width: 1; height: parent.height - head.height - foot.height; color: "#1fffffff" }

            // ---------- search + results ----------
            Item {
                id: main
                x: side.x + side.width + 25; y: head.height + 12
                width: parent.width - x - 14; height: parent.height - y - foot.height - 10

                TextField {
                    id: search
                    width: parent.width; height: 40
                    focus: root.visible
                    Connections { target: root; function onVisibleChanged() { if (root.visible) { search.text = ""; search.forceActiveFocus() } } }
                    onTextChanged: root.query = text
                    placeholderText: "Search application…"; placeholderTextColor: "#555555"
                    color: "#f0f0f0"; selectionColor: "#ffffff33"; selectedTextColor: "#ffffff"
                    font.family: Theme.font; font.pixelSize: 14; leftPadding: 30; rightPadding: 90; verticalAlignment: TextInput.AlignVCenter
                    background: Rectangle { radius: 2; color: "#0cffffff"; border.width: 1; border.color: search.activeFocus ? "#55ffffff" : "#1fffffff"
                                            Rectangle { width: 2; height: parent.height; color: "#ffffff" } }
                    Text { x: 12; anchors.verticalCenter: parent.verticalCenter; text: "›"; color: "#9a9a9a"; font.family: Theme.font; font.pixelSize: 16 }
                    Rectangle {   // which mode you're in
                        visible: root.mode !== "apps"
                        anchors.right: parent.right; anchors.rightMargin: 6; anchors.verticalCenter: parent.verticalCenter
                        width: modeLbl.implicitWidth + 18; height: 26; radius: 2; color: Theme.on
                        Text { id: modeLbl; anchors.centerIn: parent; color: Theme.onText; font.family: Theme.font; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.5
                               text: ({ calc: "MATH", cmd: "COMMAND", web: "WEB", emoji: "EMOJI", files: "FILES", apps: "" })[root.mode] }
                    }
                    Keys.onEscapePressed: root.visible = false
                    Keys.onReturnPressed: root.accept()
                    Keys.onEnterPressed: root.accept()
                    Keys.onDownPressed: root.sel = Math.min(root.sel + 1, root.shown.length - 1)
                    Keys.onUpPressed: root.sel = Math.max(root.sel - 1, 0)
                    Keys.onTabPressed: root.stepCat(1)
                    Keys.onBacktabPressed: root.stepCat(-1)
                }

                ListView {
                    id: lv
                    y: search.height + 10; width: parent.width; height: parent.height - y
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
                        width: lv.width; height: 40; radius: 2
                        color: cur ? "#1cffffff" : (rm.containsMouse ? "#0affffff" : "transparent")
                        Rectangle { visible: row.cur; width: 2; height: parent.height; color: "#ffffff" }
                        Text { id: num; x: 14; anchors.verticalCenter: parent.verticalCenter; width: 22
                               text: String(row.index + 1).padStart(2, "0"); color: row.cur ? "#ffffff" : "#555555"; font.family: Theme.font; font.pixelSize: 11 }
                        Item {
                            id: ic; anchors.left: num.right; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter; width: 24; height: 24
                            IconImage {
                                id: img; anchors.fill: parent; visible: false
                                source: row.modelData.kind === "app" || row.modelData.kind === "file"
                                        ? (Quickshell.iconPath(row.modelData.icon, true) || Quickshell.iconPath("application-x-executable")) : ""
                            }
                            MultiEffect { anchors.fill: img; source: img; saturation: -1.0; brightness: row.cur ? 0.08 : -0.08
                                          visible: row.modelData.kind === "app" || row.modelData.kind === "file" }
                            Text { visible: row.modelData.kind === "glyph"; anchors.centerIn: parent; text: row.modelData.glyph || ""
                                   font.family: Theme.font; font.pixelSize: 15; color: row.cur ? "#ffffff" : "#b0b0b0" }
                            Text { visible: row.modelData.kind === "emoji"; anchors.centerIn: parent; text: row.modelData.emoji || ""; font.pixelSize: 19 }
                        }
                        Column {
                            anchors.left: ic.right; anchors.leftMargin: 14; anchors.right: catLbl.left; anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            Text { width: parent.width; elide: Text.ElideRight; text: row.modelData.name; color: row.cur ? "#ffffff" : "#d4d4d4"; font.family: Theme.font; font.pixelSize: 13 }
                            Text { visible: !!row.modelData.sub && row.cur; width: parent.width; elide: Text.ElideMiddle; text: row.modelData.sub || ""
                                   color: "#6a6a6a"; font.family: Theme.font; font.pixelSize: 10 }
                        }
                        Text { id: catLbl; anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter
                               text: (row.modelData.cat || "").toUpperCase(); color: row.cur ? "#9a9a9a" : "#454545"
                               font.family: Theme.font; font.pixelSize: 9; font.letterSpacing: 1.5 }
                        MouseArea { id: rm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onEntered: root.sel = row.index; onClicked: root.launch(row.modelData) }
                    }
                }
                Text {
                    visible: root.shown.length === 0
                    anchors.centerIn: lv
                    text: root.mode === "files" ? (root.arg.length < 2 ? "type a file name" : (findFiles.running || fileDelay.running ? "searching…" : "no files found"))
                        : root.mode === "emoji" ? "type an emoji name"
                        : root.mode === "web" ? "type what to search" : root.mode === "cmd" ? "type a command" : "nothing found"
                    color: "#5a5a5a"; font.family: Theme.font; font.pixelSize: 12
                }
            }

            // ---------- session strip ----------
            Item {
                id: foot
                anchors.bottom: parent.bottom; width: parent.width; height: 44
                Rectangle { x: 1; width: parent.width - 2; height: 1; color: "#26ffffff" }
                Text { x: 20; anchors.verticalCenter: parent.verticalCenter; text: "?  web   :  emoji   /  files   =  math   >  command   ·   tab  category"
                       color: "#4a4a4a"; font.family: Theme.font; font.pixelSize: 10 }
                Row {
                    anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; spacing: 4
                    Repeater {
                        model: [["TERMINAL", ["kitty"]], ["FILES", ["dolphin"]], ["LOCK", ["qs", "ipc", "-p", Quickshell.env("HOME") + "/.config/quickshell/bar", "call", "curtain", "lock"]],
                                ["POWER", ["qs", "ipc", "-p", root.qsDir, "call", "bar", "power"]]]
                        Rectangle {
                            required property var modelData
                            width: fl.implicitWidth + 22; height: 26; radius: 2
                            color: fm.containsMouse ? Theme.on : "transparent"; border.width: 1; border.color: fm.containsMouse ? Theme.on : "#26ffffff"
                            Text { id: fl; anchors.centerIn: parent; text: modelData[0]; color: fm.containsMouse ? Theme.onText : "#a0a0a0"
                                   font.family: Theme.font; font.pixelSize: 9; font.letterSpacing: 1.5 }
                            MouseArea { id: fm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { root.visible = false; Quickshell.execDetached(modelData[1]) } }
                        }
                    }
                }
            }
        }
    }
}
