// Monochrome login screen (SDDM, Qt 6), island style to match the lock screen: torii at night, slow zoom,
// the picture drawn in glowing ASCII characters,
// drifting dust, a black glass pill at the top, thin clock, today's line, avatar + pill password. Made by Claude.
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Controls.Basic
import QtQuick.Particles

Item {
    id: root
    width: 2560; height: 1440

    // ---------- palette ----------
    readonly property color bg:      "#111111"
    readonly property color bgAlt:   "#1c1c1c"
    readonly property color bgHover: "#242424"
    readonly property color line:    "#3a3a3a"
    readonly property color fg:      "#eaeaea"
    readonly property color fgDim:   "#c8c8c8"
    readonly property color muted:   "#7a7a7a"
    readonly property color blue:    "#e0e0e0"
    readonly property color cyan:    "#c4c4c4"
    readonly property color purple:  "#b0b0b0"
    readonly property color yellow:  "#d6d6d6"
    readonly property color red:     "#cf6b6b"
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

    // ---------- background: the art redrawn in glowing characters (ASCII), breathing slowly ----------
    Rectangle { anchors.fill: parent; color: "#000000" }
    Item {
        id: bgArt
        anchors.fill: parent
        transformOrigin: Item.Center
        SequentialAnimation on scale { loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 1.06; duration: 38000; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1.06; to: 1.0; duration: 38000; easing.type: Easing.InOutSine } }
        readonly property size cell: Qt.size(9, 16)
        Image {   // the picture, one pixel per character cell
            id: srcImg
            source: root.isMain ? (config.asciiBackground || config.background) : (config.background2 || config.background)
            sourceSize.width: Math.ceil(root.width / bgArt.cell.width) * 2
            sourceSize.height: Math.ceil(root.height / bgArt.cell.height) * 2
            width: sourceSize.width; height: sourceSize.height
            fillMode: Image.PreserveAspectCrop; visible: false; smooth: true
        }
        MultiEffect {   // lift the night picture so the shore and rocks become characters too
            id: lifted; source: srcImg; width: srcImg.width; height: srcImg.height; visible: false
            brightness: 0.0; contrast: 0.1
        }
        ShaderEffectSource { id: srcTex; sourceItem: lifted; hideSource: true; live: true; smooth: true }
        Row {   // character atlas, dim → bright
            id: atlasRow
            readonly property string chars: " .`:-=+*cox%#@"
            visible: false
            Repeater {
                model: atlasRow.chars.length
                Text {
                    required property int index
                    width: bgArt.cell.width; height: bgArt.cell.height
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    text: atlasRow.chars[index]; color: "#ffffff"
                    font.family: root.font; font.pixelSize: 13; font.weight: Font.Bold
                }
            }
        }
        ShaderEffectSource { id: atlasTex; sourceItem: atlasRow; hideSource: true; live: true; smooth: true }
        MultiEffect {   // soft glow under the characters
            anchors.fill: parent; source: fx
            blurEnabled: true; blur: 0.55; blurMax: 32; brightness: 0.05; opacity: 0.85
        }
        ShaderEffect {
            id: fx
            anchors.fill: parent
            property real time: 0
            NumberAnimation on time { from: 0; to: 100000; duration: 100000000; loops: Animation.Infinite }
            property real glyphs: atlasRow.chars.length
            property real bright: 0.95
            property size res: Qt.size(width, height)
            property size cell: bgArt.cell
            property color tintc: "#ffffff"
            property variant src: srcTex
            property variant atlas: atlasTex
            fragmentShader: Qt.resolvedUrl("assets/ascii.frag.qsb")
        }
    }
    // slow drifting dust
    ParticleSystem { id: petals; anchors.fill: parent; running: true }
    ImageParticle {
        system: petals
        source: Qt.resolvedUrl("assets/dot.svg")
        color: "#ffffff"; colorVariation: 0.0
        alpha: 0.35; alphaVariation: 0.25
        rotation: 0; rotationVariation: 180
        autoRotation: false; rotationVelocity: 40; rotationVelocityVariation: 60
    }
    Emitter {
        system: petals
        x: -200; y: -40; width: root.width + 400; height: 20
        emitRate: root.isMain ? 9 : 3; lifeSpan: 16000
        size: 6; sizeVariation: 4
        velocity: AngleDirection { angle: 80; angleVariation: 18; magnitude: 35; magnitudeVariation: 15 }
        acceleration: PointDirection { x: 8; xVariation: 12; y: 4 }
    }
    Wander { system: petals; xVariance: 70; pace: 120; affectedParameter: Wander.Velocity }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {   // darker at the top so the clock reads over the bright character sky
            GradientStop { position: 0.0;  color: "#d0000000" }
            GradientStop { position: 0.36; color: "#a0000000" }
            GradientStop { position: 0.55; color: "#18000000" }
            GradientStop { position: 1.0;  color: "#40000000" }
        }
    }

    property date now: new Date()
    readonly property var lines: ["“The impediment to action advances action.”  — marcus aurelius", "“Waste no more time arguing what a good man should be. Be one.”  — marcus aurelius", "“You have power over your mind, not outside events.”  — marcus aurelius", "“We suffer more often in imagination than in reality.”  — seneca", "“While we wait for life, life passes.”  — seneca", "“A journey of a thousand miles begins with a single step.”  — lao tzu", "“Nature does not hurry, yet everything is accomplished.”  — lao tzu", "“It does not matter how slowly you go, as long as you do not stop.”  — confucius", "“Do nothing that is of no use.”  — miyamoto musashi", "“Perceive that which cannot be seen with the eye.”  — miyamoto musashi", "“Today is victory over yourself of yesterday.”  — miyamoto musashi", "“Fall seven times, stand up eight.”  — japanese proverb", "“Every day is a journey, and the journey itself is home.”  — matsuo bashō", "“No man ever steps in the same river twice.”  — heraclitus", "“Well begun is half done.”  — aristotle", "“First say to yourself what you would be; then do what you have to do.”  — epictetus", "“He who has a why to live can bear almost any how.”  — nietzsche", "“The unexamined life is not worth living.”  — socrates"]
    readonly property string todayLine: {
        const d = new Date(), start = new Date(d.getFullYear(), 0, 0)
        return lines[Math.floor((d - start) / 86400000) % lines.length]
    }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    // side screens: just a quiet clock
    Text {
        visible: !root.isMain
        anchors.centerIn: parent
        text: Qt.formatTime(root.now, "HH:mm")
        color: "#bbeaeaea"; font.family: root.font; font.pixelSize: 96; font.weight: Font.Light
    }

    // ---------- the island (top centre) ----------
    Rectangle {
        visible: root.isMain
        anchors.horizontalCenter: parent.horizontalCenter; y: 6
        width: islandRow.implicitWidth + 40; height: 34; radius: 17
        color: "#e6050505"; border.width: 1; border.color: "#16ffffff"
        Row {
            id: islandRow; anchors.centerIn: parent; spacing: 14
            Text { text: "\u{f033e}"; color: root.fg; font.family: root.font; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
            Text { text: Qt.formatTime(root.now, "HH:mm"); color: "#ffffff"; font.family: root.font; font.pixelSize: 13; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
            Text { text: "·"; color: "#4a4a4a"; font.family: root.font; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
            Text { text: Qt.formatDate(root.now, "ddd d MMM"); color: root.fgDim; font.family: root.font; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
        }
    }

    // ---------- clock, date, today's line (in the sky) ----------
    Column {
        visible: root.isMain
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height / 2 - 420 - 110
        spacing: 10
        opacity: 0
        NumberAnimation on opacity { from: 0; to: 1; duration: 1400; easing.type: Easing.OutCubic }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(root.now, "HH:mm")
            color: "#f5f5f5"; font.family: root.font; font.pixelSize: 200; font.weight: Font.Thin
            layer.enabled: true
            layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#880b0b0b"; shadowBlur: 0.9; shadowVerticalOffset: 3 }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(root.now, "dddd, d MMMM").toLowerCase()
            color: "#d8d8d8"; font.family: root.font; font.pixelSize: 21
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.todayLine
            color: "#b0ffffff"; font.family: root.font; font.pixelSize: 16; font.italic: true
        }
    }

    // ---------- you + password (on the dark beach) ----------
    Column {
        id: col
        visible: root.isMain
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height / 2 + 385 - 37
        spacing: 16
        opacity: 0
        NumberAnimation on opacity { from: 0; to: 1; duration: 1600; easing.type: Easing.OutCubic }
        Rectangle {   // avatar
            anchors.horizontalCenter: parent.horizontalCenter
            width: 74; height: 74; radius: 37; color: "#1c1c1c"; border.width: 1; border.color: "#26ffffff"
            Image {
                id: av; anchors.fill: parent; anchors.margins: 1; source: root.avatar; fillMode: Image.PreserveAspectCrop
                visible: false; sourceSize.width: 148; sourceSize.height: 148
            }
            Rectangle { id: avMask; anchors.fill: av; radius: width / 2; visible: false; layer.enabled: true }
            MultiEffect { anchors.fill: av; source: av; maskEnabled: true; maskSource: avMask; visible: root.avatar !== "" }
        }
        Item {
            id: cardWrap
            anchors.horizontalCenter: parent.horizontalCenter
            width: 300; height: 44
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
                    placeholderTextColor: "#6a6a6a"
                    horizontalAlignment: TextInput.AlignHCenter
                    color: root.fg
                    font.family: root.font; font.pixelSize: 15
                    leftPadding: 44; rightPadding: 44
                    selectByMouse: true
                    focus: root.isMain
                    enabled: !root.busy
                    onAccepted: root.doLogin()
                    onTextChanged: if (text.length) root.errorText = ""
                    background: Rectangle {
                        radius: height / 2
                        color: "#e6050505"
                        border.width: 1
                        border.color: root.errorText ? root.red : (password.activeFocus ? "#40ffffff" : "#16ffffff")
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                    }
                    Rectangle {   // go
                        anchors.right: parent.right; anchors.rightMargin: 5; anchors.verticalCenter: parent.verticalCenter
                        width: 34; height: 34; radius: 17
                        visible: password.text.length > 0 || root.busy
                        color: root.busy ? root.line : (goMouse.containsMouse ? "#ffffff" : "#ededed")
                        Text {
                            anchors.centerIn: parent
                            text: root.busy ? "\u{f0450}" : "\u{f0054}"
                            color: "#0b0b0b"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16
                            RotationAnimation on rotation { running: root.busy; from: 0; to: 360; duration: 900; loops: Animation.Infinite }
                        }
                        MouseArea { id: goMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.doLogin() }
                    }
                }
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.errorText ? root.errorText : (keyboard.capsLock ? "caps lock is on" : (root.realName || root.userName))
            color: root.errorText ? root.red : (keyboard.capsLock ? root.yellow : root.muted)
            font.family: root.font; font.pixelSize: 13
        }
    }

    // ---------- bottom bar: session + layout (left), power (right) ----------
    component Chip: Rectangle {
        property string icon; property string label; property color accent: root.fgDim
        signal clicked()
        height: 38; radius: 19
        width: chipRow.implicitWidth + 30
        color: chipMouse.containsMouse ? "#f01c1c1c" : "#e6050505"
        border.width: 1; border.color: "#16ffffff"
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
        x: 36; y: root.height - 36 - 38 - 10 - height
        width: 260; height: sessCol.implicitHeight + 16
        radius: 18; color: "#f2050505"; border.width: 1; border.color: "#16ffffff"
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
