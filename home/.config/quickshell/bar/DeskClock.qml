// Desk clock (Settings → Extras): at night (22:00–08:00), once you've been away 2 minutes, the side screen becomes a
// bedside clock: giant dot-matrix digits made of ASCII characters, the date and the weather, dim and slowly drifting
// so nothing burns in. Any key or mouse move brings your desktop back. The screensaver leaves the side screen to it,
// and at night only the main screen switches off (hypridle), so the clock stays up all night. Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

Scope {
    id: root
    readonly property var screen: Quickshell.screens.find(s => s.name === "DP-2") || null
    property date now: new Date()
    readonly property bool night: { const h = now.getHours(); return h >= 22 || h < 8 }
    property bool preview: false            // qs ipc call deskclock preview: show it for 12 s, any time of day
    readonly property bool on: !!screen && (preview || (Settings.cur("desk_clock") !== false && night && idle.isIdle))
    IpcHandler { target: "deskclock"; function preview(): void { root.preview = true; unpreview.restart() } }
    Timer { id: unpreview; interval: 12000; onTriggered: root.preview = false }
    IdleMonitor { id: idle; enabled: Settings.cur("desk_clock") !== false; timeout: 120; respectInhibitors: true }
    Timer { interval: 1000; repeat: true; running: true; onTriggered: root.now = new Date() }

    // 5×7 digits; "#" lit, "." dark
    readonly property var font: ({
        "0": [".###.", "#...#", "#..##", "#.#.#", "##..#", "#...#", ".###."], "1": ["..#..", ".##..", "..#..", "..#..", "..#..", "..#..", ".###."],
        "2": [".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####"], "3": ["#####", "...#.", "..#..", "...#.", "....#", "#...#", ".###."],
        "4": ["...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#."], "5": ["#####", "#....", "####.", "....#", "....#", "#...#", ".###."],
        "6": ["..##.", ".#...", "#....", "####.", "#...#", "#...#", ".###."], "7": ["#####", "....#", "...#.", "..#..", ".#...", ".#...", ".#..."],
        "8": [".###.", "#...#", "#...#", ".###.", "#...#", "#...#", ".###."], "9": [".###.", "#...#", "#...#", ".####", "....#", "...#.", ".##.."],
        ":": [".", "#", ".", ".", ".", "#", "."] })
    readonly property string hhmm: Qt.formatTime(now, "HH:mm")
    readonly property var cols: {   // the time as columns of the grid: [lit?] per row, with one-column gaps
        const out = []
        for (const ch of hhmm) {
            const g = font[ch]; const w = g[0].length
            for (let x = 0; x < w; x++) out.push(g.map(r => r[x] === "#"))
            out.push([false, false, false, false, false, false, false])
        }
        out.pop(); return out
    }

    PanelWindow {
        visible: root.on || fadeAnim.running
        screen: root.screen
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qsbar-deskclock"
        color: "transparent"
        mask: Region {}   // never takes clicks: moving the mouse ends idle and it fades away by itself

        Rectangle {
            anchors.fill: parent; color: "#000000"
            opacity: root.on ? 1 : 0
            Behavior on opacity { NumberAnimation { id: fadeAnim; duration: 1400; easing.type: Easing.InOutQuad } }

            Item {   // drifts a little every few minutes so nothing burns in
                id: face
                width: grid.width; height: col.implicitHeight
                property int drift: Math.floor(root.now.getMinutes() / 5)
                x: (parent.width - width) / 2 + Math.sin(drift * 1.7) * 60
                y: (parent.height - height) / 2 + Math.cos(drift * 1.3) * 40
                Behavior on x { NumberAnimation { duration: 4000; easing.type: Easing.InOutSine } }
                Behavior on y { NumberAnimation { duration: 4000; easing.type: Easing.InOutSine } }
                opacity: 0.62   // dim: it's night

                Column {
                    id: col
                    spacing: 26
                    Text {
                        text: Qt.formatDate(root.now, "dddd  d MMMM").toUpperCase()
                        color: "#7a7a7a"; font.family: Theme.font; font.pixelSize: 15; font.bold: true; font.letterSpacing: 6
                    }
                    Row {   // the digits: every grid cell is a character; lit cells are bright "@", dark ones a faint dot
                        id: grid
                        spacing: 0
                        Repeater {
                            model: root.cols
                            Column {
                                required property var modelData
                                Repeater {
                                    model: 7
                                    Text {
                                        required property int index
                                        width: 36; height: 46; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                                        readonly property bool lit: parent.modelData[index]
                                        text: lit ? "@" : "·"
                                        color: lit ? "#f2f2f2" : "#1c1c1c"
                                        font.family: Theme.font; font.pixelSize: lit ? 36 : 20; font.bold: lit
                                    }
                                }
                            }
                        }
                    }
                    Row {   // seconds: a row of dots filling up
                        spacing: 6
                        Repeater {
                            model: 30
                            Rectangle { required property int index; width: 4; height: 4; radius: 2
                                        color: index < Math.floor(root.now.getSeconds() / 2) ? "#9a9a9a" : "#1a1a1a" }
                        }
                    }
                    Row {
                        spacing: 18
                        Text { text: Weather.icon; color: "#cfcfcf"; font.family: Theme.font; font.pixelSize: 26; anchors.verticalCenter: parent.verticalCenter }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter; spacing: 3
                            Text { text: Weather.ready ? Weather.temp + "°  " + Weather.desc : ""; color: "#d0d0d0"; font.family: Theme.font; font.pixelSize: 16 }
                            Text { text: Weather.place; color: "#5a5a5a"; font.family: Theme.font; font.pixelSize: 11 }
                        }
                    }
                }
            }
        }
    }
}
