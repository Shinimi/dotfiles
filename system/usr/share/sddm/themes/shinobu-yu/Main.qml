// 胡蝶しのぶ login screen (SDDM, Qt 6): moonlit art, drifting butterflies, floating clock. Made by Claude.
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Controls.Basic

Item {
    id: root
    width: 2560; height: 1440

    // ---------- palette ----------
    readonly property color bg:      "#13121c"
    readonly property color bgAlt:   "#221f33"
    readonly property color bgHover: "#2a2640"
    readonly property color line:    "#403a5c"
    readonly property color fg:      "#efeaf8"
    readonly property color fgDim:   "#cfc8e2"
    readonly property color muted:   "#807a9c"
    readonly property color blue:    "#a28ae8"
    readonly property color cyan:    "#7fc4e3"
    readonly property color purple:  "#e39ec0"
    readonly property color yellow:  "#eec48e"
    readonly property color red:     "#ec6f8f"
    readonly property string font:   "GeistMono Nerd Font"
    readonly property string jp:     "Noto Serif CJK JP"

    // the big screen gets the login card; other screens just the wallpaper + clock
    readonly property bool isMain: typeof primaryScreen === "undefined" ? true : primaryScreen || root.width >= 2500

    // ---------- user + sessions ----------
    property string userName: userModel.lastUser || firstUser
    property string firstUser: ""
    property string realName: ""
    property string avatar: ""
    Instantiator {
        model: userModel
        delegate: QtObject {
            required property string name
            required property string realName
            required property string icon
            required property int index
            Component.onCompleted: {
                if (index === 0 && root.firstUser === "") root.firstUser = name
                if (name === (userModel.lastUser || root.firstUser)) { root.realName = realName; root.avatar = icon }
            }
        }
    }
    property var sessions: []
    property int sessionIndex: sessionModel.lastIndex
    Instantiator {
        model: sessionModel
        delegate: QtObject {
            required property string name
            required property int index
            Component.onCompleted: {
                const s = root.sessions.slice(); s.push({ name: name, index: index }); root.sessions = s
                // first boot: prefer plain Hyprland
                if (sessionModel.lastIndex < 0 && name === "Hyprland") root.sessionIndex = index
            }
        }
    }
    readonly property string sessionName: {
        const s = sessions.find(x => x.index === sessionIndex)
        return s ? s.name : "Session"
    }

    function doLogin() {
        if (password.text.length === 0 || busy) return
        busy = true; errorText = ""
        sddm.login(userName, password.text, sessionIndex)
    }
    property bool busy: false
    property string errorText: ""
    Connections {
        target: sddm
        function onLoginFailed() {
            root.busy = false
            root.errorText = "Wrong password"
            password.text = ""
            password.forceActiveFocus()
            shake.restart()
        }
        function onLoginSucceeded() { fadeOut.start() }
    }

    // ---------- background: the art stays sharp; a soft shade on the right for the text ----------
    Image {
        anchors.fill: parent
        source: root.isMain ? config.background : (config.background2 || config.background)
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0;  color: "#000d0c13" }
            GradientStop { position: 0.55; color: "#110d0c13" }
            GradientStop { position: 1.0;  color: "#990d0c13" }
        }
    }

    // ---------- drifting butterflies ----------
    Repeater {
        model: 9
        Image {
            id: bf
            required property int index
            source: Qt.resolvedUrl("assets/butterfly.svg")
            readonly property real sc: 0.35 + (index % 4) * 0.18
            width: 120 * sc; height: 90 * sc; sourceSize.width: width * 2; sourceSize.height: height * 2
            opacity: 0.0
            property real baseY: root.height * (0.15 + ((index * 37) % 70) / 100)
            x: -150; y: baseY
            transform: Scale { id: flap; origin.x: bf.width / 2; xScale: 1 }
            SequentialAnimation on opacity { loops: Animation.Infinite
                PauseAnimation { duration: bf.index * 2100 }
                NumberAnimation { to: 0.55 + (bf.index % 3) * 0.15; duration: 2500 }
                PauseAnimation { duration: 17000 }
                NumberAnimation { to: 0; duration: 2500 }
            }
            SequentialAnimation on x { loops: Animation.Infinite
                PauseAnimation { duration: bf.index * 2100 }
                NumberAnimation { from: -150; to: root.width + 150; duration: 22000 + (bf.index % 3) * 5000; easing.type: Easing.InOutSine }
            }
            SequentialAnimation on baseY { loops: Animation.Infinite
                NumberAnimation { to: bf.baseY - 70; duration: 3300 + bf.index * 200; easing.type: Easing.InOutSine }
                NumberAnimation { to: bf.baseY + 40; duration: 3300 + bf.index * 200; easing.type: Easing.InOutSine }
            }
            SequentialAnimation { running: true; loops: Animation.Infinite
                NumberAnimation { target: flap; property: "xScale"; to: 0.35; duration: 260 + bf.index * 20; easing.type: Easing.InOutQuad }
                NumberAnimation { target: flap; property: "xScale"; to: 1; duration: 260 + bf.index * 20; easing.type: Easing.InOutQuad }
            }
        }
    }

    property date now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    // side screens: just a quiet clock
    Text {
        visible: !root.isMain
        anchors.centerIn: parent
        text: Qt.formatTime(root.now, "HH:mm")
        color: "#bbefeaf8"; font.family: root.font; font.pixelSize: 96; font.weight: Font.Light
    }

    // ---------- right-hand column (same layout as the lock screen) ----------
    Text {   // her name, vertical
        visible: root.isMain
        anchors.right: parent.right; anchors.rightMargin: 110
        anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: -150
        text: "胡\n蝶\nし\nの\nぶ"; lineHeight: 1.05
        color: root.purple; font.family: root.jp; font.pixelSize: 36; font.weight: Font.Bold
        horizontalAlignment: Text.AlignHCenter
    }
    Column {
        id: col
        visible: root.isMain
        width: 480
        anchors.right: parent.right; anchors.rightMargin: 230
        anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: -120
        spacing: 14
        Text {
            anchors.right: parent.right
            text: Qt.formatTime(root.now, "HH:mm")
            color: root.fg; font.family: root.font; font.pixelSize: 176; font.weight: Font.Light
            layer.enabled: true
            layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#880d0c13"; shadowBlur: 0.9; shadowVerticalOffset: 3 }
        }
        Text {
            anchors.right: parent.right; anchors.rightMargin: 8
            text: Qt.formatDate(root.now, "dddd  ·  d MMMM").toLowerCase()
            color: root.blue; font.family: root.font; font.pixelSize: 23
        }
        Item { width: 1; height: 26 }
        Rectangle { anchors.right: parent.right; anchors.rightMargin: 8; width: 470; height: 1; color: "#55e39ec0" }
        Item { width: 1; height: 18 }

        Item {
            id: cardWrap
            anchors.right: parent.right; anchors.rightMargin: 8
            width: 470; height: 62
            SequentialAnimation {
                id: shake
                NumberAnimation { target: card; property: "x"; to: -14; duration: 45 }
                NumberAnimation { target: card; property: "x"; to: 12; duration: 45 }
                NumberAnimation { target: card; property: "x"; to: -8; duration: 45 }
                NumberAnimation { target: card; property: "x"; to: 5; duration: 45 }
                NumberAnimation { target: card; property: "x"; to: 0; duration: 45 }
            }
            Item {
                id: card
                width: parent.width; height: parent.height
                TextField {
                    id: password
                    anchors.fill: parent
                    echoMode: TextInput.Password
                    passwordCharacter: "●"
                    placeholderText: "password"
                    placeholderTextColor: root.muted
                    color: root.fg
                    font.family: root.font; font.pixelSize: 18
                    leftPadding: 58; rightPadding: 64
                    selectByMouse: true
                    focus: root.isMain
                    enabled: !root.busy
                    onAccepted: root.doLogin()
                    onTextChanged: if (text.length) root.errorText = ""
                    background: Rectangle {
                        radius: height / 2
                        color: "#aa0d0c13"
                        border.width: 1
                        border.color: root.errorText ? root.red : (password.activeFocus ? root.purple : "#66a28ae8")
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                    }
                    Text { x: 22; anchors.verticalCenter: parent.verticalCenter; text: "\u{f1589}"; color: root.purple; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 20 }
                    Rectangle {
                        anchors.right: parent.right; anchors.rightMargin: 7; anchors.verticalCenter: parent.verticalCenter
                        width: 48; height: 48; radius: 24
                        color: root.busy ? root.line : (goMouse.containsMouse ? "#f0b9d3" : root.purple)
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text {
                            anchors.centerIn: parent
                            text: root.busy ? "\u{f0450}" : "\u{f0054}"
                            color: "#0d0c13"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 20
                            RotationAnimation on rotation { running: root.busy; from: 0; to: 360; duration: 900; loops: Animation.Infinite }
                        }
                        MouseArea { id: goMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.doLogin() }
                    }
                }
            }
        }
        Text {
            anchors.right: parent.right; anchors.rightMargin: 30
            text: root.errorText ? root.errorText : (keyboard.capsLock ? "caps lock is on" : (root.realName || root.userName))
            color: root.errorText ? root.red : (keyboard.capsLock ? root.yellow : root.muted)
            font.family: root.font; font.pixelSize: 14
        }
    }

    // ---------- bottom bar: session + layout (left), power (right) ----------
    component Chip: Rectangle {
        property string icon; property string label; property color accent: root.fgDim
        signal clicked()
        height: 40; radius: 12
        width: chipRow.implicitWidth + 28
        color: chipMouse.containsMouse ? "#552a2640" : "#330d0c13"
        border.width: 1; border.color: "#33a28ae8"
        Behavior on color { ColorAnimation { duration: 120 } }
        Row {
            id: chipRow; anchors.centerIn: parent; spacing: 10
            Text { text: icon; color: accent; font.family: root.font; font.pixelSize: 15; anchors.verticalCenter: parent.verticalCenter }
            Text { visible: label !== ""; text: label; color: root.fg; font.family: root.font; font.pixelSize: 13; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
        }
        MouseArea { id: chipMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
    }

    Row {
        visible: root.isMain
        anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 36
        spacing: 10
        Chip {
            id: sessionChip
            icon: root.sessionName.indexOf("Plasma") >= 0 ? "" : ""
            label: root.sessionName + "  "
            accent: root.purple
            onClicked: sessionMenu.visible = !sessionMenu.visible
        }
        Chip {
            icon: ""
            label: keyboard.layouts.length ? keyboard.layouts[keyboard.currentLayout].shortName.toUpperCase() : "TR"
            accent: root.cyan
            onClicked: if (keyboard.layouts.length > 1) keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length
        }
    }
    Rectangle {   // session picker
        id: sessionMenu
        visible: false
        x: 36; y: root.height - 36 - 40 - 10 - height
        width: 260; height: sessCol.implicitHeight + 16
        radius: 14; color: root.bg; border.width: 1; border.color: root.line
        Column {
            id: sessCol; x: 8; y: 8; width: parent.width - 16; spacing: 4
            Repeater {
                model: root.sessions
                Rectangle {
                    required property var modelData
                    readonly property bool cur: modelData.index === root.sessionIndex
                    width: parent.width; height: 38; radius: 10
                    color: cur ? root.bgHover : (sMouse.containsMouse ? root.bgAlt : "transparent")
                    Row {
                        anchors.verticalCenter: parent.verticalCenter; x: 12; spacing: 10
                        Text { text: cur ? "" : ""; color: cur ? root.blue : root.muted; font.family: root.font; font.pixelSize: 14 }
                        Text { text: modelData.name; color: cur ? root.fg : root.fgDim; font.family: root.font; font.pixelSize: 13 }
                    }
                    MouseArea { id: sMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { root.sessionIndex = modelData.index; sessionMenu.visible = false; password.forceActiveFocus() } }
                }
            }
        }
    }

    Row {
        visible: root.isMain
        anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 36
        spacing: 10
        Chip { icon: ""; label: ""; accent: root.purple; visible: sddm.canSuspend; onClicked: sddm.suspend() }
        Chip { icon: ""; label: ""; accent: root.cyan;   visible: sddm.canReboot;  onClicked: sddm.reboot() }
        Chip { icon: ""; label: ""; accent: root.red;    visible: sddm.canPowerOff; onClicked: sddm.powerOff() }
    }

    Text {
        visible: root.isMain
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom; anchors.bottomMargin: 46
        text: "  CachyOS"
        color: root.muted; font.family: root.font; font.pixelSize: 13
    }

    // ---------- fade in / out ----------
    Rectangle {
        id: veil
        anchors.fill: parent; color: "#000000"; opacity: 1
        NumberAnimation on opacity { from: 1; to: 0; duration: 700; easing.type: Easing.OutCubic }
        NumberAnimation { id: fadeOut; target: veil; property: "opacity"; to: 1; duration: 400 }
    }

    Component.onCompleted: if (root.isMain) password.forceActiveFocus()
    Keys.onEscapePressed: sessionMenu.visible = false
}
