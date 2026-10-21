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
    readonly property var barWindow: anchorItem.QsWindow.window

    function toggle() { visible = !visible }
    onVisibleChanged: if (visible) PopupState.current = root
    Connections {
        target: PopupState
        function onCurrentChanged() { if (PopupState.current !== root) root.visible = false }
    }

    // click-catcher below the bar line: clicking anywhere outside closes the panel
    PanelWindow {
        visible: root.visible
        screen: root.barWindow ? root.barWindow.screen : null
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
        screen: root.barWindow ? root.barWindow.screen : null
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
            color: Theme.bg
            border.width: 1
            border.color: Theme.line
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
