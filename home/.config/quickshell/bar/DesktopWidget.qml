// Desktop clock on the wallpaper (behind windows): time, date, weather and today's line.
// On/off and position in Settings → Bar & notifications. Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris

PanelWindow {
    id: w
    required property var modelData
    screen: modelData
    readonly property string pos: Settings.cur("desktop_clock_pos")
    visible: Settings.cur("desktop_clock")
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "qsbar-desktop"
    color: "transparent"
    anchors { left: pos !== "center"; bottom: pos !== "center"; top: pos === "center" }
    margins { left: 64; bottom: 72; top: 170 }
    implicitWidth: pos === "center" ? (screen ? screen.width : 2560) : 640
    implicitHeight: body.implicitHeight + 20

    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) || null
    SystemClock { id: clk; precision: SystemClock.Minutes }

    Column {
        id: body
        anchors.horizontalCenter: w.pos === "center" ? parent.horizontalCenter : undefined
        x: w.pos === "center" ? 0 : 0
        spacing: 4

        Text {   // time with a soft accent glow
            anchors.horizontalCenter: w.pos === "center" ? parent.horizontalCenter : undefined
            text: Qt.formatDateTime(clk.date, Settings.cur("clock_12h") ? "h:mm" : "HH:mm")
            font.family: Theme.font; font.pixelSize: 132; font.weight: Font.Black
            color: Theme.fg
            style: Text.Raised; styleColor: Qt.rgba(0.88, 0.88, 0.88, 0.35)
        }
        Text {
            anchors.horizontalCenter: w.pos === "center" ? parent.horizontalCenter : undefined
            text: Qt.formatDateTime(clk.date, "dddd, d MMMM").toLowerCase()
            font.family: Theme.font; font.pixelSize: 26; font.letterSpacing: 2
            color: Theme.blue; style: Text.Raised; styleColor: "#aa000000"
        }
        Text {
            visible: Weather.ready
            anchors.horizontalCenter: w.pos === "center" ? parent.horizontalCenter : undefined
            topPadding: 6
            text: Weather.icon + "  " + Weather.temp + "°  " + Weather.desc.toLowerCase() + "  ·  " + (Weather.place || "")
            font.family: Theme.font; font.pixelSize: 17
            color: Theme.fgDim; style: Text.Raised; styleColor: "#aa000000"
        }
        Text {   // today's line
            anchors.horizontalCenter: w.pos === "center" ? parent.horizontalCenter : undefined
            topPadding: 2
            text: "— " + Journey.today()
            font.family: Theme.font; font.pixelSize: 14; font.italic: true; font.letterSpacing: 1
            color: Theme.muted; style: Text.Raised; styleColor: "#aa000000"
        }
    }
}
