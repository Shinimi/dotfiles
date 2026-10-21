// Control center button. Made by Claude.
import QtQuick
Pill {
    id: pill
    property alias popup: cc
    padding: 10
    active: cc.visible
    Label { text: ""; color: Theme.blue; font.pixelSize: 13 }
    onClicked: cc.toggle()
    ControlCenter { id: cc; anchorItem: pill }
}
