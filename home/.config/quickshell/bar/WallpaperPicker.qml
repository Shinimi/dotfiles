// Wallpaper carousel (SUPER + Y): the picked wallpaper big in the middle, the others turned away in 3D,
// category tabs on top, its colour palette underneath, all over a blurred copy of it.
// ←/→ or scroll browse · Tab category · R random · F favourite · Space apply · Enter apply + close · Esc close.
// Categories come from wallmeta.py (it looks at each picture). Made by Claude.
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root
    required property var screen
    property bool visible: false
    property string target: "DP-1"
    property var all: []                       // [{path, name, thumb, palette, cat, sat, light}]
    property var favs: []
    property string cat: "all"
    readonly property string favFile: Quickshell.env("HOME") + "/.local/state/wall-favs.json"
    readonly property var cats: [["all", "all"], ["mono", "monochrome"], ["dark", "dark"], ["light", "light"], ["colour", "colour"], ["fav", "favourites"]]
    readonly property var list: cat === "all" ? all : cat === "fav" ? all.filter(w => favs.indexOf(w.path) >= 0) : all.filter(w => w.cat === cat)
    readonly property var cur: list.length ? list[Math.max(0, Math.min(pv.currentIndex, list.length - 1))] : null
    property string flash: ""

    function toggle() { visible = !visible }
    onVisibleChanged: if (visible) { PopupState.current = root; scan.running = true; loadFavs.running = true }
    Connections { target: PopupState; function onCurrentChanged() { if (PopupState.current !== root) root.visible = false } }
    IpcHandler { target: "wallpaper"; function toggle(): void { root.toggle() } }

    Process {
        id: scan
        command: ["python3", "-I", Quickshell.env("HOME") + "/.config/quickshell/bar/wallmeta.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.all = JSON.parse(this.text) } catch (e) { return }
                root.jumpToCurrent()
            }
        }
    }
    Process { id: loadFavs; command: ["cat", root.favFile]
              stdout: StdioCollector { onStreamFinished: { try { root.favs = JSON.parse(this.text) } catch (e) { root.favs = [] } } } }
    function toggleFav() {
        if (!cur) return
        const f = favs.slice(), i = f.indexOf(cur.path)
        if (i >= 0) f.splice(i, 1); else f.push(cur.path)
        favs = f
        Quickshell.execDetached(["sh", "-c", "mkdir -p ~/.local/state && printf '%s' \"$1\" > \"$2\"", "sh", JSON.stringify(f), favFile])
    }
    function jumpToCurrent() {
        const now = Settings.cur(target === "DP-2" ? "wall_side" : "wall_main")
        const i = list.findIndex(w => w.path === now)
        pv.currentIndex = Math.max(0, i)
    }
    function setCat(c) { cat = c; Qt.callLater(jumpToCurrent) }
    function apply(close) {
        if (!cur) return
        const p = cur.path
        Quickshell.execDetached(["qs", "ipc", "-p", Quickshell.env("HOME") + "/.config/quickshell/bar", "call", "curtain", "wall", target, p])
        if (target !== "DP-2") Settings.setNow("wall_main", p)
        if (target !== "DP-1") Settings.setNow("wall_side", p)
        flash = "applied to " + (target === "both" ? "both screens" : target === "DP-1" ? "main screen" : "side screen")
        flashTimer.restart()
        if (close) visible = false
    }
    Timer { id: flashTimer; interval: 1600; onTriggered: root.flash = "" }

    PanelWindow {
        visible: root.visible; screen: root.screen
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qsbar-wallpapers"
        WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "#000000"

        // ---------- backdrop: the selected wallpaper, blurred and dimmed ----------
        Image { id: bgImg; anchors.fill: parent; source: root.cur ? "file://" + root.cur.thumb : ""; fillMode: Image.PreserveAspectCrop; visible: false; asynchronous: true }
        MultiEffect { anchors.fill: parent; source: bgImg; blurEnabled: true; blur: 1.0; blurMax: 64; brightness: -0.42; saturation: -0.2 }
        Rectangle { anchors.fill: parent; gradient: Gradient {
            GradientStop { position: 0.0; color: "#99000000" } GradientStop { position: 0.45; color: "#22000000" } GradientStop { position: 1.0; color: "#cc000000" } } }
        MouseArea { anchors.fill: parent; onClicked: root.visible = false }

        // ---------- categories ----------
        Row {
            anchors.horizontalCenter: parent.horizontalCenter; y: 70; spacing: 6
            Repeater {
                model: root.cats
                Rectangle {
                    required property var modelData
                    readonly property bool on: root.cat === modelData[0]
                    readonly property int n: modelData[0] === "all" ? root.all.length : modelData[0] === "fav" ? root.favs.length
                                             : root.all.filter(w => w.cat === modelData[0]).length
                    width: cl.implicitWidth + 30; height: 32; radius: 16
                    color: on ? "#2effffff" : (cm.containsMouse ? "#14ffffff" : "transparent")
                    border.width: on ? 1 : 0; border.color: "#33ffffff"
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Text { id: cl; anchors.centerIn: parent; text: modelData[1] + "  " + n; color: on ? "#ffffff" : "#9a9a9a"
                           font.family: Theme.font; font.pixelSize: 12; font.letterSpacing: 0.5 }
                    MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.setCat(modelData[0]) }
                }
            }
        }
        // which screen it goes on
        Row {
            anchors.right: parent.right; anchors.rightMargin: 60; y: 70; spacing: 6
            Repeater {
                model: [["DP-1", "main"], ["DP-2", "side"], ["both", "both"]]
                Rectangle {
                    required property var modelData
                    readonly property bool on: root.target === modelData[0]
                    width: 62; height: 32; radius: 16
                    color: on ? Theme.on : (sm.containsMouse ? "#14ffffff" : "#0affffff"); border.width: 1; border.color: "#1fffffff"
                    Text { anchors.centerIn: parent; text: modelData[1]; color: on ? Theme.onText : "#9a9a9a"; font.family: Theme.font; font.pixelSize: 11 }
                    MouseArea { id: sm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { root.target = modelData[0]; root.jumpToCurrent() } }
                }
            }
        }

        // ---------- the carousel ----------
        PathView {
            id: pv
            anchors.left: parent.left; anchors.right: parent.right
            y: parent.height * 0.5 - 300; height: 600
            model: root.list
            pathItemCount: Math.min(9, root.list.length)
            preferredHighlightBegin: 0.5; preferredHighlightEnd: 0.5
            highlightRangeMode: PathView.StrictlyEnforceRange
            highlightMoveDuration: 420
            snapMode: PathView.SnapOneItem
            interactive: false
            focus: root.visible
            readonly property real cx: width / 2
            readonly property real cy: height / 2
            path: Path {
                startX: -pv.width * 0.06; startY: pv.cy
                PathAttribute { name: "rot"; value: 70 }  PathAttribute { name: "sc"; value: 0.5 }  PathAttribute { name: "zz"; value: 0 }  PathAttribute { name: "op"; value: 0.0 }
                PathLine { x: pv.cx - 620; y: pv.cy }
                PathAttribute { name: "rot"; value: 58 }  PathAttribute { name: "sc"; value: 0.64 } PathAttribute { name: "zz"; value: 2 }  PathAttribute { name: "op"; value: 0.55 }
                PathLine { x: pv.cx - 470; y: pv.cy }
                PathAttribute { name: "rot"; value: 46 }  PathAttribute { name: "sc"; value: 0.76 } PathAttribute { name: "zz"; value: 5 }  PathAttribute { name: "op"; value: 0.9 }
                PathLine { x: pv.cx; y: pv.cy }
                PathAttribute { name: "rot"; value: 0 }   PathAttribute { name: "sc"; value: 1.0 }  PathAttribute { name: "zz"; value: 10 } PathAttribute { name: "op"; value: 1.0 }
                PathLine { x: pv.cx + 470; y: pv.cy }
                PathAttribute { name: "rot"; value: -46 } PathAttribute { name: "sc"; value: 0.76 } PathAttribute { name: "zz"; value: 5 }  PathAttribute { name: "op"; value: 0.9 }
                PathLine { x: pv.cx + 620; y: pv.cy }
                PathAttribute { name: "rot"; value: -58 } PathAttribute { name: "sc"; value: 0.64 } PathAttribute { name: "zz"; value: 2 }  PathAttribute { name: "op"; value: 0.55 }
                PathLine { x: pv.width * 1.06; y: pv.cy }
                PathAttribute { name: "rot"; value: -70 } PathAttribute { name: "sc"; value: 0.5 }  PathAttribute { name: "zz"; value: 0 }  PathAttribute { name: "op"; value: 0.0 }
            }
            delegate: Item {
                id: card
                required property var modelData
                required property int index
                readonly property bool isCur: PathView.isCurrentItem
                readonly property real rot: PathView.rot
                width: 760; height: 428
                scale: PathView.sc; z: PathView.zz; opacity: PathView.op
                transform: Rotation { origin.x: card.width / 2; origin.y: card.height / 2; axis { x: 0; y: 1; z: 0 } angle: card.rot }
                Rectangle {
                    anchors.fill: parent; radius: 14; color: "#111111"; clip: true
                    border.width: 1; border.color: card.isCur ? "#66ffffff" : "#22ffffff"
                    Image { anchors.fill: parent; anchors.margins: 1; source: "file://" + card.modelData.thumb; fillMode: Image.PreserveAspectCrop; asynchronous: true }
                    Image {   // full-quality picture for the one in the middle
                        anchors.fill: parent; anchors.margins: 1; visible: card.isCur && status === Image.Ready
                        source: card.isCur ? "file://" + card.modelData.path : ""; sourceSize.width: 1520
                        fillMode: Image.PreserveAspectCrop; asynchronous: true
                    }
                    Rectangle {   // favourite mark
                        visible: root.favs.indexOf(card.modelData.path) >= 0
                        anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 12
                        width: 30; height: 30; radius: 15; color: "#cc000000"
                        Text { anchors.centerIn: parent; text: "\u{f04ce}"; color: "#ffffff"; font.family: Theme.font; font.pixelSize: 14 }
                    }
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: card.isCur ? root.apply(false) : pv.currentIndex = card.index
                }
            }
            WheelHandler { onWheel: e => e.angleDelta.y < 0 || e.angleDelta.x < 0 ? pv.incrementCurrentIndex() : pv.decrementCurrentIndex() }
            Keys.onPressed: e => {
                const k = e.key
                if (k === Qt.Key_Escape) root.visible = false
                else if (k === Qt.Key_Right || k === Qt.Key_L) pv.incrementCurrentIndex()
                else if (k === Qt.Key_Left || k === Qt.Key_H) pv.decrementCurrentIndex()
                else if (k === Qt.Key_Tab || k === Qt.Key_Backtab) {
                    const i = root.cats.findIndex(c => c[0] === root.cat), d = k === Qt.Key_Backtab ? -1 : 1
                    root.setCat(root.cats[(i + d + root.cats.length) % root.cats.length][0])
                }
                else if (k === Qt.Key_R && root.list.length) pv.currentIndex = Math.floor(Math.random() * root.list.length)
                else if (k === Qt.Key_F) root.toggleFav()
                else if (k === Qt.Key_Space) root.apply(false)
                else if (k === Qt.Key_Return || k === Qt.Key_Enter) root.apply(true)
                else return
                e.accepted = true
            }
        }

        // ---------- name, palette, position ----------
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            y: pv.y + pv.height + 14; spacing: 12
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.cur ? root.cur.name.replace(/[-_]/g, " ").toLowerCase() : (root.cat === "fav" ? "no favourites yet · press F on one you like" : "")
                color: "#f0f0f0"; font.family: Theme.font; font.pixelSize: 15; font.letterSpacing: 1
            }
            Canvas {   // the palette as one soft gradient
                id: strip
                anchors.horizontalCenter: parent.horizontalCenter
                width: 440; height: 6
                property var pal: root.cur ? root.cur.palette : []
                onPalChanged: requestPaint()
                onPaint: {
                    const c = getContext("2d"); c.reset()
                    if (!pal.length) return
                    const g = c.createLinearGradient(0, 0, width, 0)
                    pal.forEach((h, i) => g.addColorStop(pal.length > 1 ? i / (pal.length - 1) : 0, h))
                    c.fillStyle = g; c.beginPath(); c.roundedRect(0, 0, width, height, 3, 3); c.fill()
                }
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter; spacing: 26
                Repeater {
                    model: root.cur ? root.cur.palette : []
                    Row {
                        required property string modelData
                        spacing: 6
                        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 9; height: 9; radius: 5; color: modelData; border.width: 1; border.color: "#33ffffff" }
                        Text { text: modelData.toUpperCase(); color: "#8a8a8a"; font.family: Theme.font; font.pixelSize: 11 }
                    }
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.flash !== "" ? "\u{f012c}  " + root.flash : (root.list.length ? (pv.currentIndex + 1) + " / " + root.list.length : "")
                color: root.flash !== "" ? "#ffffff" : "#5a5a5a"; font.family: Theme.font; font.pixelSize: 11
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 46
            text: "←  →  browse    tab  category    r  random    f  favourite    space  apply    enter  apply & close    esc"
            color: "#4a4a4a"; font.family: Theme.font; font.pixelSize: 11
        }
    }
}
