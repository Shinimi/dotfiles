// ASCII living wallpaper (Settings → Extras): each screen's wallpaper redrawn as glowing characters,
// with a slow wave of light and rising motes. Sits on the desktop layer, behind windows. Updates at a
// calm 20 fps and stops completely in game mode. Made by Claude.
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

Scope {
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: w
            required property var modelData
            screen: modelData
            visible: Settings.cur("ascii_wall")
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "qsbar-asciiwall"
            color: "#000000"
            mask: Region {}
            readonly property string wall: Settings.cur(modelData.name === "DP-2" ? "wall_side" : "wall_main")
            readonly property size cellSize: Qt.size(9, 16)

            Image {   // the wallpaper, shrunk to one pixel per character cell
                id: srcImg
                source: w.wall ? "file://" + w.wall : ""
                sourceSize.width: Math.ceil(w.width / w.cellSize.width) * 2
                sourceSize.height: Math.ceil(w.height / w.cellSize.height) * 2
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
                        width: w.cellSize.width; height: w.cellSize.height
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
                property size cell: w.cellSize
                property color tintc: Theme.tintOn ? Theme.mix(Qt.color("#ffffff"), Theme.tint, 0.55) : "#ffffff"
                property variant src: srcTex
                property variant atlas: atlasTex
                fragmentShader: Qt.resolvedUrl("shaders/ascii.frag.qsb")
                Timer {   // 20 fps is plenty for slow light; nothing runs while a game is up
                    interval: 50; repeat: true
                    running: w.visible && !SysState.gameMode
                    onTriggered: parent.time += 0.05
                }
            }
        }
    }
}
