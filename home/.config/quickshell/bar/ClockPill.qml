// The middle of the bar: time · date · weather (and a running timer). Click opens the calendar
// (`calendar: false` on screens that shouldn't). Made by Claude.
import QtQuick
import Quickshell

Pill {
    id: pill
    property alias popup: cal
    property bool calendar: true
    padding: 12
    active: cal.visible
    SystemClock { id: clock; precision: Settings.cur("clock_seconds") ? SystemClock.Seconds : SystemClock.Minutes }
    // one size, one weight, one baseline: the time is just brighter than the date and weather
    Label {
        text: Qt.formatDateTime(clock.date, (Settings.cur("clock_12h") ? "h:mm" : "HH:mm") + (Settings.cur("clock_seconds") ? ":ss" : "") + (Settings.cur("clock_12h") ? " AP" : ""))
        color: "#ffffff"; font.pixelSize: 12; font.weight: Font.Bold
    }
    Label { text: "/"; color: "#3a3a3a"; font.pixelSize: 12 }
    Label { text: Qt.formatDateTime(clock.date, "ddd d MMM").toLowerCase(); color: "#a8a8a8"; font.pixelSize: 12; font.weight: Font.Medium }
    Label { visible: Weather.ready; text: "/"; color: "#3a3a3a"; font.pixelSize: 12 }
    Row {
        visible: Weather.ready; spacing: 6
        Label { anchors.verticalCenter: parent.verticalCenter; text: Weather.icon; color: "#a8a8a8"; font.pixelSize: 13; font.weight: Font.Medium }
        Label { anchors.verticalCenter: parent.verticalCenter; text: Weather.temp + "°"; color: "#a8a8a8"; font.pixelSize: 12; font.weight: Font.Medium }
    }
    Label { visible: Timers.timerRunning; text: "\u{f051f} " + Timers.fmt(Timers.remaining); color: "#ffffff"; font.pixelSize: 11 }
    Label { visible: Timers.swRunning && !Timers.timerRunning; text: "\u{f13ab} " + Timers.fmt(Math.floor(Timers.elapsed / 100)); color: "#ffffff"; font.pixelSize: 11 }
    onClicked: if (pill.calendar) cal.toggle()
    CalendarPopup { id: cal; anchorItem: pill; now: clock.date }
}
