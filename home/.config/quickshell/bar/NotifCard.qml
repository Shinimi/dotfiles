// One notification card, used by the pop-ups and the lists. Header: app icon, app name, how long ago, close.
// Then the sender's picture (if the app sends one), the title and text, action buttons, and a reply box when the
// app supports answering from the notification. Pop-ups slide in from the right and show a countdown line.
// Left click: pop-up goes away (list: dismiss). Right click: dismiss. Made by Claude.
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "."   // our own Label wins over the Qt Controls one

Rectangle {
    id: card
    property var notif: null
    property bool popup: false
    readonly property bool critical: notif && notif.urgency === NotificationUrgency.Critical
    width: parent ? parent.width : 360
    implicitHeight: col.implicitHeight + 28
    radius: 18
    color: popup ? "#f40b0b0b" : (hover.containsMouse ? "#181818" : "#141414")
    border.width: 1
    border.color: critical ? "#cf6b6b" : popup ? "#26ffffff" : "#1f1f1f"
    Behavior on color { ColorAnimation { duration: 120 } }
    readonly property date born: new Date()
    property date now: new Date()
    Timer { interval: 30000; running: !card.popup; repeat: true; onTriggered: card.now = new Date() }
    readonly property string ago: {
        const m = Math.floor((now - born) / 60000)
        return m < 1 ? "now" : m < 60 ? m + " min ago" : Qt.formatTime(born, "HH:mm")
    }
    readonly property bool imageIsIcon: !!notif && String(notif.image || "").startsWith("image://icon/")   // an icon name, not a picture
    readonly property string appIcon: notif ? (Quickshell.iconPath(notif.appIcon || notif.desktopEntry || "", true) || (imageIsIcon ? notif.image : "")) : ""
    readonly property string picture: notif && !imageIsIcon ? (notif.image || "") : ""

    // ---- pop-up: slide in, countdown ----
    transform: Translate { id: slide; x: card.popup ? 60 : 0 }
    opacity: card.popup ? 0 : 1
    Component.onCompleted: if (card.popup) enter.start()
    ParallelAnimation {
        id: enter
        NumberAnimation { target: slide; property: "x"; to: 0; duration: 340; easing.type: Easing.OutCubic }
        NumberAnimation { target: card; property: "opacity"; to: 1; duration: 260 }
    }
    Rectangle {   // countdown: shrinks until the pop-up goes away (stops while you hover)
        visible: card.popup && !card.critical
        anchors.bottom: parent.bottom; anchors.bottomMargin: 6; x: 18; height: 2; radius: 1; color: "#40ffffff"
        width: card.width - 36
        NumberAnimation on width {
            running: card.popup && !card.critical; paused: hover.containsMouse || reply.activeFocus
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
        running: card.popup && !card.critical && !hover.containsMouse && !reply.activeFocus
        interval: Settings.cur("notif_timeout") * 1000
        onTriggered: card.close(false)
    }
    MouseArea {
        id: hover; anchors.fill: parent; hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: m => card.close(m.button === Qt.RightButton || !card.popup)
    }

    Column {
        id: col
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14
        spacing: 10
        RowLayout {   // app ·········· 5 min ago  ✕
            width: parent.width; spacing: 8
            Rectangle {
                width: 22; height: 22; radius: 7; color: "#1f1f1f"
                IconImage { id: ai; anchors.centerIn: parent; implicitSize: 14; source: card.appIcon; visible: false }
                MultiEffect { anchors.fill: ai; source: ai; saturation: -1.0; visible: card.appIcon !== "" }
                Text { anchors.centerIn: parent; visible: card.appIcon === ""; text: "\u{f009a}"; color: "#9a9a9a"; font.family: Theme.font; font.pixelSize: 11 }
            }
            Text { Layout.fillWidth: true; elide: Text.ElideRight; text: card.notif ? card.notif.appName : ""
                   color: card.critical ? "#cf6b6b" : "#a8a8a8"; font.family: Theme.font; font.pixelSize: 11; font.bold: true }
            Text { text: card.ago; color: "#5e5e5e"; font.family: Theme.font; font.pixelSize: 10 }
            Rectangle {
                width: 22; height: 22; radius: 11; color: hClose.containsMouse ? "#ececec" : "transparent"
                Text { anchors.centerIn: parent; text: "\u{f0156}"; color: hClose.containsMouse ? "#0b0b0b" : "#6a6a6a"; font.family: Theme.font; font.pixelSize: 12 }
                MouseArea { id: hClose; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: card.close(true) }
            }
        }
        RowLayout {
            width: parent.width; spacing: 12
            ClippingRectangle {   // the sender's picture, when the app sends one
                visible: card.picture !== ""
                Layout.alignment: Qt.AlignTop
                width: 42; height: 42; radius: 21; color: "#1f1f1f"
                Image { anchors.fill: parent; source: card.picture; fillMode: Image.PreserveAspectCrop; sourceSize.width: 84; asynchronous: true }
            }
            Column {
                Layout.fillWidth: true; spacing: 3
                Label { width: parent.width; text: card.notif ? card.notif.summary : ""; color: "#f2f2f2"; font.pixelSize: 13; font.weight: Font.Bold; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight }
                Label { width: parent.width; visible: text !== ""; text: card.notif ? card.notif.body : ""; color: "#9a9a9a"; font.pixelSize: 11; font.weight: Font.Normal
                        textFormat: Text.StyledText; wrapMode: Text.Wrap; maximumLineCount: 4; elide: Text.ElideRight; lineHeight: 1.15 }
            }
        }
        Flow {   // the app's own buttons
            visible: card.notif && card.notif.actions.length > 0
            width: parent.width; spacing: 6
            Repeater {
                model: card.notif ? card.notif.actions : []
                Rectangle {
                    required property var modelData
                    width: aLabel.implicitWidth + 24; height: 30; radius: 15
                    color: aMouse.containsMouse ? "#ececec" : "#1f1f1f"
                    Behavior on color { ColorAnimation { duration: 110 } }
                    Text { id: aLabel; anchors.centerIn: parent; text: modelData.text; color: aMouse.containsMouse ? "#0b0b0b" : "#dcdcdc"; font.family: Theme.font; font.pixelSize: 11; font.bold: true }
                    MouseArea { id: aMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (card.notif) modelData.invoke(); card.close(false) } }
                }
            }
        }
        TextField {   // reply right here (only apps that support it)
            id: reply
            visible: !!(card.notif && card.notif.hasInlineReply)
            width: parent.width; height: 36
            placeholderText: card.notif && card.notif.inlineReplyPlaceholder ? card.notif.inlineReplyPlaceholder : "Reply…"
            placeholderTextColor: "#5e5e5e"; color: "#f0f0f0"; font.family: Theme.font; font.pixelSize: 12; leftPadding: 14
            background: Rectangle { radius: 18; color: "#0e0e0e"; border.width: 1; border.color: reply.activeFocus ? "#55ffffff" : "#262626" }
            onAccepted: { if (text && card.notif) { card.notif.sendInlineReply(text); card.close(false) } }
        }
        Item { width: 1; height: card.popup ? 2 : 0 }
    }
}
