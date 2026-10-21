// Polls stats.sh every 2 s and exposes the values. Made by Claude.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    property var d: ({ cpu: 0, cpuTemp: 0, cpuFreq: 0, ramUsed: 0, ramTotal: 0, ram: 0,
                       gpu: 0, gpuTemp: 0, gpuPower: 0, vramUsed: 0, vramTotal: 0, uptime: "" })
    Process {
        id: proc
        command: [Qt.resolvedUrl("stats.sh").toString().replace("file://", "")]
        stdout: StdioCollector {
            onStreamFinished: { try { d = JSON.parse(this.text) } catch (e) {} }
        }
    }
    Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: proc.running = true }
}
