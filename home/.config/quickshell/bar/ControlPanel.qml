// Control center (SUPER + A, or the sliders icon in the bar): a panel under the right end of the bar.
//   media · network / bluetooth / do not disturb / night light tiles · small toggles
//   volume + output · brightness · power (lock, log out, restart, shut down) · latest notifications
// Esc or click outside closes. Made by Claude.
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

Scope {
    id: cc
    required property var screen
    property bool visible: false
    property bool shown: false
    readonly property string qsDir: Quickshell.env("HOME") + "/.config/quickshell/bar"
    function toggle() { visible = !visible }
    onVisibleChanged: {
        if (visible) { shown = true; armed = ""; PopupState.current = cc; SysState.refresh(); brGet.running = true; net.running = true; bt.running = true }
        else hideLater.restart()
    }
    Timer { id: hideLater; interval: 260; onTriggered: if (!cc.visible) cc.shown = false }
    Connections { target: PopupState; function onCurrentChanged() { if (PopupState.current !== cc) cc.visible = false } }
    IpcHandler { target: "panel"; function toggle(): void { cc.toggle() } }

    // ---------- data ----------
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio && !(n.name || "").startsWith("effect_") && n.name !== "headset_eq")
    PwObjectTracker { objects: [Pipewire.defaultAudioSink].concat(cc.sinks) }
    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) || players.find(p => p.identity === "Spotify" && p.trackTitle) || null
    property string art: ""
    readonly property string liveArt: player ? (player.trackArtUrl || "") : ""
    onLiveArtChanged: if (liveArt !== "") art = liveArt
    Timer { running: cc.visible && cc.player && cc.player.isPlaying; interval: 1000; repeat: true; onTriggered: cc.player.positionChanged() }

    // network (NetworkManager) and bluetooth, read when the panel opens
    property var netInfo: ({ wired: "", wifiDev: false, wifiOn: false, ssid: "" })
    Process {
        id: net
        command: ["sh", "-c", "nmcli -t -f TYPE,STATE,CONNECTION,DEVICE dev; echo radio=$(nmcli radio wifi)"]
        stdout: StdioCollector {
            onStreamFinished: {
                const n = { wired: "", wifiDev: false, wifiOn: false, ssid: "" }
                for (const l of this.text.split("\n")) {
                    const p = l.split(":")
                    if (l.startsWith("radio=")) n.wifiOn = l.indexOf("enabled") > 0
                    else if (p[0] === "ethernet" && p[1] === "connected") n.wired = p[3]
                    else if (p[0] === "wifi") { n.wifiDev = true; if (p[1] === "connected") n.ssid = p[2] }
                }
                cc.netInfo = n
            }
        }
    }
    property var btInfo: ({ on: false, device: "" })
    Process {
        id: bt
        command: ["sh", "-c", "bluetoothctl show | grep -m1 Powered; bluetoothctl devices Connected | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = this.text
                const d = t.split("\n").find(l => l.startsWith("Device "))
                cc.btInfo = { on: t.indexOf("Powered: yes") >= 0, device: d ? d.split(" ").slice(2).join(" ") : "" }
            }
        }
    }
    Timer { id: refreshLater; interval: 900; onTriggered: { net.running = true; bt.running = true } }
    function run(cmd) { Quickshell.execDetached(cmd); refreshLater.restart() }

    // brightness (DDC/CI)
    property var bright: ({ "DP-1": 100, "DP-2": 100 })
    property var brPending: ({})
    readonly property string brCmd: Qt.resolvedUrl("brightness.sh").toString().replace("file://", "")
    Process { id: brGet; command: [cc.brCmd, "get"]; stdout: StdioCollector { onStreamFinished: { try { cc.bright = JSON.parse(this.text) } catch (e) {} } } }
    Timer { id: brSet; interval: 250; onTriggered: { for (const k in cc.brPending) Quickshell.execDetached([cc.brCmd, "set", k, String(cc.brPending[k])]); cc.brPending = {} } }
    function setBright(mon, v) { const b = Object.assign({}, bright); b[mon] = v; bright = b; const p = Object.assign({}, brPending); p[mon] = v; brPending = p; brSet.restart() }

    function mmss(t) { t = Math.max(0, Math.floor(t || 0)); return Math.floor(t / 60) + ":" + String(t % 60).padStart(2, "0") }
    function nice(n) { return (n ? (n.nickname || n.description || n.name || "") : "").replace(/ Analog Stereo| Digital Stereo \(HDMI\)| Stereo/g, "") }
    function go(cmd) { cc.visible = false; Quickshell.execDetached(cmd) }
    function qs(target, fn) { go(["qs", "ipc", "-p", qsDir, "call", target, fn || "toggle"]) }
    property string armed: ""                 // power action waiting for its second click
    Timer { id: disarm; interval: 3000; onTriggered: cc.armed = "" }

    // ---------- building blocks ----------
    component Tile: Rectangle {   // big tile: icon, name, state; the whole tile toggles
        id: t
        property string icon; property string name; property string info; property bool on: false
        signal hit()
        Layout.fillWidth: true; Layout.preferredWidth: 1; height: 64; radius: 8
        color: on ? Theme.on : (tm.containsMouse ? "#14ffffff" : "#0affffff")
        border.width: 1; border.color: on ? Theme.on : "#1cffffff"
        Behavior on color { ColorAnimation { duration: 140 } }
        Rectangle {
            x: 10; anchors.verticalCenter: parent.verticalCenter; width: 40; height: 40; radius: 20
            color: t.on ? "#1a000000" : "#12ffffff"
            Text { anchors.centerIn: parent; text: t.icon; color: t.on ? Theme.onText : "#e8e8e8"; font.family: Theme.font; font.pixelSize: 17 }
        }
        Column {
            x: 60; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 70; spacing: 2
            Text { width: parent.width; elide: Text.ElideRight; text: t.name; color: t.on ? Theme.onText : "#f0f0f0"; font.family: Theme.font; font.pixelSize: 12; font.bold: true }
            Text { width: parent.width; elide: Text.ElideRight; text: t.info; color: t.on ? "#80000000" : "#8a8a8a"; font.family: Theme.font; font.pixelSize: 10 }
        }
        MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: t.hit() }
    }
    component Mini: Rectangle {   // small toggle: icon + label
        id: m
        property string icon; property string name; property bool on: false
        signal hit()
        Layout.fillWidth: true; Layout.preferredWidth: 1; height: 54; radius: 8
        color: on ? Theme.on : (mm.containsMouse ? "#14ffffff" : "#0affffff")
        border.width: 1; border.color: on ? Theme.on : "#1cffffff"
        Behavior on color { ColorAnimation { duration: 140 } }
        Column {
            anchors.centerIn: parent; spacing: 4
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: m.icon; color: m.on ? Theme.onText : "#e0e0e0"; font.family: Theme.font; font.pixelSize: 16 }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: m.name; color: m.on ? Theme.onText : "#9a9a9a"; font.family: Theme.font; font.pixelSize: 9 }
        }
        MouseArea { id: mm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: m.hit() }
    }
    component Label2: Text { color: "#7a7a7a"; font.family: Theme.font; font.pixelSize: 10; font.letterSpacing: 1.5 }

    PanelWindow {
        visible: cc.shown; screen: cc.screen
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qsbar-control"
        WlrLayershell.keyboardFocus: cc.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"
        MouseArea { anchors.fill: parent; onClicked: cc.visible = false }

        Rectangle {
            id: panel
            width: 440; height: body.implicitHeight + 32
            x: parent.width - width - 10
            y: Theme.barHeight + 16
            opacity: cc.visible ? 1 : 0
            transform: Translate { y: cc.visible ? 0 : -10; Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } } }
            Behavior on opacity { NumberAnimation { duration: 180 } }
            radius: 12
            color: Theme.mix(Qt.rgba(0.04, 0.04, 0.04, 0.9), Theme.tint, 0.08 * Theme.tintOn)
            border.width: 1; border.color: "#24ffffff"
            MouseArea { anchors.fill: parent }
            focus: cc.visible
            Keys.onEscapePressed: cc.visible = false

            Column {
                id: body
                x: 16; y: 16; width: parent.width - 32; spacing: 12

                // ---------- you ----------
                RowLayout {
                    width: parent.width; spacing: 12
                    Avatar { size: 40 }
                    Column {
                        Layout.fillWidth: true; spacing: 2
                        Text { text: Settings.cur("user_name") || "yu"; color: "#ffffff"; font.family: Theme.font; font.pixelSize: 14; font.bold: true }
                        Text { text: "up " + Stats.d.uptime + "  ·  cpu " + Stats.d.cpu + "%  ·  ram " + Stats.d.ram + "%"; color: "#7a7a7a"; font.family: Theme.font; font.pixelSize: 10 }
                    }
                    Rectangle {
                        width: 34; height: 34; radius: 17
                        color: sm2.containsMouse ? Theme.on : "#0affffff"; border.width: 1; border.color: "#1cffffff"
                        Text { anchors.centerIn: parent; text: "\u{f0493}"; color: sm2.containsMouse ? Theme.onText : "#d8d8d8"; font.family: Theme.font; font.pixelSize: 15 }
                        MouseArea { id: sm2; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: cc.qs("settings") }
                    }
                }

                // ---------- media ----------
                Rectangle {
                    visible: cc.player !== null
                    width: parent.width; height: 96; radius: 10; color: "#0affffff"; border.width: 1; border.color: "#1cffffff"
                    clip: true
                    Image { id: bgArt; anchors.fill: parent; source: cc.art; fillMode: Image.PreserveAspectCrop; asynchronous: true; visible: false; sourceSize.width: 600 }
                    MultiEffect { anchors.fill: parent; source: bgArt; blurEnabled: true; blur: 1.0; blurMax: 48; brightness: -0.45; saturation: -0.2; opacity: 0.8; visible: cc.art !== "" }
                    ClippingRectangle {
                        x: 12; anchors.verticalCenter: parent.verticalCenter; width: 70; height: 70; radius: 8; color: "#1a1a1a"
                        Image { anchors.fill: parent; source: cc.art; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 160 }
                    }
                    Column {
                        x: 96; y: 14; width: parent.width - 96 - 12; spacing: 2
                        Text { width: parent.width; elide: Text.ElideRight; text: cc.player ? cc.player.trackTitle : ""; color: "#ffffff"; font.family: Theme.font; font.pixelSize: 13; font.bold: true }
                        Text { width: parent.width; elide: Text.ElideRight; text: cc.player ? (cc.player.trackArtist || cc.player.identity) : ""; color: "#b0b0b0"; font.family: Theme.font; font.pixelSize: 10 }
                    }
                    Row {
                        x: 92; anchors.bottom: parent.bottom; anchors.bottomMargin: 10; spacing: 4
                        Repeater {
                            model: [["\u{f04ae}", "prev"], ["", "toggle"], ["\u{f04ad}", "next"]]
                            Rectangle {
                                required property var modelData
                                readonly property bool main: modelData[1] === "toggle"
                                width: main ? 40 : 30; height: 30; radius: 15
                                color: main ? (pm.containsMouse ? "#ffffff" : Theme.on) : (pm.containsMouse ? "#1fffffff" : "transparent")
                                Text { anchors.centerIn: parent; font.family: Theme.font; font.pixelSize: main ? 15 : 13; color: main ? Theme.onText : "#e0e0e0"
                                       text: main ? (cc.player && cc.player.isPlaying ? "\u{f03e4}" : "\u{f040a}") : modelData[0] }
                                MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { const p = cc.player; if (!p) return; modelData[1] === "prev" ? p.previous() : modelData[1] === "next" ? p.next() : p.togglePlaying() } }
                            }
                        }
                    }
                    Rectangle {   // progress
                        visible: !!(cc.player && cc.player.length > 0)
                        anchors.right: parent.right; anchors.rightMargin: 14; anchors.bottom: parent.bottom; anchors.bottomMargin: 23
                        width: parent.width - 96 - 140 - 14; height: 3; radius: 2; color: "#26ffffff"
                        Rectangle { height: parent.height; radius: 2; color: "#f0f0f0"; width: cc.player && cc.player.length > 0 ? parent.width * Math.min(1, cc.player.position / cc.player.length) : 0 }
                        Text { anchors.right: parent.right; anchors.top: parent.bottom; anchors.topMargin: 4; text: cc.player ? cc.mmss(cc.player.position) + " / " + cc.mmss(cc.player.length) : ""
                               color: "#7a7a7a"; font.family: Theme.font; font.pixelSize: 9 }
                        MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor
                                    onClicked: e => { if (cc.player && cc.player.canSeek) cc.player.position = (e.x / width) * cc.player.length } }
                    }
                }

                // ---------- big tiles ----------
                GridLayout {
                    width: parent.width; columns: 2; rowSpacing: 8; columnSpacing: 8
                    Tile {
                        icon: cc.netInfo.ssid ? "\u{f05a9}" : cc.netInfo.wired ? "\u{f0200}" : "\u{f05aa}"
                        name: cc.netInfo.wifiDev ? "Wi-Fi" : "Network"
                        on: cc.netInfo.wifiDev ? cc.netInfo.wifiOn : cc.netInfo.wired !== ""
                        info: cc.netInfo.ssid ? cc.netInfo.ssid : cc.netInfo.wired ? "wired · " + cc.netInfo.wired + (cc.netInfo.wifiDev ? "" : " · no wi-fi card") : (cc.netInfo.wifiDev ? (cc.netInfo.wifiOn ? "on · not connected" : "off") : "offline")
                        onHit: cc.netInfo.wifiDev ? cc.run(["nmcli", "radio", "wifi", cc.netInfo.wifiOn ? "off" : "on"]) : cc.qs("settings", "toggle")
                    }
                    Tile {
                        icon: cc.btInfo.on ? "\u{f00af}" : "\u{f00b2}"; name: "Bluetooth"; on: cc.btInfo.on
                        info: !cc.btInfo.on ? "off" : cc.btInfo.device ? cc.btInfo.device : "on · nothing connected"
                        onHit: cc.run(["bluetoothctl", "power", cc.btInfo.on ? "off" : "on"])
                    }
                    Tile { icon: "\u{f009b}"; name: "Do not disturb"; on: Notifs.dnd; info: Notifs.dnd ? "pop-ups hidden" : "off"; onHit: Notifs.dnd = !Notifs.dnd }
                    Tile { icon: "\u{f0594}"; name: "Night light"; on: SysState.night; info: SysState.night ? "warm screen" : "off"; onHit: SysState.toggleNight() }
                }
                RowLayout {
                    width: parent.width; spacing: 8
                    Mini { icon: "\u{f0176}"; name: "awake"; on: SysState.awake; onHit: SysState.toggleAwake() }
                    Mini { icon: "\u{f04c5}"; name: "performance"; on: SysState.perf; onHit: SysState.setProfile(SysState.perf ? "balanced" : "performance") }
                    Mini { icon: "\u{f036c}"; name: "clean mic"; on: !!SysState.fx.mic; onHit: SysState.fxToggle("mic") }
                    Mini { icon: "\u{f0eb5}"; name: "game mode"; on: SysState.gameMode
                           onHit: { Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/gamemode.sh", SysState.gameMode ? "off" : "on"]); SysState.gameMode = !SysState.gameMode } }
                }

                // ---------- sound ----------
                Label2 { text: "SOUND" }
                CcSlider {
                    icon: "\u{f057e}"; text: cc.nice(cc.sink).slice(0, 26)
                    muted: !!(cc.sink && cc.sink.audio && cc.sink.audio.muted)
                    value: cc.sink && cc.sink.audio ? Math.min(1, cc.sink.audio.volume) : 0
                    onMoved: v => { if (cc.sink) { cc.sink.audio.muted = false; cc.sink.audio.volume = v } }
                    onIconClicked: if (cc.sink) cc.sink.audio.muted = !cc.sink.audio.muted
                }
                RowLayout {   // output switch
                    visible: cc.sinks.length > 1
                    width: parent.width; spacing: 6
                    Repeater {
                        model: cc.sinks
                        Rectangle {
                            required property var modelData
                            readonly property bool cur: cc.sink && (cc.sink.id === modelData.id || (cc.sink.name === "headset_eq" && (modelData.name || "").indexOf("Fuxi") >= 0))
                            Layout.fillWidth: true; height: 32; radius: 8
                            color: cur ? Theme.on : (om.containsMouse ? "#14ffffff" : "#0affffff"); border.width: 1; border.color: cur ? Theme.on : "#1cffffff"
                            Text { anchors.centerIn: parent; width: parent.width - 16; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                                   text: (cur ? "\u{f012c}  " : "") + cc.nice(modelData); color: cur ? Theme.onText : "#b0b0b0"; font.family: Theme.font; font.pixelSize: 10; font.bold: cur }
                            MouseArea { id: om; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { if (cur) return; if (SysState.fx.eq) SysState.fxToggle("eq"); Pipewire.preferredDefaultAudioSink = modelData } }
                        }
                    }
                }

                // ---------- brightness ----------
                Label2 { text: "BRIGHTNESS" }
                Repeater {
                    model: [["DP-1", "main screen"], ["DP-2", "side screen"]]
                    CcSlider {
                        required property var modelData
                        icon: "\u{f00df}"; text: modelData[1]
                        value: (cc.bright[modelData[0]] || 0) / 100
                        onMoved: v => cc.setBright(modelData[0], Math.round(v * 100))
                    }
                }

                // ---------- power ----------
                RowLayout {
                    width: parent.width; spacing: 6
                    Repeater {
                        model: [["lock", "\u{f033e}", "lock", false, ["qs", "ipc", "-p", cc.qsDir, "call", "curtain", "lock"]],
                                ["logout", "\u{f0343}", "log out", true, ["hyprctl", "dispatch", "hl.dsp.exit()"]],
                                ["reboot", "\u{f0709}", "restart", true, ["systemctl", "reboot"]],
                                ["off", "\u{f0425}", "shut down", true, ["systemctl", "poweroff"]]]
                        Rectangle {
                            required property var modelData
                            readonly property bool armedHere: cc.armed === modelData[0]
                            Layout.fillWidth: true; height: 50; radius: 8
                            color: armedHere ? (modelData[0] === "off" ? Theme.red : Theme.on) : (pw.containsMouse ? "#14ffffff" : "#0affffff")
                            border.width: 1; border.color: armedHere ? "transparent" : "#1cffffff"
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Column {
                                anchors.centerIn: parent; spacing: 3
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData[1]; color: parent.parent.armedHere ? Theme.onText : "#e0e0e0"; font.family: Theme.font; font.pixelSize: 15 }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: parent.parent.armedHere ? "again" : modelData[2]
                                       color: parent.parent.armedHere ? Theme.onText : "#8a8a8a"; font.family: Theme.font; font.pixelSize: 9 }
                            }
                            MouseArea {
                                id: pw; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData[3] && !parent.armedHere) { cc.armed = modelData[0]; disarm.restart(); return }
                                    cc.go(modelData[4])
                                }
                            }
                        }
                    }
                }

                // ---------- latest notifications ----------
                Item {
                    width: parent.width; height: 18
                    Label2 { text: "NOTIFICATIONS" + (Notifs.count > 0 ? "  ·  " + Notifs.count : "") }
                    Text {
                        visible: Notifs.count > 0
                        anchors.right: parent.right; text: "clear all"; color: clr.containsMouse ? "#ffffff" : "#7a7a7a"; font.family: Theme.font; font.pixelSize: 10
                        MouseArea { id: clr; anchors.fill: parent; anchors.margins: -4; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Notifs.clearAll() }
                    }
                }
                Text { visible: Notifs.count === 0; text: "nothing new"; color: "#4a4a4a"; font.family: Theme.font; font.pixelSize: 11 }
                Column {
                    visible: Notifs.count > 0; width: parent.width; spacing: 6
                    Repeater {
                        model: Notifs.model
                        NotifCard { required property var modelData; required property int index; visible: index < 3; notif: modelData; width: parent.width }
                    }
                }
            }
        }
    }
}
