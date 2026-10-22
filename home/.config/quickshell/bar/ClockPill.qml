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
    Label {
        text: Qt.formatDateTime(clock.date, (Settings.cur("clock_12h") ? "h:mm" : "HH:mm") + (Settings.cur("clock_seconds") ? ":ss" : "") + (Settings.cur("clock_12h") ? " AP" : ""))
        color: "#ffffff"; font.pixelSize: 13; font.weight: Font.Bold; font.letterSpacing: 1
    }
    Label { text: "·"; color: "#4a4a4a" }
    Label { text: Qt.formatDateTime(clock.date, "ddd d MMM"); color: "#b0b0b0"; font.pixelSize: 11; font.weight: Font.Normal }
    Label { visible: Weather.ready; text: "·"; color: "#4a4a4a" }
    Label { visible: Weather.ready; text: Weather.icon + "  " + Weather.temp + "°"; color: "#b0b0b0"; font.pixelSize: 11; font.weight: Font.Normal }
    Label { visible: Timers.timerRunning; text: "\u{f051f} " + Timers.fmt(Timers.remaining); color: "#ffffff"; font.pixelSize: 11 }
    Label { visible: Timers.swRunning && !Timers.timerRunning; text: "\u{f13ab} " + Timers.fmt(Math.floor(Timers.elapsed / 100)); color: "#ffffff"; font.pixelSize: 11 }
    onClicked: if (pill.calendar) cal.toggle()
    CalendarPopup { id: cal; anchorItem: pill; now: clock.date }
}
