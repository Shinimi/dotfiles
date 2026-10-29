// Your picture (Settings → Account), or the logo if you picked that. If the picture file is gone, your initial
// on soft graphite instead of a blank circle. Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Widgets

ClippingRectangle {
    id: a
    property int size: 46
    property string pick: ""          // preview a picture before it's applied
    readonly property string src: pick !== "" ? pick : (Settings.cur("cc_logo") === "avatar" ? Settings.cur("avatar") : "")
    readonly property bool ok: img.status === Image.Ready
    width: size; height: size; radius: size * 0.32; color: "transparent"
    Rectangle {
        anchors.fill: parent; visible: !a.ok
        gradient: Gradient {
            GradientStop { position: 0; color: a.src === "" ? Theme.blue : "#3c3c3c" }
            GradientStop { position: 1; color: a.src === "" ? Theme.purple : "#141414" } }
    }
    Label {   // no picture chosen: the logo · picture missing: your initial
        anchors.centerIn: parent; visible: !a.ok
        text: a.src === "" ? "\u{f08c7}" : (Settings.cur("user_name") || Quickshell.env("USER") || "?").charAt(0).toUpperCase()
        color: a.src === "" ? Theme.bg : "#f2f2f2"; font.pixelSize: a.size * (a.src === "" ? 0.48 : 0.42); font.weight: Font.Bold
    }
    Image {
        id: img
        anchors.fill: parent; visible: a.ok; asynchronous: true
        source: Theme.fileUrl(a.src)
        fillMode: Image.PreserveAspectCrop; sourceSize.width: a.size * 2; sourceSize.height: a.size * 2
    }
}
