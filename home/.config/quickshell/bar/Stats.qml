// Polls stats.sh and exposes the values: every 2 s while a panel shows them, every 30 s otherwise. Made by Claude.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    property var d: ({ cpu: 0, cpuTemp: 0, cpuFreq: 0, ramUsed: 0, ramTotal: 0, ram: 0,
                       gpu: 0, gpuTemp: 0, gpuPower: 0, vramUsed: 0, vramTotal: 0, uptime: "",
                       gpuHot: 0, gpuMem: 0, fan: 0, gpuCap: 0, fanMode: "balanced", fanOk: 0 })
    function refresh() { proc.running = true }
    Process {
        id: proc
        command: [Qt.resolvedUrl("stats.sh").toString().replace("file://", "")]
        stdout: StdioCollector {
            onStreamFinished: { try { d = JSON.parse(this.text) } catch (e) {} }
        }
    }
    property int watchers: 0          // panels that are open and showing stats (they add/remove themselves)
    onWatchersChanged: if (watchers > 0) proc.running = true
    Timer { interval: watchers > 0 ? 2000 : 30000; running: true; repeat: true; triggeredOnStart: true; onTriggered: proc.running = true }
}
