// Shared system toggles for the control center and settings: night light, keep awake,
// power profile, audio FX. Made by Claude.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: s
    readonly property string scripts: Quickshell.env("HOME") + "/.config/hypr/scripts"
    readonly property string fxCmd: Quickshell.env("HOME") + "/.local/bin/audio-fx.sh"
    property bool night: false
    property bool awake: false
    property string profile: "balanced"
    readonly property bool perf: profile === "performance"
    property var fx: ({ mic: false, eq: false, preset: "flat" })

    function refresh() { st.running = true; fxState.running = true }
    function run(cmd) { Quickshell.execDetached(cmd); later.restart() }
    function toggleNight() { run([scripts + "/nightlight.sh"]) }
    function toggleAwake() { run([scripts + "/idle-inhibit.sh"]) }
    function setProfile(p) { profile = p; run(["powerprofilesctl", "set", p]) }
    function fxRun(args) { Quickshell.execDetached([fxCmd].concat(args)); fxLater.restart() }
    function fxToggle(k) { const n = Object.assign({}, fx); n[k] = !fx[k]; fx = n; fxRun([k, n[k] ? "on" : "off"]) }
    function fxPreset(p) { const n = Object.assign({}, fx); n.preset = p; fx = n; fxRun(["preset", p]) }

    Process {
        id: st
        command: ["sh", "-c", "pgrep -x hyprsunset >/dev/null && echo n1 || echo n0; pgrep -x hypridle >/dev/null && echo a0 || echo a1; echo p=$(powerprofilesctl get)"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = this.text
                s.night = t.indexOf("n1") >= 0; s.awake = t.indexOf("a1") >= 0
                const m = t.match(/p=(\S+)/); if (m) s.profile = m[1]
            }
        }
    }
    Process {
        id: fxState
        command: [s.fxCmd, "status"]
        stdout: StdioCollector { onStreamFinished: { try { s.fx = JSON.parse(this.text) } catch (e) {} } }
    }
    Timer { id: later; interval: 500; onTriggered: st.running = true }
    Timer { id: fxLater; interval: 400; onTriggered: fxState.running = true }
    Component.onCompleted: refresh()
}
