// Settings → Games: a profile per game (FPS cap, overlay, power) applied automatically while it runs. Made by Claude.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

Column {
    id: pg
    spacing: 12
    property var games: []
    Process {
        running: pg.visible
        command: [Qt.resolvedUrl("games.sh").toString().replace("file://", "")]
        stdout: StdioCollector { onStreamFinished: { try { pg.games = JSON.parse(this.text) } catch (e) {} } }
    }
    function prof(id) { return Object.assign({ fps: 0, hud: "off", power: "performance" }, (Settings.get("game_profiles") || {})[id] || {}) }
    function setProf(id, k, v) {
        const all = Object.assign({}, Settings.get("game_profiles") || {})
        const p = prof(id); p[k] = v; all[id] = p
        Settings.set("game_profiles", all)
    }
    Label { width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: 11
        text: "Applied the moment a game opens and undone when it closes (with Automatic game mode on). Overlay toggle in game: Right Shift + F12. Start Steam from the launcher once so the overlay can load." }
    Repeater {
        model: pg.games
        Rectangle {
            id: row
            required property var modelData
            readonly property var p: pg.prof(modelData.id)
            width: pg.width; height: 118; radius: 16; color: Theme.card; border.width: 1; border.color: "#14efeaf8"
            ClippingRectangle {
                x: 12; y: 12; width: 64; height: 94; radius: 10; color: Theme.bgAlt
                Image { anchors.fill: parent; source: Theme.fileUrl(row.modelData.cover); fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 128 }
            }
            Column {
                x: 92; y: 12; width: parent.width - 104; spacing: 8
                Label { text: row.modelData.name; font.pixelSize: 14; font.bold: true; width: parent.width; elide: Text.ElideRight }
                Row {
                    spacing: 18
                    Repeater {
                        model: [["fps", "FPS cap", [[0, "off"], [60, "60"], [90, "90"], [120, "120"], [141, "141"]]],
                                ["hud", "Overlay", [["off", "off"], ["fps", "fps"], ["full", "full"]]],
                                ["power", "Power", [["performance", "max"], ["balanced", "balanced"]]]]
                        Column {
                            id: grp
                            required property var modelData
                            spacing: 4
                            Label { text: grp.modelData[1]; color: Theme.muted; font.pixelSize: 10 }
                            Row {
                                spacing: 4
                                Repeater {
                                    model: grp.modelData[2]
                                    Rectangle {
                                        id: chip
                                        required property var modelData
                                        readonly property bool cur: row.p[grp.modelData[0]] === modelData[0]
                                        width: cl.implicitWidth + 16; height: 24; radius: 8
                                        color: cur ? Theme.purple : (cm.containsMouse ? Theme.bgHover : Theme.bgAlt)
                                        Label { id: cl; anchors.centerIn: parent; text: chip.modelData[1]; color: chip.cur ? Theme.bg : Theme.fgDim; font.pixelSize: 10 }
                                        MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pg.setProf(row.modelData.id, grp.modelData[0], chip.modelData[0]) }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
