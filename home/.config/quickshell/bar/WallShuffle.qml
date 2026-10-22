// Wallpaper shuffle: every N minutes picks another picture from ~/Pictures/wallpaper
// (only the mono-* ones while the monochrome theme is on). Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    readonly property int minutes: Settings.cur("wall_shuffle")
    Timer {
        running: parent.minutes > 0; repeat: true
        interval: Math.max(1, parent.minutes) * 60000
        onTriggered: pick.running = true
    }
    Process {
        id: pick
        command: ["sh", "-c", "ls ~/Pictures/wallpaper/mono-*.* 2>/dev/null | shuf -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = this.text.trim()
                if (!f || f === Settings.cur("wall_main")) return
                Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/bar/setwall.sh", "DP-1", f])
                Settings.setNow("wall_main", f)
            }
        }
    }
}
