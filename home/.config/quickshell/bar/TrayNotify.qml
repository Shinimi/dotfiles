// Minimal tray icons + notification bell in one small pill. Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.SystemTray

Pill {
    id: pill
    padding: 10
    property alias popup: notifPanel
    readonly property int notifCount: Notifs.count
    readonly property bool dnd: Notifs.dnd

    Repeater {
        model: SystemTray.items
        Item {
            required property var modelData
            width: 16; height: 16
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
            IconImage { anchors.fill: parent; source: modelData.icon; opacity: trayMouse.containsMouse ? 1 : 0.75 }
            MouseArea {
                id: trayMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: m => {
                    if (m.button === Qt.RightButton || modelData.onlyMenu) {
                        const win = pill.QsWindow.window
                        const p = mapToItem(win.contentItem, 0, height + 10)
                        modelData.display(win, p.x, p.y)
                    } else modelData.activate()
                }
            }
        }
    }

    Rectangle { visible: SystemTray.items.values.length > 0; width: 1; height: 14; color: Theme.line; anchors.verticalCenter: parent ? parent.verticalCenter : undefined }

    Item {
        width: 14; height: 16
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        Label { anchors.centerIn: parent; text: pill.dnd ? "" : ""; color: pill.dnd ? Theme.muted : Theme.fg }
        Rectangle {
            visible: pill.notifCount > 0 && !pill.dnd
            width: 7; height: 7; radius: 4; color: Theme.red
            border.width: 1; border.color: Theme.bg
            x: parent.width - 4; y: -1
        }
        MouseArea {
            anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: m => { if (m.button === Qt.RightButton) Notifs.dnd = !Notifs.dnd; else notifPanel.toggle() }
        }
    }

    NotifPanel { id: notifPanel; anchorItem: pill }
}
