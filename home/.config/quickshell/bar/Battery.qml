// Mouse battery (VXE dongle, via ~/.local/bin/mouse-battery.py). Checked every 5 minutes and whenever the
// control center opens. Warns once when it drops to 15%. Made by Claude.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property int percent: -1          // -1 = no mouse dongle
    property bool charging: false
    property bool asleep: false
    readonly property bool known: percent >= 0
    readonly property bool low: known && !charging && percent <= 20
    readonly property string icon: charging ? "\u{f0084}" : "\u{f037d}"
    property bool warned: false

    function refresh() { if (!proc.running) proc.running = true }
    Timer { interval: 300000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
    Process {
        id: proc
        command: [Quickshell.env("HOME") + "/.local/bin/mouse-battery.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                let d = {}
                try { d = JSON.parse(this.text) } catch (e) {}
                root.percent = d.percent !== undefined ? d.percent : -1
                root.charging = !!d.charging
                root.asleep = !!d.asleep
                if (root.charging || root.percent > 20) root.warned = false
                else if (root.known && root.percent <= 15 && !root.warned) {
                    root.warned = true
                    Quickshell.execDetached(["notify-send", "-a", "Mouse", "-i", "input-mouse", "Mouse battery low",
                                             root.percent + "% left – time to charge it"])
                }
            }
        }
    }
}
