// Countdown timer + stopwatch shared by the clock pill and panel. Made by Claude.
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: t
    // countdown
    property int total: 300          // seconds chosen
    property int remaining: 300
    property bool timerRunning: false
    readonly property bool timerActive: timerRunning || remaining !== total
    function setMinutes(m) { if (!timerRunning) { total = Math.max(60, Math.min(5999, m * 60)); remaining = total } }
    function addMinutes(m) { total = Math.max(60, Math.min(5999, total + m * 60)); if (!timerRunning) remaining = total; else remaining = Math.max(1, remaining + m * 60) }
    function toggleTimer() { if (remaining <= 0) remaining = total; timerRunning = !timerRunning }
    function resetTimer() { timerRunning = false; remaining = total }
    Timer {
        interval: 1000; repeat: true; running: t.timerRunning
        onTriggered: {
            t.remaining -= 1
            if (t.remaining <= 0) {
                t.timerRunning = false; t.remaining = t.total
                Quickshell.execDetached(["notify-send", "-a", "Timer", "-u", "critical", "⏰  Time's up", Math.round(t.total / 60) + " minute timer finished"])
                Quickshell.execDetached(["sh", "-c", "for i in 1 2 3; do pw-play /usr/share/sounds/freedesktop/stereo/complete.oga; done"])
            }
        }
    }

    // stopwatch
    property int elapsed: 0           // centiseconds
    property bool swRunning: false
    readonly property bool swActive: swRunning || elapsed > 0
    property real _start: 0
    property int _base: 0
    function toggleStopwatch() {
        if (swRunning) { swRunning = false; _base = elapsed }
        else { _start = Date.now(); swRunning = true }
    }
    function resetStopwatch() { swRunning = false; elapsed = 0; _base = 0 }
    Timer { interval: 50; repeat: true; running: t.swRunning; onTriggered: t.elapsed = t._base + Math.floor((Date.now() - t._start) / 10) }

    function fmt(sec) { return Math.floor(sec / 60) + ":" + ("0" + (sec % 60)).slice(-2) }
    function fmtSw(cs) { const s = Math.floor(cs / 100); return Math.floor(s / 60) + ":" + ("0" + (s % 60)).slice(-2) + "." + ("0" + (cs % 100)).slice(-2) }
}
