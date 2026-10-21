// Game library (SUPER + G): installed Steam games as covers, recent first. Made by Claude.
import QtQuick
import QtQuick.Layouts
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
    function toggle() { visible = !visible }
    onVisibleChanged: if (visible) { load.running = true; PopupState.current = root }
    Connections { target: PopupState; function onCurrentChanged() { if (PopupState.current !== root) root.visible = false } }
    IpcHandler { target: "games"; function toggle(): void { root.toggle() } }

    Process {
        id: load
        command: [Qt.resolvedUrl("games.sh").toString().replace("file://", "")]
        stdout: StdioCollector { onStreamFinished: { try { root.games = JSON.parse(this.text) } catch (e) {} } }
    }
    function launch(g) {
        root.visible = false
        Quickshell.execDetached(["steam", "steam://rungameid/" + g.id])
        Quickshell.execDetached(["notify-send", "-a", "Games", "  Launching", g.name])
    }

    PanelWindow {
        visible: root.visible; screen: root.screen
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "qsbar-dismiss"
        color: "#88000000"
        MouseArea { anchors.fill: parent; onClicked: root.visible = false }
    }

    PanelWindow {
        visible: root.visible; screen: root.screen
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qsbar-games"
        WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "transparent"
        readonly property int cols: Math.min(5, Math.max(1, root.games.length))
        implicitWidth: cols * 196 + 48
        implicitHeight: Math.ceil(root.games.length / cols) * 300 + 90

        Rectangle {
            anchors.fill: parent; radius: 20; color: Theme.panel; border.width: 1; border.color: Theme.glassLine
            focus: true
            Keys.onEscapePressed: root.visible = false
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 24; spacing: 16
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "  Library"; font.pixelSize: 17; font.weight: Font.Bold }
                    Label { text: root.games.length + " games"; color: Theme.muted; font.pixelSize: 11; Layout.fillWidth: true }
                    Label { text: "Esc to close"; color: Theme.line; font.pixelSize: 10 }
                }
                Grid {
                    columns: parent.parent.parent.cols
                    columnSpacing: 16; rowSpacing: 16
                    Repeater {
                        model: root.games
                        Item {
                            id: card
                            required property var modelData
                            width: 180; height: 284
                            readonly property bool hot: cMouse.containsMouse
                            ClippingRectangle {
                                id: cover
                                width: 180; height: 270; radius: 14
                                y: card.hot ? -6 : 0
                                Behavior on y { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                                color: Theme.bgAlt
                                border.width: card.hot ? 2 : 0; border.color: Theme.blue
                                Image {
                                    anchors.fill: parent
                                    source: card.modelData.cover ? "file://" + card.modelData.cover : ""
                                    sourceSize.width: 360
                                    fillMode: Image.PreserveAspectCrop; asynchronous: true
                                }
                                Rectangle {     // name slides in on hover
                                    anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                                    height: 64
                                    opacity: card.hot ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: 140 } }
                                    gradient: Gradient { GradientStop { position: 0; color: "#001a1b26" } GradientStop { position: 1; color: "#f01a1b26" } }
                                    Label {
                                        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 10
                                        text: card.modelData.name; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight; font.pixelSize: 12
                                    }
                                }
                                Label {
                                    anchors.centerIn: parent; visible: !card.modelData.cover
                                    width: parent.width - 20; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap
                                    text: card.modelData.name
                                }
                            }
                            MouseArea { id: cMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.launch(card.modelData) }
                        }
                    }
                }
            }
        }
    }
}
