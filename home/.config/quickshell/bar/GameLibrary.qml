// Game library (SUPER + G): a big banner for the game you're on (your last played, or the one you hover/arrow to)
// with its logo, hours played, last played, size and its game-mode profile, a Play button, and every installed
// Steam game as a cover underneath. Sort by recent / most played / A–Z. ← → ↑ ↓ pick, Enter plays, Esc closes.
// Made by Claude.
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

Scope {
    id: root
    required property var screen
    property bool visible: false
    property var games: []
    property string sort: "recent"
    property int sel: 0
    readonly property var list: sort === "played" ? games.slice().sort((a, b) => b.minutes - a.minutes)
                              : sort === "name" ? games.slice().sort((a, b) => a.name.localeCompare(b.name)) : games
    readonly property var cur: list[sel] || null
    function toggle() { visible = !visible }
    onVisibleChanged: if (visible) { sel = 0; sort = "recent"; load.running = true; PopupState.current = root }
    Connections { target: PopupState; function onCurrentChanged() { if (PopupState.current !== root) root.visible = false } }
    IpcHandler { target: "games"; function toggle(): void { root.toggle() } }

    Process {
        id: load
        command: [Qt.resolvedUrl("games.sh").toString().replace("file://", "")]
        stdout: StdioCollector { onStreamFinished: { try { root.games = JSON.parse(this.text) } catch (e) {} } }
    }
    function launch(g) {
        if (!g) return
        root.visible = false
        Quickshell.execDetached(["steam", "steam://rungameid/" + g.id])
        Quickshell.execDetached(["notify-send", "-a", "Games", "Launching", g.name])
    }
    function hours(m) { return m < 60 ? (m > 0 ? m + " min played" : "Not played yet") : (m / 60 >= 10 ? Math.round(m / 60) : (m / 60).toFixed(1)) + " h played" }
    function ago(ts) {
        if (!ts) return "Never played"
        const d = Math.floor((Date.now() / 1000 - ts) / 86400)
        return d <= 0 ? "Played today" : d === 1 ? "Played yesterday" : d < 30 ? "Played " + d + " days ago" : d < 365 ? "Played " + Math.round(d / 30) + " months ago" : "Played over a year ago"
    }
    function profile(id) { return Object.assign({ fps: 0, hud: "off", power: "performance" }, (Settings.cur("game_profiles") || {})[id] || {}) }

    PanelWindow {
        visible: root.visible; screen: root.screen
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "qsbar-dismiss"
        color: "#99000000"
        MouseArea { anchors.fill: parent; onClicked: root.visible = false }
    }

    PanelWindow {
        id: win
        visible: root.visible; screen: root.screen
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qsbar-games"
        WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "transparent"
        implicitWidth: 1320; implicitHeight: 860
        readonly property int cols: 8

        Rectangle {
            anchors.fill: parent; radius: 28; color: "#f40b0b0b"; border.width: 1; border.color: "#1fffffff"
            focus: true
            Keys.onEscapePressed: root.visible = false
            Keys.onReturnPressed: root.launch(root.cur)
            Keys.onEnterPressed: root.launch(root.cur)
            Keys.onLeftPressed: root.sel = Math.max(0, root.sel - 1)
            Keys.onRightPressed: root.sel = Math.min(root.list.length - 1, root.sel + 1)
            Keys.onUpPressed: root.sel = Math.max(0, root.sel - win.cols)
            Keys.onDownPressed: root.sel = Math.min(root.list.length - 1, root.sel + win.cols)

            // ================= the banner =================
            ClippingRectangle {
                id: hero
                x: 20; y: 20; width: parent.width - 40; height: 380; radius: 20; color: "#141414"
                Image {
                    anchors.fill: parent; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 1400
                    source: root.cur && root.cur.hero ? "file://" + root.cur.hero : ""
                    opacity: status === Image.Ready ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 220 } }
                }
                Rectangle { anchors.fill: parent; gradient: Gradient { orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "#f00b0b0b" } GradientStop { position: 0.55; color: "#900b0b0b" } GradientStop { position: 1; color: "#100b0b0b" } } }
                Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 120
                    gradient: Gradient { GradientStop { position: 0; color: "#000b0b0b" } GradientStop { position: 1; color: "#d00b0b0b" } } }
                Column {
                    x: 40; anchors.bottom: parent.bottom; anchors.bottomMargin: 34; width: parent.width * 0.5; spacing: 14
                    Text { text: root.cur && root.sel === 0 && root.sort === "recent" ? "CONTINUE PLAYING" : "LIBRARY"; color: "#9a9a9a"; font.family: Theme.font; font.pixelSize: 10; font.bold: true; font.letterSpacing: 2 }
                    Item {
                        width: parent.width; height: logo.visible ? Math.min(130, logo.paintedHeight) : nameT.implicitHeight
                        Image { id: logo; width: Math.min(parent.width, 420); height: 130; fillMode: Image.PreserveAspectFit; horizontalAlignment: Image.AlignLeft; verticalAlignment: Image.AlignBottom
                                source: root.cur && root.cur.logo ? "file://" + root.cur.logo : ""; visible: status === Image.Ready; asynchronous: true; anchors.bottom: parent.bottom }
                        Text { id: nameT; visible: !logo.visible; width: parent.width; wrapMode: Text.WordWrap; text: root.cur ? root.cur.name : ""
                               color: "#ffffff"; font.family: Theme.font; font.pixelSize: 34; font.bold: true; anchors.bottom: parent.bottom }
                    }
                    Text { text: root.cur ? root.ago(root.cur.last) + "  ·  " + root.hours(root.cur.minutes) + (root.cur.size ? "  ·  " + Math.round(root.cur.size / 1e9) + " GB" : "") : ""
                           color: "#cfcfcf"; font.family: Theme.font; font.pixelSize: 12 }
                    Row {   // its game-mode profile
                        spacing: 6
                        Repeater {
                            model: root.cur ? (p => [p.fps ? p.fps + " FPS cap" : "No FPS cap", p.hud === "off" ? "No overlay" : p.hud === "fps" ? "FPS overlay" : "Full overlay", p.power === "performance" ? "Max power" : "Balanced power"])(root.profile(root.cur.id)) : []
                            Rectangle { required property string modelData; width: pt.implicitWidth + 18; height: 24; radius: 12; color: "#b0141414"; border.width: 1; border.color: "#33ffffff"
                                        Text { id: pt; anchors.centerIn: parent; text: parent.modelData; color: "#d8d8d8"; font.family: Theme.font; font.pixelSize: 10 } }
                        }
                    }
                    Row {
                        spacing: 10
                        Rectangle {
                            width: pl.implicitWidth + 48; height: 48; radius: 24; color: pm.containsMouse ? "#ffffff" : "#ececec"
                            scale: pm.pressed ? 0.96 : 1
                            Behavior on scale { NumberAnimation { duration: 90 } }
                            Text { id: pl; anchors.centerIn: parent; text: "\u{f040a}  Play"; color: "#0b0b0b"; font.family: Theme.font; font.pixelSize: 14; font.bold: true }
                            MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.launch(root.cur) }
                        }
                        Rectangle {
                            width: gp.implicitWidth + 36; height: 48; radius: 24; color: gpm.containsMouse ? "#2a2a2a" : "#b0141414"; border.width: 1; border.color: "#33ffffff"
                            Text { id: gp; anchors.centerIn: parent; text: "\u{f0493}  Game profile"; color: "#e6e6e6"; font.family: Theme.font; font.pixelSize: 12 }
                            MouseArea { id: gpm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { root.visible = false; Quickshell.execDetached(["qs", "ipc", "-p", Quickshell.env("HOME") + "/.config/quickshell/bar", "call", "settings", "open", "games"]) } }
                        }
                    }
                }
            }

            // ================= the shelf =================
            Text {
                id: shelfHead
                x: 26; y: hero.y + hero.height + 26
                text: "LIBRARY · " + root.games.length + " GAMES"; color: "#7a7a7a"; font.family: Theme.font; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.6
            }
            Row {
                anchors.right: parent.right; anchors.rightMargin: 26; anchors.verticalCenter: shelfHead.verticalCenter; spacing: 6
                Repeater {
                    model: [["recent", "Recent"], ["played", "Most played"], ["name", "A–Z"]]
                    Rectangle {
                        required property var modelData
                        readonly property bool on: root.sort === modelData[0]
                        width: st.implicitWidth + 22; height: 28; radius: 14; color: on ? "#ececec" : stm.containsMouse ? "#1f1f1f" : "#151515"
                        Text { id: st; anchors.centerIn: parent; text: parent.modelData[1]; color: parent.on ? "#0b0b0b" : "#a8a8a8"; font.family: Theme.font; font.pixelSize: 11; font.bold: parent.on }
                        MouseArea { id: stm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.sort = parent.modelData[0]; root.sel = 0 } }
                    }
                }
            }
            Flickable {
                x: 20; y: shelfHead.y + 30; width: parent.width - 40; height: parent.height - y - 18
                contentHeight: grid.implicitHeight + 10; clip: true; boundsBehavior: Flickable.StopAtBounds
                topMargin: 8
                Grid {
                    id: grid
                    columns: win.cols; columnSpacing: 14; rowSpacing: 14
                    readonly property real cw: (parent.width - 14 * (win.cols - 1)) / win.cols
                    Repeater {
                        model: root.list
                        Item {
                            id: card
                            required property var modelData
                            required property int index
                            readonly property bool on: root.sel === index
                            width: grid.cw; height: grid.cw * 1.5 + 44
                            ClippingRectangle {
                                width: parent.width; height: parent.width * 1.5; radius: 14; color: "#161616"
                                y: card.on ? -6 : 0
                                Behavior on y { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                                border.width: card.on ? 2 : 0; border.color: "#ececec"
                                Image { anchors.fill: parent; source: card.modelData.cover ? "file://" + card.modelData.cover : ""; sourceSize.width: 320
                                        fillMode: Image.PreserveAspectCrop; asynchronous: true; opacity: card.on ? 1 : 0.8
                                        Behavior on opacity { NumberAnimation { duration: 140 } } }
                                Text { anchors.centerIn: parent; visible: !card.modelData.cover; width: parent.width - 16; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                                       text: card.modelData.name; color: "#d8d8d8"; font.family: Theme.font; font.pixelSize: 12 }
                            }
                            Column {
                                y: parent.width * 1.5 + 8; width: parent.width; spacing: 1
                                Text { width: parent.width; elide: Text.ElideRight; text: card.modelData.name; color: card.on ? "#ffffff" : "#c8c8c8"; font.family: Theme.font; font.pixelSize: 11; font.bold: card.on }
                                Text { text: root.hours(card.modelData.minutes); color: "#6a6a6a"; font.family: Theme.font; font.pixelSize: 9 }
                            }
                            MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onEntered: root.sel = card.index; onClicked: root.launch(card.modelData) }
                        }
                    }
                }
            }
        }
    }
}
