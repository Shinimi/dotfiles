// The middle of the bar: just the time (and a running timer). Click it for the date, weather and month
// (`calendar: false` on screens that shouldn't). Made by Claude.
import QtQuick
import Quickshell

Pill {
    id: pill
    property alias popup: cal
    property bool calendar: true
    property var player: null            // (unused now: the bar shows no song)
    padding: 14
    active: cal.visible
    SystemClock { id: clock; precision: Settings.cur("clock_seconds") ? SystemClock.Seconds : SystemClock.Minutes }
    // one size, one weight, one baseline: the time is just brighter than the date and weather
    Item {   // the time; hover and it turns into the date and weather
        width: Math.max(timeT.implicitWidth, pill.hovered ? dateT.implicitWidth : 0); height: timeT.implicitHeight
        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Label {
            id: timeT; anchors.centerIn: parent
            text: Qt.formatDateTime(clock.date, (Settings.cur("clock_12h") ? "h:mm" : "HH:mm") + (Settings.cur("clock_seconds") ? ":ss" : "") + (Settings.cur("clock_12h") ? " AP" : ""))
            color: "#ffffff"; font.pixelSize: 13; font.weight: Font.Bold; font.letterSpacing: 1.5
            opacity: pill.hovered ? 0 : 1; Behavior on opacity { NumberAnimation { duration: 160 } }
        }
        Label {
            id: dateT; anchors.centerIn: parent
            text: Qt.formatDate(clock.date, "dddd d MMMM") + (Weather.ready ? "  ·  " + Weather.icon + " " + Weather.temp + "°" : "")
            color: "#e6e6e6"; font.pixelSize: 12; font.weight: Font.Medium
            opacity: pill.hovered ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 160 } }
        }
    }
    Label { visible: Timers.timerRunning; text: "\u{f051f} " + Timers.fmt(Timers.remaining); color: "#ffffff"; font.pixelSize: 11 }
    Label { visible: Timers.swRunning && !Timers.timerRunning; text: "\u{f13ab} " + Timers.fmt(Math.floor(Timers.elapsed / 100)); color: "#ffffff"; font.pixelSize: 11 }
    onClicked: if (pill.calendar) cal.toggle()
    CalendarPopup { id: cal; anchorItem: pill; now: clock.date }
}
