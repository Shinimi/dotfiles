// Settings: the small spaced-capitals heading used above groups and card grids. Made by Claude.
import QtQuick

Row {
    property string text; property string icon
    x: 6; spacing: 8
    Text { text: parent.icon; color: "#6a6a6a"; font.family: Theme.font; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
    Text { text: parent.text.toUpperCase(); color: "#808080"; font.family: Theme.font; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.6; anchors.verticalCenter: parent.verticalCenter }
}
