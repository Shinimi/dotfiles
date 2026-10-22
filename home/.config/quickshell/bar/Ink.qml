// Ink (SUPER + D): draw on top of everything — explain something, mark up a screenshot.
// Left drag = white pen · right drag = red marker · scroll = pen size · Ctrl+Z undo · C clear
// Ctrl+S saves a screenshot with your drawing (and copies it) · Esc closes. Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root
    required property var screen
    property bool visible: false
    property var strokes: []          // [{ c, w, pts: [x, y, x, y, ...] }]
    property var cur: null
    property real penW: 4
    property bool saving: false
    function toggle() { visible = !visible; if (visible) { strokes = []; cur = null } }
    IpcHandler { target: "ink"; function toggle(): void { root.toggle() } }

    PanelWindow {
        visible: root.visible; screen: root.screen
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qsbar-ink"
        WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "#0d000000"            // a whisper of tint so you can tell ink mode is on

        Canvas {
            id: cv
            anchors.fill: parent
            renderStrategy: Canvas.Threaded
            function drawStroke(c, s) {
                const p = s.pts; if (p.length < 2) return
                c.strokeStyle = s.c; c.lineWidth = s.w; c.lineCap = "round"; c.lineJoin = "round"
                c.beginPath(); c.moveTo(p[0], p[1])
                if (p.length === 2) c.lineTo(p[0] + 0.1, p[1])
                for (let i = 2; i + 3 < p.length; i += 2)   // smooth: curve through midpoints
                    c.quadraticCurveTo(p[i], p[i + 1], (p[i] + p[i + 2]) / 2, (p[i + 1] + p[i + 3]) / 2)
                if (p.length >= 4) c.lineTo(p[p.length - 2], p[p.length - 1])
                c.stroke()
            }
            onPaint: {
                const c = getContext("2d"); c.clearRect(0, 0, width, height)
                c.shadowColor = "rgba(0,0,0,0.45)"; c.shadowBlur = 6
                for (const s of root.strokes) drawStroke(c, s)
                if (root.cur) drawStroke(c, root.cur)
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.CrossCursor
            onPressed: m => root.cur = { c: m.button === Qt.RightButton ? "#e05555" : "#f4f4f4",
                                          w: m.button === Qt.RightButton ? root.penW * 2.5 : root.penW, pts: [m.x, m.y] }
            onPositionChanged: m => { if (!root.cur) return; root.cur.pts.push(m.x, m.y); cv.requestPaint() }
            onReleased: { if (!root.cur) return; root.strokes = root.strokes.concat([root.cur]); root.cur = null; cv.requestPaint() }
            onWheel: w => root.penW = Math.max(2, Math.min(24, root.penW + (w.angleDelta.y > 0 ? 1 : -1)))
        }

        Item {
            anchors.fill: parent; focus: root.visible
            Keys.onPressed: e => {
                if (e.key === Qt.Key_Escape) root.visible = false
                else if (e.key === Qt.Key_Z && (e.modifiers & Qt.ControlModifier)) { root.strokes = root.strokes.slice(0, -1); cv.requestPaint() }
                else if (e.key === Qt.Key_C) { root.strokes = []; cv.requestPaint() }
                else if (e.key === Qt.Key_S && (e.modifiers & Qt.ControlModifier)) { root.saving = true; shot.restart() }
            }
        }
        Timer {   // wait one frame so the hint is gone from the screenshot
            id: shot; interval: 120
            onTriggered: {
                Quickshell.execDetached(["sh", "-c", "d=~/Pictures/Screenshots; mkdir -p $d; f=$d/ink-$(date +%Y%m%d-%H%M%S).png; grim -o " + root.screen.name +
                    " \"$f\" && wl-copy < \"$f\" && ~/.local/bin/kocho-sound.sh screen-capture && notify-send -h boolean:suppress-sound:true -i \"$f\" 'Ink saved' \"$(basename $f) · copied\""])
                after.restart()
            }
        }
        Timer { id: after; interval: 400; onTriggered: root.saving = false }

        Rectangle {   // hint pill
            visible: !root.saving
            anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 36
            width: hint.implicitWidth + 36; height: 38; radius: 19
            color: Theme.island; border.width: 1; border.color: "#16ffffff"
            Row {
                id: hint; anchors.centerIn: parent; spacing: 14
                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: root.penW + 4; height: width; radius: width / 2; color: "#f4f4f4" }
                Label { text: "left pen  ·  right marker  ·  scroll size  ·  ctrl+z undo  ·  c clear  ·  ctrl+s save  ·  esc"
                        color: Theme.fgDim; font.pixelSize: 11; font.weight: Font.Normal; anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }
}
