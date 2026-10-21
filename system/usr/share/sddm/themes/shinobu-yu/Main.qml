// Tokyo Night login screen for yu's CachyOS (SDDM, Qt 6). Made by Claude.
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
    readonly property string font:   config.font || "JetBrainsMono Nerd Font"

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

    // ---------- background ----------
    Image {
        id: wall
        anchors.fill: parent
        source: root.isMain ? config.background : (config.background2 || config.background)
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        visible: false
    }
    MultiEffect {
        anchors.fill: wall
        source: wall
        blurEnabled: true
        blur: root.isMain ? 0.55 : 0.25
        blurMax: 64
        brightness: -0.18
        saturation: 0.05
    }
    Rectangle {   // soft vignette so text always reads well
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#6613121c" }
            GradientStop { position: 0.45; color: "#2213121c" }
            GradientStop { position: 1.0; color: "#cc0d0c13" }
        }
    }

    // ---------- clock ----------
    property date now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }
    Column {
        id: clock
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * (root.isMain ? 0.10 : 0.36)
        spacing: 2
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(root.now, "HH:mm")
            color: root.fg; font.family: root.font; font.pixelSize: root.isMain ? 128 : 110; font.weight: Font.Bold
            layer.enabled: true
            layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#aa000000"; shadowBlur: 0.8; shadowVerticalOffset: 4 }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(root.now, "dddd, d MMMM")
            color: root.blue; font.family: root.font; font.pixelSize: 24; font.weight: Font.DemiBold
        }
    }

    // ---------- login card ----------
    Item {
        id: cardWrap
        visible: root.isMain
        width: 420; height: card.height
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: clock.bottom; anchors.topMargin: 70

        SequentialAnimation {
            id: shake
            loops: 1
            NumberAnimation { target: card; property: "x"; to: -14; duration: 45 }
            NumberAnimation { target: card; property: "x"; to: 12; duration: 45 }
            NumberAnimation { target: card; property: "x"; to: -8; duration: 45 }
            NumberAnimation { target: card; property: "x"; to: 5; duration: 45 }
            NumberAnimation { target: card; property: "x"; to: 0; duration: 45 }
        }

        Rectangle {
            id: card
            width: parent.width
            height: content.implicitHeight + 64
            radius: 26
            color: root.bg
            border.width: 1; border.color: root.line
            layer.enabled: true
            layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#99000000"; shadowBlur: 1.0; shadowVerticalOffset: 10 }

            ColumnLayout {
                id: content
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                anchors.margins: 32
                spacing: 18

                // avatar with gradient ring
                Item {
                    Layout.alignment: Qt.AlignHCenter
                    width: 108; height: 108
                    Rectangle {
                        anchors.fill: parent; radius: width / 2
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: root.blue }
                            GradientStop { position: 1; color: root.purple }
                        }
                        RotationAnimation on rotation { from: 0; to: 360; duration: 12000; loops: Animation.Infinite }
                    }
                    Rectangle {
                        anchors.centerIn: parent; width: 98; height: 98; radius: 49; color: root.bgAlt
                        Image {
                            id: avatarImg
                            anchors.fill: parent; anchors.margins: 3
                            source: root.avatar; fillMode: Image.PreserveAspectCrop
                            visible: false
                        }
                        Rectangle { id: avatarMask; anchors.fill: avatarImg; radius: width / 2; visible: false; layer.enabled: true }
                        MultiEffect {
                            anchors.fill: avatarImg; source: avatarImg
                            maskEnabled: true; maskSource: avatarMask
                            visible: avatarImg.status === Image.Ready
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: avatarImg.status !== Image.Ready
                            text: (root.realName || root.userName).charAt(0).toUpperCase()
                            color: root.fg; font.family: root.font; font.pixelSize: 44; font.weight: Font.Bold
                        }
                    }
                }

                Column {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 2
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.realName || root.userName; color: root.fg; font.family: root.font; font.pixelSize: 22; font.weight: Font.Bold }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "@" + root.userName + (sddm.hostName ? " · " + sddm.hostName : ""); color: root.muted; font.family: root.font; font.pixelSize: 13 }
                }

                // password row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    TextField {
                        id: password
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        echoMode: reveal.checked ? TextInput.Normal : TextInput.Password
                        passwordCharacter: "●"
                        placeholderText: "Password"
                        placeholderTextColor: root.muted
                        color: root.fg
                        font.family: root.font; font.pixelSize: 15
                        leftPadding: 46; rightPadding: 44
                        selectByMouse: true
                        focus: root.isMain
                        enabled: !root.busy
                        onAccepted: root.doLogin()
                        onTextChanged: if (text.length) root.errorText = ""
                        background: Rectangle {
                            radius: 14
                            color: root.bgAlt
                            border.width: password.activeFocus ? 2 : 1
                            border.color: root.errorText ? root.red : (password.activeFocus ? root.blue : root.line)
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                        }
                        Text { x: 16; anchors.verticalCenter: parent.verticalCenter; text: ""; color: password.activeFocus ? root.blue : root.muted; font.family: root.font; font.pixelSize: 16 }
                        Item {
                            id: reveal
                            property bool checked: false
                            width: 36; height: parent.height
                            anchors.right: parent.right; anchors.rightMargin: 4
                            Text { anchors.centerIn: parent; text: reveal.checked ? "" : ""; color: revealMouse.containsMouse ? root.fg : root.muted; font.family: root.font; font.pixelSize: 15 }
                            MouseArea { id: revealMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: reveal.checked = !reveal.checked }
                        }
                    }
                    Rectangle {
                        Layout.preferredWidth: 50; Layout.preferredHeight: 50
                        radius: 14
                        color: root.busy ? root.line : (goMouse.containsMouse ? "#b5a2f2" : root.blue)
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text {
                            anchors.centerIn: parent
                            text: root.busy ? "" : ""
                            color: root.bg; font.family: root.font; font.pixelSize: 18
                            RotationAnimation on rotation { running: root.busy; from: 0; to: 360; duration: 900; loops: Animation.Infinite }
                        }
                        MouseArea { id: goMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.doLogin() }
                    }
                }

                // status line
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 18
                    Text {
                        anchors.centerIn: parent
                        text: root.errorText ? "  " + root.errorText
                              : (keyboard.capsLock ? "  Caps Lock is on" : "Welcome back")
                        color: root.errorText ? root.red : (keyboard.capsLock ? root.yellow : root.muted)
                        font.family: root.font; font.pixelSize: 12
                    }
                }
            }
        }
    }

    // ---------- bottom bar: session + layout (left), power (right) ----------
    component Chip: Rectangle {
        property string icon; property string label; property color accent: root.fgDim
        signal clicked()
        height: 40; radius: 12
        width: chipRow.implicitWidth + 28
        color: chipMouse.containsMouse ? root.bgHover : root.bg
        border.width: 1; border.color: root.line
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
