// App launcher (SUPER + Space) – monochrome, replaces rofi.
// Type to search apps and quick actions (fix audio, lock, focus mode, ink…).
//   ? query  → search the web      : name → emoji (Enter copies)      / name → files in your home
//   = 12*7   → calculator (copies)  > cmd  → run a command
// ↑↓ / Tab to move · Enter or click to open · Esc or click outside to close. Made by Claude.
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
    property var usage: ({})                    // item key -> launch count (most used first)
    readonly property string usageFile: Quickshell.env("HOME") + "/.local/state/launcher-usage.json"
    readonly property string scripts: Quickshell.env("HOME") + "/.config/hypr/scripts"
    readonly property string qsDir: Quickshell.env("HOME") + "/.config/quickshell/bar"
    readonly property string q: query.trim()
    readonly property string mode: q.startsWith("=") ? "calc" : q.startsWith(">") ? "cmd" : q.startsWith("?") ? "web"
                                  : q.startsWith(":") ? "emoji" : q.startsWith("/") ? "files" : "apps"
    readonly property string arg: mode === "apps" ? q : q.slice(1).trim()

    // ---------- sources ----------
    readonly property var apps: DesktopEntries.applications.values.filter(a => !a.noDisplay && a.name)
    function ipc(target, fn) { return ["qs", "ipc", "-p", qsDir, "call", target, fn || "toggle"] }
    // quick actions: [name, keywords, glyph, command]
    readonly property var actions: [
        ["Fix audio", "sound broken restart pipewire spotify discord no sound", "\u{f057e}", [scripts + "/fix-audio.sh"]],
        ["Lock screen", "lock away", "\u{f033e}", ["loginctl", "lock-session"]],
        ["Focus mode", "zen no gaps distraction", "\u{f0d4a}", [scripts + "/focus-mode.sh"]],
        ["Drop-down terminal", "terminal kitty console", "\u{f018d}", [scripts + "/dropterm.sh"]],
        ["Draw on screen", "ink annotate pen marker", "\u{f03eb}", ipc("ink")],
        ["Screenshot region", "snip capture print", "\u{f0100}", ["sh", "-c", "sleep 0.3; " + scripts + "/screenshot.sh region"]],
        ["Color picker", "colour pick hex eyedropper", "\u{f0d52}", ["sh", "-c", "sleep 0.3; hyprpicker -a"]],
        ["Clipboard history", "paste copy", "\u{f014c}", ipc("clipboard")],
        ["Wallpaper", "background picture", "\u{f02e9}", ipc("wallpaper")],
        ["Workspace overview", "windows expose", "\u{f0d61}", ipc("overview")],
        ["Control center", "quick settings volume", "\u{f0493}", ["qs", "ipc", "-p", qsDir, "call", "bar", "control"]],
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
        command: ["fd", "-i", "-H", "--max-results", "8", "--max-depth", "7",
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

    // ---------- one list for everything: {kind, key, name, sub, icon, glyph, emoji, run} ----------
    readonly property var shown: {
        const a = arg.toLowerCase()
        if (mode === "calc") return calc === null ? [] : [{ kind: "glyph", glyph: "\u{f00ec}", name: "= " + calc, sub: "Enter copies the result",
                                                             run: () => Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | wl-copy", "sh", calc]) }]
        if (mode === "cmd") return arg ? [{ kind: "glyph", glyph: "\u{f018d}", name: arg, sub: "run command", run: () => Quickshell.execDetached(["sh", "-c", arg]) }] : []
        if (mode === "web") return arg ? [{ kind: "glyph", glyph: "\u{f059f}", name: arg, sub: "search the web",
                                            run: () => Quickshell.execDetached(["xdg-open", "https://duckduckgo.com/?q=" + encodeURIComponent(arg)]) }] : []
        if (mode === "emoji") {
            if (!a) return []
            return emojis.filter(e => e.n.indexOf(a) >= 0).slice(0, 8).map(e => ({ kind: "emoji", emoji: e.e, name: e.n, sub: "Enter copies",
                run: () => Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | wl-copy", "sh", e.e]) }))
        }
        if (mode === "files") return files.map(f => ({ kind: "file", name: f.replace(/\/$/, "").split("/").pop(),
            sub: f.replace(Quickshell.env("HOME"), "~").replace(/\/[^/]*\/?$/, ""), icon: f.endsWith("/") ? "folder" : "text-x-generic",
            run: () => Quickshell.execDetached(["xdg-open", f]) }))
        const items = apps.map(x => ({ kind: "app", key: x.id, name: x.name, sub: x.genericName || "", icon: x.icon, extra: (x.genericName || "") + " " + (x.keywords || []).join(" "), entry: x }))
            .concat(actions.map(x => ({ kind: "glyph", key: "action:" + x[0], name: x[0], sub: "action", glyph: x[2], extra: x[1], cmd: x[3] })))
        const list = a ? items.map(x => ({ x: x, s: score(x.name, x.extra, a) })).filter(o => o.s >= 0)
                       : items.filter(x => x.kind === "app").map(x => ({ x: x, s: 0 }))
        list.sort((m, n) => (n.s + (usage[n.x.key] || 0) * 3) - (m.s + (usage[m.x.key] || 0) * 3) || m.x.name.localeCompare(n.x.name))
        return list.slice(0, 8).map(o => o.x)
    }
    onShownChanged: sel = 0
    onArgChanged: if (mode === "files") { files = []; fileDelay.restart() }
    onModeChanged: if (mode === "emoji" && emojis.length === 0) loadEmoji.running = true

    function toggle() { visible = !visible }
    onVisibleChanged: if (visible) { query = ""; sel = 0; PopupState.current = root; loadUsage.running = true }
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

    PanelWindow {   // dim + click anywhere outside closes
        visible: root.visible; screen: root.screen
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "qsbar-dismiss"
        color: "#66000000"
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onClicked: root.visible = false }
    }

    PanelWindow {
        visible: root.visible; screen: root.screen
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qsbar-launcher"
        WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "transparent"
        implicitWidth: 580
        implicitHeight: 84 + Math.max(1, root.shown.length) * 52 + (root.mode === "apps" && !root.q ? 30 : 0) + 18

        Rectangle {
            id: frame
            anchors.fill: parent; radius: 22
            color: "#f20c0c0c"; border.width: 1; border.color: "#24ffffff"

            TextField {
                id: search
                x: 18; y: 16; width: parent.width - 36; height: 48
                focus: root.visible
                Connections { target: root; function onVisibleChanged() { if (root.visible) { search.text = ""; search.forceActiveFocus() } } }
                onTextChanged: root.query = text
                placeholderText: "Search apps & actions"; placeholderTextColor: "#5a5a5a"
                color: "#f0f0f0"; selectionColor: "#ffffff33"; selectedTextColor: "#ffffff"
                font.family: Theme.font; font.pixelSize: 16; leftPadding: 40; rightPadding: 90; verticalAlignment: TextInput.AlignVCenter
                background: Rectangle { radius: 24; color: "#161616"; border.width: 1; border.color: search.activeFocus ? "#4dffffff" : "#1fffffff" }
                Text { x: 14; anchors.verticalCenter: parent.verticalCenter; text: "\u{f0349}"; color: "#8a8a8a"; font.family: Theme.font; font.pixelSize: 17 }
                Rectangle {   // which mode you're in
                    visible: root.mode !== "apps"
                    anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter
                    width: modeLbl.implicitWidth + 20; height: 28; radius: 14; color: Theme.on
                    Text { id: modeLbl; anchors.centerIn: parent; color: Theme.onText; font.family: Theme.font; font.pixelSize: 10; font.bold: true
                           text: ({ calc: "math", cmd: "command", web: "web", emoji: "emoji", files: "files", apps: "" })[root.mode] }
                }
                Keys.onEscapePressed: root.visible = false
                Keys.onReturnPressed: root.accept()
                Keys.onEnterPressed: root.accept()
                Keys.onDownPressed: root.sel = Math.min(root.sel + 1, root.shown.length - 1)
                Keys.onUpPressed: root.sel = Math.max(root.sel - 1, 0)
                Keys.onTabPressed: root.sel = (root.sel + 1) % Math.max(1, root.shown.length)
                Keys.onBacktabPressed: root.sel = (root.sel - 1 + root.shown.length) % Math.max(1, root.shown.length)
            }

            Column {
                x: 12; y: 76; width: parent.width - 24; spacing: 4

                Repeater {
                    model: root.shown
                    Rectangle {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool cur: index === root.sel
                        width: parent.width; height: 48; radius: 14
                        color: cur ? "#1fffffff" : (rm.containsMouse ? "#0fffffff" : "transparent")
                        Behavior on color { ColorAnimation { duration: 90 } }
                        Rectangle { visible: row.cur; x: 0; anchors.verticalCenter: parent.verticalCenter; width: 3; height: 20; radius: 2; color: "#f0f0f0" }
                        Item {
                            id: ic; x: 14; anchors.verticalCenter: parent.verticalCenter; width: 30; height: 30
                            IconImage {
                                id: img; anchors.fill: parent; visible: false
                                source: row.modelData.kind === "app" || row.modelData.kind === "file"
                                        ? (Quickshell.iconPath(row.modelData.icon, true) || Quickshell.iconPath("application-x-executable")) : ""
                            }
                            MultiEffect { anchors.fill: img; source: img; saturation: -1.0; brightness: row.cur ? 0.08 : -0.05
                                          visible: row.modelData.kind === "app" || row.modelData.kind === "file" }
                            Rectangle {
                                visible: row.modelData.kind === "glyph"
                                anchors.fill: parent; radius: 15; color: row.cur ? Theme.on : "#1affffff"
                                Text { anchors.centerIn: parent; text: row.modelData.glyph || ""; font.family: Theme.font; font.pixelSize: 15
                                       color: row.cur ? Theme.onText : "#e0e0e0" }
                            }
                            Text { visible: row.modelData.kind === "emoji"; anchors.centerIn: parent; text: row.modelData.emoji || ""; font.pixelSize: 24 }
                        }
                        Column {
                            anchors.left: ic.right; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 70
                            Text { width: parent.width; elide: Text.ElideRight; text: row.modelData.name; color: row.cur ? "#ffffff" : "#d0d0d0"; font.family: Theme.font; font.pixelSize: 14 }
                            Text { visible: !!row.modelData.sub; width: parent.width; elide: Text.ElideMiddle; text: row.modelData.sub || ""; color: "#6a6a6a"; font.family: Theme.font; font.pixelSize: 11 }
                        }
                        MouseArea { id: rm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onEntered: root.sel = row.index; onClicked: root.launch(row.modelData) }
                    }
                }
                Text {
                    visible: root.shown.length === 0
                    width: parent.width; height: 48; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    text: root.mode === "files" ? (root.arg.length < 2 ? "type a file name" : (findFiles.running || fileDelay.running ? "searching…" : "no files found"))
                        : root.mode === "emoji" ? "type an emoji name"
                        : root.mode === "web" ? "type what to search" : root.mode === "cmd" ? "type a command" : "nothing found"
                    color: "#5a5a5a"; font.family: Theme.font; font.pixelSize: 13
                }
                Text {   // tips, only on the empty start screen
                    visible: root.mode === "apps" && !root.q
                    width: parent.width; height: 26; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    text: "?  web    :  emoji    /  files    =  math    >  command"
                    color: "#4a4a4a"; font.family: Theme.font; font.pixelSize: 11
                }
            }
        }
    }
}
