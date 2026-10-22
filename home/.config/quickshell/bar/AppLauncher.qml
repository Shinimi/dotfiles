// App launcher (SUPER + Space) – monochrome, replaces rofi.
// Type to search · ↑↓ / Tab to move · Enter or click to open · Esc or click outside to close.
// Extras: "= 12*7" calculates, "> cmd" runs a command. Made by Claude.
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
    property var usage: ({})                    // app id -> launch count (most used first)
    readonly property string usageFile: Quickshell.env("HOME") + "/.local/state/launcher-usage.json"

    readonly property var apps: DesktopEntries.applications.values.filter(a => !a.noDisplay && a.name)
    function score(a, q) {
        const n = a.name.toLowerCase(), g = (a.genericName || "").toLowerCase(), k = (a.keywords || []).join(" ").toLowerCase()
        if (n === q) return 1000
        if (n.startsWith(q)) return 800
        if (n.split(/[\s\-_.]/).some(w => w.startsWith(q))) return 600
        if (n.indexOf(q) >= 0) return 400
        if (g.indexOf(q) >= 0 || k.indexOf(q) >= 0) return 200
        let i = 0; for (const c of n) if (c === q[i]) i++          // fuzzy: letters in order
        return i === q.length ? 100 : -1
    }
    readonly property var calc: {
        const q = query.trim()
        if (!q.startsWith("=")) return null
        const e = q.slice(1).replace(/\^/g, "**").replace(/x/g, "*")
        if (!/^[\d\s+\-*/().%*]+$/.test(e) || !e.trim()) return null
        try { const v = Function('"use strict";return (' + e + ')')(); return isFinite(v) ? String(Math.round(v * 1e10) / 1e10) : null } catch (x) { return null }
    }
    readonly property var shown: {
        const q = query.trim().toLowerCase()
        if (q.startsWith("=") || q.startsWith(">")) return []
        const list = q ? apps.map(a => ({ a: a, s: score(a, q) })).filter(x => x.s >= 0) : apps.map(a => ({ a: a, s: 0 }))
        list.sort((x, y) => (y.s + (usage[y.a.id] || 0) * 3) - (x.s + (usage[x.a.id] || 0) * 3) || x.a.name.localeCompare(y.a.name))
        return list.slice(0, 8).map(x => x.a)
    }
    onShownChanged: sel = 0

    function toggle() { visible = !visible }
    onVisibleChanged: if (visible) { query = ""; sel = 0; PopupState.current = root; loadUsage.running = true }
    Connections { target: PopupState; function onCurrentChanged() { if (PopupState.current !== root) root.visible = false } }
    IpcHandler { target: "launcher"; function toggle(): void { root.toggle() } }

    Process {
        id: loadUsage
        command: ["cat", root.usageFile]
        stdout: StdioCollector { onStreamFinished: { try { root.usage = JSON.parse(this.text) } catch (e) {} } }
    }
    function launch(a) {
        if (!a) return
        visible = false
        const u = Object.assign({}, usage); u[a.id] = (u[a.id] || 0) + 1; usage = u
        Quickshell.execDetached(["sh", "-c", "mkdir -p ~/.local/state && printf '%s' \"$1\" > \"$2\"", "sh", JSON.stringify(u), usageFile])
        a.execute()
    }
    function accept() {
        const q = query.trim()
        if (q.startsWith(">") && q.length > 1) { visible = false; Quickshell.execDetached(["sh", "-c", q.slice(1)]); return }
        if (calc !== null) { visible = false; Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | wl-copy", "sh", calc]); return }
        launch(shown[sel])
    }

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
        implicitWidth: 560
        implicitHeight: 84 + Math.max(1, (root.calc !== null || root.query.trim().startsWith(">")) ? 1 : root.shown.length) * 52 + 18

        Rectangle {
            id: frame
            anchors.fill: parent; radius: 20
            color: "#f20c0c0c"; border.width: 1; border.color: "#24ffffff"
            Behavior on height { NumberAnimation { duration: 120 } }

            TextField {
                id: search
                x: 18; y: 16; width: parent.width - 36; height: 48
                focus: root.visible
                Connections { target: root; function onVisibleChanged() { if (root.visible) { search.text = ""; search.forceActiveFocus() } } }
                onTextChanged: root.query = text
                placeholderText: "Search apps   ·   = math   ·   > command"; placeholderTextColor: "#5a5a5a"
                color: "#f0f0f0"; selectionColor: "#ffffff33"; selectedTextColor: "#ffffff"
                font.family: Theme.font; font.pixelSize: 16; leftPadding: 40; verticalAlignment: TextInput.AlignVCenter
                background: Rectangle { radius: 14; color: "#161616"; border.width: 1; border.color: search.activeFocus ? "#4dffffff" : "#1fffffff" }
                Text { x: 14; anchors.verticalCenter: parent.verticalCenter; text: "\u{f0349}"; color: "#8a8a8a"; font.family: Theme.font; font.pixelSize: 17 }
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

                Rectangle {   // calculator / command result
                    visible: root.calc !== null || root.query.trim().startsWith(">")
                    width: parent.width; height: 48; radius: 12; color: "#1affffff"
                    Text { x: 16; anchors.verticalCenter: parent.verticalCenter; color: "#f0f0f0"; font.family: Theme.font; font.pixelSize: 15
                        text: root.calc !== null ? "= " + root.calc + "      ⏎ copy" : "run  " + root.query.trim().slice(1) }
                }

                Repeater {
                    model: root.shown
                    Rectangle {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool cur: index === root.sel
                        width: parent.width; height: 48; radius: 12
                        color: cur ? "#1fffffff" : (rm.containsMouse ? "#0fffffff" : "transparent")
                        Behavior on color { ColorAnimation { duration: 90 } }
                        Rectangle { visible: row.cur; x: 0; anchors.verticalCenter: parent.verticalCenter; width: 3; height: 20; radius: 2; color: "#f0f0f0" }
                        Item {
                            id: ic; x: 14; anchors.verticalCenter: parent.verticalCenter; width: 30; height: 30
                            IconImage { id: img; anchors.fill: parent; source: Quickshell.iconPath(row.modelData.icon, true) || Quickshell.iconPath("application-x-executable"); visible: false }
                            MultiEffect { anchors.fill: img; source: img; saturation: -1.0; brightness: row.cur ? 0.08 : -0.05 }
                        }
                        Column {
                            anchors.left: ic.right; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 70
                            Text { width: parent.width; elide: Text.ElideRight; text: row.modelData.name; color: row.cur ? "#ffffff" : "#d0d0d0"; font.family: Theme.font; font.pixelSize: 14 }
                            Text { visible: !!row.modelData.genericName; width: parent.width; elide: Text.ElideRight; text: row.modelData.genericName || ""; color: "#6a6a6a"; font.family: Theme.font; font.pixelSize: 11 }
                        }
                        MouseArea { id: rm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onEntered: root.sel = row.index; onClicked: root.launch(row.modelData) }
                    }
                }
                Text {
                    visible: root.shown.length === 0 && root.calc === null && !root.query.trim().startsWith(">")
                    width: parent.width; height: 48; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    text: "nothing found"; color: "#5a5a5a"; font.family: Theme.font; font.pixelSize: 13
                }
            }
        }
    }
}
