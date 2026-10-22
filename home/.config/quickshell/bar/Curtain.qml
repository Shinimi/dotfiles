// Curtains (Tsugumori-style, in mono): two black panels slide in from the sides, meet at a thin white seam,
// something happens behind them (lock / new wallpaper), then they part again. On every screen.
//   qs ipc call curtain lock                       → close, lock the screen, open
//   qs ipc call curtain wall <DP-1|DP-2|both> <img> → close, swap the wallpaper, open
// Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root
    property bool closed: false
    property bool shown: false
    property string label: ""
    property string sub: ""
    property var after: null                  // what to run once the curtains have met
    property int hold: 450

    function play(lbl, sb, fn, holdMs) {
        if (shown) return
        label = lbl; sub = sb; after = fn; hold = holdMs || 450
        shown = true; closed = true; atClose.restart()
    }
    Timer { id: atClose; interval: 430; onTriggered: { if (root.after) root.after(); reopen.interval = root.hold; reopen.restart() } }
    Timer { id: reopen; onTriggered: { root.closed = false; done.restart() } }
    Timer { id: done; interval: 480; onTriggered: root.shown = false }

    IpcHandler {
        target: "curtain"
        function lock(): void {
            // through hypridle when it runs (it pauses music too); straight to hyprlock when "keep awake" stopped it
            root.play("LOCK", "施錠", () => Quickshell.execDetached(["sh", "-c",
                "if pgrep -x hypridle >/dev/null; then loginctl lock-session; else " +
                (Settings.cur("pause_on_lock") ? "playerctl -a pause; " : "") + "pidof hyprlock || hyprlock; fi"]), 900)
        }
        function wall(target: string, path: string): void {
            root.play("WALLPAPER", "壁紙", () => Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/bar/setwall.sh", target, path]), 420)
        }
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: w
            required property var modelData
            screen: modelData
            visible: root.shown
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qsbar-curtain"
            color: "transparent"
            mask: Region {}

            Repeater {
                model: [0, 1]   // left, right
                Rectangle {
                    required property int modelData
                    readonly property bool isLeft: modelData === 0
                    width: w.width / 2 + 1; height: w.height
                    x: isLeft ? (root.closed ? 0 : -width) : (root.closed ? w.width / 2 : w.width)
                    color: "#050505"
                    Behavior on x { NumberAnimation { duration: 420; easing.type: Easing.InOutQuart } }
                    Rectangle {   // the seam
                        x: parent.isLeft ? parent.width - 1 : 0; width: 1; height: parent.height; color: "#ffffff"; opacity: 0.85
                    }
                    Repeater {   // fine horizontal scan lines on each panel
                        model: 6
                        Rectangle {
                            required property int index
                            x: parent.isLeft ? parent.width - 160 - index * 30 : 20 + index * 30
                            y: w.height * (0.2 + index * 0.12); width: 140; height: 1; color: "#18ffffff"
                        }
                    }
                }
            }
            Column {   // label at the seam once closed
                anchors.centerIn: parent; spacing: 8
                opacity: root.closed ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 220 } }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: lbl.implicitWidth + 30; height: 28; color: "#ffffff"
                    Text { id: lbl; anchors.centerIn: parent; text: root.label; color: "#050505"; font.family: Theme.font; font.pixelSize: 12; font.letterSpacing: 4; font.bold: true }
                }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.sub; color: "#9a9a9a"; font.family: "Noto Sans CJK JP"; font.pixelSize: 13 }
            }
        }
    }
}
