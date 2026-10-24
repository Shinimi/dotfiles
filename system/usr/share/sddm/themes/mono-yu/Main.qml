// Login screen (SDDM, Qt 6) — "Night console". The torii-at-night picture redrawn in glowing ASCII characters,
// breathing slowly, with drifting dust and a scanline that sweeps down now and then. On top:
//   left   a giant stacked clock with a seconds rail, the date and today's quote
//   right  the console: avatar inside a turning ring, your name, a password field that draws its own
//          pulsing dots, hints, and a status line that types itself out
//   bottom session + keyboard (left), this machine (centre), sleep / restart / power off (right)
// Text is in normal case; only the small labels are spaced capitals. Made by Claude.
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
    readonly property string font:   "JetBrainsMono Nerd Font"
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
            root.errorText = "Wrong password, try again"
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
    // shade: dark on both sides so the clock (left) and the console (right) read, the art stays bright in the middle
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0;  color: "#e6000000" }
            GradientStop { position: 0.30; color: "#99000000" }
            GradientStop { position: 0.50; color: "#22000000" }
            GradientStop { position: 0.68; color: "#99000000" }
            GradientStop { position: 1.0;  color: "#ee000000" }
        }
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0;  color: "#66000000" }
            GradientStop { position: 0.2;  color: "#00000000" }
            GradientStop { position: 0.85; color: "#00000000" }
            GradientStop { position: 1.0;  color: "#cc000000" }
        }
    }
    // a soft scanline that sweeps down over the art every few seconds
    Rectangle {
        id: scan
        width: parent.width; height: 220; y: -height
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#00ffffff" }
            GradientStop { position: 0.8; color: "#0dffffff" }
            GradientStop { position: 1.0; color: "#26ffffff" }
        }
        SequentialAnimation on y { loops: Animation.Infinite
            PauseAnimation { duration: 4000 }
            NumberAnimation { from: -220; to: root.height; duration: 5200; easing.type: Easing.InOutSine } }
    }

    property date now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }
    readonly property var quotes: [
        ["The impediment to action advances action.", "Marcus Aurelius"], ["Waste no more time arguing what a good man should be. Be one.", "Marcus Aurelius"],
        ["You have power over your mind, not outside events.", "Marcus Aurelius"], ["We suffer more often in imagination than in reality.", "Seneca"],
        ["While we wait for life, life passes.", "Seneca"], ["A journey of a thousand miles begins with a single step.", "Lao Tzu"],
        ["Nature does not hurry, yet everything is accomplished.", "Lao Tzu"], ["It does not matter how slowly you go, as long as you do not stop.", "Confucius"],
        ["Do nothing that is of no use.", "Miyamoto Musashi"], ["Perceive that which cannot be seen with the eye.", "Miyamoto Musashi"],
        ["Today is victory over yourself of yesterday.", "Miyamoto Musashi"], ["Fall seven times, stand up eight.", "Japanese proverb"],
        ["Every day is a journey, and the journey itself is home.", "Matsuo Bashō"], ["No man ever steps in the same river twice.", "Heraclitus"],
        ["Well begun is half done.", "Aristotle"], ["First say to yourself what you would be; then do what you have to do.", "Epictetus"],
        ["He who has a why to live can bear almost any how.", "Nietzsche"], ["The unexamined life is not worth living.", "Socrates"]]
    readonly property var quote: {
        const d = new Date(), start = new Date(d.getFullYear(), 0, 0)
        return quotes[Math.floor((d - start) / 86400000) % quotes.length]
    }
    function nice(n) { n = n || ""; return n.charAt(0).toUpperCase() + n.slice(1).toLowerCase() }
    readonly property string who: nice(root.realName || root.userName)
    readonly property string hello: {
        const h = now.getHours()
        return h < 5 ? "Still up" : h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening"
    }

    // small spaced capitals, the only uppercase on the screen
    component Tag: Text {
        color: "#7a7a7a"; font.family: root.font; font.pixelSize: 11; font.bold: true; font.letterSpacing: 3
    }

    // side screens: a quiet clock
    Text {
        visible: !root.isMain
        anchors.centerIn: parent
        text: Qt.formatTime(root.now, "HH:mm")
        color: "#bbeaeaea"; font.family: root.font; font.pixelSize: 96; font.weight: Font.Thin
    }

    // ================= left: the stacked clock =================
    Item {
        id: clockBlock
        visible: root.isMain
        x: 120; y: root.height * 0.20
        width: 640; height: clockCol.implicitHeight
        opacity: 0
        NumberAnimation on opacity { from: 0; to: 1; duration: 1400; easing.type: Easing.OutCubic }
        NumberAnimation on x { from: 80; to: 120; duration: 1400; easing.type: Easing.OutCubic }
        Rectangle { x: -36; y: 18; width: 2; height: clockCol.implicitHeight - 36; color: "#40ffffff" }   // the rail
        Column {
            id: clockCol
            spacing: 0
            Tag { text: Qt.formatDate(root.now, "dddd").toUpperCase(); bottomPadding: 6 }
            Text {
                text: Qt.formatTime(root.now, "HH")
                color: "#ffffff"; font.family: root.font; font.pixelSize: 210; font.weight: Font.ExtraBold
                height: 178; verticalAlignment: Text.AlignTop; topPadding: -24
            }
            Text {
                text: Qt.formatTime(root.now, "mm")
                color: "transparent"; font.family: root.font; font.pixelSize: 210; font.weight: Font.ExtraBold
                style: Text.Outline; styleColor: "#b0ffffff"
                height: 196; verticalAlignment: Text.AlignTop; topPadding: -24
            }
            Item {   // seconds: a thin rail that fills once a minute, with a dot riding on it
                width: 420; height: 18
                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 2; color: "#26ffffff" }
                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width * root.now.getSeconds() / 59; height: 2; color: "#ffffff"
                            Behavior on width { NumberAnimation { duration: 400 } } }
                Rectangle { anchors.verticalCenter: parent.verticalCenter; x: parent.width * root.now.getSeconds() / 59 - 4; width: 8; height: 8; radius: 4; color: "#ffffff"
                            Behavior on x { NumberAnimation { duration: 400 } } }
            }
            Item { width: 1; height: 26 }
            Text { text: Qt.formatDate(root.now, "d MMMM yyyy"); color: "#e8e8e8"; font.family: root.font; font.pixelSize: 24; font.weight: Font.Medium }
            Item { width: 1; height: 26 }
            Text {
                width: 520; wrapMode: Text.WordWrap
                text: "“" + root.quote[0] + "”"
                color: "#c8c8c8"; font.family: root.font; font.pixelSize: 17; font.italic: true; lineHeight: 1.25
            }
            Text { topPadding: 8; text: "— " + root.quote[1]; color: "#7a7a7a"; font.family: root.font; font.pixelSize: 14 }
        }
    }

    // ================= right: the console =================
    Item {
        id: consoleBox
        visible: root.isMain
        width: 470; height: con.implicitHeight + 64
        x: root.width - width - 120; y: root.height * 0.5 - height / 2 + 20
        opacity: 0
        NumberAnimation on opacity { from: 0; to: 1; duration: 1600; easing.type: Easing.OutCubic }
        NumberAnimation on y { from: root.height * 0.5 - consoleBox.height / 2 + 60; to: root.height * 0.5 - consoleBox.height / 2 + 20; duration: 1600; easing.type: Easing.OutCubic }

        Rectangle {   // the slab
            anchors.fill: parent; radius: 6
            color: "#f00a0a0a"; border.width: 1; border.color: "#2affffff"
        }
        Rectangle { x: 0; y: 0; width: parent.width; height: 3; radius: 2; color: root.errorText ? root.red : "#ffffff"   // top edge light
                    Behavior on color { ColorAnimation { duration: 200 } } }

        Column {
            id: con
            x: 40; y: 34; width: parent.width - 80
            spacing: 0

            // header: a tiny title bar
            Row {
                spacing: 10
                Rectangle { width: 8; height: 8; radius: 4; color: "#ffffff"; anchors.verticalCenter: parent.verticalCenter
                            SequentialAnimation on opacity { loops: Animation.Infinite
                                NumberAnimation { to: 0.25; duration: 1100 } NumberAnimation { to: 1; duration: 1100 } } }
                Tag { text: "SIGN IN"; color: "#bdbdbd" }
                Tag { text: "·  " + root.sessionName.toUpperCase(); color: "#5a5a5a" }
            }
            Item { width: 1; height: 34 }

            // you
            Row {
                spacing: 22
                Item {
                    width: 96; height: 96
                    Canvas {   // a dashed ring that slowly turns around the picture
                        id: ring; anchors.fill: parent
                        onPaint: {
                            const c = getContext("2d"); c.reset(); c.strokeStyle = "rgba(255,255,255,0.55)"; c.lineWidth = 1.5
                            for (let i = 0; i < 24; i++) {
                                const a0 = i / 24 * 2 * Math.PI, a1 = a0 + 0.14
                                c.beginPath(); c.arc(48, 48, 46, a0, a1); c.stroke()
                            }
                        }
                        RotationAnimation on rotation { from: 0; to: 360; duration: 24000; loops: Animation.Infinite }
                    }
                    Rectangle {
                        anchors.centerIn: parent; width: 78; height: 78; radius: 39; color: "#1c1c1c"
                        Image {
                            id: av; anchors.fill: parent; source: root.avatar; fillMode: Image.PreserveAspectCrop
                            visible: false; sourceSize.width: 156; sourceSize.height: 156
                        }
                        Rectangle { id: avMask; anchors.fill: av; radius: width / 2; visible: false; layer.enabled: true }
                        MultiEffect { anchors.fill: av; source: av; maskEnabled: true; maskSource: avMask; visible: root.avatar !== "" }
                        Text { anchors.centerIn: parent; visible: root.avatar === ""; text: "\u{f0004}"; color: root.muted; font.family: root.font; font.pixelSize: 30 }
                    }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter; spacing: 4
                    Text { text: root.hello + ","; color: "#8a8a8a"; font.family: root.font; font.pixelSize: 15 }
                    Text { text: root.who; color: "#ffffff"; font.family: root.font; font.pixelSize: 34; font.weight: Font.Bold }
                }
            }
            Item { width: 1; height: 34 }

            // password: the real field is invisible; we draw the dots ourselves
            Tag { text: "PASSWORD"; bottomPadding: 10 }
            Item {
                id: cardWrap
                width: con.width; height: 56
                SequentialAnimation {
                    id: shake
                    NumberAnimation { target: card; property: "x"; to: -16; duration: 45 }
                    NumberAnimation { target: card; property: "x"; to: 13; duration: 45 }
                    NumberAnimation { target: card; property: "x"; to: -9; duration: 45 }
                    NumberAnimation { target: card; property: "x"; to: 5; duration: 45 }
                    NumberAnimation { target: card; property: "x"; to: 0; duration: 45 }
                }
                Item {
                    id: card
                    width: parent.width; height: parent.height
                    Rectangle {
                        anchors.fill: parent; radius: 4; color: "#121212"
                        border.width: 1
                        border.color: root.errorText ? root.red : (password.activeFocus ? "#66ffffff" : "#22ffffff")
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                    }
                    Text { x: 18; anchors.verticalCenter: parent.verticalCenter; text: "\u{f033e}"; color: password.text.length ? "#ffffff" : "#5a5a5a"; font.family: root.font; font.pixelSize: 16 }
                    TextField {
                        id: password
                        anchors.fill: parent
                        echoMode: TextInput.Password
                        color: "transparent"; selectionColor: "transparent"; selectedTextColor: "transparent"
                        cursorVisible: false; cursorDelegate: Item {}
                        background: Item {}
                        font.family: root.font; font.pixelSize: 15
                        focus: root.isMain
                        enabled: !root.busy
                        onAccepted: root.doLogin()
                        onTextChanged: if (text.length) root.errorText = ""
                        Keys.onEscapePressed: { text = ""; sessionMenu.visible = false }
                        Keys.onPressed: e => { if (e.key === Qt.Key_F2) { sessionMenu.visible = !sessionMenu.visible; e.accepted = true } }
                    }
                    Text {   // placeholder
                        x: 50; anchors.verticalCenter: parent.verticalCenter
                        visible: password.text.length === 0
                        text: root.busy ? "Signing in…" : "Type your password"
                        color: "#5a5a5a"; font.family: root.font; font.pixelSize: 15
                    }
                    Row {   // our own dots: each one pops in, the newest pulses
                        x: 50; anchors.verticalCenter: parent.verticalCenter; spacing: 9
                        Repeater {
                            model: Math.min(password.text.length, 24)
                            Rectangle {
                                id: dotR
                                required property int index
                                width: 9; height: 9; radius: 2; color: "#ffffff"
                                anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                                scale: 0
                                Component.onCompleted: pop.start()
                                NumberAnimation { id: pop; target: dotR; property: "scale"; from: 0; to: 1; duration: 160; easing.type: Easing.OutBack }
                                SequentialAnimation on opacity {
                                    running: index === password.text.length - 1; loops: Animation.Infinite
                                    NumberAnimation { to: 0.35; duration: 500 } NumberAnimation { to: 1; duration: 500 }
                                }
                            }
                        }
                        Rectangle {   // block cursor
                            width: 10; height: 20; color: "#ffffff"; anchors.verticalCenter: parent.verticalCenter
                            visible: password.activeFocus && !root.busy
                            SequentialAnimation on opacity { loops: Animation.Infinite
                                NumberAnimation { to: 0; duration: 500 } NumberAnimation { to: 1; duration: 500 } }
                        }
                    }
                    Rectangle {   // go
                        anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter
                        width: 40; height: 40; radius: 4
                        color: root.busy ? "#2a2a2a" : (password.text.length ? (goMouse.containsMouse ? "#ffffff" : "#ececec") : "#1e1e1e")
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text {
                            anchors.centerIn: parent
                            text: root.busy ? "\u{f0450}" : "\u{f0054}"
                            color: password.text.length && !root.busy ? "#0b0b0b" : "#6a6a6a"; font.family: root.font; font.pixelSize: 17
                            RotationAnimation on rotation { running: root.busy; from: 0; to: 360; duration: 900; loops: Animation.Infinite }
                        }
                        MouseArea { id: goMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.doLogin() }
                    }
                }
            }
            Item { width: 1; height: 16 }

            // status line: types itself out whenever it changes
            Text {
                id: status
                readonly property string full: root.errorText ? root.errorText
                                              : keyboard.capsLock ? "Caps Lock is on"
                                              : root.busy ? "Starting " + root.sessionName + "…"
                                              : "Press Enter to sign in"
                property int shown: 0
                onFullChanged: { shown = 0; typer.restart() }
                Component.onCompleted: typer.start()
                Timer { id: typer; interval: 22; repeat: true; onTriggered: { if (status.shown < status.full.length) status.shown++; else stop() } }
                text: "> " + full.slice(0, shown)
                color: root.errorText ? root.red : keyboard.capsLock ? "#ffffff" : "#8a8a8a"
                font.family: root.font; font.pixelSize: 13
            }
            Item { width: 1; height: 26 }
            Rectangle { width: con.width; height: 1; color: "#1affffff" }
            Item { width: 1; height: 16 }
            Row {   // key hints
                spacing: 22
                Repeater {
                    model: [["Enter", "sign in"], ["Esc", "clear"], ["F2", "session"]]
                    Row {
                        required property var modelData
                        spacing: 8
                        Rectangle {
                            width: kl.implicitWidth + 14; height: 22; radius: 4; color: "transparent"; border.width: 1; border.color: "#33ffffff"
                            Text { id: kl; anchors.centerIn: parent; text: modelData[0]; color: "#bdbdbd"; font.family: root.font; font.pixelSize: 11 }
                        }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: modelData[1]; color: "#6a6a6a"; font.family: root.font; font.pixelSize: 12 }
                    }
                }
            }
        }
    }

    // ================= bottom strip =================
    component Chip: Rectangle {
        property string icon; property string label; property string tag
        signal clicked()
        height: 44; radius: 4
        width: chipRow.implicitWidth + 30
        color: chipMouse.containsMouse ? "#1c1c1c" : "#d90a0a0a"
        border.width: 1; border.color: chipMouse.containsMouse ? "#40ffffff" : "#1fffffff"
        Behavior on color { ColorAnimation { duration: 120 } }
        Row {
            id: chipRow; anchors.centerIn: parent; spacing: 10
            Text { text: icon; color: "#e8e8e8"; font.family: root.font; font.pixelSize: 15; anchors.verticalCenter: parent.verticalCenter }
            Column {
                anchors.verticalCenter: parent.verticalCenter; spacing: 1
                visible: label !== ""
                Text { text: tag; color: "#6a6a6a"; font.family: root.font; font.pixelSize: 9; font.bold: true; font.letterSpacing: 2 }
                Text { text: label; color: "#e8e8e8"; font.family: root.font; font.pixelSize: 13; font.weight: Font.Medium }
            }
        }
        MouseArea { id: chipMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
    }

    Rectangle { visible: root.isMain; x: 48; width: parent.width - 96; y: parent.height - 108; height: 1; color: "#1affffff" }
    Row {
        visible: root.isMain
        anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.leftMargin: 48; anchors.bottomMargin: 36
        spacing: 10
        Chip { icon: "\u{f0d3f}"; tag: "SESSION"; label: root.sessionName; onClicked: sessionMenu.visible = !sessionMenu.visible }
        Chip {
            icon: "\u{f030c}"; tag: "KEYBOARD"
            label: keyboard.layouts.length ? keyboard.layouts[keyboard.currentLayout].shortName.toUpperCase() : "TR"
            onClicked: if (keyboard.layouts.length > 1) keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length
        }
    }
    Rectangle {   // session picker
        id: sessionMenu
        visible: false
        x: 48; y: root.height - 36 - 44 - 12 - height
        width: 280; height: sessCol.implicitHeight + 16
        radius: 6; color: "#f50a0a0a"; border.width: 1; border.color: "#2affffff"
        Column {
            id: sessCol; x: 8; y: 8; width: parent.width - 16; spacing: 2
            Repeater {
                model: root.sessions
                Rectangle {
                    required property var modelData
                    readonly property bool cur: modelData.index === root.sessionIndex
                    width: parent.width; height: 40; radius: 4
                    color: cur ? "#ececec" : (sMouse.containsMouse ? "#1c1c1c" : "transparent")
                    Text { x: 14; anchors.verticalCenter: parent.verticalCenter; text: modelData.name; color: cur ? "#0b0b0b" : "#d8d8d8"
                           font.family: root.font; font.pixelSize: 13; font.weight: cur ? Font.Bold : Font.Normal }
                    MouseArea { id: sMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { root.sessionIndex = modelData.index; sessionMenu.visible = false; password.forceActiveFocus() } }
                }
            }
        }
    }

    Column {   // this machine
        visible: root.isMain
        anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 38
        spacing: 4
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "\u{f303}  CachyOS"; color: "#d8d8d8"; font.family: root.font; font.pixelSize: 14; font.weight: Font.Medium }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Ryzen 7 5700X  ·  Radeon RX 9060 XT  ·  32 GB"; color: "#5a5a5a"; font.family: root.font; font.pixelSize: 11 }
    }

    Row {
        visible: root.isMain
        anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.rightMargin: 48; anchors.bottomMargin: 36
        spacing: 10
        Chip { icon: "\u{f0904}"; tag: ""; label: ""; visible: sddm.canSuspend; onClicked: sddm.suspend() }
        Chip { icon: "\u{f0709}"; tag: ""; label: ""; visible: sddm.canReboot; onClicked: sddm.reboot() }
        Chip { icon: "\u{f0425}"; tag: ""; label: ""; visible: sddm.canPowerOff; onClicked: sddm.powerOff() }
    }

    // ---------- fade in / out ----------
    Rectangle {
        id: veil
        anchors.fill: parent; color: "#000000"; opacity: 1
        NumberAnimation on opacity { from: 1; to: 0; duration: 900; easing.type: Easing.OutCubic }
        NumberAnimation { id: fadeOut; target: veil; property: "opacity"; to: 1; duration: 500 }
    }

    Component.onCompleted: if (root.isMain) password.forceActiveFocus()
    Keys.onEscapePressed: sessionMenu.visible = false
    Keys.onPressed: e => { if (e.key === Qt.Key_F2) { sessionMenu.visible = !sessionMenu.visible; e.accepted = true } }
}
