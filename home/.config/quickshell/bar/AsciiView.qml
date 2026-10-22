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
                font.family: "GeistMono Nerd Font"; font.pixelSize: 13; font.weight: Font.Bold
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
        property variant src: srcTex
        property variant atlas: atlasTex
        fragmentShader: Qt.resolvedUrl("shaders/ascii.frag.qsb")
        Timer { interval: 50; repeat: true; running: v.running && v.visible; onTriggered: parent.time += 0.05 }
    }
}
