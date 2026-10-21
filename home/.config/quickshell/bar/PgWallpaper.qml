// Settings → Wallpaper: pick for the main and side screens (applies with Apply). Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Io

Column {
    id: pg
    spacing: 14
    property string target: "wall_main"
    property var walls: []
    property var active: ({})
    property var thumbs: ({})
    function thumb(img) { return thumbs[img] || "" }
    Process {   // small cached previews (made once, new wallpapers get one the next time)
        running: pg.visible
        command: [Qt.resolvedUrl("wallthumbs.sh").toString().replace("file://", "")]
        stdout: StdioCollector {
            onStreamFinished: {
                const w = [], t = {}
                for (const l of this.text.split("\n")) { const p = l.split("\t"); if (p.length === 2) { w.push(p[0]); t[p[0]] = p[1] } }
                pg.thumbs = t; pg.walls = w
            }
        }
    }
    Process {
        running: pg.visible
        command: ["hyprctl", "hyprpaper", "listactive"]
        stdout: StdioCollector {
            onStreamFinished: {
                const a = {}
                for (const l of this.text.split("\n")) { const i = l.indexOf(" = "); const j = l.indexOf(": "); const k = i > 0 ? i : j; if (k > 0) a[l.slice(0, k).trim()] = l.slice(k + (i > 0 ? 3 : 2)).trim() }
                pg.active = a
            }
        }
    }
    readonly property string shownFor: Settings.get(target) || pg.active[target === "wall_main" ? "DP-1" : "DP-2"] || ""

    Row {
        width: parent.width; spacing: 14
        Repeater {
            model: [["wall_main", "Main screen", "DP-1"], ["wall_side", "Side screen", "DP-2"]]
            Rectangle {
                id: sc
                required property var modelData
                readonly property bool sel: pg.target === modelData[0]
                readonly property string img: Settings.get(modelData[0]) || pg.active[modelData[2]] || ""
                width: (parent.width - 14) / 2; height: 150; radius: 16; clip: true
                color: Theme.card; border.width: sel ? 2 : 1; border.color: sel ? Theme.blue : "#14c0caf5"
                Image { anchors.fill: parent; anchors.margins: 2; source: Theme.fileUrl(pg.thumb(sc.img)); fillMode: Image.PreserveAspectCrop; asynchronous: true; opacity: 0.9 }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 36; color: "#cc16161e"
                    Label { x: 14; anchors.verticalCenter: parent.verticalCenter; text: (sc.sel ? "\u{f012c}  " : "") + sc.modelData[1]; color: sc.sel ? Theme.blue : Theme.fg; font.pixelSize: 12 } }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: pg.target = sc.modelData[0] }
            }
        }
    }
    Label { text: pg.walls.length + " wallpapers in ~/Pictures/wallpaper · click one for the " + (pg.target === "wall_main" ? "main" : "side") + " screen"; color: Theme.muted; font.pixelSize: 11 }
    Flow {
        width: parent.width; spacing: 10
        Repeater {
            model: pg.visible ? pg.walls : []
            Rectangle {
                id: wt
                required property string modelData
                readonly property bool cur: pg.shownFor === modelData
                width: (parent.width - 30) / 4; height: width * 9 / 16; radius: 12; clip: true; color: Theme.bgAlt
                border.width: cur ? 3 : 0; border.color: Theme.blue
                Image { anchors.fill: parent; anchors.margins: wt.cur ? 3 : 0; source: Theme.fileUrl(pg.thumb(wt.modelData)); fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 240 }
                Rectangle { anchors.fill: parent; color: wm.containsMouse ? "#22c0caf5" : "transparent"; radius: 12 }
                MouseArea { id: wm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Settings.set(pg.target, wt.modelData) }
            }
        }
    }
}
