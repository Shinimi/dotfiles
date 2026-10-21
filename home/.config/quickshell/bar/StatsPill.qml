// CPU / RAM / GPU usage; click opens the system panel. Made by Claude.
import QtQuick

Pill {
    id: pill
    property alias popup: panel
    active: panel.visible
    Label { text: "  " + Stats.d.cpu + "%"; color: Theme.cyan }
    Label { text: "  " + Stats.d.ram + "%"; color: Theme.yellow }
    Label { text: "\u{f08ae}  " + Stats.d.gpu + "%"; color: Theme.purple }
    onClicked: panel.toggle()
    StatsPopup { id: panel; anchorItem: pill }
}
