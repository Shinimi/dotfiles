// The middle of the bar: just the time (and a running timer). Click it for the date, weather and month
// (`calendar: false` on screens that shouldn't). Made by Claude.
import QtQuick
import Quickshell

Pill {
    id: pill
    property alias popup: cal
    property bool calendar: true
    property var player: null            // the bar passes the playing player: its song shows after the date
    readonly property bool playing: !!(player && player.isPlaying && player.trackTitle)
    padding: 12
    active: cal.visible
    SystemClock { id: clock; precision: Settings.cur("clock_seconds") ? SystemClock.Seconds : SystemClock.Minutes }
    // one size, one weight, one baseline: the time is just brighter than the date and weather
    Label {
        text: Qt.formatDateTime(clock.date, (Settings.cur("clock_12h") ? "h:mm" : "HH:mm") + (Settings.cur("clock_seconds") ? ":ss" : "") + (Settings.cur("clock_12h") ? " AP" : ""))
        color: "#ffffff"; font.pixelSize: 13; font.weight: Font.Bold; font.letterSpacing: 1
    }
    Label { text: Qt.formatDate(clock.date, "ddd d MMM"); color: "#8a8a8a"; font.pixelSize: 11 }
    Rectangle { visible: pill.playing; width: 1; height: 12; color: "#2affffff"; anchors.verticalCenter: parent ? parent.verticalCenter : undefined }
    MusicBars { visible: pill.playing; running: pill.playing; anchors.verticalCenter: parent ? parent.verticalCenter : undefined }
    Label { visible: pill.playing; text: pill.player ? (t => t.length > 28 ? t.slice(0, 27) + "…" : t)(pill.player.trackTitle || "") : ""; color: "#c8c8c8"; font.pixelSize: 11 }
    Label { visible: Timers.timerRunning; text: "\u{f051f} " + Timers.fmt(Timers.remaining); color: "#ffffff"; font.pixelSize: 11 }
    Label { visible: Timers.swRunning && !Timers.timerRunning; text: "\u{f13ab} " + Timers.fmt(Math.floor(Timers.elapsed / 100)); color: "#ffffff"; font.pixelSize: 11 }
    onClicked: if (pill.calendar) cal.toggle()
    CalendarPopup { id: cal; anchorItem: pill; now: clock.date }
}
