// Calendar panel: big clock + month grid (Monday first). Made by Claude.
import QtQuick
import QtQuick.Layouts

BarPopup {
    id: popup
    property date now: new Date()
    property int monthOffset: 0
    contentWidth: 280
    onVisibleChanged: if (visible) monthOffset = 0

    readonly property date shown: new Date(now.getFullYear(), now.getMonth() + monthOffset, 1)

    Column {
        width: parent.width; spacing: 2
        Label { text: Qt.formatDateTime(popup.now, "HH:mm:ss"); font.pixelSize: 34; font.weight: Font.Bold; color: Theme.fg }
        Label { text: Qt.formatDateTime(popup.now, "dddd, d MMMM yyyy"); color: Theme.blue }
    }
    // weather
    Rectangle {
        visible: Weather.ready
        width: parent.width; height: wcol.implicitHeight + 20; radius: 2; color: Theme.card
        Column {
            id: wcol
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 10
            spacing: 8
            RowLayout {
                width: parent.width; spacing: 10
                Label { text: Weather.icon; font.pixelSize: 26; color: Theme.yellow }
                Column {
                    Layout.fillWidth: true
                    Label { text: Weather.temp + "°  " + Weather.desc; font.pixelSize: 14 }
                    Label { text: "\uf041 " + Weather.place + "  ·  feels " + Weather.feels + "°"; color: Theme.muted; font.pixelSize: 11 }
                }
            }
            RowLayout {
                width: parent.width
                Label { text: "\ue373 " + Weather.humidity + "%"; color: Theme.cyan; font.pixelSize: 11; Layout.fillWidth: true }
                Label { text: "\ue34b " + Weather.wind + " km/h"; color: Theme.fgDim; font.pixelSize: 11 }
            }
            Row {
                width: parent.width
                Repeater {
                    model: Weather.days
                    Column {
                        required property var modelData
                        required property int index
                        width: parent.width / 3; spacing: 2
                        Label { anchors.horizontalCenter: parent.horizontalCenter; text: index === 0 ? "Today" : Qt.formatDate(new Date(modelData.date), "ddd"); color: Theme.muted; font.pixelSize: 11 }
                        Label { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.icon; color: Theme.yellow; font.pixelSize: 16 }
                        Label { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.max + "° / " + modelData.min + "°"; font.pixelSize: 11 }
                    }
                }
            }
        }
    }
    Rectangle { width: parent.width; height: 1; color: Theme.border }

    RowLayout {
        width: parent.width
        Label { text: Qt.formatDateTime(popup.shown, "MMMM yyyy"); Layout.fillWidth: true }
        Repeater {
            model: [["", -1], ["", 0], ["", 1]]
            Rectangle {
                required property var modelData
                width: 26; height: 22; radius: 2
                color: navMouse.containsMouse ? Theme.bgHover : "transparent"
                Label { anchors.centerIn: parent; text: modelData[0]; font.pixelSize: modelData[1] === 0 ? 7 : 11; color: Theme.fgDim }
                MouseArea {
                    id: navMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: popup.monthOffset = modelData[1] === 0 ? 0 : popup.monthOffset + modelData[1]
                }
            }
        }
    }

    Grid {
        id: grid
        columns: 7; columnSpacing: 2; rowSpacing: 2
        readonly property int cell: (popup.contentWidth - 6 * columnSpacing) / 7
        Repeater {
            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
            Label { required property var modelData; width: grid.cell; height: 20; text: modelData; horizontalAlignment: Text.AlignHCenter; color: Theme.muted; font.pixelSize: 11 }
        }
        Repeater {
            model: 42
            Rectangle {
                required property int index
                readonly property int lead: (popup.shown.getDay() + 6) % 7
                readonly property date day: new Date(popup.shown.getFullYear(), popup.shown.getMonth(), index - lead + 1)
                readonly property bool inMonth: day.getMonth() === popup.shown.getMonth()
                readonly property bool isToday: day.toDateString() === popup.now.toDateString()
                width: grid.cell; height: 30; radius: 2
                color: isToday ? Theme.blue : "transparent"
                Label {
                    anchors.centerIn: parent
                    text: day.getDate()
                    font.weight: isToday ? Font.Bold : Font.Normal
                    color: isToday ? Theme.bg : (inMonth ? ((day.getDay() === 0 || day.getDay() === 6) ? Theme.purple : Theme.fg) : Theme.line)
                }
            }
        }
    }
    TimerCard {}
}
