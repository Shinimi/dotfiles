// A picture redrawn as glowing ASCII characters, with a slow wave of light and rising motes, plus a soft glow.
// Used by the screensaver and the (optional) ASCII desktop wallpaper. Animates at 20 fps only while `running`.
// Made by Claude.
import QtQuick
import QtQuick.Effects

Item {
    id: v
    property string source: ""                 // image path
    property bool running: true
    readonly property size cell: Qt.size(9, 16)
    readonly property bool ready: srcImg.status === Image.Ready
    // the real sky outside (Weather): 0 day … 1 night, easing an hour either side of sunrise and sunset
    property real night: 0
    function updateNight() {
        const now = new Date(), key = Qt.formatDate(now, "yyyy-MM-dd"), w = Weather.week[key]
        const toMin = t => { const p = (t || "").split(":").map(Number); return p.length === 2 ? p[0] * 60 + p[1] : -1 }
        let rise = w ? toMin(w.sunrise) : 6 * 60, set = w ? toMin(w.sunset) : 18 * 60 + 30
        if (rise < 0) rise = 6 * 60; if (set < 0) set = 18 * 60 + 30
        const m = now.getHours() * 60 + now.getMinutes()
        const ease = x => Math.max(0, Math.min(1, x))
        night = m < rise ? ease((rise + 40 - m) / 80) : m > set ? ease((m - set + 40) / 80) : ease(Math.max((rise + 40 - m), (m - set + 40)) / 80)
    }
    Timer { interval: 60000; repeat: true; running: v.visible; triggeredOnStart: true; onTriggered: v.updateNight() }

    Image {   // the picture, one pixel per character cell
        id: srcImg
        source: v.source ? "file://" + v.source : ""
        sourceSize.width: Math.ceil(v.width / v.cell.width) * 2
        sourceSize.height: Math.ceil(v.height / v.cell.height) * 2
        fillMode: Image.PreserveAspectCrop
        width: sourceSize.width; height: sourceSize.height
        visible: false; asynchronous: true; smooth: true
    }
    ShaderEffectSource { id: srcTex; sourceItem: srcImg; hideSource: true; live: false; smooth: true
                         Connections { target: srcImg; function onStatusChanged() { if (srcImg.status === Image.Ready) srcTex.scheduleUpdate() } } }

    Row {   // character atlas, dim → bright
        id: atlasRow
        readonly property string chars: " .`:-=+*cox%#@"
        visible: false
        Repeater {
            model: atlasRow.chars.length
            Text {
                required property int index
                width: v.cell.width; height: v.cell.height
                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                text: atlasRow.chars[index]; color: "#ffffff"
                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; font.weight: Font.Bold
            }
        }
    }
    ShaderEffectSource { id: atlasTex; sourceItem: atlasRow; hideSource: true; live: false; smooth: true }

    MultiEffect {   // soft glow under the characters
        anchors.fill: parent; source: fx
        blurEnabled: true; blur: 0.55; blurMax: 32; brightness: 0.05; opacity: 0.85
    }
    ShaderEffect {
        id: fx
        anchors.fill: parent
        property real time: 0
        property real glyphs: atlasRow.chars.length
        property real bright: 0.95
        property size res: Qt.size(width, height)
        property size cell: v.cell
        property color tintc: Theme.tintOn ? Theme.mix(Qt.color("#ffffff"), Theme.tint, 0.55) : "#ffffff"
        property real rain: 0   // off: rain streaks were distracting
        property real snow: 0
        property real wind: Math.min(1, Weather.wind / 40)
        property real night: v.night
        property real fog: Weather.fog
        property variant src: srcTex
        property variant atlas: atlasTex
        fragmentShader: Qt.resolvedUrl("shaders/ascii.frag.qsb")
        Timer { interval: 50; repeat: true; running: v.running && v.visible; onTriggered: parent.time += 0.05 }
    }
}
