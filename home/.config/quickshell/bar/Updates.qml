// Pending update count, checked every 30 min. Made by Claude.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    property int total: 0; property int repo: 0; property int aur: 0
    function check() { proc.running = true }
    Process {
        id: proc
        command: [Qt.resolvedUrl("updates.sh").toString().replace("file://", "")]
        stdout: StdioCollector { onStreamFinished: { try { const j = JSON.parse(this.text); total = j.total; repo = j.repo; aur = j.aur } catch (e) {} } }
    }
    Timer { interval: 30 * 60 * 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: proc.running = true }
}
