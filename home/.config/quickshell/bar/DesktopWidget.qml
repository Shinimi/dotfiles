// Desktop clock on the wallpaper (behind windows): time, date, weather, now playing.
// On/off and position in Settings → Bar & notifications. Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Mpris

PanelWindow {
    id: w
    required property var screen
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
    property string art: ""
    readonly property string liveArt: player ? (player.trackArtUrl || "") : ""
    onLiveArtChanged: if (liveArt !== "") art = liveArt   // never hand Image an empty source (Qt 6.12 crash)
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
            style: Text.Raised; styleColor: Qt.rgba(0.64, 0.54, 0.91, 0.35)
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
        Item { width: 1; height: 14 }
        Rectangle {   // now playing
            visible: w.player !== null
            anchors.horizontalCenter: w.pos === "center" ? parent.horizontalCenter : undefined
            width: Math.min(560, np.implicitWidth + 24); height: 64; radius: 16
            color: Qt.rgba(0.05, 0.05, 0.07, 0.55); border.width: 1; border.color: "#22efeaf8"
            Row {
                id: np
                x: 10; anchors.verticalCenter: parent.verticalCenter; spacing: 12
                ClippingRectangle {
                    width: 44; height: 44; radius: 10; color: Theme.bgAlt
                    Image { anchors.fill: parent; source: w.art; fillMode: Image.PreserveAspectCrop; asynchronous: true; visible: w.art !== "" }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Text { width: Math.min(implicitWidth, 470); elide: Text.ElideRight; text: w.player ? w.player.trackTitle : ""; color: Theme.fg; font.family: Theme.font; font.pixelSize: 14; font.bold: true }
                    Text { width: Math.min(implicitWidth, 470); elide: Text.ElideRight; text: w.player ? (w.player.trackArtist || w.player.identity) : ""; color: Theme.green; font.family: Theme.font; font.pixelSize: 12 }
                }
            }
        }
    }
}
