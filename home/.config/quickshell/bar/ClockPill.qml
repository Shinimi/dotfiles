// Time + date; click opens the calendar panel. Made by Claude.
import QtQuick
import Quickshell

Pill {
    property alias popup: cal
    id: pill
    padding: 14
    active: cal.visible
    SystemClock { id: clock; precision: SystemClock.Seconds }
    Label { text: Qt.formatDateTime(clock.date, (Settings.cur("clock_12h") ? "h:mm" : "HH:mm") + (Settings.cur("clock_seconds") ? ":ss" : "") + (Settings.cur("clock_12h") ? " AP" : "")); font.weight: Font.Bold; color: "#ffffff" }
    Label { visible: Settings.cur("clock_date"); text: "·"; color: "#4a4a4a" }
    Label { visible: Settings.cur("clock_date"); text: Qt.formatDateTime(clock.date, "ddd d MMM"); color: Theme.fgDim; font.weight: Font.Normal }
    Label { visible: Weather.ready && Settings.cur("bar_weather"); text: "·"; color: "#4a4a4a" }
    Label { visible: Weather.ready && Settings.cur("bar_weather"); text: Weather.icon + " " + Weather.temp + "°"; color: Theme.fgDim; font.weight: Font.Normal }
    Label { visible: Timers.timerRunning; text: "·"; color: "#4a4a4a" }
    Label { visible: Timers.timerRunning; text: "\uf254 " + Timers.fmt(Timers.remaining); color: Theme.blue }
    Label { visible: Timers.swRunning && !Timers.timerRunning; text: "·"; color: "#4a4a4a" }
    Label { visible: Timers.swRunning && !Timers.timerRunning; text: "\uf2f2 " + Timers.fmt(Math.floor(Timers.elapsed / 100)); color: Theme.green }
    onClicked: cal.toggle()
    CalendarPopup { id: cal; anchorItem: pill; now: clock.date }
}
