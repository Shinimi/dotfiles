// Date panel (click the clock in the bar): today, the weather now and the next days, and the month.
// Made by Claude.
import QtQuick
import QtQuick.Layouts

BarPopup {
    id: popup
    property date now: new Date()
    property int monthOffset: 0
    contentWidth: 320
    padding: 18
    onVisibleChanged: if (visible) monthOffset = 0
    readonly property int week: {   // ISO week number
        const d = new Date(Date.UTC(now.getFullYear(), now.getMonth(), now.getDate())); const day = d.getUTCDay() || 7
        d.setUTCDate(d.getUTCDate() + 4 - day); const y0 = new Date(Date.UTC(d.getUTCFullYear(), 0, 1))
        return Math.ceil(((d - y0) / 86400000 + 1) / 7)
    }
    readonly property date shown: new Date(now.getFullYear(), now.getMonth() + monthOffset, 1)

    // ---------- today ----------
    Item {
        width: parent.width; height: 70
        Text {
            id: dayNum
            text: popup.now.getDate()
            color: "#ffffff"; font.family: Theme.font; font.pixelSize: 56; font.weight: Font.Light
        }
        Column {
            anchors.left: dayNum.right; anchors.leftMargin: 14; anchors.verticalCenter: dayNum.verticalCenter; spacing: 2
            Text { text: Qt.formatDate(popup.now, "dddd").toLowerCase(); color: "#ffffff"; font.family: Theme.font; font.pixelSize: 15; font.bold: true }
            Text { text: Qt.formatDate(popup.now, "MMMM yyyy").toLowerCase(); color: "#9a9a9a"; font.family: Theme.font; font.pixelSize: 12 }
            Text { text: "week " + popup.week + "  ·  " + Qt.formatTime(popup.now, "HH:mm"); color: "#5a5a5a"; font.family: Theme.font; font.pixelSize: 10; topPadding: 2 }
        }
    }

    // ---------- weather ----------
    Rectangle {
        visible: Weather.ready
        width: parent.width; height: wcol.implicitHeight + 28; radius: 12
        color: "#0affffff"; border.width: 1; border.color: "#16ffffff"
        Column {
            id: wcol
            x: 14; y: 14; width: parent.width - 28; spacing: 14
            RowLayout {
                width: parent.width; spacing: 14
                Text { text: Weather.icon; color: "#ffffff"; font.family: Theme.font; font.pixelSize: 34 }
                Column {
                    Layout.fillWidth: true; spacing: 1
                    Text { text: Weather.temp + "°"; color: "#ffffff"; font.family: Theme.font; font.pixelSize: 26; font.bold: true }
                    Text { text: Weather.desc.toLowerCase(); color: "#b0b0b0"; font.family: Theme.font; font.pixelSize: 11 }
                }
                Column {
                    spacing: 3
                    Text { anchors.right: parent.right; text: "feels " + Weather.feels + "°"; color: "#9a9a9a"; font.family: Theme.font; font.pixelSize: 10 }
                    Text { anchors.right: parent.right; text: "\u{f058e} " + Weather.humidity + "%"; color: "#9a9a9a"; font.family: Theme.font; font.pixelSize: 10 }
                    Text { anchors.right: parent.right; text: "\u{f059d} " + Weather.wind + " km/h"; color: "#9a9a9a"; font.family: Theme.font; font.pixelSize: 10 }
                }
            }
            Rectangle { width: parent.width; height: 1; color: "#14ffffff" }
            Row {
                width: parent.width
                Repeater {
                    model: Weather.days
                    Column {
                        required property var modelData
                        required property int index
                        width: parent.width / Math.max(1, Weather.days.length); spacing: 5
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: index === 0 ? "today" : Qt.formatDate(new Date(modelData.date), "ddd").toLowerCase()
                               color: index === 0 ? "#ffffff" : "#8a8a8a"; font.family: Theme.font; font.pixelSize: 10 }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.icon; color: "#e0e0e0"; font.family: Theme.font; font.pixelSize: 17 }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.max + "°  " + modelData.min + "°"; color: "#a0a0a0"; font.family: Theme.font; font.pixelSize: 10 }
                    }
                }
            }
            Text { text: "\u{f05f6}  " + Weather.place.toLowerCase(); color: "#5a5a5a"; font.family: Theme.font; font.pixelSize: 9 }
        }
    }

    // ---------- month ----------
    RowLayout {
        width: parent.width
        Text { text: Qt.formatDateTime(popup.shown, "MMMM yyyy").toLowerCase(); color: "#e8e8e8"; font.family: Theme.font; font.pixelSize: 12; font.bold: true; Layout.fillWidth: true }
        Repeater {
            model: [["\u{f0141}", -1], ["\u{f0d74}", 0], ["\u{f0142}", 1]]
            Rectangle {
                required property var modelData
                width: 26; height: 26; radius: 13
                color: navMouse.containsMouse ? "#1affffff" : "transparent"
                Text { anchors.centerIn: parent; text: modelData[0]; color: "#c8c8c8"; font.family: Theme.font; font.pixelSize: 13 }
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
            model: ["m", "t", "w", "t", "f", "s", "s"]
            Text { required property var modelData; width: grid.cell; height: 22; text: modelData; horizontalAlignment: Text.AlignHCenter
                   color: "#5a5a5a"; font.family: Theme.font; font.pixelSize: 10 }
        }
        Repeater {
            model: 42
            Rectangle {
                required property int index
                readonly property int lead: (popup.shown.getDay() + 6) % 7
                readonly property date day: new Date(popup.shown.getFullYear(), popup.shown.getMonth(), index - lead + 1)
                readonly property bool inMonth: day.getMonth() === popup.shown.getMonth()
                readonly property bool isToday: day.toDateString() === popup.now.toDateString()
                width: grid.cell; height: 32; radius: 16
                color: isToday ? Theme.on : (dm.containsMouse && inMonth ? "#12ffffff" : "transparent")
                Text {
                    anchors.centerIn: parent
                    text: day.getDate()
                    font.family: Theme.font; font.pixelSize: 12; font.bold: isToday
                    color: isToday ? Theme.onText : (!inMonth ? "#333333" : (day.getDay() === 0 || day.getDay() === 6) ? "#8a8a8a" : "#e0e0e0")
                }
                MouseArea { id: dm; anchors.fill: parent; hoverEnabled: true }
            }
        }
    }
}
