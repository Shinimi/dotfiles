// Media panel: album art, track info, progress, controls. Made by Claude.
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

BarPopup {
    id: popup
    property var player
    // album art: keep the last picture while a new track loads (an empty image source crashes Qt 6.12)
    property string art: ""
    readonly property string liveArt: popup.player ? (popup.player.trackArtUrl || "") : ""
    onLiveArtChanged: if (liveArt !== "") art = liveArt
    contentWidth: 320
    function fmt(s) { s = Math.max(0, Math.floor(s)); return Math.floor(s / 60) + ":" + ("0" + (s % 60)).slice(-2) }
    Timer { running: popup.visible && popup.player && popup.player.isPlaying; interval: 1000; repeat: true; onTriggered: popup.player.positionChanged() }

    RowLayout {
        width: parent.width; spacing: 14
        ClippingRectangle {
            width: 84; height: 84; radius: 2; color: Theme.card
            Image { anchors.fill: parent; source: popup.art; fillMode: Image.PreserveAspectCrop; asynchronous: true }
            Label { anchors.centerIn: parent; visible: popup.art === ""; text: ""; font.pixelSize: 28; color: Theme.muted }
        }
        Column {
            Layout.fillWidth: true; spacing: 4
            Label { width: parent.width; text: popup.player ? popup.player.trackTitle : ""; font.pixelSize: 15; font.weight: Font.Bold; elide: Text.ElideRight }
            Label { width: parent.width; text: popup.player ? popup.player.trackArtist : ""; color: Theme.blue; elide: Text.ElideRight }
            Label { width: parent.width; text: popup.player ? popup.player.trackAlbum : ""; color: Theme.muted; font.pixelSize: 11; elide: Text.ElideRight }
            Label { text: popup.player ? popup.player.identity : ""; color: Theme.line; font.pixelSize: 10 }
        }
    }
    Column {
        width: parent.width; spacing: 4
        visible: popup.player && popup.player.lengthSupported && popup.player.length > 0
        Slider {
            value: popup.player && popup.player.length > 0 ? popup.player.position / popup.player.length : 0
            accent: Theme.purple
            onMoved: v => { if (popup.player && popup.player.canSeek) popup.player.position = v * popup.player.length }
        }
        RowLayout {
            width: parent.width
            Label { text: popup.player ? popup.fmt(popup.player.position) : ""; color: Theme.muted; font.pixelSize: 10; Layout.fillWidth: true }
            Label { text: popup.player ? popup.fmt(popup.player.length) : ""; color: Theme.muted; font.pixelSize: 10 }
        }
    }
    Row {
        anchors.horizontalCenter: parent.horizontalCenter; spacing: 14
        Repeater {
            model: [["", "prev"], ["", "toggle"], ["", "next"]]
            Rectangle {
                required property var modelData
                readonly property bool main: modelData[1] === "toggle"
                width: main ? 48 : 38; height: width; radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                color: main ? Theme.purple : (cMouse.containsMouse ? Theme.bgHover : Theme.bgAlt)
                Label {
                    anchors.centerIn: parent
                    text: main ? (popup.player && popup.player.isPlaying ? "" : "") : modelData[0]
                    color: main ? Theme.bg : Theme.fg; font.pixelSize: main ? 16 : 13
                }
                MouseArea {
                    id: cMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { if (!popup.player) return; if (modelData[1] === "prev") popup.player.previous(); else if (modelData[1] === "next") popup.player.next(); else popup.player.togglePlaying() }
                }
            }
        }
    }
}
