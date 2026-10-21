// One notification. Used for pop-ups and in the panel. Made by Claude.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

Rectangle {
    id: card
    required property var notif
    property bool popup: false
    readonly property bool critical: notif && notif.urgency === NotificationUrgency.Critical
    width: parent ? parent.width : 340
    implicitHeight: col.implicitHeight + 24
    radius: 12
    color: popup ? Theme.bg : Theme.bgAlt
    border.width: 1
    border.color: critical ? Theme.red : (popup ? Theme.line : "transparent")

    Timer {
        running: card.popup && !card.critical && !hover.containsMouse
        interval: card.notif && card.notif.expireTimeout > 0 ? card.notif.expireTimeout : 5000
        onTriggered: Notifs.removePopup(card.notif)
    }
    MouseArea {
        id: hover; anchors.fill: parent; hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: m => {
            if (m.button === Qt.RightButton || !card.popup) { card.notif.dismiss(); Notifs.removePopup(card.notif) }
            else Notifs.removePopup(card.notif)
        }
    }
    Column {
        id: col
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 12
        spacing: 6
        RowLayout {
            width: parent.width; spacing: 10
            IconImage {
                implicitSize: 34
                source: card.notif ? (card.notif.image || Quickshell.iconPath(card.notif.appIcon || card.notif.desktopEntry, true) || Quickshell.iconPath("dialog-information")) : ""
            }
            Column {
                Layout.fillWidth: true; spacing: 2
                RowLayout {
                    width: parent.width
                    Label { text: card.notif ? card.notif.appName : ""; color: card.critical ? Theme.red : Theme.blue; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                    Label { text: ""; color: closeMouse.containsMouse ? Theme.red : Theme.muted; font.pixelSize: 11
                        MouseArea { id: closeMouse; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { card.notif.dismiss(); Notifs.removePopup(card.notif) } } }
                }
                Label { width: parent.width; text: card.notif ? card.notif.summary : ""; font.weight: Font.Bold; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight }
                Label { width: parent.width; visible: text !== ""; text: card.notif ? card.notif.body : ""; color: Theme.fgDim; font.weight: Font.Normal; textFormat: Text.StyledText; wrapMode: Text.Wrap; maximumLineCount: 4; elide: Text.ElideRight }
            }
        }
        Row {
            visible: card.notif && card.notif.actions.length > 0
            spacing: 6; leftPadding: 44
            Repeater {
                model: card.notif ? card.notif.actions : []
                Rectangle {
                    required property var modelData
                    width: aLabel.implicitWidth + 20; height: 26; radius: 8
                    color: aMouse.containsMouse ? Theme.bgHover : Theme.bgAlt; border.width: 1; border.color: Theme.line
                    Label { id: aLabel; anchors.centerIn: parent; text: modelData.text; font.pixelSize: 11 }
                    MouseArea { id: aMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { modelData.invoke(); Notifs.removePopup(card.notif) } }
                }
            }
        }
    }
}
