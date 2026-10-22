// Clipboard history (SUPER + V): text and pictures, newest first, with pins at the top that survive a wipe.
// ↑↓ choose · Enter paste · P pin/unpin · Del delete (undo for 6 s) · Tab all/text/images · Esc close.
// Made by Claude.
import QtQuick
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root
    required property var screen
    property bool visible: false
    property var items: []                     // history: {id, img, path, text}
    property var pins: []                      // pinned: {img, path, text}
    property string query: ""
    property string kind: "all"                // all | text | img
    property int sel: 0
    property var pendingDelete: null           // history item waiting to be deleted (undo window)
    readonly property string helper: Qt.resolvedUrl("clip.sh").toString().replace("file://", "")
    readonly property string pinFile: Quickshell.env("HOME") + "/.local/state/clip-pins.json"
    function keep(x) {
        const q = query.trim().toLowerCase()
        return (kind === "all" || (kind === "img") === !!x.img) && (!q || x.text.toLowerCase().indexOf(q) >= 0)
    }
    // one list: pins first (marked), then the history minus anything already pinned or waiting to be deleted
    readonly property var shown: pins.filter(keep).map(x => Object.assign({ pinned: true }, x))
        .concat(items.filter(x => keep(x) && !(pendingDelete && pendingDelete.id === x.id)
                                  && !pins.some(p => !p.img && !x.img && p.text === x.text)))
    onShownChanged: sel = Math.min(sel, Math.max(0, shown.length - 1))

    function toggle() { visible = !visible }
    onVisibleChanged: if (visible) { query = ""; sel = 0; kind = "all"; PopupState.current = root; load.running = true; loadPins.running = true }
    Connections { target: PopupState; function onCurrentChanged() { if (PopupState.current !== root) root.visible = false } }
    IpcHandler { target: "clipboard"; function toggle(): void { root.toggle() } }

    Process {
        id: load
        command: [root.helper, "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                for (const l of this.text.split("\n")) {
                    const p = l.split("\t"); if (p.length < 4) continue
                    out.push({ id: p[0], img: p[1] === "1", path: p[2], text: p.slice(3).join("\t") })
                }
                root.items = out
            }
        }
    }
    Process { id: loadPins; command: ["cat", root.pinFile]
              stdout: StdioCollector { onStreamFinished: { try { root.pins = JSON.parse(this.text) } catch (e) { root.pins = [] } } } }
    function savePins() { Quickshell.execDetached(["sh", "-c", "mkdir -p ~/.local/state && printf '%s' \"$1\" > \"$2\"", "sh", JSON.stringify(pins), pinFile]) }
    Process {   // copies a picture into the pin folder so it outlives the history
        id: pinImg
        property string src: ""
        command: [root.helper, "pinimg", src]
        stdout: StdioCollector { onStreamFinished: { const f = this.text.trim(); if (f) { root.pins = [{ img: true, path: f, text: "pinned image" }].concat(root.pins); root.savePins() } } }
    }
    function togglePin(it) {
        if (!it) return
        if (it.pinned) { pins = pins.filter(p => !(p.text === it.text && p.path === it.path)); savePins(); return }
        if (it.img) { pinImg.src = it.path; pinImg.running = true }
        else { pins = [{ img: false, path: "", text: it.text }].concat(pins); savePins() }
    }
    function paste(it) {
        if (!it) return
        root.visible = false
        if (it.pinned) Quickshell.execDetached(it.img ? [helper, "pastefile", it.path] : [helper, "pastetext", it.text])
        else Quickshell.execDetached([helper, "paste", it.id])
    }
    function remove(it) {
        if (!it) return
        if (it.pinned) { togglePin(it); return }
        commitDelete()
        pendingDelete = it; undoTimer.restart()
    }
    function commitDelete() { if (pendingDelete) { Quickshell.execDetached([helper, "delete", pendingDelete.id]); items = items.filter(x => x.id !== pendingDelete.id); pendingDelete = null } }
    Timer { id: undoTimer; interval: 6000; onTriggered: root.commitDelete() }
    function stepKind() { kind = kind === "all" ? "text" : kind === "text" ? "img" : "all" }

    PanelWindow {
        visible: root.visible; screen: root.screen
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "qsbar-dismiss"
        color: "#66000000"
        MouseArea { anchors.fill: parent; onClicked: root.visible = false }
    }

    PanelWindow {
        visible: root.visible; screen: root.screen
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qsbar-clipboard"
        WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "transparent"
        implicitWidth: 620; implicitHeight: 680

        Rectangle {
            anchors.fill: parent; radius: 3; color: Theme.mix(Qt.rgba(0.035, 0.035, 0.035, 0.95), Theme.tint, 0.07 * Theme.tintOn)
            border.width: 1; border.color: "#3dffffff"

            Row {
                id: head; x: 20; y: 16; spacing: 12
                Text { text: "CLIPBOARD"; color: "#f2f2f2"; font.family: Theme.font; font.pixelSize: 13; font.letterSpacing: 4; font.bold: true }
                Text { text: "//"; color: "#454545"; font.family: Theme.font; font.pixelSize: 13 }
                Text { text: "履歴"; color: "#7a7a7a"; font.family: "Noto Sans CJK JP"; font.pixelSize: 13 }
            }
            Row {
                anchors.right: parent.right; anchors.rightMargin: 16; y: 12; spacing: 4
                Repeater {
                    model: [["all", "ALL"], ["text", "TEXT"], ["img", "IMAGES"]]
                    Rectangle {
                        required property var modelData
                        readonly property bool on: root.kind === modelData[0]
                        width: kl.implicitWidth + 18; height: 24; radius: 2
                        color: on ? Theme.on : (km.containsMouse ? "#14ffffff" : "transparent"); border.width: 1; border.color: on ? Theme.on : "#33ffffff"
                        Text { id: kl; anchors.centerIn: parent; text: modelData[1]; color: on ? Theme.onText : "#a0a0a0"; font.family: Theme.font; font.pixelSize: 9; font.letterSpacing: 1.5; font.bold: on }
                        MouseArea { id: km; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.kind = modelData[0] }
                    }
                }
            }
            Rectangle { x: 1; y: 50; width: parent.width - 2; height: 1; color: "#26ffffff" }

            TextField {
                id: search
                x: 16; y: 64; width: parent.width - 32; height: 40
                focus: root.visible
                Connections { target: root; function onVisibleChanged() { if (root.visible) { search.text = ""; search.forceActiveFocus() } } }
                onTextChanged: root.query = text
                placeholderText: "search clipboard…"; placeholderTextColor: "#555555"
                color: "#f0f0f0"; font.family: Theme.font; font.pixelSize: 13; leftPadding: 28
                background: Rectangle { radius: 2; color: "#0cffffff"; border.width: 1; border.color: search.activeFocus ? "#77ffffff" : "#26ffffff"
                                        Rectangle { width: 2; height: parent.height; color: "#ffffff" } }
                Text { x: 11; anchors.verticalCenter: parent.verticalCenter; text: "›"; color: "#9a9a9a"; font.family: Theme.font; font.pixelSize: 15 }
                Keys.onEscapePressed: root.visible = false
                Keys.onReturnPressed: root.paste(root.shown[root.sel])
                Keys.onEnterPressed: root.paste(root.shown[root.sel])
                Keys.onDownPressed: { root.sel = Math.min(root.sel + 1, root.shown.length - 1); list.positionViewAtIndex(root.sel, ListView.Contain) }
                Keys.onUpPressed: { root.sel = Math.max(root.sel - 1, 0); list.positionViewAtIndex(root.sel, ListView.Contain) }
                Keys.onDeletePressed: root.remove(root.shown[root.sel])
                Keys.onTabPressed: root.stepKind()
                Keys.onPressed: e => { if (e.key === Qt.Key_P && search.text === "") { root.togglePin(root.shown[root.sel]); e.accepted = true } }
            }

            ListView {
                id: list
                x: 16; y: 116; width: parent.width - 32; height: parent.height - y - foot.height - 8
                clip: true; spacing: 4
                model: root.shown
                boundsBehavior: Flickable.StopAtBounds
                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool current: index === root.sel
                    width: list.width
                    height: modelData.img ? 112 : Math.min(78, txt.implicitHeight + 26)
                    radius: 2
                    color: current ? "#1cffffff" : (rowMouse.containsMouse ? "#0affffff" : "transparent")
                    border.width: 1; border.color: current ? "#66ffffff" : "#1affffff"
                    Rectangle { visible: row.current; width: 2; height: parent.height; color: "#ffffff" }
                    MouseArea {
                        id: rowMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onContainsMouseChanged: if (containsMouse) root.sel = row.index
                        onClicked: root.paste(row.modelData)
                    }
                    Text { x: 10; y: 12; text: row.modelData.pinned ? "\u{f0403}" : String(row.index + 1).padStart(2, "0")
                           color: row.modelData.pinned ? "#ffffff" : "#4a4a4a"; font.family: Theme.font; font.pixelSize: row.modelData.pinned ? 12 : 10 }
                    Text {
                        id: txt
                        visible: !row.modelData.img
                        anchors { left: parent.left; right: tools.left; verticalCenter: parent.verticalCenter; leftMargin: 38; rightMargin: 8 }
                        text: row.modelData.text
                        color: "#e8e8e8"; font.family: Theme.font; font.pixelSize: 12
                        wrapMode: Text.WrapAnywhere; maximumLineCount: 3; elide: Text.ElideRight
                    }
                    Rectangle {
                        visible: row.modelData.img
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom; leftMargin: 38; topMargin: 8; bottomMargin: 8 }
                        width: 170; radius: 1; color: "#0cffffff"; clip: true; border.width: 1; border.color: "#1affffff"
                        Image {
                            anchors.fill: parent; anchors.margins: 2
                            source: row.modelData.img ? "file://" + row.modelData.path : ""
                            fillMode: Image.PreserveAspectFit; asynchronous: true; cache: false
                            sourceSize.width: 340
                        }
                    }
                    Text {
                        visible: row.modelData.img
                        anchors { left: parent.left; leftMargin: 222; verticalCenter: parent.verticalCenter }
                        text: "IMAGE\n" + row.modelData.text
                        color: "#8a8a8a"; font.family: Theme.font; font.pixelSize: 10; lineHeight: 1.4
                    }
                    Row {
                        id: tools
                        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        spacing: 2
                        opacity: rowMouse.containsMouse || row.current || pinM.containsMouse || delM.containsMouse ? 1 : 0
                        Rectangle {
                            width: 28; height: 28; radius: 2; color: pinM.containsMouse ? "#1fffffff" : "transparent"
                            Text { anchors.centerIn: parent; text: row.modelData.pinned ? "\u{f0404}" : "\u{f0403}"; color: pinM.containsMouse || row.modelData.pinned ? "#ffffff" : "#7a7a7a"
                                   font.family: Theme.font; font.pixelSize: 14 }
                            MouseArea { id: pinM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.togglePin(row.modelData) }
                        }
                        Rectangle {
                            width: 28; height: 28; radius: 2; color: delM.containsMouse ? "#1fffffff" : "transparent"
                            Text { anchors.centerIn: parent; text: "\u{f0156}"; color: delM.containsMouse ? "#ffffff" : "#7a7a7a"; font.family: Theme.font; font.pixelSize: 14 }
                            MouseArea { id: delM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.remove(row.modelData) }
                        }
                    }
                }
                Text {
                    anchors.centerIn: parent; visible: root.shown.length === 0
                    text: root.items.length || root.pins.length ? "nothing matches" : "copy something and it shows up here"
                    color: "#4a4a4a"; font.family: Theme.font; font.pixelSize: 12
                }
            }

            Item {
                id: foot
                anchors.bottom: parent.bottom; width: parent.width; height: 44
                Rectangle { x: 1; width: parent.width - 2; height: 1; color: "#26ffffff" }
                Rectangle {
                    visible: root.pendingDelete !== null
                    x: 16; anchors.verticalCenter: parent.verticalCenter
                    width: ul.implicitWidth + 22; height: 26; radius: 2; color: Theme.on
                    Text { id: ul; anchors.centerIn: parent; text: "DELETED · UNDO"; color: Theme.onText; font.family: Theme.font; font.pixelSize: 9; font.letterSpacing: 1.5; font.bold: true }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { undoTimer.stop(); root.pendingDelete = null } }
                }
                Text {
                    visible: root.pendingDelete === null
                    x: 18; anchors.verticalCenter: parent.verticalCenter
                    text: "enter paste   p pin   del delete   tab filter   esc"
                    color: "#4a4a4a"; font.family: Theme.font; font.pixelSize: 10
                }
                Rectangle {
                    visible: root.items.length > 0
                    anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter
                    width: wl.implicitWidth + 22; height: 26; radius: 2
                    color: wm.containsMouse ? "#14ffffff" : "transparent"; border.width: 1; border.color: "#33ffffff"
                    Text { id: wl; anchors.centerIn: parent; text: wm.armed ? "CLICK AGAIN" : "CLEAR HISTORY"; color: wm.armed ? "#ffffff" : "#a0a0a0"
                           font.family: Theme.font; font.pixelSize: 9; font.letterSpacing: 1.5 }
                    MouseArea {
                        id: wm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        property bool armed: false
                        Timer { id: wDisarm; interval: 3000; onTriggered: wm.armed = false }
                        onClicked: { if (!armed) { armed = true; wDisarm.restart(); return }
                                     armed = false; root.items = []; Quickshell.execDetached([root.helper, "wipe"]) }   // pins stay
                    }
                }
            }
        }
    }
}
