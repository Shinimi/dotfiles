// One notification: a soft rounded card. Pop-ups add the app name, a close button and a countdown line,
// and slide in from the right. Made by Claude.
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

Rectangle {
    id: card
    property var notif: null
    property bool popup: false
    readonly property bool critical: notif && notif.urgency === NotificationUrgency.Critical
    width: parent ? parent.width : 340
    implicitHeight: col.implicitHeight + 24
    radius: popup ? 16 : 8
    color: popup ? "#f20b0b0b" : "#161616"
    border.width: 1
    border.color: critical ? Theme.red : (popup ? "#14ffffff" : "transparent")
    readonly property date born: new Date()
    readonly property string num: card.notif ? String(card.notif.id % 100).padStart(2, "0") : "00"

    // ---- pop-up dressing: seam, brackets, slide-in, countdown ----
    transform: Translate { id: slide; x: card.popup ? 60 : 0 }
    opacity: card.popup ? 0 : 1
    Component.onCompleted: if (card.popup) enter.start()
    ParallelAnimation {
        id: enter
        NumberAnimation { target: slide; property: "x"; to: 0; duration: 340; easing.type: Easing.OutCubic }
        NumberAnimation { target: card; property: "opacity"; to: 1; duration: 260 }
    }
    Rectangle {   // countdown: shrinks until the pop-up goes away
        id: countdown
        visible: card.popup && !card.critical
        anchors.bottom: parent.bottom; anchors.bottomMargin: 1; x: 18; height: 2; radius: 1; color: "#55ffffff"
        width: card.width - 36
        NumberAnimation on width {
            running: card.popup && !card.critical; paused: hover.containsMouse
            from: card.width - 36; to: 0; duration: Settings.cur("notif_timeout") * 1000
        }
    }

    // Deferred: removing the card rebuilds the list, which must not happen inside the card's own handler
    function close(dismiss) {
        if (!card.notif) return
        const id = card.notif.id
        Qt.callLater(() => {
            Notifs.removePopup(id)
            if (dismiss) { const n = Notifs.notifById(id); if (n) n.dismiss() }
        })
    }

    Timer {
        running: card.popup && !card.critical && !hover.containsMouse
        interval: Settings.cur("notif_timeout") * 1000
        onTriggered: card.close(false)
    }
    MouseArea {
        id: hover; anchors.fill: parent; hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: m => {
            card.close(m.button === Qt.RightButton || !card.popup)
        }
    }
    Column {
        id: col
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 12
        anchors.leftMargin: 14
        spacing: card.popup ? 8 : 6
        RowLayout {   // pop-up header: app ········ 17:52  ✕
            visible: card.popup
            width: parent.width; spacing: 8
            Text { Layout.fillWidth: true; elide: Text.ElideRight; text: (card.notif ? card.notif.appName : "").toLowerCase()
                   color: card.critical ? Theme.red : "#8a8a8a"; font.family: Theme.font; font.pixelSize: 10; font.bold: true }
            Text { text: Qt.formatTime(card.born, "HH:mm"); color: "#6a6a6a"; font.family: Theme.font; font.pixelSize: 10 }
            Text { text: "\u{f0156}"; color: hClose.containsMouse ? "#ffffff" : "#6a6a6a"; font.family: Theme.font; font.pixelSize: 12
                   MouseArea { id: hClose; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: card.close(true) } }
        }
        RowLayout {
            width: parent.width; spacing: 10
            Item {
                implicitWidth: 34; implicitHeight: 34
                IconImage {
                    id: nIcon; anchors.fill: parent; visible: !card.popup
                    source: card.notif ? (card.notif.image || Quickshell.iconPath(card.notif.appIcon || card.notif.desktopEntry, true) || Quickshell.iconPath("dialog-information")) : ""
                }
                MultiEffect { visible: card.popup; anchors.fill: nIcon; source: nIcon; saturation: -1.0 }
            }
            Column {
                Layout.fillWidth: true; spacing: 2
                RowLayout {
                    visible: !card.popup
                    width: parent.width
                    Label { text: card.notif ? card.notif.appName : ""; color: card.critical ? Theme.red : Theme.blue; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                    Label { text: ""; color: closeMouse.containsMouse ? Theme.red : Theme.muted; font.pixelSize: 11
                        MouseArea { id: closeMouse; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: card.close(true) } }
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
                    width: aLabel.implicitWidth + 20; height: 26; radius: 13
                    color: aMouse.containsMouse ? Theme.bgHover : Theme.bgAlt; border.width: 1; border.color: Theme.line
                    Label { id: aLabel; anchors.centerIn: parent; text: modelData.text; font.pixelSize: 11 }
                    MouseArea { id: aMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (card.notif) modelData.invoke(); card.close(false) } }
                }
            }
        }
    }
}
