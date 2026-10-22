// The middle of the bar: just the time (and a running timer). Click it for the date, weather and month
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
        color: "#ffffff"; font.pixelSize: 13; font.weight: Font.Bold; font.letterSpacing: 1
    }
    Label { visible: Timers.timerRunning; text: "\u{f051f} " + Timers.fmt(Timers.remaining); color: "#ffffff"; font.pixelSize: 11 }
    Label { visible: Timers.swRunning && !Timers.timerRunning; text: "\u{f13ab} " + Timers.fmt(Math.floor(Timers.elapsed / 100)); color: "#ffffff"; font.pixelSize: 11 }
    onClicked: if (pill.calendar) cal.toggle()
    CalendarPopup { id: cal; anchorItem: pill; now: clock.date }
}
