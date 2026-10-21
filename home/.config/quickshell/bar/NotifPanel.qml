// Notification panel (bell). Made by Claude.
import QtQuick
import QtQuick.Layouts

BarPopup {
    id: panel
    contentWidth: 360
    RowLayout {
        width: parent.width; spacing: 8
        Label { text: "Notifications"; font.pixelSize: 15; font.weight: Font.Bold; Layout.fillWidth: true }
        Rectangle {
            width: dndRow.implicitWidth + 18; height: 26; radius: 8
            color: Notifs.dnd ? Theme.purple : (dndMouse.containsMouse ? Theme.bgHover : Theme.bgAlt)
            Row { id: dndRow; anchors.centerIn: parent; spacing: 6
                Label { text: ""; color: Notifs.dnd ? Theme.bg : Theme.fgDim; font.pixelSize: 11 }
                Label { text: "Silent"; color: Notifs.dnd ? Theme.bg : Theme.fgDim; font.pixelSize: 11 } }
            MouseArea { id: dndMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Notifs.dnd = !Notifs.dnd }
        }
        Rectangle {
            visible: Notifs.count > 0
            width: clr.implicitWidth + 18; height: 26; radius: 8
            color: clrMouse.containsMouse ? Theme.bgHover : Theme.bgAlt
            Label { id: clr; anchors.centerIn: parent; text: "Clear all"; color: Theme.fgDim; font.pixelSize: 11 }
            MouseArea { id: clrMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Notifs.clearAll() }
        }
    }
    Item {
        visible: Notifs.count === 0
        width: parent.width; height: 110
        Column {
            anchors.centerIn: parent; spacing: 8
            Label { anchors.horizontalCenter: parent.horizontalCenter; text: ""; font.pixelSize: 26; color: Theme.line }
            Label { anchors.horizontalCenter: parent.horizontalCenter; text: "You're all caught up"; color: Theme.muted }
        }
    }
    ListView {
        visible: Notifs.count > 0
        width: parent.width
        height: Math.min(contentHeight, 460)
        clip: true
        spacing: 8
        verticalLayoutDirection: ListView.BottomToTop      // newest on top
        model: Notifs.model
        delegate: NotifCard { required property var modelData; notif: modelData; width: ListView.view ? ListView.view.width : 360 }
    }
}
