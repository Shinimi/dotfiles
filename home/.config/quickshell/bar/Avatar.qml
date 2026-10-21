// Your picture (Settings → Account), or the gradient logo if none is set. Made by Claude.
import QtQuick
import Quickshell.Widgets

ClippingRectangle {
    id: a
    property int size: 46
    property string pick: ""          // preview a picture before it's applied
    readonly property string src: pick !== "" ? pick : (Settings.cur("cc_logo") === "avatar" ? Settings.cur("avatar") : "")
    width: size; height: size; radius: size * 0.32; color: "transparent"
    Rectangle {
        anchors.fill: parent
        gradient: Gradient { orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Theme.blue } GradientStop { position: 1; color: Theme.purple } }
    }
    Label { anchors.centerIn: parent; visible: a.src === ""; text: "\u{f08c7}"; color: Theme.bg; font.pixelSize: a.size * 0.48 }
    Image {
        anchors.fill: parent; visible: a.src !== ""; asynchronous: true
        source: Theme.fileUrl(a.src)
        fillMode: Image.PreserveAspectCrop; sourceSize.width: a.size * 2; sourceSize.height: a.size * 2
    }
}
