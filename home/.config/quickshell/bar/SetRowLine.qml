// The thin line between two rows of a settings group (drawn in the gap above a row that isn't first). Made by Claude.
import QtQuick

Rectangle {
    property bool show: false
    visible: show; y: -7; x: -16; width: parent ? parent.width + 32 : 0; height: 1; color: "#1e1e1e"
}
