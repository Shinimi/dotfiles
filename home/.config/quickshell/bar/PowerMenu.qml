// Power menu (SUPER + X, or the power icon in the bar): full screen over a dimmed, blurred desktop. A big clock,
// "See you, Yu", and five tiles. Lock and Sleep work on a click; Log out, Restart and Shut down are held for a
// moment while a ring fills (if "Ask before power actions" is on). Keys: ← → pick, Enter (twice for the held
// ones), L S O R P jump straight to one, Esc closes. Made by Claude.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

Singleton {
    id: root
    property bool visible: false
    property int sel: 0
    property string armed: ""            // keyboard: first Enter arms a held action, the second runs it
    function toggle() { visible = !visible }
    onVisibleChanged: if (visible) { sel = 0; armed = ""; now = new Date(); PopupState.current = root }
    Connections { target: PopupState; function onCurrentChanged() { if (PopupState.current !== root) root.visible = false } }
    readonly property bool ask: Settings.cur("confirm_power") !== false
    property date now: new Date()
    Timer { running: root.visible; interval: 1000; repeat: true; onTriggered: root.now = new Date() }
    readonly property string qsDir: Quickshell.env("HOME") + "/.config/quickshell/bar"
    readonly property var actions: [
        { key: "lock",     letter: "L", icon: "\u{f033e}", text: "Lock",      sub: "Back in a moment", hold: false, cmd: ["qs", "ipc", "-p", qsDir, "call", "curtain", "lock"] },
        { key: "suspend",  letter: "S", icon: "\u{f0904}", text: "Sleep",     sub: "Wakes on a key",   hold: false, cmd: ["systemctl", "suspend"] },
        { key: "logout",   letter: "O", icon: "\u{f0343}", text: "Log out",   sub: "Closes your apps", hold: true,  cmd: ["hyprctl", "dispatch", "hl.dsp.exit()"] },
        { key: "reboot",   letter: "R", icon: "\u{f0709}", text: "Restart",   sub: "Back in a minute", hold: true,  cmd: ["systemctl", "reboot"] },
        { key: "shutdown", letter: "P", icon: "\u{f0425}", text: "Shut down", sub: "See you later",    hold: true,  cmd: ["systemctl", "poweroff"] }
    ]
    function run(a) { visible = false; Quickshell.execDetached(a.cmd) }
    function press(i) {
        const a = actions[i]; sel = i
        if (!a.hold || !ask || armed === a.key) run(a)
        else armed = a.key
    }
    readonly property string name: (n => n.charAt(0).toUpperCase() + n.slice(1).toLowerCase())(Settings.cur("user_name") || "yu")

    PanelWindow {
        visible: root.visible
        screen: Quickshell.screens.find(s => s.name === "DP-1") || Quickshell.screens[0]
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qsbar-power"
        WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "transparent"

        Rectangle {
            id: bg
            anchors.fill: parent; color: "#d8060606"
            opacity: root.visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180 } }
            MouseArea { anchors.fill: parent; onClicked: root.visible = false }
            focus: root.visible
            Keys.onEscapePressed: root.visible = false
            Keys.onLeftPressed: { root.sel = (root.sel + 4) % 5; root.armed = "" }
            Keys.onRightPressed: { root.sel = (root.sel + 1) % 5; root.armed = "" }
            Keys.onReturnPressed: root.press(root.sel)
            Keys.onEnterPressed: root.press(root.sel)
            Keys.onPressed: e => {
                const i = root.actions.findIndex(a => a.letter === e.text.toUpperCase())
                if (i >= 0) { root.press(i); e.accepted = true }
            }

            Column {   // the clock and the goodbye
                anchors.horizontalCenter: parent.horizontalCenter; y: parent.height * 0.18; spacing: 6
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatTime(root.now, "HH:mm"); color: "#ffffff"; font.family: Theme.font; font.pixelSize: 110; font.bold: true }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDate(root.now, "dddd d MMMM"); color: "#8a8a8a"; font.family: Theme.font; font.pixelSize: 15 }
            }

            Column {
                anchors.centerIn: parent; anchors.verticalCenterOffset: 70; spacing: 34
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter; spacing: 14
                    ClippingRectangle {
                        width: 46; height: 46; radius: 23; color: "#161616"
                        Image { anchors.fill: parent; fillMode: Image.PreserveAspectCrop; sourceSize.width: 96; asynchronous: true
                                source: Settings.cur("avatar") ? "file://" + Settings.cur("avatar") : "file://" + Quickshell.env("HOME") + "/.face" }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter; spacing: 2
                        Text { text: root.armed ? "Hold it, or press Enter again" : "See you, " + root.name; color: "#ffffff"; font.family: Theme.font; font.pixelSize: 18; font.bold: true }
                        Text { text: "Up " + Stats.d.uptime; color: "#7a7a7a"; font.family: Theme.font; font.pixelSize: 11 }
                    }
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter; spacing: 16
                    Repeater {
                        model: root.actions
                        Rectangle {
                            id: t
                            required property var modelData
                            required property int index
                            readonly property bool cur: root.sel === index
                            readonly property bool lit: cur || tm.containsMouse
                            property real hold: 0          // 0 → 1 while pressed
                            width: 170; height: 196; radius: 28
                            color: lit ? "#ececec" : "#141414"; border.width: 1; border.color: lit ? "#ececec" : "#262626"
                            Behavior on color { ColorAnimation { duration: 140 } }
                            scale: tm.pressed ? 0.96 : 1
                            Behavior on scale { NumberAnimation { duration: 120 } }
                            Canvas {   // the hold ring around the icon
                                id: ring
                                anchors.horizontalCenter: parent.horizontalCenter; y: 34; width: 84; height: 84
                                property real v: t.hold
                                onVChanged: requestPaint()
                                onPaint: {
                                    const c = getContext("2d"); c.reset()
                                    if (v <= 0) return
                                    c.lineWidth = 4; c.lineCap = "round"; c.strokeStyle = "#0b0b0b"
                                    c.beginPath(); c.arc(42, 42, 39, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * v); c.stroke()
                                }
                            }
                            Rectangle {
                                anchors.centerIn: ring; width: 68; height: 68; radius: 34
                                color: t.lit ? "#1f000000" : "#1e1e1e"
                                Text { anchors.centerIn: parent; text: t.modelData.icon; color: t.lit ? "#0b0b0b" : "#e6e6e6"; font.family: Theme.font; font.pixelSize: 28 }
                            }
                            Column {
                                anchors.horizontalCenter: parent.horizontalCenter; y: 132; spacing: 3
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: t.modelData.text; color: t.lit ? "#0b0b0b" : "#ececec"; font.family: Theme.font; font.pixelSize: 15; font.bold: true }
                                Text { anchors.horizontalCenter: parent.horizontalCenter
                                       text: root.armed === t.modelData.key ? "Enter again" : t.modelData.hold && root.ask ? (tm.containsMouse ? "Hold to " + t.modelData.text.toLowerCase() : t.modelData.sub) : t.modelData.sub
                                       color: t.lit ? "#70000000" : "#6a6a6a"; font.family: Theme.font; font.pixelSize: 10 }
                            }
                            Rectangle {   // keyboard letter
                                anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 12; width: 22; height: 22; radius: 7
                                color: t.lit ? "#1a000000" : "#1e1e1e"
                                Text { anchors.centerIn: parent; text: t.modelData.letter; color: t.lit ? "#60000000" : "#6a6a6a"; font.family: Theme.font; font.pixelSize: 10; font.bold: true }
                            }
                            NumberAnimation { id: fill; target: t; property: "hold"; from: 0; to: 1; duration: 750
                                              onFinished: if (t.hold >= 1) root.run(t.modelData) }
                            MouseArea {
                                id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onEntered: { root.sel = t.index; root.armed = "" }
                                onPressed: if (t.modelData.hold && root.ask) fill.restart()
                                onReleased: { if (t.modelData.hold && root.ask) { fill.stop(); t.hold = 0 } else root.run(t.modelData) }
                                onCanceled: { fill.stop(); t.hold = 0 }
                            }
                        }
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "← → to pick  ·  Enter  ·  L S O R P  ·  Esc to close"; color: "#4a4a4a"; font.family: Theme.font; font.pixelSize: 10
                }
            }
        }
    }
}
