// Panel that drops under a bar pill. It's its own overlay window (so every click inside
// it works), with an invisible full-screen layer behind it that closes it when you click
// outside. Esc closes it too. Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
    id: root
    required property Item anchorItem
    default property alias content: body.data
    property int padding: 16
    property int contentWidth: 300
    property bool visible: false
    // the bar only lives on the main screen; look it up directly (robust across live reloads)
    readonly property var barScreen: Quickshell.screens.find(s => s.name === "DP-1") || Quickshell.screens[0]

    function toggle() { visible = !visible }
    onVisibleChanged: if (visible) PopupState.current = root
    Connections {
        target: PopupState
        function onCurrentChanged() { if (PopupState.current !== root) root.visible = false }
    }

    // click-catcher below the bar line: clicking anywhere outside closes the panel
    PanelWindow {
        visible: root.visible
        screen: root.barScreen
        anchors { top: true; bottom: true; left: true; right: true }
        margins.top: Theme.barHeight + 6
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "qsbar-dismiss"
        color: "transparent"
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onClicked: root.visible = false }
    }

    // the panel itself
    PanelWindow {
        id: panel
        visible: root.visible
        screen: root.barScreen
        anchors { top: true; left: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qsbar-panel"
        WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"
        implicitWidth: root.contentWidth + root.padding * 2
        implicitHeight: body.implicitHeight + root.padding * 2

        readonly property real anchorX: {
            root.visible; // re-evaluate when opened
            const p = root.anchorItem.mapToItem(null, root.anchorItem.width / 2, 0)
            return p.x
        }
        margins.top: Theme.barHeight + 10
        margins.left: Math.max(8, Math.min((screen ? screen.width : 2560) - implicitWidth - 8, anchorX - implicitWidth / 2))

        Rectangle {
            id: frame
            anchors.fill: parent
            radius: 14
            color: Theme.mix(Qt.rgba(0.035, 0.035, 0.035, 0.94), Theme.tint, 0.07 * Theme.tintOn)
            border.width: 1
            border.color: "#3dffffff"
            opacity: root.visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 140 } }
            focus: true
            Keys.onEscapePressed: root.visible = false

            Column {
                id: body
                x: root.padding; y: root.padding
                width: root.contentWidth
                spacing: 12
            }
        }
    }
}
