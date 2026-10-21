// Time + date; click opens the calendar panel. Made by Claude.
import QtQuick
import Quickshell

Pill {
    property alias popup: cal
    id: pill
    padding: 14
    active: cal.visible
    SystemClock { id: clock; precision: SystemClock.Seconds }
    Label { text: ""; color: Theme.blue }
    Label { text: Qt.formatDateTime(clock.date, (Settings.cur("clock_12h") ? "h:mm" : "HH:mm") + (Settings.cur("clock_seconds") ? ":ss" : "") + (Settings.cur("clock_12h") ? " AP" : "")) }
    Label { visible: Settings.cur("clock_date"); text: "·"; color: Theme.muted }
    Label { visible: Settings.cur("clock_date"); text: Qt.formatDateTime(clock.date, "ddd d MMM"); color: Theme.fgDim }
    Label { visible: Weather.ready && Settings.cur("bar_weather"); text: "·"; color: Theme.muted }
    Label { visible: Weather.ready && Settings.cur("bar_weather"); text: Weather.icon + "  " + Weather.temp + "°"; color: Theme.yellow }
    Label { visible: Timers.timerRunning; text: "·"; color: Theme.muted }
    Label { visible: Timers.timerRunning; text: "\uf254 " + Timers.fmt(Timers.remaining); color: Theme.blue }
    Label { visible: Timers.swRunning && !Timers.timerRunning; text: "·"; color: Theme.muted }
    Label { visible: Timers.swRunning && !Timers.timerRunning; text: "\uf2f2 " + Timers.fmt(Math.floor(Timers.elapsed / 100)); color: Theme.green }
    onClicked: cal.toggle()
    CalendarPopup { id: cal; anchorItem: pill; now: clock.date }
}
