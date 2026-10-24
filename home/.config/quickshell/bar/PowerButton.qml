// Power button in the bar: opens the full-screen power menu (PowerMenu.qml). Made by Claude.
import QtQuick
import Quickshell

Pill {
    id: pill
    readonly property var popup: PowerMenu   // the bar asks popup.visible / popup.toggle()
    implicitWidth: 34
    active: PowerMenu.visible
    Label { text: ""; color: pill.hovered ? "#ffffff" : Theme.fg; font.pixelSize: 15 }
    property bool menu: true             // kept for the side screen bar; both open the same menu now
    onClicked: PowerMenu.toggle()
}
